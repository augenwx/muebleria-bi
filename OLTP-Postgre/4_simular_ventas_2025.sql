-- ============================================================
-- 4_simular_ventas_2025.sql
-- Ventas simuladas para comparacion interanual YoY en Power BI
-- Rango exclusivo: 2025-01-01 a 2025-12-31
-- ============================================================

SET search_path TO transaccional, public;

DO $$
BEGIN
    IF NOT EXISTS (SELECT 1 FROM cliente) THEN
        RAISE EXCEPTION 'No existen clientes maestros para simular ventas 2025.';
    END IF;

    IF NOT EXISTS (SELECT 1 FROM producto) THEN
        RAISE EXCEPTION 'No existen productos maestros para simular ventas 2025.';
    END IF;

    IF NOT EXISTS (
        SELECT 1
        FROM usuario
        WHERE rol = 'vendedor'
          AND activo IS TRUE
    ) THEN
        RAISE EXCEPTION 'No existen usuarios vendedores activos para simular ventas 2025.';
    END IF;

    IF NOT EXISTS (SELECT 1 FROM tipo_venta WHERE nombre = 'Contado') THEN
        RAISE EXCEPTION 'No existe tipo_venta = Contado.';
    END IF;

    IF NOT EXISTS (SELECT 1 FROM tipo_venta WHERE nombre ILIKE 'Cr%%') THEN
        RAISE EXCEPTION 'No existe tipo_venta de credito.';
    END IF;

    IF EXISTS (
        SELECT 1
        FROM venta
        WHERE fecha BETWEEN DATE '2025-01-01' AND DATE '2025-12-31'
          AND notas = 'SIM_2025_YOY'
    ) THEN
        RAISE EXCEPTION 'Ya existen ventas simuladas 2025 con notas = SIM_2025_YOY. Elimina esas filas si necesitas regenerarlas.';
    END IF;
END $$;

WITH params AS MATERIALIZED (
    SELECT (150 + FLOOR(random() * 101))::INT AS total_transacciones
),
pesos_mensuales(mes, peso) AS (
    VALUES
        (1,  4),  -- Enero bajo
        (2,  5),  -- Febrero bajo
        (3,  8),
        (4,  8),
        (5,  9),
        (6, 10),
        (7, 22),  -- Julio alto por gratificaciones
        (8,  9),
        (9,  9),
        (10, 9),
        (11,10),
        (12,24)   -- Diciembre alto por Navidad
),
pool_meses AS (
    SELECT pm.mes
    FROM pesos_mensuales pm
    CROSS JOIN LATERAL generate_series(1, pm.peso)
),
base AS (
    SELECT gs.n AS fila
    FROM params p
    CROSS JOIN LATERAL generate_series(1, p.total_transacciones) AS gs(n)
),
ventas_simuladas AS (
    SELECT
        (
            make_date(2025, mes_venta.mes, 1)
            + FLOOR(
                random()
                * EXTRACT(
                    DAY FROM (
                        date_trunc('month', make_date(2025, mes_venta.mes, 1))::date
                        + INTERVAL '1 month'
                        - INTERVAL '1 day'
                    )
                )
            )::INT
        )::DATE AS fecha,
        c.id AS cliente_id,
        c.tipo_cliente_id,
        p.id AS producto_id,
        CASE
            WHEN tc.nombre = 'Mayorista' THEN (2 + FLOOR(random() * 9))::INT
            WHEN mes_venta.mes IN (7, 12) THEN (1 + FLOOR(random() * 5))::INT
            ELSE (1 + FLOOR(random() * 4))::INT
        END AS cantidad,
        CASE
            WHEN tc.nombre = 'Mayorista'
                THEN COALESCE(p.precio_venta_mayorista, p.precio_venta_retail, 0)
            ELSE COALESCE(p.precio_venta_retail, p.precio_venta_mayorista, 0)
        END AS precio_unitario,
        tv.id AS tipo_venta_id,
        u.id AS usuario_id,
        base.fila
    FROM base
    JOIN LATERAL (
        SELECT mes
        FROM pool_meses
        ORDER BY random() + base.fila * 0
        LIMIT 1
    ) mes_venta ON TRUE
    JOIN LATERAL (
        SELECT *
        FROM cliente
        ORDER BY random() + base.fila * 0
        LIMIT 1
    ) c ON TRUE
    JOIN tipo_cliente tc ON tc.id = c.tipo_cliente_id
    JOIN LATERAL (
        SELECT *
        FROM producto
        WHERE COALESCE(precio_venta_retail, precio_venta_mayorista, 0) > 0
        ORDER BY random() + base.fila * 0
        LIMIT 1
    ) p ON TRUE
    JOIN LATERAL (
        SELECT *
        FROM usuario
        WHERE rol = 'vendedor'
          AND activo IS TRUE
        ORDER BY random() + base.fila * 0
        LIMIT 1
    ) u ON TRUE
    CROSS JOIN LATERAL (
        SELECT CASE
            WHEN tc.nombre = 'Mayorista' AND random() + base.fila * 0 < 0.65 THEN 'Cr%'
            WHEN tc.nombre <> 'Mayorista' AND random() + base.fila * 0 < 0.12 THEN 'Cr%'
            ELSE 'Contado'
        END AS patron_tipo_venta
    ) tipo_elegido
    JOIN tipo_venta tv ON tv.nombre ILIKE tipo_elegido.patron_tipo_venta
),
ventas_insertadas AS (
    INSERT INTO venta (
        fecha,
        cliente_id,
        tipo_cliente_id,
        producto_id,
        cantidad,
        precio_unitario,
        total_venta,
        tipo_venta_id,
        usuario_id,
        notas,
        created_at
    )
    SELECT
        fecha,
        cliente_id,
        tipo_cliente_id,
        producto_id,
        cantidad,
        precio_unitario,
        ROUND(cantidad * precio_unitario, 2) AS total_venta,
        tipo_venta_id,
        usuario_id,
        'SIM_2025_YOY' AS notas,
        fecha::timestamp
            + INTERVAL '8 hours'
            + (random() * INTERVAL '10 hours') AS created_at
    FROM ventas_simuladas
    RETURNING id, fecha, total_venta, tipo_venta_id
),
cuentas_credito AS (
    INSERT INTO cuentas_cobrar (
        venta_id,
        fecha_emision,
        fecha_vencimiento,
        monto_total,
        saldo_pendiente,
        estado,
        numero_cuota,
        total_cuotas,
        created_at
    )
    SELECT
        vi.id,
        vi.fecha,
        vi.fecha + INTERVAL '15 days',
        vi.total_venta,
        vi.total_venta,
        CASE
            WHEN vi.fecha + INTERVAL '15 days' < CURRENT_DATE THEN 'vencido'
            ELSE 'pendiente'
        END,
        1,
        1,
        vi.fecha::timestamp + INTERVAL '18 hours'
    FROM ventas_insertadas vi
    JOIN tipo_venta tv ON tv.id = vi.tipo_venta_id
    WHERE tv.nombre ILIKE 'Cr%'
    RETURNING id
)
SELECT
    (SELECT COUNT(*) FROM ventas_insertadas) AS ventas_2025_insertadas,
    (SELECT COUNT(*) FROM cuentas_credito)  AS cuentas_credito_insertadas;
