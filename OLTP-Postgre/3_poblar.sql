-- ============================================================
-- 3_poblar.sql  — v4.0
-- POBLAR DIMENSIONES Y TABLAS DE HECHOS (ETL MANUAL)
-- Esquema: marts
--
-- CAMBIOS respecto a versión anterior:
--   - Esquema cambiado de 'estrella' a 'marts'
--   - Dimensiones nuevas: dim_proveedor, dim_destino_prod,
--     dim_tipo_venta, dim_usuario
--   - dim_tiempo: incluye dia_semana_num, dia_semana_nombre,
--     semana_anio (ya no tiene TEMPORADA / ES_PICO)
--   - dim_producto: incluye margen_retail y margen_mayorista
--     calculados (ya no tiene SCD / campos derivados complejos)
--   - dim_cliente: incluye razon_social, tipo_cliente desde
--     tabla tipo_cliente (ya no usa CDCLIENTE / códigos)
--   - dim_material: usa unidad_nombre y unidad_abreviatura
--     (ya no tiene PROVEEDOR embebido)
--   - fact_inventario: basado en movimiento_material (kardex),
--     no en compra_material (reemplaza HCOMPRAS_MATERIAL)
--   - fact_ventas: desde vw_fact_ventas_prep (ya no
--     vw_g_ventas_muebleria)
-- ============================================================

SET search_path TO marts, transaccional, public;

-- ============================================================
-- 1. POBLAR DIMENSIONES
-- ============================================================

-- ► dim_tiempo
--   Fuentes: venta, produccion, movimiento_material, gasto
INSERT INTO dim_tiempo (
    fecha_key, fecha, dia, mes, mes_nombre,
    trimestre, anio, dia_semana_num, dia_semana_nombre, semana_anio
)
SELECT DISTINCT
    CAST(TO_CHAR(f, 'YYYYMMDD') AS INT)          AS fecha_key,
    f                                             AS fecha,
    EXTRACT(DAY     FROM f)::INT                  AS dia,
    EXTRACT(MONTH   FROM f)::INT                  AS mes,
    TO_CHAR(f, 'TMMonth')                         AS mes_nombre,
    EXTRACT(QUARTER FROM f)::INT                  AS trimestre,
    EXTRACT(YEAR    FROM f)::INT                  AS anio,
    EXTRACT(DOW     FROM f)::INT                  AS dia_semana_num,
    TO_CHAR(f, 'TMDay')                           AS dia_semana_nombre,
    EXTRACT(WEEK    FROM f)::INT                  AS semana_anio
FROM (
    -- fechas de ventas
    SELECT v.fecha AS f FROM venta v
    UNION
    -- fechas de producción
    SELECT pr.fecha_produccion FROM produccion pr
    UNION
    -- fechas de movimientos de material (kardex)
    SELECT mm.fecha FROM movimiento_material mm
    UNION
    -- fechas de gastos individuales
    SELECT g.fecha FROM gasto g
) sub
WHERE f IS NOT NULL
ON CONFLICT (fecha_key) DO NOTHING;

-- ► dim_producto
--   Productos con márgenes estándar calculados
INSERT INTO dim_producto (
    producto_id, nombre, costo_estandar,
    precio_venta_retail, precio_venta_mayorista,
    margen_retail, margen_mayorista, activo
)
SELECT
    p.id                                                  AS producto_id,
    p.nombre,
    p.costo_estandar,
    p.precio_venta_retail,
    p.precio_venta_mayorista,
    ROUND(p.precio_venta_retail    - p.costo_estandar, 2) AS margen_retail,
    ROUND(p.precio_venta_mayorista - p.costo_estandar, 2) AS margen_mayorista,
    p.activo
FROM producto p;

-- ► dim_cliente
--   Clientes con tipo_cliente desde tabla tipo_cliente
INSERT INTO dim_cliente (
    cliente_id, documento, nombre, razon_social,
    tipo_cliente, direccion, telefono, email,
    limite_credito, estado, activo
)
SELECT
    c.id                                                  AS cliente_id,
    c.documento,
    c.nombre,
    COALESCE(c.razon_social, c.nombre)                    AS razon_social,
    tc.nombre                                             AS tipo_cliente,
    c.direccion,
    c.telefono,
    c.email,
    c.limite_credito,
    c.estado,
    c.activo
FROM cliente c
LEFT JOIN tipo_cliente tc ON tc.id = c.tipo_cliente_id;

-- ► dim_material
--   Materiales con unidad de medida (nombre y abreviatura)
INSERT INTO dim_material (
    material_id, nombre, unidad_nombre,
    unidad_abreviatura, stock_minimo, activo
)
SELECT
    m.id                                                  AS material_id,
    m.nombre,
    um.nombre                                             AS unidad_nombre,
    um.abreviatura                                        AS unidad_abreviatura,
    m.stock_minimo,
    m.activo
FROM material m
LEFT JOIN unidad_medida um ON um.id = m.unidad_medida_id;

-- ► dim_categoria_gasto
--   Categorías directas desde catálogo
INSERT INTO dim_categoria_gasto (
    categoria_id, categoria, tipo_gasto
)
SELECT
    cg.id                                                 AS categoria_id,
    cg.nombre                                             AS categoria,
    cg.tipo                                               AS tipo_gasto
FROM categoria_gasto cg;

-- ► dim_proveedor
--   Proveedores de materiales
INSERT INTO dim_proveedor (
    proveedor_id, ruc, nombre, contacto,
    telefono, email, direccion, activo
)
SELECT
    p.id                                                  AS proveedor_id,
    p.ruc,
    p.nombre,
    p.contacto,
    p.telefono,
    p.email,
    p.direccion,
    p.activo
FROM proveedor p;

-- ► dim_destino_prod
--   Destinos de producción
INSERT INTO dim_destino_prod (destino_id, destino)
SELECT
    dp.id                                                 AS destino_id,
    dp.descripcion                                        AS destino
FROM destino_produccion dp;

-- ► dim_tipo_venta
--   Tipos de venta (Contado / Crédito)
INSERT INTO dim_tipo_venta (tipo_venta_id, tipo_venta)
SELECT
    tv.id                                                 AS tipo_venta_id,
    tv.nombre                                             AS tipo_venta
FROM tipo_venta tv;

-- ► dim_usuario
--   Usuarios del sistema
INSERT INTO dim_usuario (
    usuario_id, nombre, email, rol, activo
)
SELECT
    u.id                                                  AS usuario_id,
    u.nombre,
    u.email,
    u.rol,
    u.activo
FROM usuario u;

-- ============================================================
-- 2. POBLAR HECHOS
-- ============================================================

-- ► fact_gastos
--   Fuente: tabla gasto (fecha individual + anio/mes GENERATED)
INSERT INTO fact_gastos (
    gasto_id, tiempo_key, categoria_id, usuario_id,
    anio, mes, monto, detalle, comprobante
)
SELECT
    g.id                                                  AS gasto_id,
    CAST(TO_CHAR(g.fecha, 'YYYYMMDD') AS INT)             AS tiempo_key,
    g.categoria_id,
    g.usuario_id,
    g.anio,
    g.mes,
    g.monto,
    g.detalle,
    g.comprobante
FROM gasto g;

-- ► fact_produccion
--   1 fila por lote de producción (sin fan-out por consumo_material)
INSERT INTO fact_produccion (
    produccion_id, tiempo_key, producto_id, destino_id,
    usuario_id, orden_id_oltp, numero_orden,
    cantidad_producida, costo_materia_prima, mano_de_obra,
    costo_total, costo_unitario
)
SELECT
    pr.id                                                 AS produccion_id,
    CAST(TO_CHAR(pr.fecha_produccion, 'YYYYMMDD') AS INT) AS tiempo_key,
    pr.producto_id,
    pr.destino_id,
    op.responsable_id                                     AS usuario_id,
    pr.orden_produccion_id                                AS orden_id_oltp,
    op.numero_orden,
    pr.cantidad_producida,
    pr.costo_materia_prima,
    pr.mano_de_obra,
    pr.costo_total,
    pr.costo_unitario
FROM produccion pr
LEFT JOIN orden_produccion op ON op.id = pr.orden_produccion_id;

-- ► fact_inventario
--   Fuente: movimiento_material (kardex unificado)
--   proveedor_id solo se llena para entradas por compra_material
INSERT INTO fact_inventario (
    movimiento_id, tiempo_key, material_id, proveedor_id,
    tipo_movimiento, cantidad, precio_unitario, total_valor,
    referencia_id, referencia_tabla, notas
)
SELECT
    mm.id                                                 AS movimiento_id,
    CAST(TO_CHAR(mm.fecha, 'YYYYMMDD') AS INT)            AS tiempo_key,
    mm.material_id,
    -- proveedor solo cuando es entrada por compra (NULLs son correctos)
    cm.proveedor_id,
    mm.tipo_movimiento,
    mm.cantidad,
    mm.precio_unitario,
    mm.total_valor,
    mm.referencia_id,
    mm.referencia_tabla,
    mm.notas
FROM movimiento_material mm
LEFT JOIN compra_material cm
    ON  mm.referencia_tabla = 'compra_material'
    AND mm.referencia_id    = cm.id;

-- ► fact_ventas
--   Fuente: vw_fact_ventas_prep (vista creada en 2_G_pasos.sql)
INSERT INTO fact_ventas (
    detalle_venta_id, tiempo_key, cliente_id, producto_id,
    tipo_venta_id, usuario_id, venta_id_oltp,
    cantidad, precio_unitario, subtotal,
    costo_estandar, costo_total, margen_bruto, pct_margen
)
SELECT
    detalle_venta_id, tiempo_key, cliente_id, producto_id,
    tipo_venta_id, usuario_id, venta_id_oltp,
    cantidad, precio_unitario, subtotal,
    costo_estandar, costo_total, margen_bruto, pct_margen
FROM vw_fact_ventas_prep;

-- ============================================================
-- 3. VALIDACIÓN FINAL
-- ============================================================

SELECT 'dim_tiempo'          AS tabla, COUNT(*) AS filas FROM dim_tiempo
UNION ALL SELECT 'dim_producto',       COUNT(*) FROM dim_producto
UNION ALL SELECT 'dim_cliente',        COUNT(*) FROM dim_cliente
UNION ALL SELECT 'dim_material',       COUNT(*) FROM dim_material
UNION ALL SELECT 'dim_categoria_gasto',COUNT(*) FROM dim_categoria_gasto
UNION ALL SELECT 'dim_proveedor',      COUNT(*) FROM dim_proveedor
UNION ALL SELECT 'dim_destino_prod',   COUNT(*) FROM dim_destino_prod
UNION ALL SELECT 'dim_tipo_venta',     COUNT(*) FROM dim_tipo_venta
UNION ALL SELECT 'dim_usuario',        COUNT(*) FROM dim_usuario
UNION ALL SELECT '--- HECHOS ---',     0
UNION ALL SELECT 'fact_ventas',        COUNT(*) FROM fact_ventas
UNION ALL SELECT 'fact_produccion',    COUNT(*) FROM fact_produccion
UNION ALL SELECT 'fact_inventario',    COUNT(*) FROM fact_inventario
UNION ALL SELECT 'fact_gastos',        COUNT(*) FROM fact_gastos
ORDER BY 1;

-- Verificación de totales vs OLTP (deben coincidir)
SELECT 'Ventas OLTP'    AS origen, SUM(total_venta)    AS total_importe FROM venta
UNION ALL
SELECT 'Ventas DM',               SUM(subtotal)                        FROM fact_ventas;

SELECT 'Gastos OLTP'    AS origen, SUM(monto)           AS total_monto  FROM gasto
UNION ALL
SELECT 'Gastos DM',               SUM(monto)                           FROM fact_gastos;

-- ============================================================
-- FIN 3_poblar.sql
-- ============================================================