-- ============================================================
--  MUEBLERÍA / CARPINTERÍA â€” ESTRUCTURA DE BASE DE DATOS
--  
--  Motor:   PostgreSQL 14+
--  Esquema: transaccional
-- ============================================================
--  MÃ“DULOS:
--    1.  Catálogos / Maestros
--    2.  Productos y Stock
--    3.  Proveedores
--    4.  Materiales e Inventario
--    5.  Clientes
--    6.  Usuarios y Roles
--    7.  Trabajadores
--    8.  Ventas (cabecera + detalle multi-producto)
--    9.  Devoluciones
--   10.  Cuentas por Cobrar y Pagos
--   11.  Ã“rdenes de Producción y Producción
--   12.  Consumo de Materiales
--   13.  Gastos Operativos
--   14.  Caja
--   15.  Índices
--   16.  Funciones y Triggers
--   17.  Vistas Analíticas
-- ============================================================

CREATE SCHEMA IF NOT EXISTS transaccional;
SET search_path TO transaccional, public;

-- ============================================================
--  1. CATÁLOGOS
-- ============================================================

CREATE TABLE IF NOT EXISTS tipo_cliente (
    id     SERIAL PRIMARY KEY,
    nombre VARCHAR(50) NOT NULL UNIQUE
);

CREATE TABLE IF NOT EXISTS tipo_venta (
    id     SERIAL PRIMARY KEY,
    nombre VARCHAR(50) NOT NULL UNIQUE
);

CREATE TABLE IF NOT EXISTS destino_produccion (
    id          SERIAL PRIMARY KEY,
    descripcion VARCHAR(100) NOT NULL UNIQUE
);

CREATE TABLE IF NOT EXISTS unidad_medida (
    id          SERIAL PRIMARY KEY,
    nombre      VARCHAR(50)  NOT NULL UNIQUE,
    abreviatura VARCHAR(10)
);

CREATE TABLE IF NOT EXISTS categoria_gasto (
    id     SERIAL PRIMARY KEY,
    nombre VARCHAR(150) NOT NULL UNIQUE,
    tipo   VARCHAR(20)  NOT NULL DEFAULT 'variable'
           CHECK (tipo IN ('fijo', 'variable'))
);

-- ============================================================
--  2. PRODUCTOS Y STOCK
-- ============================================================

CREATE TABLE IF NOT EXISTS producto (
    id                     SERIAL PRIMARY KEY,
    nombre                 VARCHAR(100)  NOT NULL UNIQUE,
    costo_estandar         NUMERIC(10,2) NOT NULL DEFAULT 0   CHECK (costo_estandar >= 0),
    precio_venta_retail    NUMERIC(10,2) NOT NULL             CHECK (precio_venta_retail >= 0),
    precio_venta_mayorista NUMERIC(10,2) NOT NULL             CHECK (precio_venta_mayorista >= 0),
    activo                 BOOLEAN       NOT NULL DEFAULT TRUE,
    created_at             TIMESTAMPTZ   DEFAULT NOW()
);

CREATE TABLE IF NOT EXISTS stock_producto_terminado (
    producto_id          INT PRIMARY KEY REFERENCES producto(id),
    cantidad_disponible  INT NOT NULL DEFAULT 0 CHECK (cantidad_disponible >= 0),
    cantidad_reservada   INT NOT NULL DEFAULT 0 CHECK (cantidad_reservada  >= 0),
    punto_reorden        INT NOT NULL DEFAULT 5,
    ultima_actualizacion TIMESTAMPTZ DEFAULT NOW()
);

-- ============================================================
--  3. PROVEEDORES
-- ============================================================

CREATE TABLE IF NOT EXISTS proveedor (
    id         SERIAL PRIMARY KEY,
    ruc        VARCHAR(20)  UNIQUE,
    nombre     VARCHAR(100) NOT NULL,
    contacto   VARCHAR(100),
    telefono   VARCHAR(20),
    email      VARCHAR(100),
    direccion  TEXT,
    activo     BOOLEAN     NOT NULL DEFAULT TRUE,
    created_at TIMESTAMPTZ DEFAULT NOW()
);

-- ============================================================
--  4. MATERIALES E INVENTARIO
-- ============================================================

CREATE TABLE IF NOT EXISTS material (
    id                     SERIAL PRIMARY KEY,
    nombre                 VARCHAR(150) NOT NULL UNIQUE,
    unidad_medida_id       INT NOT NULL REFERENCES unidad_medida(id),
    stock_minimo           NUMERIC(10,2) NOT NULL DEFAULT 0,
    stock_actual           NUMERIC(10,2) NOT NULL DEFAULT 0,
    proveedor_preferido_id INT REFERENCES proveedor(id),
    activo                 BOOLEAN NOT NULL DEFAULT TRUE,
    created_at             TIMESTAMPTZ DEFAULT NOW()
);

CREATE TABLE IF NOT EXISTS compra_material (
    id              SERIAL PRIMARY KEY,
    fecha           DATE          NOT NULL,
    proveedor_id    INT           REFERENCES proveedor(id),
    material_id     INT           NOT NULL REFERENCES material(id),
    cantidad        NUMERIC(10,2) NOT NULL CHECK (cantidad > 0),
    precio_unitario NUMERIC(10,2) NOT NULL CHECK (precio_unitario >= 0),
    total_compra    NUMERIC(12,2) GENERATED ALWAYS AS (cantidad * precio_unitario) STORED,
    factura_numero  VARCHAR(50),
    notas           TEXT,
    usuario_id      INT,          -- FK agregada después de crear usuario
    created_at      TIMESTAMPTZ DEFAULT NOW()
);

-- Kardex completo de movimientos de materiales
CREATE TABLE IF NOT EXISTS movimiento_material (
    id               SERIAL PRIMARY KEY,
    fecha            DATE         NOT NULL,
    material_id      INT          NOT NULL REFERENCES material(id),
    tipo_movimiento  VARCHAR(20)  NOT NULL CHECK (tipo_movimiento IN ('entrada','salida','ajuste')),
    cantidad         NUMERIC(10,2) NOT NULL,
    precio_unitario  NUMERIC(10,2),
    total_valor      NUMERIC(12,2),
    referencia_id    INT,
    referencia_tabla VARCHAR(50),
    notas            TEXT,
    created_at       TIMESTAMPTZ DEFAULT NOW()
);

-- ============================================================
--  5. CLIENTES
-- ============================================================

CREATE TABLE IF NOT EXISTS cliente (
    id              SERIAL PRIMARY KEY,
    tipo_cliente_id INT           NOT NULL REFERENCES tipo_cliente(id),
    documento       VARCHAR(20)   UNIQUE,
    nombre          VARCHAR(150)  NOT NULL,
    razon_social    VARCHAR(150),
    direccion       TEXT,
    telefono        VARCHAR(20),
    email           VARCHAR(100),
    limite_credito  NUMERIC(12,2) NOT NULL DEFAULT 0,
    saldo_pendiente NUMERIC(12,2) NOT NULL DEFAULT 0,
    estado          VARCHAR(20)   NOT NULL DEFAULT 'activo'
                    CHECK (estado IN ('activo','inactivo','moroso')),
    activo          BOOLEAN       NOT NULL DEFAULT TRUE,
    created_at      TIMESTAMPTZ   DEFAULT NOW(),
    updated_at      TIMESTAMPTZ   DEFAULT NOW()
);

-- ============================================================
--  6. USUARIOS Y ROLES
-- ============================================================

CREATE TABLE IF NOT EXISTS usuario (
    id         SERIAL PRIMARY KEY,
    nombre     VARCHAR(100) NOT NULL,
    email      VARCHAR(100) UNIQUE NOT NULL,
    rol        VARCHAR(50)  NOT NULL DEFAULT 'vendedor'
               CHECK (rol IN ('admin','vendedor','produccion','contador')),
    activo     BOOLEAN      NOT NULL DEFAULT TRUE,
    created_at TIMESTAMPTZ  DEFAULT NOW()
);

-- FK diferida: compra_material â†’ usuario
ALTER TABLE compra_material
    ADD CONSTRAINT fk_compra_usuario FOREIGN KEY (usuario_id) REFERENCES usuario(id);

-- ============================================================
--  7. TRABAJADORES
-- ============================================================

CREATE TABLE IF NOT EXISTS trabajador (
    id         SERIAL PRIMARY KEY,
    nombre     VARCHAR(150) NOT NULL,
    tipo       VARCHAR(20)  NOT NULL DEFAULT 'eventual'
               CHECK (tipo IN ('fijo','eventual')),
    activo     BOOLEAN      NOT NULL DEFAULT TRUE,
    created_at TIMESTAMPTZ  DEFAULT NOW()
);

-- ============================================================
--  8. VENTAS â€” CABECERA + DETALLE MULTI-PRODUCTO
-- ============================================================

CREATE TABLE IF NOT EXISTS venta (
    id            SERIAL PRIMARY KEY,
    fecha         DATE          NOT NULL,
    cliente_id    INT           NOT NULL REFERENCES cliente(id),
    tipo_venta_id INT           NOT NULL REFERENCES tipo_venta(id),
    total_venta   NUMERIC(12,2) NOT NULL DEFAULT 0 CHECK (total_venta >= 0),
    usuario_id    INT           REFERENCES usuario(id),
    observaciones TEXT,
    created_at    TIMESTAMPTZ   DEFAULT NOW()
);

CREATE TABLE IF NOT EXISTS detalle_venta (
    id              SERIAL PRIMARY KEY,
    venta_id        INT           NOT NULL REFERENCES venta(id) ON DELETE CASCADE,
    producto_id     INT           NOT NULL REFERENCES producto(id),
    cantidad        INT           NOT NULL CHECK (cantidad > 0),
    precio_unitario NUMERIC(10,2) NOT NULL CHECK (precio_unitario >= 0),
    subtotal        NUMERIC(12,2) GENERATED ALWAYS AS (cantidad * precio_unitario) STORED,
    created_at      TIMESTAMPTZ   DEFAULT NOW()
);

-- ============================================================
--  9. DEVOLUCIONES DE VENTA
-- ============================================================

CREATE TABLE IF NOT EXISTS devolucion_venta (
    id                SERIAL PRIMARY KEY,
    venta_id          INT           NOT NULL REFERENCES venta(id),
    detalle_venta_id  INT           REFERENCES detalle_venta(id),
    fecha             DATE          NOT NULL,
    cantidad          INT           NOT NULL CHECK (cantidad > 0),
    motivo            TEXT,
    monto_reembolsado NUMERIC(12,2) NOT NULL DEFAULT 0,
    usuario_id        INT           REFERENCES usuario(id),
    created_at        TIMESTAMPTZ   DEFAULT NOW()
);

-- ============================================================
--  10. CUENTAS POR COBRAR Y PAGOS
-- ============================================================

CREATE TABLE IF NOT EXISTS cuentas_cobrar (
    id                SERIAL PRIMARY KEY,
    venta_id          INT           NOT NULL REFERENCES venta(id),
    fecha_emision     DATE          NOT NULL,
    fecha_vencimiento DATE          NOT NULL,
    monto_total       NUMERIC(12,2) NOT NULL CHECK (monto_total > 0),
    saldo_pendiente   NUMERIC(12,2) NOT NULL CHECK (saldo_pendiente >= 0),
    estado            VARCHAR(20)   NOT NULL DEFAULT 'pendiente'
                      CHECK (estado IN ('pendiente','parcial','pagado','vencido')),
    numero_cuota      INT           NOT NULL DEFAULT 1,
    total_cuotas      INT           NOT NULL DEFAULT 1,
    created_at        TIMESTAMPTZ   DEFAULT NOW()
);

CREATE TABLE IF NOT EXISTS pago_cliente (
    id               SERIAL PRIMARY KEY,
    cuenta_cobrar_id INT           NOT NULL REFERENCES cuentas_cobrar(id),
    fecha            DATE          NOT NULL,
    monto            NUMERIC(12,2) NOT NULL CHECK (monto > 0),
    metodo_pago      VARCHAR(50)   NOT NULL DEFAULT 'efectivo'
                     CHECK (metodo_pago IN ('efectivo','transferencia','tarjeta','cheque','yape','plin')),
    referencia       VARCHAR(100),
    usuario_id       INT           REFERENCES usuario(id),
    created_at       TIMESTAMPTZ   DEFAULT NOW()
);

-- ============================================================
--  11. Ã“RDENES DE PRODUCCIÃ“N Y PRODUCCIÃ“N
-- ============================================================

CREATE TABLE IF NOT EXISTS orden_produccion (
    id                   SERIAL PRIMARY KEY,
    numero_orden         VARCHAR(50)   UNIQUE NOT NULL,
    fecha_inicio         DATE          NOT NULL,
    fecha_fin_estimada   DATE,
    fecha_fin_real       DATE,
    producto_id          INT           NOT NULL REFERENCES producto(id),
    cantidad_ordenada    INT           NOT NULL CHECK (cantidad_ordenada > 0),
    cantidad_producida   INT           NOT NULL DEFAULT 0,
    estado               VARCHAR(30)   NOT NULL DEFAULT 'planificada'
                         CHECK (estado IN ('planificada','en_proceso','completada','cancelada')),
    responsable_id       INT           REFERENCES usuario(id),
    costo_mp_estimado    NUMERIC(12,2),
    costo_mo_estimado    NUMERIC(12,2),
    notas                TEXT,
    created_at           TIMESTAMPTZ   DEFAULT NOW(),
    updated_at           TIMESTAMPTZ   DEFAULT NOW()
);

CREATE TABLE IF NOT EXISTS produccion (
    id                  SERIAL PRIMARY KEY,
    orden_produccion_id INT           NOT NULL REFERENCES orden_produccion(id),
    fecha_produccion    DATE          NOT NULL,
    producto_id         INT           NOT NULL REFERENCES producto(id),
    cantidad_producida  INT           NOT NULL CHECK (cantidad_producida > 0),
    -- costos TOTALES del lote (no por unidad)
    costo_materia_prima NUMERIC(12,2) NOT NULL CHECK (costo_materia_prima >= 0),
    mano_de_obra        NUMERIC(12,2) NOT NULL CHECK (mano_de_obra >= 0),
    costo_total         NUMERIC(12,2) GENERATED ALWAYS AS (costo_materia_prima + mano_de_obra) STORED,
    costo_unitario      NUMERIC(10,4) GENERATED ALWAYS AS (
                            CASE WHEN cantidad_producida > 0
                                 THEN (costo_materia_prima + mano_de_obra) / cantidad_producida
                                 ELSE 0 END
                        ) STORED,
    destino_id          INT           NOT NULL REFERENCES destino_produccion(id),
    notas               TEXT,
    created_at          TIMESTAMPTZ   DEFAULT NOW()
);

-- ============================================================
--  12. CONSUMO DE MATERIALES
-- ============================================================

CREATE TABLE IF NOT EXISTS consumo_material (
    id                 SERIAL PRIMARY KEY,
    produccion_id      INT           NOT NULL REFERENCES produccion(id),
    material_id        INT           NOT NULL REFERENCES material(id),
    cantidad_consumida NUMERIC(10,2) NOT NULL CHECK (cantidad_consumida > 0),
    costo_unitario     NUMERIC(10,2) NOT NULL CHECK (costo_unitario >= 0),
    costo_total        NUMERIC(12,2) GENERATED ALWAYS AS (cantidad_consumida * costo_unitario) STORED,
    created_at         TIMESTAMPTZ   DEFAULT NOW()
);

-- ============================================================
--  13. GASTOS OPERATIVOS
-- ============================================================

CREATE TABLE IF NOT EXISTS gasto (
    id           SERIAL PRIMARY KEY,
    fecha        DATE          NOT NULL,
    categoria_id INT           NOT NULL REFERENCES categoria_gasto(id),
    anio         SMALLINT      NOT NULL GENERATED ALWAYS AS (EXTRACT(YEAR  FROM fecha)::SMALLINT) STORED,
    mes          SMALLINT      NOT NULL GENERATED ALWAYS AS (EXTRACT(MONTH FROM fecha)::SMALLINT) STORED,
    monto        NUMERIC(12,2) NOT NULL CHECK (monto >= 0),
    detalle      TEXT,
    comprobante  VARCHAR(50),
    usuario_id   INT           REFERENCES usuario(id),
    created_at   TIMESTAMPTZ   DEFAULT NOW()
);

-- ============================================================
--  14. CAJA
-- ============================================================

CREATE TABLE IF NOT EXISTS caja (
    id                  SERIAL PRIMARY KEY,
    fecha_apertura      DATE          NOT NULL,
    fecha_cierre        DATE,
    saldo_inicial       NUMERIC(12,2) NOT NULL CHECK (saldo_inicial >= 0),
    saldo_final         NUMERIC(12,2),
    total_ingresos      NUMERIC(12,2) NOT NULL DEFAULT 0,
    total_egresos       NUMERIC(12,2) NOT NULL DEFAULT 0,
    estado              VARCHAR(20)   NOT NULL DEFAULT 'abierta'
                        CHECK (estado IN ('abierta','cerrada')),
    usuario_apertura_id INT           REFERENCES usuario(id),
    usuario_cierre_id   INT           REFERENCES usuario(id),
    created_at          TIMESTAMPTZ   DEFAULT NOW()
);

CREATE TABLE IF NOT EXISTS movimiento_caja (
    id               SERIAL PRIMARY KEY,
    caja_id          INT           NOT NULL REFERENCES caja(id),
    fecha            TIMESTAMPTZ   NOT NULL DEFAULT NOW(),
    tipo             VARCHAR(20)   NOT NULL CHECK (tipo IN ('ingreso','egreso')),
    concepto         VARCHAR(200)  NOT NULL,
    monto            NUMERIC(12,2) NOT NULL CHECK (monto > 0),
    metodo_pago      VARCHAR(50)   DEFAULT 'efectivo',
    referencia_id    INT,
    referencia_tabla VARCHAR(50),
    usuario_id       INT           REFERENCES usuario(id),
    created_at       TIMESTAMPTZ   DEFAULT NOW()
);

-- ============================================================
--  15. ÍNDICES
-- ============================================================

CREATE INDEX IF NOT EXISTS idx_venta_fecha          ON venta(fecha);
CREATE INDEX IF NOT EXISTS idx_venta_cliente        ON venta(cliente_id);
CREATE INDEX IF NOT EXISTS idx_venta_tipo_venta     ON venta(tipo_venta_id);
CREATE INDEX IF NOT EXISTS idx_venta_usuario        ON venta(usuario_id);
CREATE INDEX IF NOT EXISTS idx_detalle_venta_venta  ON detalle_venta(venta_id);
CREATE INDEX IF NOT EXISTS idx_detalle_venta_prod   ON detalle_venta(producto_id);
CREATE INDEX IF NOT EXISTS idx_cc_venta             ON cuentas_cobrar(venta_id);
CREATE INDEX IF NOT EXISTS idx_cc_estado            ON cuentas_cobrar(estado);
CREATE INDEX IF NOT EXISTS idx_cc_vencimiento       ON cuentas_cobrar(fecha_vencimiento);
CREATE INDEX IF NOT EXISTS idx_pago_cuenta          ON pago_cliente(cuenta_cobrar_id);
CREATE INDEX IF NOT EXISTS idx_pago_fecha           ON pago_cliente(fecha);
CREATE INDEX IF NOT EXISTS idx_op_estado            ON orden_produccion(estado);
CREATE INDEX IF NOT EXISTS idx_op_fechas            ON orden_produccion(fecha_inicio, fecha_fin_estimada);
CREATE INDEX IF NOT EXISTS idx_prod_orden           ON produccion(orden_produccion_id);
CREATE INDEX IF NOT EXISTS idx_prod_fecha           ON produccion(fecha_produccion);
CREATE INDEX IF NOT EXISTS idx_prod_producto        ON produccion(producto_id);
CREATE INDEX IF NOT EXISTS idx_consumo_prod         ON consumo_material(produccion_id);
CREATE INDEX IF NOT EXISTS idx_consumo_mat          ON consumo_material(material_id);
CREATE INDEX IF NOT EXISTS idx_compra_fecha         ON compra_material(fecha);
CREATE INDEX IF NOT EXISTS idx_compra_proveedor     ON compra_material(proveedor_id);
CREATE INDEX IF NOT EXISTS idx_mov_mat_fecha        ON movimiento_material(fecha);
CREATE INDEX IF NOT EXISTS idx_mov_mat_material     ON movimiento_material(material_id);
CREATE INDEX IF NOT EXISTS idx_gasto_fecha          ON gasto(fecha);
CREATE INDEX IF NOT EXISTS idx_gasto_anio_mes       ON gasto(anio, mes);
CREATE INDEX IF NOT EXISTS idx_gasto_categoria      ON gasto(categoria_id);
CREATE INDEX IF NOT EXISTS idx_mov_caja_caja        ON movimiento_caja(caja_id);
CREATE INDEX IF NOT EXISTS idx_mov_caja_fecha       ON movimiento_caja(fecha);
CREATE INDEX IF NOT EXISTS idx_cliente_tipo         ON cliente(tipo_cliente_id);
CREATE INDEX IF NOT EXISTS idx_cliente_estado       ON cliente(estado);
CREATE INDEX IF NOT EXISTS idx_devolucion_venta     ON devolucion_venta(venta_id);

-- ============================================================
--  16. FUNCIONES Y TRIGGERS
-- ============================================================

-- â–º Recalcula total_venta al insertar/actualizar/borrar detalle
CREATE OR REPLACE FUNCTION fn_actualizar_total_venta()
RETURNS TRIGGER LANGUAGE plpgsql AS $$
BEGIN
    UPDATE venta
    SET total_venta = (
        SELECT COALESCE(SUM(subtotal), 0)
        FROM detalle_venta
        WHERE venta_id = COALESCE(NEW.venta_id, OLD.venta_id)
    )
    WHERE id = COALESCE(NEW.venta_id, OLD.venta_id);
    RETURN COALESCE(NEW, OLD);
END;
$$;

DROP TRIGGER IF EXISTS trg_total_venta ON detalle_venta;
CREATE TRIGGER trg_total_venta
AFTER INSERT OR UPDATE OR DELETE ON detalle_venta
FOR EACH ROW EXECUTE FUNCTION fn_actualizar_total_venta();

-- â–º Descuenta stock de producto terminado al registrar línea de venta
CREATE OR REPLACE FUNCTION fn_stock_venta()
RETURNS TRIGGER LANGUAGE plpgsql AS $$
BEGIN
    -- 1. CASO: Venta nueva (Se descuenta el stock)
    IF TG_OP = 'INSERT' THEN
        UPDATE stock_producto_terminado
        SET cantidad_disponible  = cantidad_disponible - NEW.cantidad,
            ultima_actualizacion = NOW()
        WHERE producto_id = NEW.producto_id;
        RETURN NEW;

    -- 2. CASO: Anulación o eliminación de un producto de la venta (Se devuelve el stock)
    ELSIF TG_OP = 'DELETE' THEN
        UPDATE stock_producto_terminado
        SET cantidad_disponible  = cantidad_disponible + OLD.cantidad,
            ultima_actualizacion = NOW()
        WHERE producto_id = OLD.producto_id;
        RETURN OLD;

    -- 3. CASO: Modificación de la venta (Corrección de error humano)
    ELSIF TG_OP = 'UPDATE' THEN
        -- Si el vendedor se equivocó de producto (Ej: Marcó Ropero pero era Cómoda)
        IF OLD.producto_id <> NEW.producto_id THEN
            -- Devolvemos el stock al producto equivocado
            UPDATE stock_producto_terminado
            SET cantidad_disponible  = cantidad_disponible + OLD.cantidad,
                ultima_actualizacion = NOW()
            WHERE producto_id = OLD.producto_id;
            
            -- Descontamos el stock al producto correcto
            UPDATE stock_producto_terminado
            SET cantidad_disponible  = cantidad_disponible - NEW.cantidad,
                ultima_actualizacion = NOW()
            WHERE producto_id = NEW.producto_id;
            
        -- Si es el mismo producto, pero corrigió la cantidad (Ej: Puso 5 por error, lo baja a 2)
        ELSE
            UPDATE stock_producto_terminado
            -- Si old = 5 y new = 2: suma 5 y resta 2 (devuelve 3 al stock real)
            SET cantidad_disponible  = cantidad_disponible + (OLD.cantidad - NEW.cantidad),
                ultima_actualizacion = NOW()
            WHERE producto_id = NEW.producto_id;
        END IF;
        RETURN NEW;
    END IF;
END;
$$;

DROP TRIGGER IF EXISTS trg_stock_venta ON detalle_venta;
CREATE TRIGGER trg_stock_venta
AFTER INSERT OR UPDATE OR DELETE ON detalle_venta
FOR EACH ROW EXECUTE FUNCTION fn_stock_venta();

-- â–º Restaura stock al registrar una devolución
CREATE OR REPLACE FUNCTION fn_stock_devolucion()
RETURNS TRIGGER LANGUAGE plpgsql AS $$
DECLARE
    v_producto_id INT;
BEGIN
    SELECT producto_id INTO v_producto_id
    FROM detalle_venta WHERE id = NEW.detalle_venta_id;

    IF v_producto_id IS NOT NULL THEN
        UPDATE stock_producto_terminado
        SET cantidad_disponible  = cantidad_disponible + NEW.cantidad,
            ultima_actualizacion = NOW()
        WHERE producto_id = v_producto_id;
    END IF;
    RETURN NEW;
END;
$$;

DROP TRIGGER IF EXISTS trg_stock_devolucion ON devolucion_venta;
CREATE TRIGGER trg_stock_devolucion
AFTER INSERT ON devolucion_venta
FOR EACH ROW EXECUTE FUNCTION fn_stock_devolucion();

-- â–º Incrementa stock de producto terminado al registrar producción
CREATE OR REPLACE FUNCTION fn_stock_produccion()
RETURNS TRIGGER LANGUAGE plpgsql AS $$
BEGIN
    INSERT INTO stock_producto_terminado
        (producto_id, cantidad_disponible, ultima_actualizacion)
    VALUES (NEW.producto_id, NEW.cantidad_producida, NOW())
    ON CONFLICT (producto_id) DO UPDATE
    SET cantidad_disponible  = stock_producto_terminado.cantidad_disponible + NEW.cantidad_producida,
        ultima_actualizacion = NOW();
    RETURN NEW;
END;
$$;

DROP TRIGGER IF EXISTS trg_stock_produccion ON produccion;
CREATE TRIGGER trg_stock_produccion
AFTER INSERT ON produccion
FOR EACH ROW EXECUTE FUNCTION fn_stock_produccion();

-- â–º Actualiza stock de material y genera movimiento al registrar compra
CREATE OR REPLACE FUNCTION fn_stock_compra_material()
RETURNS TRIGGER LANGUAGE plpgsql AS $$
BEGIN
    UPDATE material
    SET stock_actual = stock_actual + NEW.cantidad
    WHERE id = NEW.material_id;

    INSERT INTO movimiento_material
        (fecha, material_id, tipo_movimiento, cantidad, precio_unitario,
         total_valor, referencia_id, referencia_tabla)
    VALUES
        (NEW.fecha, NEW.material_id, 'entrada', NEW.cantidad, NEW.precio_unitario,
         NEW.total_compra, NEW.id, 'compra_material');
    RETURN NEW;
END;
$$;

DROP TRIGGER IF EXISTS trg_stock_compra_material ON compra_material;
CREATE TRIGGER trg_stock_compra_material
AFTER INSERT ON compra_material
FOR EACH ROW EXECUTE FUNCTION fn_stock_compra_material();

-- â–º Descuenta stock de material y genera movimiento al consumir en producción
CREATE OR REPLACE FUNCTION fn_stock_consumo_material()
RETURNS TRIGGER LANGUAGE plpgsql AS $$
BEGIN
    UPDATE material
    SET stock_actual = stock_actual - NEW.cantidad_consumida
    WHERE id = NEW.material_id;

    INSERT INTO movimiento_material
        (fecha, material_id, tipo_movimiento, cantidad, precio_unitario,
         total_valor, referencia_id, referencia_tabla)
    VALUES
        (CURRENT_DATE, NEW.material_id, 'salida', NEW.cantidad_consumida, NEW.costo_unitario,
         NEW.costo_total, NEW.id, 'consumo_material');
    RETURN NEW;
END;
$$;

DROP TRIGGER IF EXISTS trg_stock_consumo_material ON consumo_material;
CREATE TRIGGER trg_stock_consumo_material
AFTER INSERT ON consumo_material
FOR EACH ROW EXECUTE FUNCTION fn_stock_consumo_material();

-- â–º Actualiza saldo de cuenta por cobrar y cliente al registrar un pago
CREATE OR REPLACE FUNCTION fn_pago_cliente()
RETURNS TRIGGER LANGUAGE plpgsql AS $$
DECLARE
    v_cliente_id  INT;
    v_venta_id    INT;
BEGIN
    SELECT venta_id INTO v_venta_id
    FROM cuentas_cobrar WHERE id = NEW.cuenta_cobrar_id;

    SELECT cliente_id INTO v_cliente_id
    FROM venta WHERE id = v_venta_id;

    UPDATE cuentas_cobrar
    SET saldo_pendiente = GREATEST(saldo_pendiente - NEW.monto, 0),
        estado = CASE
            WHEN GREATEST(saldo_pendiente - NEW.monto, 0) = 0          THEN 'pagado'
            WHEN GREATEST(saldo_pendiente - NEW.monto, 0) < monto_total THEN 'parcial'
            ELSE estado
        END
    WHERE id = NEW.cuenta_cobrar_id;

    UPDATE cliente
    SET saldo_pendiente = GREATEST(saldo_pendiente - NEW.monto, 0),
        estado = CASE
            WHEN GREATEST(saldo_pendiente - NEW.monto, 0) = 0 THEN 'activo'
            ELSE estado
        END,
        updated_at = NOW()
    WHERE id = v_cliente_id;

    RETURN NEW;
END;
$$;

DROP TRIGGER IF EXISTS trg_pago_cliente ON pago_cliente;
CREATE TRIGGER trg_pago_cliente
AFTER INSERT ON pago_cliente
FOR EACH ROW EXECUTE FUNCTION fn_pago_cliente();

-- â–º Actualiza totales de caja al registrar movimiento
CREATE OR REPLACE FUNCTION fn_actualizar_caja()
RETURNS TRIGGER LANGUAGE plpgsql AS $$
BEGIN
    IF NEW.tipo = 'ingreso' THEN
        UPDATE caja SET total_ingresos = total_ingresos + NEW.monto WHERE id = NEW.caja_id;
    ELSE
        UPDATE caja SET total_egresos  = total_egresos  + NEW.monto WHERE id = NEW.caja_id;
    END IF;
    RETURN NEW;
END;
$$;

DROP TRIGGER IF EXISTS trg_actualizar_caja ON movimiento_caja;
CREATE TRIGGER trg_actualizar_caja
AFTER INSERT ON movimiento_caja
FOR EACH ROW EXECUTE FUNCTION fn_actualizar_caja();

-- â–º Actualiza updated_at en orden_produccion
CREATE OR REPLACE FUNCTION fn_orden_updated_at()
RETURNS TRIGGER LANGUAGE plpgsql AS $$
BEGIN
    NEW.updated_at = NOW();
    RETURN NEW;
END;
$$;

DROP TRIGGER IF EXISTS trg_orden_updated_at ON orden_produccion;
CREATE TRIGGER trg_orden_updated_at
BEFORE UPDATE ON orden_produccion
FOR EACH ROW EXECUTE FUNCTION fn_orden_updated_at();

-- ============================================================
--  17. VISTAS ANALÍTICAS
-- ============================================================

-- Ventas con detalle por línea de producto
CREATE OR REPLACE VIEW v_ventas_detalle AS
SELECT
    v.id                     AS venta_id,
    v.fecha,
    c.nombre                 AS cliente,
    tc.nombre                AS tipo_cliente,
    tv.nombre                AS tipo_venta,
    p.nombre                 AS producto,
    dv.cantidad,
    dv.precio_unitario,
    dv.subtotal,
    v.total_venta,
    u.nombre                 AS vendedor
FROM venta v
JOIN cliente       c  ON c.id  = v.cliente_id
JOIN tipo_cliente  tc ON tc.id = c.tipo_cliente_id
JOIN tipo_venta    tv ON tv.id = v.tipo_venta_id
JOIN detalle_venta dv ON dv.venta_id = v.id
JOIN producto      p  ON p.id  = dv.producto_id
LEFT JOIN usuario  u  ON u.id  = v.usuario_id
ORDER BY v.fecha, v.id;

-- Ventas agrupadas por producto con margen bruto
CREATE OR REPLACE VIEW v_ventas_por_producto AS
SELECT
    p.nombre                 AS producto,
    SUM(dv.cantidad)         AS unidades_vendidas,
    SUM(dv.subtotal)         AS ingreso_total,
    ROUND(AVG(dv.precio_unitario), 2) AS precio_promedio,
    p.costo_estandar,
    ROUND(SUM(dv.subtotal) - (SUM(dv.cantidad) * p.costo_estandar), 2) AS margen_bruto,
    ROUND(
        ((SUM(dv.subtotal) - (SUM(dv.cantidad) * p.costo_estandar))
         / NULLIF(SUM(dv.subtotal), 0)) * 100, 2
    ) AS margen_porcentaje
FROM detalle_venta dv
JOIN producto p ON p.id = dv.producto_id
JOIN venta    v ON v.id = dv.venta_id
GROUP BY p.nombre, p.costo_estandar
ORDER BY ingreso_total DESC;

-- Cuentas por cobrar pendientes con alerta de mora
CREATE OR REPLACE VIEW v_cuentas_cobrar_pendientes AS
SELECT
    cc.id                                           AS cuenta_id,
    c.nombre                                        AS cliente,
    v.fecha                                         AS fecha_venta,
    v.total_venta,
    cc.monto_total,
    cc.saldo_pendiente,
    cc.fecha_vencimiento,
    cc.estado,
    CASE
        WHEN cc.fecha_vencimiento < CURRENT_DATE
         AND cc.saldo_pendiente > 0 THEN 'VENCIDO'
        ELSE 'AL DÍA'
    END                                             AS alerta,
    GREATEST(CURRENT_DATE - cc.fecha_vencimiento, 0) AS dias_mora
FROM cuentas_cobrar cc
JOIN venta   v ON v.id = cc.venta_id
JOIN cliente c ON c.id = v.cliente_id
WHERE cc.saldo_pendiente > 0
ORDER BY cc.fecha_vencimiento;

-- Stock de materiales con alerta de nivel mínimo
CREATE OR REPLACE VIEW v_stock_materiales AS
SELECT
    m.nombre,
    m.stock_actual,
    m.stock_minimo,
    um.abreviatura                   AS unidad,
    p.nombre                         AS proveedor_preferido,
    CASE
        WHEN m.stock_actual = 0               THEN 'SIN STOCK'
        WHEN m.stock_actual <= m.stock_minimo THEN 'STOCK BAJO'
        ELSE 'OK'
    END                              AS estado
FROM material m
JOIN unidad_medida um ON um.id = m.unidad_medida_id
LEFT JOIN proveedor p ON p.id  = m.proveedor_preferido_id
WHERE m.activo = TRUE
ORDER BY
    CASE WHEN m.stock_actual = 0               THEN 0
         WHEN m.stock_actual <= m.stock_minimo THEN 1
         ELSE 2 END,
    m.nombre;

-- Stock de productos terminados con alerta
CREATE OR REPLACE VIEW v_stock_productos AS
SELECT
    p.nombre,
    COALESCE(s.cantidad_disponible, 0) AS cantidad_disponible,
    COALESCE(s.cantidad_reservada,  0) AS cantidad_reservada,
    COALESCE(s.punto_reorden,       5) AS punto_reorden,
    CASE
        WHEN COALESCE(s.cantidad_disponible, 0) = 0                              THEN 'SIN STOCK'
        WHEN COALESCE(s.cantidad_disponible, 0) <= COALESCE(s.punto_reorden, 5)  THEN 'STOCK BAJO'
        ELSE 'OK'
    END                                AS estado,
    s.ultima_actualizacion
FROM producto p
LEFT JOIN stock_producto_terminado s ON s.producto_id = p.id
WHERE p.activo = TRUE
ORDER BY cantidad_disponible;

-- Rentabilidad real por lote de producción
CREATE OR REPLACE VIEW v_rentabilidad_produccion AS
SELECT
    p.nombre                         AS producto,
    prod.fecha_produccion,
    prod.cantidad_producida,
    prod.costo_materia_prima,
    prod.mano_de_obra,
    prod.costo_total,
    ROUND(prod.costo_unitario, 2)    AS costo_unitario,
    p.precio_venta_retail,
    p.precio_venta_mayorista,
    ROUND(p.precio_venta_retail    - prod.costo_unitario, 2) AS margen_retail,
    ROUND(p.precio_venta_mayorista - prod.costo_unitario, 2) AS margen_mayorista
FROM produccion prod
JOIN producto p ON p.id = prod.producto_id
ORDER BY prod.fecha_produccion DESC;

-- Resumen mensual: ingresos, gastos, utilidad bruta
CREATE OR REPLACE VIEW v_resumen_mensual AS
SELECT
    g.anio,
    g.mes,
    COALESCE(v_ing.total_ingresos, 0)         AS total_ingresos,
    COALESCE(SUM(g.monto), 0)                 AS total_gastos,
    COALESCE(v_ing.total_ingresos, 0)
      - COALESCE(SUM(g.monto), 0)             AS utilidad_bruta
FROM gasto g
LEFT JOIN (
    SELECT
        EXTRACT(YEAR  FROM fecha)::INT AS anio,
        EXTRACT(MONTH FROM fecha)::INT AS mes,
        SUM(total_venta)               AS total_ingresos
    FROM venta
    GROUP BY 1, 2
) v_ing ON v_ing.anio = g.anio AND v_ing.mes = g.mes
GROUP BY g.anio, g.mes, v_ing.total_ingresos
ORDER BY g.anio, g.mes;

-- Kardex de movimientos de materiales
CREATE OR REPLACE VIEW v_kardex_materiales AS
SELECT
    mm.fecha,
    m.nombre                         AS material,
    mm.tipo_movimiento,
    mm.cantidad,
    um.abreviatura                   AS unidad,
    mm.precio_unitario,
    mm.total_valor,
    mm.referencia_tabla,
    mm.referencia_id
FROM movimiento_material mm
JOIN material      m  ON m.id  = mm.material_id
JOIN unidad_medida um ON um.id = m.unidad_medida_id
ORDER BY mm.fecha DESC, mm.id DESC;

-- ============================================================
--  FIN DEL SCRIPT DE ESTRUCTURA
-- ============================================================

-- ============================================================
--  MUEBLERÍA / CARPINTERÍA â€” DATOS DE PRUEBA

--  Motor:   PostgreSQL 14+
--  Período: Marzo 2026
--
--  EJECUTAR DESPUÃ‰S DE: 01_muebleria_schema.sql
-- ============================================================

SET search_path TO transaccional, public;

-- ============================================================
--  1. CATÁLOGOS MAESTROS
-- ============================================================

INSERT INTO tipo_cliente (nombre) VALUES
    ('Retail'), ('Mayorista')
ON CONFLICT (nombre) DO NOTHING;

INSERT INTO tipo_venta (nombre) VALUES
    ('Contado'), ('Crédito')
ON CONFLICT (nombre) DO NOTHING;

INSERT INTO destino_produccion (descripcion) VALUES
    ('Stock + pedidos'), ('Mayoristas'), ('Stock'), ('Retail'), ('Pedidos finales')
ON CONFLICT (descripcion) DO NOTHING;

INSERT INTO unidad_medida (nombre, abreviatura) VALUES
    ('planchas', 'pl'),
    ('caja',     'cj'),
    ('rollos',   'rl'),
    ('unidades', 'und'),
    ('pares',    'pr'),
    ('metros',   'mt'),
    ('litros',   'lt'),
    ('kilos',    'kg')
ON CONFLICT (nombre) DO NOTHING;

INSERT INTO categoria_gasto (nombre, tipo) VALUES
    ('Mano de Obra (eventual)',          'variable'),
    ('Compra Melamina y accesorios',     'variable'),
    ('Alquiler local + servicios',       'fijo'),
    ('Transporte y delivery',            'variable'),
    ('Otros (herramientas, etc.)',       'variable'),
    ('Servicios (luz, agua, internet)',  'fijo'),
    ('Marketing y publicidad',           'variable')
ON CONFLICT (nombre) DO NOTHING;

-- ============================================================
--  2. PROVEEDORES
-- ============================================================

INSERT INTO proveedor (ruc, nombre, contacto, telefono, email, direccion) VALUES
    ('20123456789', 'Melaminas del Perú S.A.C.', 'Carlos López',  '987654321', 'ventas@melaminas.pe',  'Av. Industrial 123, Lima'),
    ('20567890123', 'Ferretodo S.A.C.',           'María García',  '976543210', 'pedidos@ferretodo.pe', 'Jr. Comercio 456, Lima'),
    ('20678901234', 'Maderas Noble E.I.R.L.',     'Juan Pérez',    '965432187', 'noble@maderas.pe',     'Carretera Central Km 12'),
    ('20789012345', 'Acabados y Más S.A.C.',      'Rosa Mamani',   '954321876', 'ventas@acabados.pe',   'Av. Arequipa 789, Lima')
ON CONFLICT (ruc) DO NOTHING;

-- ============================================================
--  3. MATERIALES
-- ============================================================

INSERT INTO material (nombre, unidad_medida_id, stock_minimo, proveedor_preferido_id) VALUES
    ('Melamina Blanco 18mm',  (SELECT id FROM unidad_medida WHERE nombre='planchas'),  10000,  (SELECT id FROM proveedor WHERE ruc='20123456789')),
    ('Melamina Color 18mm',   (SELECT id FROM unidad_medida WHERE nombre='planchas'),  10000,  (SELECT id FROM proveedor WHERE ruc='20123456789')),
    ('Mapresa (fondo)',        (SELECT id FROM unidad_medida WHERE nombre='planchas'),  10000,  (SELECT id FROM proveedor WHERE ruc='20567890123')),
    ('Tapacanto (rollo)',      (SELECT id FROM unidad_medida WHERE nombre='rollos'),    10000,  (SELECT id FROM proveedor WHERE ruc='20678901234')),
    ('Tornillos (caja 1000)', (SELECT id FROM unidad_medida WHERE nombre='caja'),      10000,  (SELECT id FROM proveedor WHERE ruc='20567890123')),
    ('Bisagras (caja 100)',   (SELECT id FROM unidad_medida WHERE nombre='caja'),      10000,  (SELECT id FROM proveedor WHERE ruc='20567890123')),
    ('Jaladores',             (SELECT id FROM unidad_medida WHERE nombre='unidades'), 10000,  (SELECT id FROM proveedor WHERE ruc='20567890123')),
    ('Correderas (30cm)',     (SELECT id FROM unidad_medida WHERE nombre='pares'),    10000,  (SELECT id FROM proveedor WHERE ruc='20678901234')),
    ('Patitas',               (SELECT id FROM unidad_medida WHERE nombre='unidades'),10000,  (SELECT id FROM proveedor WHERE ruc='20567890123')),
    ('Laca selladora',        (SELECT id FROM unidad_medida WHERE nombre='litros'),    10000,  (SELECT id FROM proveedor WHERE ruc='20789012345')),
    ('Pegamento contacto',    (SELECT id FROM unidad_medida WHERE nombre='kilos'),    10000,  (SELECT id FROM proveedor WHERE ruc='20789012345'))
ON CONFLICT (nombre) DO NOTHING;

-- ============================================================
--  4. PRODUCTOS
-- ============================================================

INSERT INTO producto (nombre, costo_estandar, precio_venta_retail, precio_venta_mayorista) VALUES
    ('Ropero',  465.00, 760.00, 730.00),
    ('Velador',  69.00,  90.00,  80.00),
    ('Cómoda',  240.00, 480.00, 450.00),
    ('Comodín', 110.00, 230.00, 210.00),
    ('Tocador', 380.00, 650.00, 620.00),
    ('Estante', 150.00, 280.00, 260.00)
ON CONFLICT (nombre) DO NOTHING;

-- Inicializar stock en 0 para todos los productos
INSERT INTO stock_producto_terminado (producto_id, cantidad_disponible, punto_reorden)
SELECT id, 10000, 5 FROM producto
ON CONFLICT (producto_id) DO NOTHING;

-- ============================================================
--  5. USUARIOS
-- ============================================================

INSERT INTO usuario (nombre, email, rol) VALUES
    ('Admin Sistema',  'admin@muebleria.com',  'admin'),
    ('Juan Quispe',    'juan@muebleria.com',   'vendedor'),
    ('Pedro Mamani',   'pedro@muebleria.com',  'produccion'),
    ('Maria Condori',  'maria@muebleria.com',  'contador'),
    ('Luis Apaza',     'luis@muebleria.com',   'vendedor')
ON CONFLICT (email) DO NOTHING;

-- ============================================================
--  6. TRABAJADORES
-- ============================================================

INSERT INTO trabajador (nombre, tipo) VALUES
    ('Operario Flores',  'eventual'),
    ('Operario Ticona',  'eventual'),
    ('Operario Huanca',  'eventual'),
    ('Maestro Calisaya', 'fijo');

-- ============================================================
--  7. CLIENTES
-- ============================================================

INSERT INTO cliente (tipo_cliente_id, documento, nombre, razon_social, direccion, telefono, email, limite_credito) VALUES
    ((SELECT id FROM tipo_cliente WHERE nombre='Retail'),    '12345678',    'Ana Torres',               NULL,                               'Jr. Lima 123, Juliaca',       '987111111', 'ana@gmail.com',      0),
    ((SELECT id FROM tipo_cliente WHERE nombre='Retail'),    '87654321',    'Carlos Mamani',            NULL,                               'Av. Puno 456, Juliaca',       '987222222', NULL,                 0),
    ((SELECT id FROM tipo_cliente WHERE nombre='Retail'),    '45678901',    'Rosa Quispe',              NULL,                               'Calle Arequipa 789, Juliaca', '987333333', NULL,                 0),
    ((SELECT id FROM tipo_cliente WHERE nombre='Retail'),    '23456789',    'Luis Condori',             NULL,                               'Av. Floral 321, Juliaca',     '987444444', NULL,                 0),
    ((SELECT id FROM tipo_cliente WHERE nombre='Mayorista'), '20111222333', 'Muebles El Norte S.A.C.', 'Muebles El Norte S.A.C.',          'Av. Industrial 100, Puno',    '951000001', 'norte@muebles.pe',  20000.00),
    ((SELECT id FROM tipo_cliente WHERE nombre='Mayorista'), '20444555666', 'Distribuidora Altiplano', 'Distribuidora Altiplano E.I.R.L.', 'Jr. Comercio 200, Puno',      '951000002', 'altiplano@dist.pe', 15000.00),
    ((SELECT id FROM tipo_cliente WHERE nombre='Mayorista'), '20777888999', 'Mueblería Centro',        'Mueblería Centro S.R.L.',          'Calle Real 50, Puno',         '951000003', NULL,                10000.00)
ON CONFLICT (documento) DO NOTHING;

-- ============================================================
