-- ============================================================
--  MUEBLERÍA / CARPINTERÍA — ESTRUCTURA DE BASE DE DATOS
--  
--  Motor:   PostgreSQL 14+
--  Esquema: transaccional
-- ============================================================
--  MÓDULOS:
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
--   11.  Órdenes de Producción y Producción
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

-- FK diferida: compra_material → usuario
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
--  8. VENTAS — CABECERA + DETALLE MULTI-PRODUCTO
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
--  11. ÓRDENES DE PRODUCCIÓN Y PRODUCCIÓN
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

-- ► Recalcula total_venta al insertar/actualizar/borrar detalle
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

-- ► Descuenta stock de producto terminado al registrar línea de venta
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

-- ► Restaura stock al registrar una devolución
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

-- ► Incrementa stock de producto terminado al registrar producción
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

-- ► Actualiza stock de material y genera movimiento al registrar compra
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

-- ► Descuenta stock de material y genera movimiento al consumir en producción
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

-- ► Actualiza saldo de cuenta por cobrar y cliente al registrar un pago
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

-- ► Actualiza totales de caja al registrar movimiento
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

-- ► Actualiza updated_at en orden_produccion
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
--  MUEBLERÍA / CARPINTERÍA — DATOS DE PRUEBA

--  Motor:   PostgreSQL 14+
--  Período: Marzo 2026
--
--  EJECUTAR DESPUÉS DE: 01_muebleria_schema.sql
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
    ('Melamina Blanco 18mm',  (SELECT id FROM unidad_medida WHERE nombre='planchas'),  5,  (SELECT id FROM proveedor WHERE ruc='20123456789')),
    ('Melamina Color 18mm',   (SELECT id FROM unidad_medida WHERE nombre='planchas'),  4,  (SELECT id FROM proveedor WHERE ruc='20123456789')),
    ('Mapresa (fondo)',        (SELECT id FROM unidad_medida WHERE nombre='planchas'),  3,  (SELECT id FROM proveedor WHERE ruc='20567890123')),
    ('Tapacanto (rollo)',      (SELECT id FROM unidad_medida WHERE nombre='rollos'),    2,  (SELECT id FROM proveedor WHERE ruc='20678901234')),
    ('Tornillos (caja 1000)', (SELECT id FROM unidad_medida WHERE nombre='caja'),      2,  (SELECT id FROM proveedor WHERE ruc='20567890123')),
    ('Bisagras (caja 100)',   (SELECT id FROM unidad_medida WHERE nombre='caja'),      1,  (SELECT id FROM proveedor WHERE ruc='20567890123')),
    ('Jaladores',             (SELECT id FROM unidad_medida WHERE nombre='unidades'), 50,  (SELECT id FROM proveedor WHERE ruc='20567890123')),
    ('Correderas (30cm)',     (SELECT id FROM unidad_medida WHERE nombre='pares'),    20,  (SELECT id FROM proveedor WHERE ruc='20678901234')),
    ('Patitas',               (SELECT id FROM unidad_medida WHERE nombre='unidades'),100,  (SELECT id FROM proveedor WHERE ruc='20567890123')),
    ('Laca selladora',        (SELECT id FROM unidad_medida WHERE nombre='litros'),    5,  (SELECT id FROM proveedor WHERE ruc='20789012345')),
    ('Pegamento contacto',    (SELECT id FROM unidad_medida WHERE nombre='kilos'),    10,  (SELECT id FROM proveedor WHERE ruc='20789012345'))
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
SELECT id, 20, 5 FROM producto
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
--  8. APERTURA DE CAJA — MARZO 2026
-- ============================================================

INSERT INTO caja (fecha_apertura, saldo_inicial, estado, usuario_apertura_id)
VALUES (
    '2026-03-01', 2000.00, 'abierta',
    (SELECT id FROM usuario WHERE email='admin@muebleria.com')
);

-- ============================================================
--  9. COMPRAS DE MATERIALES — MARZO 2026
--     Los triggers actualizan stock_actual y movimiento_material
-- ============================================================

INSERT INTO compra_material
    (fecha, proveedor_id, material_id, cantidad, precio_unitario, factura_numero, notas, usuario_id)
SELECT
    cm.fecha, pr.id, m.id, cm.cantidad, cm.precio_unit,
    cm.factura, cm.notas,
    (SELECT id FROM usuario WHERE email='admin@muebleria.com')
FROM (VALUES
    ('2026-03-01'::date, 'Melaminas del Perú S.A.C.', 'Melamina Blanco 18mm',    8,   150.00, 'F001-001', 'Compra inicial mes'),
    ('2026-03-01'::date, 'Ferretodo S.A.C.',          'Mapresa (fondo)',          5,   100.00, 'F002-001', 'Compra inicial mes'),
    ('2026-03-02'::date, 'Ferretodo S.A.C.',          'Tornillos (caja 1000)',    2,    80.00, 'F002-002', 'Stock inicial'),
    ('2026-03-03'::date, 'Melaminas del Perú S.A.C.', 'Melamina Color 18mm',     6,   180.00, 'F001-002', 'Para cómodas'),
    ('2026-03-05'::date, 'Maderas Noble E.I.R.L.',    'Tapacanto (rollo)',        4,    35.00, 'F003-001', 'Varios colores'),
    ('2026-03-07'::date, 'Ferretodo S.A.C.',          'Jaladores',             200,     1.00, 'F002-003', 'Variedad modelos'),
    ('2026-03-08'::date, 'Maderas Noble E.I.R.L.',    'Correderas (30cm)',       50,    20.00, 'F003-002', 'Stock correderas'),
    ('2026-03-10'::date, 'Ferretodo S.A.C.',          'Bisagras (caja 100)',      2,    90.00, 'F002-004', 'Bisagras estándar'),
    ('2026-03-12'::date, 'Acabados y Más S.A.C.',     'Laca selladora',         10,    28.00, 'F004-001', 'Para acabados'),
    ('2026-03-14'::date, 'Acabados y Más S.A.C.',     'Pegamento contacto',     15,    12.00, 'F004-002', 'Pegamento contacto'),
    ('2026-03-15'::date, 'Ferretodo S.A.C.',          'Patitas',               300,     0.40, 'F002-005', 'Surtido tamaños'),
    ('2026-03-18'::date, 'Melaminas del Perú S.A.C.', 'Melamina Blanco 18mm',    7,   152.00, 'F001-003', 'Reposición urgente'),
    ('2026-03-20'::date, 'Ferretodo S.A.C.',          'Tornillos (caja 1000)',    1,    80.00, 'F002-006', 'Reposición'),
    ('2026-03-22'::date, 'Ferretodo S.A.C.',          'Mapresa (fondo)',          4,   100.00, 'F002-007', 'Reposición fondo'),
    ('2026-03-25'::date, 'Melaminas del Perú S.A.C.', 'Melamina Color 18mm',     5,   175.00, 'F001-004', 'Compra urgente'),
    ('2026-03-28'::date, 'Ferretodo S.A.C.',          'Jaladores',             100,     1.00, 'F002-008', 'Reposición'),
    ('2026-03-30'::date, 'Maderas Noble E.I.R.L.',    'Tapacanto (rollo)',        2,    35.00, 'F003-003', 'Reposición cierre mes')
) AS cm(fecha, proveedor_nombre, material_nombre, cantidad, precio_unit, factura, notas)
JOIN proveedor pr ON pr.nombre = cm.proveedor_nombre
JOIN material   m ON  m.nombre = cm.material_nombre;

-- ============================================================
--  10. ÓRDENES DE PRODUCCIÓN — MARZO 2026
-- ============================================================

INSERT INTO orden_produccion
    (numero_orden, fecha_inicio, fecha_fin_estimada, fecha_fin_real,
     producto_id, cantidad_ordenada, cantidad_producida, estado, responsable_id,
     costo_mp_estimado, costo_mo_estimado, notas)
VALUES
    ('OP-2026-001','2026-03-01','2026-03-05','2026-03-04',
     (SELECT id FROM producto WHERE nombre='Ropero'),  12,12,'completada',
     (SELECT id FROM usuario WHERE email='pedro@muebleria.com'), 4320.00,1260.00,'Lote 1 inicio mes'),

    ('OP-2026-002','2026-03-08','2026-03-12','2026-03-11',
     (SELECT id FROM producto WHERE nombre='Ropero'),  15,15,'completada',
     (SELECT id FROM usuario WHERE email='pedro@muebleria.com'), 5400.00,1575.00,'Pedido Muebles Norte'),

    ('OP-2026-003','2026-03-10','2026-03-15','2026-03-14',
     (SELECT id FROM producto WHERE nombre='Cómoda'),  18,18,'completada',
     (SELECT id FROM usuario WHERE email='pedro@muebleria.com'), 3240.00,1080.00,'Reposición cómodas'),

    ('OP-2026-004','2026-03-15','2026-03-20','2026-03-19',
     (SELECT id FROM producto WHERE nombre='Velador'), 35,35,'completada',
     (SELECT id FROM usuario WHERE email='pedro@muebleria.com'), 1575.00, 875.00,'Alta rotación veladores'),

    ('OP-2026-005','2026-03-20','2026-03-24','2026-03-24',
     (SELECT id FROM producto WHERE nombre='Comodín'), 15,15,'completada',
     (SELECT id FROM usuario WHERE email='pedro@muebleria.com'),  900.00, 450.00,'Reposición comodines'),

    ('OP-2026-006','2026-03-25','2026-03-30','2026-03-29',
     (SELECT id FROM producto WHERE nombre='Ropero'),  10,10,'completada',
     (SELECT id FROM usuario WHERE email='pedro@muebleria.com'), 3600.00,1050.00,'Cierre de mes'),

    ('OP-2026-007','2026-03-28','2026-04-03',NULL,
     (SELECT id FROM producto WHERE nombre='Estante'),  8, 0,'en_proceso',
     (SELECT id FROM usuario WHERE email='pedro@muebleria.com'),  960.00, 400.00,'Orden en curso');

-- ============================================================
--  11. PRODUCCIÓN REAL — MARZO 2026
--      costo_materia_prima y mano_de_obra = TOTALES DEL LOTE
--      costo_unitario se calcula automáticamente (columna GENERATED)
-- ============================================================

INSERT INTO produccion
    (orden_produccion_id, fecha_produccion, producto_id, cantidad_producida,
     costo_materia_prima, mano_de_obra, destino_id, notas)
SELECT op.id, pr.fecha, p.id, pr.cantidad, pr.costo_mp, pr.mano_obra, d.id, pr.notas
FROM (VALUES
    ('OP-2026-001','2026-03-04'::date,'Ropero',  12, 4320.00,1260.00,'Stock + pedidos','Lote 1'),
    ('OP-2026-002','2026-03-11'::date,'Ropero',  15, 5400.00,1575.00,'Mayoristas',     'Pedido Norte'),
    ('OP-2026-003','2026-03-14'::date,'Cómoda',  18, 3240.00,1080.00,'Stock',          'Reposición'),
    ('OP-2026-004','2026-03-19'::date,'Velador', 35, 1575.00, 875.00,'Retail',         'Alta rotación'),
    ('OP-2026-005','2026-03-24'::date,'Comodín', 15,  900.00, 450.00,'Stock',          'Reposición'),
    ('OP-2026-006','2026-03-29'::date,'Ropero',  10, 3600.00,1050.00,'Pedidos finales','Cierre mes')
) AS pr(orden_numero, fecha, producto, cantidad, costo_mp, mano_obra, destino, notas)
JOIN orden_produccion   op ON op.numero_orden   = pr.orden_numero
JOIN producto            p ON  p.nombre          = pr.producto
JOIN destino_produccion  d ON  d.descripcion     = pr.destino;

-- ============================================================
--  12. CONSUMO DE MATERIALES POR PRODUCCIÓN
--      Los triggers descuentan stock_actual y generan movimiento_material
-- ============================================================

-- Consumo: OP-2026-001 → Ropero x12
INSERT INTO consumo_material (produccion_id, material_id, cantidad_consumida, costo_unitario)
SELECT p.id, m.id, cons.cantidad, cons.precio
FROM produccion p
JOIN orden_produccion op ON op.id = p.orden_produccion_id
CROSS JOIN (VALUES
    ('Melamina Blanco 18mm', 30.0, 150.00),
    ('Mapresa (fondo)',       12.0, 100.00),
    ('Tapacanto (rollo)',      3.0,  35.00),
    ('Tornillos (caja 1000)', 0.60,  80.00),
    ('Jaladores',            48.0,   1.00),
    ('Correderas (30cm)',    24.0,  20.00),
    ('Patitas',              48.0,   0.40)
) AS cons(material_nombre, cantidad, precio)
JOIN material m ON m.nombre = cons.material_nombre
WHERE op.numero_orden = 'OP-2026-001';

-- Consumo: OP-2026-002 → Ropero x15
INSERT INTO consumo_material (produccion_id, material_id, cantidad_consumida, costo_unitario)
SELECT p.id, m.id, cons.cantidad, cons.precio
FROM produccion p
JOIN orden_produccion op ON op.id = p.orden_produccion_id
CROSS JOIN (VALUES
    ('Melamina Blanco 18mm', 37.5, 150.00),
    ('Mapresa (fondo)',       15.0, 100.00),
    ('Tapacanto (rollo)',      3.8,  35.00),
    ('Tornillos (caja 1000)', 0.75,  80.00),
    ('Jaladores',            60.0,   1.00),
    ('Correderas (30cm)',    30.0,  20.00),
    ('Patitas',              60.0,   0.40)
) AS cons(material_nombre, cantidad, precio)
JOIN material m ON m.nombre = cons.material_nombre
WHERE op.numero_orden = 'OP-2026-002';

-- Consumo: OP-2026-003 → Cómoda x18
INSERT INTO consumo_material (produccion_id, material_id, cantidad_consumida, costo_unitario)
SELECT p.id, m.id, cons.cantidad, cons.precio
FROM produccion p
JOIN orden_produccion op ON op.id = p.orden_produccion_id
CROSS JOIN (VALUES
    ('Melamina Color 18mm',  36.0, 180.00),
    ('Mapresa (fondo)',       14.4, 100.00),
    ('Tapacanto (rollo)',      3.6,  35.00),
    ('Tornillos (caja 1000)', 0.72,  80.00),
    ('Bisagras (caja 100)',   0.36,  90.00),
    ('Jaladores',            54.0,   1.00),
    ('Correderas (30cm)',    36.0,  20.00)
) AS cons(material_nombre, cantidad, precio)
JOIN material m ON m.nombre = cons.material_nombre
WHERE op.numero_orden = 'OP-2026-003';

-- Consumo: OP-2026-004 → Velador x35
INSERT INTO consumo_material (produccion_id, material_id, cantidad_consumida, costo_unitario)
SELECT p.id, m.id, cons.cantidad, cons.precio
FROM produccion p
JOIN orden_produccion op ON op.id = p.orden_produccion_id
CROSS JOIN (VALUES
    ('Melamina Blanco 18mm', 28.0, 150.00),
    ('Mapresa (fondo)',       10.5, 100.00),
    ('Tapacanto (rollo)',      2.1,  35.00),
    ('Tornillos (caja 1000)', 0.70,  80.00),
    ('Jaladores',            35.0,   1.00),
    ('Patitas',             140.0,   0.40)
) AS cons(material_nombre, cantidad, precio)
JOIN material m ON m.nombre = cons.material_nombre
WHERE op.numero_orden = 'OP-2026-004';

-- Consumo: OP-2026-005 → Comodín x15
INSERT INTO consumo_material (produccion_id, material_id, cantidad_consumida, costo_unitario)
SELECT p.id, m.id, cons.cantidad, cons.precio
FROM produccion p
JOIN orden_produccion op ON op.id = p.orden_produccion_id
CROSS JOIN (VALUES
    ('Melamina Blanco 18mm', 18.0, 150.00),
    ('Mapresa (fondo)',        7.5, 100.00),
    ('Tapacanto (rollo)',      1.5,  35.00),
    ('Tornillos (caja 1000)', 0.45,  80.00),
    ('Bisagras (caja 100)',   0.30,  90.00),
    ('Jaladores',            30.0,   1.00)
) AS cons(material_nombre, cantidad, precio)
JOIN material m ON m.nombre = cons.material_nombre
WHERE op.numero_orden = 'OP-2026-005';

-- Consumo: OP-2026-006 → Ropero x10
INSERT INTO consumo_material (produccion_id, material_id, cantidad_consumida, costo_unitario)
SELECT p.id, m.id, cons.cantidad, cons.precio
FROM produccion p
JOIN orden_produccion op ON op.id = p.orden_produccion_id
CROSS JOIN (VALUES
    ('Melamina Blanco 18mm', 25.0, 152.00),
    ('Mapresa (fondo)',       10.0, 100.00),
    ('Tapacanto (rollo)',      2.5,  35.00),
    ('Tornillos (caja 1000)', 0.50,  80.00),
    ('Jaladores',            40.0,   1.00),
    ('Correderas (30cm)',    20.0,  20.00),
    ('Patitas',              40.0,   0.40)
) AS cons(material_nombre, cantidad, precio)
JOIN material m ON m.nombre = cons.material_nombre
WHERE op.numero_orden = 'OP-2026-006';

-- ============================================================
--  13. VENTAS — MARZO 2026
--      1 cabecera por venta, N líneas en detalle_venta
--      El trigger trg_total_venta recalcula total_venta automáticamente
-- ============================================================

-- 02-Mar: Ana Torres — Ropero x2 + Velador x3
WITH v AS (INSERT INTO venta (fecha,cliente_id,tipo_venta_id,usuario_id)
VALUES ('2026-03-02',(SELECT id FROM cliente WHERE documento='12345678'),
        (SELECT id FROM tipo_venta WHERE nombre='Contado'),
        (SELECT id FROM usuario WHERE email='juan@muebleria.com')) RETURNING id)
INSERT INTO detalle_venta (venta_id,producto_id,cantidad,precio_unitario)
SELECT v.id,p.id,d.c,d.pr FROM v,
(VALUES ('Ropero',2,760.00),('Velador',3,90.00)) AS d(nm,c,pr)
JOIN producto p ON p.nombre=d.nm;

-- 03-Mar: Ana Torres — Velador x2
WITH v AS (INSERT INTO venta (fecha,cliente_id,tipo_venta_id,usuario_id)
VALUES ('2026-03-03',(SELECT id FROM cliente WHERE documento='12345678'),
        (SELECT id FROM tipo_venta WHERE nombre='Contado'),
        (SELECT id FROM usuario WHERE email='juan@muebleria.com')) RETURNING id)
INSERT INTO detalle_venta (venta_id,producto_id,cantidad,precio_unitario)
SELECT v.id,p.id,2,90.00 FROM v JOIN producto p ON p.nombre='Velador';

-- 04-Mar: Carlos Mamani — Ropero x3 + Comodín x2
WITH v AS (INSERT INTO venta (fecha,cliente_id,tipo_venta_id,usuario_id)
VALUES ('2026-03-04',(SELECT id FROM cliente WHERE documento='87654321'),
        (SELECT id FROM tipo_venta WHERE nombre='Contado'),
        (SELECT id FROM usuario WHERE email='luis@muebleria.com')) RETURNING id)
INSERT INTO detalle_venta (venta_id,producto_id,cantidad,precio_unitario)
SELECT v.id,p.id,d.c,d.pr FROM v,
(VALUES ('Ropero',3,760.00),('Comodín',2,230.00)) AS d(nm,c,pr)
JOIN producto p ON p.nombre=d.nm;

-- 05-Mar: Ana Torres — Velador x4
WITH v AS (INSERT INTO venta (fecha,cliente_id,tipo_venta_id,usuario_id)
VALUES ('2026-03-05',(SELECT id FROM cliente WHERE documento='12345678'),
        (SELECT id FROM tipo_venta WHERE nombre='Contado'),
        (SELECT id FROM usuario WHERE email='juan@muebleria.com')) RETURNING id)
INSERT INTO detalle_venta (venta_id,producto_id,cantidad,precio_unitario)
SELECT v.id,p.id,4,90.00 FROM v JOIN producto p ON p.nombre='Velador';

-- 06-Mar: Muebles El Norte (mayorista crédito) — Ropero x5
WITH v AS (INSERT INTO venta (fecha,cliente_id,tipo_venta_id,usuario_id)
VALUES ('2026-03-06',(SELECT id FROM cliente WHERE documento='20111222333'),
        (SELECT id FROM tipo_venta WHERE nombre='Crédito'),
        (SELECT id FROM usuario WHERE email='juan@muebleria.com')) RETURNING id)
INSERT INTO detalle_venta (venta_id,producto_id,cantidad,precio_unitario)
SELECT v.id,p.id,5,730.00 FROM v JOIN producto p ON p.nombre='Ropero';

-- 06-Mar: Carlos Mamani — Cómoda x1
WITH v AS (INSERT INTO venta (fecha,cliente_id,tipo_venta_id,usuario_id)
VALUES ('2026-03-06',(SELECT id FROM cliente WHERE documento='87654321'),
        (SELECT id FROM tipo_venta WHERE nombre='Contado'),
        (SELECT id FROM usuario WHERE email='luis@muebleria.com')) RETURNING id)
INSERT INTO detalle_venta (venta_id,producto_id,cantidad,precio_unitario)
SELECT v.id,p.id,1,480.00 FROM v JOIN producto p ON p.nombre='Cómoda';

-- 08-Mar: Rosa Quispe — Velador x5
WITH v AS (INSERT INTO venta (fecha,cliente_id,tipo_venta_id,usuario_id)
VALUES ('2026-03-08',(SELECT id FROM cliente WHERE documento='45678901'),
        (SELECT id FROM tipo_venta WHERE nombre='Contado'),
        (SELECT id FROM usuario WHERE email='juan@muebleria.com')) RETURNING id)
INSERT INTO detalle_venta (venta_id,producto_id,cantidad,precio_unitario)
SELECT v.id,p.id,5,90.00 FROM v JOIN producto p ON p.nombre='Velador';

-- 09-Mar: Ana Torres — Ropero x1
WITH v AS (INSERT INTO venta (fecha,cliente_id,tipo_venta_id,usuario_id)
VALUES ('2026-03-09',(SELECT id FROM cliente WHERE documento='12345678'),
        (SELECT id FROM tipo_venta WHERE nombre='Contado'),
        (SELECT id FROM usuario WHERE email='juan@muebleria.com')) RETURNING id)
INSERT INTO detalle_venta (venta_id,producto_id,cantidad,precio_unitario)
SELECT v.id,p.id,1,760.00 FROM v JOIN producto p ON p.nombre='Ropero';

-- 09-Mar: Carlos Mamani — Ropero x3 + Comodín x2
WITH v AS (INSERT INTO venta (fecha,cliente_id,tipo_venta_id,usuario_id)
VALUES ('2026-03-09',(SELECT id FROM cliente WHERE documento='87654321'),
        (SELECT id FROM tipo_venta WHERE nombre='Contado'),
        (SELECT id FROM usuario WHERE email='luis@muebleria.com')) RETURNING id)
INSERT INTO detalle_venta (venta_id,producto_id,cantidad,precio_unitario)
SELECT v.id,p.id,d.c,d.pr FROM v,
(VALUES ('Ropero',3,760.00),('Comodín',2,230.00)) AS d(nm,c,pr)
JOIN producto p ON p.nombre=d.nm;

-- 11-Mar: Ana Torres — Velador x6 + Cómoda x2
WITH v AS (INSERT INTO venta (fecha,cliente_id,tipo_venta_id,usuario_id)
VALUES ('2026-03-11',(SELECT id FROM cliente WHERE documento='12345678'),
        (SELECT id FROM tipo_venta WHERE nombre='Contado'),
        (SELECT id FROM usuario WHERE email='juan@muebleria.com')) RETURNING id)
INSERT INTO detalle_venta (venta_id,producto_id,cantidad,precio_unitario)
SELECT v.id,p.id,d.c,d.pr FROM v,
(VALUES ('Velador',6,90.00),('Cómoda',2,480.00)) AS d(nm,c,pr)
JOIN producto p ON p.nombre=d.nm;

-- 12-Mar: Luis Condori — Ropero x1
WITH v AS (INSERT INTO venta (fecha,cliente_id,tipo_venta_id,usuario_id)
VALUES ('2026-03-12',(SELECT id FROM cliente WHERE documento='23456789'),
        (SELECT id FROM tipo_venta WHERE nombre='Contado'),
        (SELECT id FROM usuario WHERE email='luis@muebleria.com')) RETURNING id)
INSERT INTO detalle_venta (venta_id,producto_id,cantidad,precio_unitario)
SELECT v.id,p.id,1,760.00 FROM v JOIN producto p ON p.nombre='Ropero';

-- 13-Mar: Rosa Quispe — Velador x4
WITH v AS (INSERT INTO venta (fecha,cliente_id,tipo_venta_id,usuario_id)
VALUES ('2026-03-13',(SELECT id FROM cliente WHERE documento='45678901'),
        (SELECT id FROM tipo_venta WHERE nombre='Contado'),
        (SELECT id FROM usuario WHERE email='juan@muebleria.com')) RETURNING id)
INSERT INTO detalle_venta (venta_id,producto_id,cantidad,precio_unitario)
SELECT v.id,p.id,4,90.00 FROM v JOIN producto p ON p.nombre='Velador';

-- 14-Mar: Distribuidora Altiplano (mayorista crédito) — Ropero x6
WITH v AS (INSERT INTO venta (fecha,cliente_id,tipo_venta_id,usuario_id)
VALUES ('2026-03-14',(SELECT id FROM cliente WHERE documento='20444555666'),
        (SELECT id FROM tipo_venta WHERE nombre='Crédito'),
        (SELECT id FROM usuario WHERE email='juan@muebleria.com')) RETURNING id)
INSERT INTO detalle_venta (venta_id,producto_id,cantidad,precio_unitario)
SELECT v.id,p.id,6,740.00 FROM v JOIN producto p ON p.nombre='Ropero';

-- 15-Mar: Carlos Mamani — Cómoda x3
WITH v AS (INSERT INTO venta (fecha,cliente_id,tipo_venta_id,usuario_id)
VALUES ('2026-03-15',(SELECT id FROM cliente WHERE documento='87654321'),
        (SELECT id FROM tipo_venta WHERE nombre='Contado'),
        (SELECT id FROM usuario WHERE email='luis@muebleria.com')) RETURNING id)
INSERT INTO detalle_venta (venta_id,producto_id,cantidad,precio_unitario)
SELECT v.id,p.id,3,480.00 FROM v JOIN producto p ON p.nombre='Cómoda';

-- 16-Mar: Ana Torres — Velador x7
WITH v AS (INSERT INTO venta (fecha,cliente_id,tipo_venta_id,usuario_id)
VALUES ('2026-03-16',(SELECT id FROM cliente WHERE documento='12345678'),
        (SELECT id FROM tipo_venta WHERE nombre='Contado'),
        (SELECT id FROM usuario WHERE email='juan@muebleria.com')) RETURNING id)
INSERT INTO detalle_venta (venta_id,producto_id,cantidad,precio_unitario)
SELECT v.id,p.id,7,90.00 FROM v JOIN producto p ON p.nombre='Velador';

-- 17-Mar: Luis Condori — Ropero x3
WITH v AS (INSERT INTO venta (fecha,cliente_id,tipo_venta_id,usuario_id)
VALUES ('2026-03-17',(SELECT id FROM cliente WHERE documento='23456789'),
        (SELECT id FROM tipo_venta WHERE nombre='Contado'),
        (SELECT id FROM usuario WHERE email='luis@muebleria.com')) RETURNING id)
INSERT INTO detalle_venta (venta_id,producto_id,cantidad,precio_unitario)
SELECT v.id,p.id,3,760.00 FROM v JOIN producto p ON p.nombre='Ropero';

-- 18-Mar: Rosa Quispe — Comodín x3
WITH v AS (INSERT INTO venta (fecha,cliente_id,tipo_venta_id,usuario_id)
VALUES ('2026-03-18',(SELECT id FROM cliente WHERE documento='45678901'),
        (SELECT id FROM tipo_venta WHERE nombre='Contado'),
        (SELECT id FROM usuario WHERE email='juan@muebleria.com')) RETURNING id)
INSERT INTO detalle_venta (venta_id,producto_id,cantidad,precio_unitario)
SELECT v.id,p.id,3,230.00 FROM v JOIN producto p ON p.nombre='Comodín';

-- 19-Mar: Carlos Mamani — Velador x5
WITH v AS (INSERT INTO venta (fecha,cliente_id,tipo_venta_id,usuario_id)
VALUES ('2026-03-19',(SELECT id FROM cliente WHERE documento='87654321'),
        (SELECT id FROM tipo_venta WHERE nombre='Contado'),
        (SELECT id FROM usuario WHERE email='luis@muebleria.com')) RETURNING id)
INSERT INTO detalle_venta (venta_id,producto_id,cantidad,precio_unitario)
SELECT v.id,p.id,5,90.00 FROM v JOIN producto p ON p.nombre='Velador';

-- 20-Mar: Ana Torres — Ropero x2
WITH v AS (INSERT INTO venta (fecha,cliente_id,tipo_venta_id,usuario_id)
VALUES ('2026-03-20',(SELECT id FROM cliente WHERE documento='12345678'),
        (SELECT id FROM tipo_venta WHERE nombre='Contado'),
        (SELECT id FROM usuario WHERE email='juan@muebleria.com')) RETURNING id)
INSERT INTO detalle_venta (venta_id,producto_id,cantidad,precio_unitario)
SELECT v.id,p.id,2,760.00 FROM v JOIN producto p ON p.nombre='Ropero';

-- 21-Mar: Luis Condori — Velador x3
WITH v AS (INSERT INTO venta (fecha,cliente_id,tipo_venta_id,usuario_id)
VALUES ('2026-03-21',(SELECT id FROM cliente WHERE documento='23456789'),
        (SELECT id FROM tipo_venta WHERE nombre='Contado'),
        (SELECT id FROM usuario WHERE email='luis@muebleria.com')) RETURNING id)
INSERT INTO detalle_venta (venta_id,producto_id,cantidad,precio_unitario)
SELECT v.id,p.id,3,90.00 FROM v JOIN producto p ON p.nombre='Velador';

-- 23-Mar: Muebles El Norte (mayorista contado) — Ropero x8
WITH v AS (INSERT INTO venta (fecha,cliente_id,tipo_venta_id,usuario_id)
VALUES ('2026-03-23',(SELECT id FROM cliente WHERE documento='20111222333'),
        (SELECT id FROM tipo_venta WHERE nombre='Contado'),
        (SELECT id FROM usuario WHERE email='juan@muebleria.com')) RETURNING id)
INSERT INTO detalle_venta (venta_id,producto_id,cantidad,precio_unitario)
SELECT v.id,p.id,8,730.00 FROM v JOIN producto p ON p.nombre='Ropero';

-- 24-Mar: Carlos Mamani — Cómoda x4
WITH v AS (INSERT INTO venta (fecha,cliente_id,tipo_venta_id,usuario_id)
VALUES ('2026-03-24',(SELECT id FROM cliente WHERE documento='87654321'),
        (SELECT id FROM tipo_venta WHERE nombre='Contado'),
        (SELECT id FROM usuario WHERE email='luis@muebleria.com')) RETURNING id)
INSERT INTO detalle_venta (venta_id,producto_id,cantidad,precio_unitario)
SELECT v.id,p.id,4,480.00 FROM v JOIN producto p ON p.nombre='Cómoda';

-- 25-Mar: Rosa Quispe — Velador x6
WITH v AS (INSERT INTO venta (fecha,cliente_id,tipo_venta_id,usuario_id)
VALUES ('2026-03-25',(SELECT id FROM cliente WHERE documento='45678901'),
        (SELECT id FROM tipo_venta WHERE nombre='Contado'),
        (SELECT id FROM usuario WHERE email='juan@muebleria.com')) RETURNING id)
INSERT INTO detalle_venta (venta_id,producto_id,cantidad,precio_unitario)
SELECT v.id,p.id,6,90.00 FROM v JOIN producto p ON p.nombre='Velador';

-- 26-Mar: Luis Condori — Ropero x1
WITH v AS (INSERT INTO venta (fecha,cliente_id,tipo_venta_id,usuario_id)
VALUES ('2026-03-26',(SELECT id FROM cliente WHERE documento='23456789'),
        (SELECT id FROM tipo_venta WHERE nombre='Contado'),
        (SELECT id FROM usuario WHERE email='luis@muebleria.com')) RETURNING id)
INSERT INTO detalle_venta (venta_id,producto_id,cantidad,precio_unitario)
SELECT v.id,p.id,1,760.00 FROM v JOIN producto p ON p.nombre='Ropero';

-- 27-Mar: Ana Torres — Comodín x3
WITH v AS (INSERT INTO venta (fecha,cliente_id,tipo_venta_id,usuario_id)
VALUES ('2026-03-27',(SELECT id FROM cliente WHERE documento='12345678'),
        (SELECT id FROM tipo_venta WHERE nombre='Contado'),
        (SELECT id FROM usuario WHERE email='juan@muebleria.com')) RETURNING id)
INSERT INTO detalle_venta (venta_id,producto_id,cantidad,precio_unitario)
SELECT v.id,p.id,3,230.00 FROM v JOIN producto p ON p.nombre='Comodín';

-- 28-Mar: Carlos Mamani — Velador x5
WITH v AS (INSERT INTO venta (fecha,cliente_id,tipo_venta_id,usuario_id)
VALUES ('2026-03-28',(SELECT id FROM cliente WHERE documento='87654321'),
        (SELECT id FROM tipo_venta WHERE nombre='Contado'),
        (SELECT id FROM usuario WHERE email='luis@muebleria.com')) RETURNING id)
INSERT INTO detalle_venta (venta_id,producto_id,cantidad,precio_unitario)
SELECT v.id,p.id,5,90.00 FROM v JOIN producto p ON p.nombre='Velador';

-- 30-Mar: Mueblería Centro (mayorista crédito) — Ropero x4 + Cómoda x2
WITH v AS (INSERT INTO venta (fecha,cliente_id,tipo_venta_id,usuario_id)
VALUES ('2026-03-30',(SELECT id FROM cliente WHERE documento='20777888999'),
        (SELECT id FROM tipo_venta WHERE nombre='Crédito'),
        (SELECT id FROM usuario WHERE email='juan@muebleria.com')) RETURNING id)
INSERT INTO detalle_venta (venta_id,producto_id,cantidad,precio_unitario)
SELECT v.id,p.id,d.c,d.pr FROM v,
(VALUES ('Ropero',4,730.00),('Cómoda',2,450.00)) AS d(nm,c,pr)
JOIN producto p ON p.nombre=d.nm;

-- ============================================================
--  14. CUENTAS POR COBRAR — ventas a crédito (30 días plazo)
-- ============================================================

INSERT INTO cuentas_cobrar
    (venta_id, fecha_emision, fecha_vencimiento, monto_total, saldo_pendiente, estado, numero_cuota, total_cuotas)
SELECT
    v.id, v.fecha,
    v.fecha + INTERVAL '30 days',
    v.total_venta, v.total_venta,
    'pendiente', 1, 1
FROM venta v
WHERE v.tipo_venta_id = (SELECT id FROM tipo_venta WHERE nombre='Crédito');

-- ============================================================
--  15. PAGOS DE CLIENTES — abonos registrados en marzo
-- ============================================================

-- Muebles El Norte abona S/1,500 el 20-Mar
INSERT INTO pago_cliente (cuenta_cobrar_id, fecha, monto, metodo_pago, referencia, usuario_id)
SELECT cc.id,'2026-03-20',1500.00,'transferencia','TRF-BN-20260320',
       (SELECT id FROM usuario WHERE email='maria@muebleria.com')
FROM cuentas_cobrar cc
JOIN venta v ON v.id = cc.venta_id
JOIN cliente c ON c.id = v.cliente_id
WHERE c.documento = '20111222333' AND cc.saldo_pendiente > 0
LIMIT 1;

-- Distribuidora Altiplano abona S/2,220 el 25-Mar
INSERT INTO pago_cliente (cuenta_cobrar_id, fecha, monto, metodo_pago, referencia, usuario_id)
SELECT cc.id,'2026-03-25',2220.00,'transferencia','TRF-BCP-20260325',
       (SELECT id FROM usuario WHERE email='maria@muebleria.com')
FROM cuentas_cobrar cc
JOIN venta v ON v.id = cc.venta_id
JOIN cliente c ON c.id = v.cliente_id
WHERE c.documento = '20444555666' AND cc.saldo_pendiente > 0
LIMIT 1;

-- ============================================================
--  16. GASTOS OPERATIVOS — MARZO 2026
-- ============================================================

INSERT INTO gasto (fecha, categoria_id, monto, detalle, comprobante, usuario_id)
SELECT g.fecha, cg.id, g.monto, g.detalle, g.comprobante,
       (SELECT id FROM usuario WHERE email='maria@muebleria.com')
FROM (VALUES
    ('2026-03-01'::date, 'Alquiler local + servicios',        2800.00, 'Alquiler taller + agua + luz',             'REC-001'),
    ('2026-03-01'::date, 'Servicios (luz, agua, internet)',    320.00,  'Internet taller',                          'REC-002'),
    ('2026-03-10'::date, 'Compra Melamina y accesorios',      4200.00, 'Compra materiales primera quincena',        'F-VARS-01'),
    ('2026-03-15'::date, 'Mano de Obra (eventual)',           6800.00, 'Pago 3 operarios + maestro (quincena)',     'PL-001'),
    ('2026-03-20'::date, 'Compra Melamina y accesorios',      4150.00, 'Compra materiales segunda quincena',        'F-VARS-02'),
    ('2026-03-22'::date, 'Transporte y delivery',              980.00, 'Entregas a clientes y recojo materiales',   'REC-003'),
    ('2026-03-28'::date, 'Otros (herramientas, etc.)',         650.00, 'Mantenimiento maquinaria y herramientas',   'REC-004'),
    ('2026-03-29'::date, 'Marketing y publicidad',             350.00, 'Publicidad Facebook e Instagram',           'REC-005'),
    ('2026-03-31'::date, 'Mano de Obra (eventual)',           6800.00, 'Pago 3 operarios + maestro (fin de mes)',   'PL-002'),
    ('2026-03-31'::date, 'Servicios (luz, agua, internet)',    280.00, 'Luz y agua - cierre mes',                   'REC-006')
) AS g(fecha, categoria, monto, detalle, comprobante)
JOIN categoria_gasto cg ON cg.nombre = g.categoria;

-- ============================================================
--  17. MOVIMIENTOS DE CAJA — MARZO 2026
-- ============================================================

INSERT INTO movimiento_caja
    (caja_id, fecha, tipo, concepto, monto, metodo_pago, referencia_tabla, usuario_id)
SELECT
    (SELECT id FROM caja WHERE fecha_apertura='2026-03-01' LIMIT 1),
    mc.fecha, mc.tipo, mc.concepto, mc.monto, mc.metodo_pago, mc.ref_tabla,
    (SELECT id FROM usuario WHERE email='maria@muebleria.com')
FROM (VALUES
    -- INGRESOS
    ('2026-03-02'::timestamptz,'ingreso','Venta contado - Ana Torres (Ropero x2 + Velador x3)',          2060.00,'efectivo',    'venta'),
    ('2026-03-03'::timestamptz,'ingreso','Venta contado - Ana Torres (Velador x2)',                        180.00,'efectivo',    'venta'),
    ('2026-03-04'::timestamptz,'ingreso','Venta contado - Carlos Mamani (Ropero x3 + Comodín x2)',        2740.00,'efectivo',    'venta'),
    ('2026-03-05'::timestamptz,'ingreso','Venta contado - Ana Torres (Velador x4)',                        360.00,'efectivo',    'venta'),
    ('2026-03-06'::timestamptz,'ingreso','Venta contado - Carlos Mamani (Cómoda x1)',                      480.00,'efectivo',    'venta'),
    ('2026-03-08'::timestamptz,'ingreso','Venta contado - Rosa Quispe (Velador x5)',                       450.00,'efectivo',    'venta'),
    ('2026-03-09'::timestamptz,'ingreso','Venta contado - Ana Torres (Ropero x1)',                         760.00,'efectivo',    'venta'),
    ('2026-03-09'::timestamptz,'ingreso','Venta contado - Carlos Mamani (Ropero x3 + Comodín x2)',        2740.00,'efectivo',    'venta'),
    ('2026-03-11'::timestamptz,'ingreso','Venta contado - Ana Torres (Velador x6 + Cómoda x2)',           1500.00,'efectivo',    'venta'),
    ('2026-03-12'::timestamptz,'ingreso','Venta contado - Luis Condori (Ropero x1)',                       760.00,'efectivo',    'venta'),
    ('2026-03-13'::timestamptz,'ingreso','Venta contado - Rosa Quispe (Velador x4)',                       360.00,'efectivo',    'venta'),
    ('2026-03-15'::timestamptz,'ingreso','Venta contado - Carlos Mamani (Cómoda x3)',                     1440.00,'efectivo',    'venta'),
    ('2026-03-16'::timestamptz,'ingreso','Venta contado - Ana Torres (Velador x7)',                        630.00,'efectivo',    'venta'),
    ('2026-03-17'::timestamptz,'ingreso','Venta contado - Luis Condori (Ropero x3)',                      2280.00,'efectivo',    'venta'),
    ('2026-03-18'::timestamptz,'ingreso','Venta contado - Rosa Quispe (Comodín x3)',                       690.00,'efectivo',    'venta'),
    ('2026-03-19'::timestamptz,'ingreso','Venta contado - Carlos Mamani (Velador x5)',                     450.00,'efectivo',    'venta'),
    ('2026-03-20'::timestamptz,'ingreso','Venta contado - Ana Torres (Ropero x2)',                        1520.00,'efectivo',    'venta'),
    ('2026-03-20'::timestamptz,'ingreso','Pago crédito - Muebles El Norte (abono)',                       1500.00,'transferencia','pago_cliente'),
    ('2026-03-21'::timestamptz,'ingreso','Venta contado - Luis Condori (Velador x3)',                      270.00,'efectivo',    'venta'),
    ('2026-03-23'::timestamptz,'ingreso','Venta contado - Muebles El Norte (Ropero x8)',                  5840.00,'transferencia','venta'),
    ('2026-03-24'::timestamptz,'ingreso','Venta contado - Carlos Mamani (Cómoda x4)',                     1920.00,'efectivo',    'venta'),
    ('2026-03-25'::timestamptz,'ingreso','Venta contado - Rosa Quispe (Velador x6)',                       540.00,'efectivo',    'venta'),
    ('2026-03-25'::timestamptz,'ingreso','Pago crédito - Distribuidora Altiplano (abono)',                2220.00,'transferencia','pago_cliente'),
    ('2026-03-26'::timestamptz,'ingreso','Venta contado - Luis Condori (Ropero x1)',                       760.00,'efectivo',    'venta'),
    ('2026-03-27'::timestamptz,'ingreso','Venta contado - Ana Torres (Comodín x3)',                        690.00,'efectivo',    'venta'),
    ('2026-03-28'::timestamptz,'ingreso','Venta contado - Carlos Mamani (Velador x5)',                     450.00,'efectivo',    'venta'),
    -- EGRESOS
    ('2026-03-01'::timestamptz,'egreso', 'Alquiler local + servicios - marzo',                            2800.00,'efectivo',    'gasto'),
    ('2026-03-01'::timestamptz,'egreso', 'Internet taller - marzo',                                        320.00,'transferencia','gasto'),
    ('2026-03-10'::timestamptz,'egreso', 'Compra materiales primera quincena',                            4200.00,'efectivo',    'gasto'),
    ('2026-03-15'::timestamptz,'egreso', 'Pago planilla operarios - quincena',                            6800.00,'efectivo',    'gasto'),
    ('2026-03-20'::timestamptz,'egreso', 'Compra materiales segunda quincena',                            4150.00,'efectivo',    'gasto'),
    ('2026-03-22'::timestamptz,'egreso', 'Transporte y delivery marzo',                                    980.00,'efectivo',    'gasto'),
    ('2026-03-28'::timestamptz,'egreso', 'Mantenimiento herramientas y maquinaria',                        650.00,'efectivo',    'gasto'),
    ('2026-03-29'::timestamptz,'egreso', 'Publicidad redes sociales',                                      350.00,'transferencia','gasto'),
    ('2026-03-31'::timestamptz,'egreso', 'Pago planilla operarios - fin de mes',                          6800.00,'efectivo',    'gasto'),
    ('2026-03-31'::timestamptz,'egreso', 'Luz y agua - cierre mes',                                        280.00,'efectivo',    'gasto')
) AS mc(fecha, tipo, concepto, monto, metodo_pago, ref_tabla);

-- Cierre de caja al 31 de marzo
UPDATE caja
SET fecha_cierre      = '2026-03-31',
    estado            = 'cerrada',
    saldo_final       = saldo_inicial + total_ingresos - total_egresos,
    usuario_cierre_id = (SELECT id FROM usuario WHERE email='admin@muebleria.com')
WHERE fecha_apertura  = '2026-03-01' AND estado = 'abierta';

-- ============================================================
--  18. DEVOLUCIÓN — Carlos Mamani devuelve 1 velador (28-Mar)
-- ============================================================

INSERT INTO devolucion_venta
    (venta_id, detalle_venta_id, fecha, cantidad, motivo, monto_reembolsado, usuario_id)
SELECT
    dv.venta_id, dv.id,
    '2026-03-29', 1,
    'Producto con defecto en la superficie',
    90.00,
    (SELECT id FROM usuario WHERE email='juan@muebleria.com')
FROM detalle_venta dv
JOIN venta v    ON v.id  = dv.venta_id
JOIN cliente c  ON c.id  = v.cliente_id
JOIN producto p ON p.id  = dv.producto_id
WHERE c.documento = '87654321'
  AND p.nombre    = 'Velador'
  AND v.fecha     = '2026-03-28'
LIMIT 1;

-- ============================================================
--  19. VERIFICACIONES FINALES — ejecutar para confirmar carga
-- ============================================================

-- Stock actual de materiales con alertas
SELECT * FROM v_stock_materiales;

-- Stock de productos terminados con alertas
SELECT * FROM v_stock_productos;

-- Ventas agrupadas por producto con margen bruto
SELECT * FROM v_ventas_por_producto;

-- Cuentas por cobrar pendientes / vencidas
SELECT * FROM v_cuentas_cobrar_pendientes;

-- Resumen mensual: ingresos, gastos, utilidad bruta
SELECT * FROM v_resumen_mensual;

-- Rentabilidad real por lote de producción
SELECT * FROM v_rentabilidad_produccion;

-- Kardex de movimientos de materiales (últimos 20)
SELECT * FROM v_kardex_materiales LIMIT 20;

-- Estado de caja al cierre de mes
SELECT fecha_apertura, fecha_cierre, saldo_inicial,
       total_ingresos, total_egresos,
       saldo_inicial + total_ingresos - total_egresos AS saldo_calculado,
       saldo_final, estado
FROM caja;

-- ============================================================
--  FIN DEL SCRIPT DE DATOS
-- ============================================================
