-- ============================================================
--  MUEBLERÍA / CARPINTERÍA — DATOS MARZO 2026
--
--  Motor:   PostgreSQL 14+
--  Esquema: transaccional
--  Período: Enero 2026
--
--  EJECUTAR DESPUÉS DE: base_datos_transaccional.sql
-- ============================================================

SET search_path TO transaccional, public;
--  8. APERTURA DE CAJA â€” MARZO 2026
-- ============================================================

INSERT INTO caja (fecha_apertura, saldo_inicial, estado, usuario_apertura_id)
VALUES (
    '2026-01-01', COALESCE((SELECT saldo_final FROM caja WHERE fecha_cierre = '2025-12-31'), 2000.00), 'abierta',
    (SELECT id FROM usuario WHERE email='admin@muebleria.com')
);

-- ============================================================
--  9. COMPRAS DE MATERIALES â€” MARZO 2026
--     Los triggers actualizan stock_actual y movimiento_material
-- ============================================================

INSERT INTO compra_material
    (fecha, proveedor_id, material_id, cantidad, precio_unitario, factura_numero, notas, usuario_id)
SELECT
    cm.fecha, pr.id, m.id, cm.cantidad, cm.precio_unit,
    cm.factura, cm.notas,
    (SELECT id FROM usuario WHERE email='admin@muebleria.com')
FROM (VALUES
    ('2026-01-01'::date, 'Melaminas del Perú S.A.C.', 'Melamina Blanco 18mm',    8,   150.00, 'F001-001', 'Compra inicial mes'),
    ('2026-01-01'::date, 'Ferretodo S.A.C.',          'Mapresa (fondo)',          5,   100.00, 'F002-001', 'Compra inicial mes'),
    ('2026-01-02'::date, 'Ferretodo S.A.C.',          'Tornillos (caja 1000)',    2,    80.00, 'F002-002', 'Stock inicial'),
    ('2026-01-03'::date, 'Melaminas del Perú S.A.C.', 'Melamina Color 18mm',     6,   180.00, 'F001-002', 'Para cómodas'),
    ('2026-01-05'::date, 'Maderas Noble E.I.R.L.',    'Tapacanto (rollo)',        4,    35.00, 'F003-001', 'Varios colores'),
    ('2026-01-07'::date, 'Ferretodo S.A.C.',          'Jaladores',             200,     1.00, 'F002-003', 'Variedad modelos'),
    ('2026-01-08'::date, 'Maderas Noble E.I.R.L.',    'Correderas (30cm)',       50,    20.00, 'F003-002', 'Stock correderas'),
    ('2026-01-10'::date, 'Ferretodo S.A.C.',          'Bisagras (caja 100)',      2,    90.00, 'F002-004', 'Bisagras estándar'),
    ('2026-01-12'::date, 'Acabados y Más S.A.C.',     'Laca selladora',         10,    28.00, 'F004-001', 'Para acabados'),
    ('2026-01-14'::date, 'Acabados y Más S.A.C.',     'Pegamento contacto',     15,    12.00, 'F004-002', 'Pegamento contacto'),
    ('2026-01-15'::date, 'Ferretodo S.A.C.',          'Patitas',               300,     0.40, 'F002-005', 'Surtido tamaños'),
    ('2026-01-18'::date, 'Melaminas del Perú S.A.C.', 'Melamina Blanco 18mm',    7,   152.00, 'F001-003', 'Reposición urgente'),
    ('2026-01-20'::date, 'Ferretodo S.A.C.',          'Tornillos (caja 1000)',    1,    80.00, 'F002-006', 'Reposición'),
    ('2026-01-22'::date, 'Ferretodo S.A.C.',          'Mapresa (fondo)',          4,   100.00, 'F002-007', 'Reposición fondo'),
    ('2026-01-25'::date, 'Melaminas del Perú S.A.C.', 'Melamina Color 18mm',     5,   175.00, 'F001-004', 'Compra urgente'),
    ('2026-01-28'::date, 'Ferretodo S.A.C.',          'Jaladores',             100,     1.00, 'F002-008', 'Reposición'),
    ('2026-01-30'::date, 'Maderas Noble E.I.R.L.',    'Tapacanto (rollo)',        2,    35.00, 'F003-003', 'Reposición cierre mes')
) AS cm(fecha, proveedor_nombre, material_nombre, cantidad, precio_unit, factura, notas)
JOIN proveedor pr ON pr.nombre = cm.proveedor_nombre
JOIN material   m ON  m.nombre = cm.material_nombre;

-- ============================================================
--  10. Ã“RDENES DE PRODUCCIÃ“N â€” MARZO 2026
-- ============================================================

INSERT INTO orden_produccion
    (numero_orden, fecha_inicio, fecha_fin_estimada, fecha_fin_real,
     producto_id, cantidad_ordenada, cantidad_producida, estado, responsable_id,
     costo_mp_estimado, costo_mo_estimado, notas)
VALUES
    ('OP-2026-101','2026-01-01','2026-01-05','2026-01-04',
     (SELECT id FROM producto WHERE nombre='Ropero'),  12,12,'completada',
     (SELECT id FROM usuario WHERE email='pedro@muebleria.com'), 4320.00,1260.00,'Lote 1 inicio mes'),

    ('OP-2026-102','2026-01-08','2026-01-12','2026-01-11',
     (SELECT id FROM producto WHERE nombre='Ropero'),  15,15,'completada',
     (SELECT id FROM usuario WHERE email='pedro@muebleria.com'), 5400.00,1575.00,'Pedido Muebles Norte'),

    ('OP-2026-103','2026-01-10','2026-01-15','2026-01-14',
     (SELECT id FROM producto WHERE nombre='Cómoda'),  18,18,'completada',
     (SELECT id FROM usuario WHERE email='pedro@muebleria.com'), 3240.00,1080.00,'Reposición cómodas'),

    ('OP-2026-104','2026-01-15','2026-01-20','2026-01-19',
     (SELECT id FROM producto WHERE nombre='Velador'), 35,35,'completada',
     (SELECT id FROM usuario WHERE email='pedro@muebleria.com'), 1575.00, 875.00,'Alta rotación veladores'),

    ('OP-2026-105','2026-01-20','2026-01-24','2026-01-24',
     (SELECT id FROM producto WHERE nombre='Comodín'), 15,15,'completada',
     (SELECT id FROM usuario WHERE email='pedro@muebleria.com'),  900.00, 450.00,'Reposición comodines'),

    ('OP-2026-106','2026-01-25','2026-01-30','2026-01-29',
     (SELECT id FROM producto WHERE nombre='Ropero'),  10,10,'completada',
     (SELECT id FROM usuario WHERE email='pedro@muebleria.com'), 3600.00,1050.00,'Cierre de mes'),

    ('OP-2026-107','2026-01-28','2026-04-03',NULL,
     (SELECT id FROM producto WHERE nombre='Estante'),  8, 0,'en_proceso',
     (SELECT id FROM usuario WHERE email='pedro@muebleria.com'),  960.00, 400.00,'Orden en curso');

-- ============================================================
--  11. PRODUCCIÃ“N REAL â€” MARZO 2026
--      costo_materia_prima y mano_de_obra = TOTALES DEL LOTE
--      costo_unitario se calcula automáticamente (columna GENERATED)
-- ============================================================

INSERT INTO produccion
    (orden_produccion_id, fecha_produccion, producto_id, cantidad_producida,
     costo_materia_prima, mano_de_obra, destino_id, notas)
SELECT op.id, pr.fecha, p.id, pr.cantidad, pr.costo_mp, pr.mano_obra, d.id, pr.notas
FROM (VALUES
    ('OP-2026-101','2026-01-04'::date,'Ropero',  12, 4320.00,1260.00,'Stock + pedidos','Lote 1'),
    ('OP-2026-102','2026-01-11'::date,'Ropero',  15, 5400.00,1575.00,'Mayoristas',     'Pedido Norte'),
    ('OP-2026-103','2026-01-14'::date,'Cómoda',  18, 3240.00,1080.00,'Stock',          'Reposición'),
    ('OP-2026-104','2026-01-19'::date,'Velador', 35, 1575.00, 875.00,'Retail',         'Alta rotación'),
    ('OP-2026-105','2026-01-24'::date,'Comodín', 15,  900.00, 450.00,'Stock',          'Reposición'),
    ('OP-2026-106','2026-01-29'::date,'Ropero',  10, 3600.00,1050.00,'Pedidos finales','Cierre mes')
) AS pr(orden_numero, fecha, producto, cantidad, costo_mp, mano_obra, destino, notas)
JOIN orden_produccion   op ON op.numero_orden   = pr.orden_numero
JOIN producto            p ON  p.nombre          = pr.producto
JOIN destino_produccion  d ON  d.descripcion     = pr.destino;

-- ============================================================
--  12. CONSUMO DE MATERIALES POR PRODUCCIÃ“N
--      Los triggers descuentan stock_actual y generan movimiento_material
-- ============================================================

-- Consumo: OP-2026-101 â†’ Ropero x12
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
WHERE op.numero_orden = 'OP-2026-101';

-- Consumo: OP-2026-102 â†’ Ropero x15
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
WHERE op.numero_orden = 'OP-2026-102';

-- Consumo: OP-2026-103 â†’ Cómoda x18
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
WHERE op.numero_orden = 'OP-2026-103';

-- Consumo: OP-2026-104 â†’ Velador x35
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
WHERE op.numero_orden = 'OP-2026-104';

-- Consumo: OP-2026-105 â†’ Comodín x15
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
WHERE op.numero_orden = 'OP-2026-105';

-- Consumo: OP-2026-106 â†’ Ropero x10
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
WHERE op.numero_orden = 'OP-2026-106';

-- ============================================================
--  13. VENTAS â€” MARZO 2026
--      1 cabecera por venta, N líneas en detalle_venta
--      El trigger trg_total_venta recalcula total_venta automáticamente
-- ============================================================

-- 02-Mar: Ana Torres â€” Ropero x2 + Velador x3
WITH v AS (INSERT INTO venta (fecha,cliente_id,tipo_venta_id,usuario_id)
VALUES ('2026-01-02',(SELECT id FROM cliente WHERE documento='12345678'),
        (SELECT id FROM tipo_venta WHERE nombre='Contado'),
        (SELECT id FROM usuario WHERE email='juan@muebleria.com')) RETURNING id)
INSERT INTO detalle_venta (venta_id,producto_id,cantidad,precio_unitario)
SELECT v.id,p.id,d.c,d.pr FROM v,
(VALUES ('Ropero',2,760.00),('Velador',3,90.00)) AS d(nm,c,pr)
JOIN producto p ON p.nombre=d.nm;

-- 03-Mar: Ana Torres â€” Velador x2
WITH v AS (INSERT INTO venta (fecha,cliente_id,tipo_venta_id,usuario_id)
VALUES ('2026-01-03',(SELECT id FROM cliente WHERE documento='12345678'),
        (SELECT id FROM tipo_venta WHERE nombre='Contado'),
        (SELECT id FROM usuario WHERE email='juan@muebleria.com')) RETURNING id)
INSERT INTO detalle_venta (venta_id,producto_id,cantidad,precio_unitario)
SELECT v.id,p.id,2,90.00 FROM v JOIN producto p ON p.nombre='Velador';

-- 04-Mar: Carlos Mamani â€” Ropero x3 + Comodín x2
WITH v AS (INSERT INTO venta (fecha,cliente_id,tipo_venta_id,usuario_id)
VALUES ('2026-01-04',(SELECT id FROM cliente WHERE documento='87654321'),
        (SELECT id FROM tipo_venta WHERE nombre='Contado'),
        (SELECT id FROM usuario WHERE email='luis@muebleria.com')) RETURNING id)
INSERT INTO detalle_venta (venta_id,producto_id,cantidad,precio_unitario)
SELECT v.id,p.id,d.c,d.pr FROM v,
(VALUES ('Ropero',3,760.00),('Comodín',2,230.00)) AS d(nm,c,pr)
JOIN producto p ON p.nombre=d.nm;

-- 05-Mar: Ana Torres â€” Velador x4
WITH v AS (INSERT INTO venta (fecha,cliente_id,tipo_venta_id,usuario_id)
VALUES ('2026-01-05',(SELECT id FROM cliente WHERE documento='12345678'),
        (SELECT id FROM tipo_venta WHERE nombre='Contado'),
        (SELECT id FROM usuario WHERE email='juan@muebleria.com')) RETURNING id)
INSERT INTO detalle_venta (venta_id,producto_id,cantidad,precio_unitario)
SELECT v.id,p.id,4,90.00 FROM v JOIN producto p ON p.nombre='Velador';

-- 06-Mar: Muebles El Norte (mayorista crédito) â€” Ropero x5
WITH v AS (INSERT INTO venta (fecha,cliente_id,tipo_venta_id,usuario_id)
VALUES ('2026-01-06',(SELECT id FROM cliente WHERE documento='20111222333'),
        (SELECT id FROM tipo_venta WHERE nombre='Crédito'),
        (SELECT id FROM usuario WHERE email='juan@muebleria.com')) RETURNING id)
INSERT INTO detalle_venta (venta_id,producto_id,cantidad,precio_unitario)
SELECT v.id,p.id,5,730.00 FROM v JOIN producto p ON p.nombre='Ropero';

-- 06-Mar: Carlos Mamani â€” Cómoda x1
WITH v AS (INSERT INTO venta (fecha,cliente_id,tipo_venta_id,usuario_id)
VALUES ('2026-01-06',(SELECT id FROM cliente WHERE documento='87654321'),
        (SELECT id FROM tipo_venta WHERE nombre='Contado'),
        (SELECT id FROM usuario WHERE email='luis@muebleria.com')) RETURNING id)
INSERT INTO detalle_venta (venta_id,producto_id,cantidad,precio_unitario)
SELECT v.id,p.id,1,480.00 FROM v JOIN producto p ON p.nombre='Cómoda';

-- 08-Mar: Rosa Quispe â€” Velador x5
WITH v AS (INSERT INTO venta (fecha,cliente_id,tipo_venta_id,usuario_id)
VALUES ('2026-01-08',(SELECT id FROM cliente WHERE documento='45678901'),
        (SELECT id FROM tipo_venta WHERE nombre='Contado'),
        (SELECT id FROM usuario WHERE email='juan@muebleria.com')) RETURNING id)
INSERT INTO detalle_venta (venta_id,producto_id,cantidad,precio_unitario)
SELECT v.id,p.id,5,90.00 FROM v JOIN producto p ON p.nombre='Velador';

-- 09-Mar: Ana Torres â€” Ropero x1
WITH v AS (INSERT INTO venta (fecha,cliente_id,tipo_venta_id,usuario_id)
VALUES ('2026-01-09',(SELECT id FROM cliente WHERE documento='12345678'),
        (SELECT id FROM tipo_venta WHERE nombre='Contado'),
        (SELECT id FROM usuario WHERE email='juan@muebleria.com')) RETURNING id)
INSERT INTO detalle_venta (venta_id,producto_id,cantidad,precio_unitario)
SELECT v.id,p.id,1,760.00 FROM v JOIN producto p ON p.nombre='Ropero';

-- 09-Mar: Carlos Mamani â€” Ropero x3 + Comodín x2
WITH v AS (INSERT INTO venta (fecha,cliente_id,tipo_venta_id,usuario_id)
VALUES ('2026-01-09',(SELECT id FROM cliente WHERE documento='87654321'),
        (SELECT id FROM tipo_venta WHERE nombre='Contado'),
        (SELECT id FROM usuario WHERE email='luis@muebleria.com')) RETURNING id)
INSERT INTO detalle_venta (venta_id,producto_id,cantidad,precio_unitario)
SELECT v.id,p.id,d.c,d.pr FROM v,
(VALUES ('Ropero',3,760.00),('Comodín',2,230.00)) AS d(nm,c,pr)
JOIN producto p ON p.nombre=d.nm;

-- 11-Mar: Ana Torres â€” Velador x6 + Cómoda x2
WITH v AS (INSERT INTO venta (fecha,cliente_id,tipo_venta_id,usuario_id)
VALUES ('2026-01-11',(SELECT id FROM cliente WHERE documento='12345678'),
        (SELECT id FROM tipo_venta WHERE nombre='Contado'),
        (SELECT id FROM usuario WHERE email='juan@muebleria.com')) RETURNING id)
INSERT INTO detalle_venta (venta_id,producto_id,cantidad,precio_unitario)
SELECT v.id,p.id,d.c,d.pr FROM v,
(VALUES ('Velador',6,90.00),('Cómoda',2,480.00)) AS d(nm,c,pr)
JOIN producto p ON p.nombre=d.nm;

-- 12-Mar: Luis Condori â€” Ropero x1
WITH v AS (INSERT INTO venta (fecha,cliente_id,tipo_venta_id,usuario_id)
VALUES ('2026-01-12',(SELECT id FROM cliente WHERE documento='23456789'),
        (SELECT id FROM tipo_venta WHERE nombre='Contado'),
        (SELECT id FROM usuario WHERE email='luis@muebleria.com')) RETURNING id)
INSERT INTO detalle_venta (venta_id,producto_id,cantidad,precio_unitario)
SELECT v.id,p.id,1,760.00 FROM v JOIN producto p ON p.nombre='Ropero';

-- 13-Mar: Rosa Quispe â€” Velador x4
WITH v AS (INSERT INTO venta (fecha,cliente_id,tipo_venta_id,usuario_id)
VALUES ('2026-01-13',(SELECT id FROM cliente WHERE documento='45678901'),
        (SELECT id FROM tipo_venta WHERE nombre='Contado'),
        (SELECT id FROM usuario WHERE email='juan@muebleria.com')) RETURNING id)
INSERT INTO detalle_venta (venta_id,producto_id,cantidad,precio_unitario)
SELECT v.id,p.id,4,90.00 FROM v JOIN producto p ON p.nombre='Velador';

-- 14-Mar: Distribuidora Altiplano (mayorista crédito) â€” Ropero x6
WITH v AS (INSERT INTO venta (fecha,cliente_id,tipo_venta_id,usuario_id)
VALUES ('2026-01-14',(SELECT id FROM cliente WHERE documento='20444555666'),
        (SELECT id FROM tipo_venta WHERE nombre='Crédito'),
        (SELECT id FROM usuario WHERE email='juan@muebleria.com')) RETURNING id)
INSERT INTO detalle_venta (venta_id,producto_id,cantidad,precio_unitario)
SELECT v.id,p.id,6,740.00 FROM v JOIN producto p ON p.nombre='Ropero';

-- 15-Mar: Carlos Mamani â€” Cómoda x3
WITH v AS (INSERT INTO venta (fecha,cliente_id,tipo_venta_id,usuario_id)
VALUES ('2026-01-15',(SELECT id FROM cliente WHERE documento='87654321'),
        (SELECT id FROM tipo_venta WHERE nombre='Contado'),
        (SELECT id FROM usuario WHERE email='luis@muebleria.com')) RETURNING id)
INSERT INTO detalle_venta (venta_id,producto_id,cantidad,precio_unitario)
SELECT v.id,p.id,3,480.00 FROM v JOIN producto p ON p.nombre='Cómoda';

-- 16-Mar: Ana Torres â€” Velador x7
WITH v AS (INSERT INTO venta (fecha,cliente_id,tipo_venta_id,usuario_id)
VALUES ('2026-01-16',(SELECT id FROM cliente WHERE documento='12345678'),
        (SELECT id FROM tipo_venta WHERE nombre='Contado'),
        (SELECT id FROM usuario WHERE email='juan@muebleria.com')) RETURNING id)
INSERT INTO detalle_venta (venta_id,producto_id,cantidad,precio_unitario)
SELECT v.id,p.id,7,90.00 FROM v JOIN producto p ON p.nombre='Velador';

-- 17-Mar: Luis Condori â€” Ropero x3
WITH v AS (INSERT INTO venta (fecha,cliente_id,tipo_venta_id,usuario_id)
VALUES ('2026-01-17',(SELECT id FROM cliente WHERE documento='23456789'),
        (SELECT id FROM tipo_venta WHERE nombre='Contado'),
        (SELECT id FROM usuario WHERE email='luis@muebleria.com')) RETURNING id)
INSERT INTO detalle_venta (venta_id,producto_id,cantidad,precio_unitario)
SELECT v.id,p.id,3,760.00 FROM v JOIN producto p ON p.nombre='Ropero';

-- 18-Mar: Rosa Quispe â€” Comodín x3
WITH v AS (INSERT INTO venta (fecha,cliente_id,tipo_venta_id,usuario_id)
VALUES ('2026-01-18',(SELECT id FROM cliente WHERE documento='45678901'),
        (SELECT id FROM tipo_venta WHERE nombre='Contado'),
        (SELECT id FROM usuario WHERE email='juan@muebleria.com')) RETURNING id)
INSERT INTO detalle_venta (venta_id,producto_id,cantidad,precio_unitario)
SELECT v.id,p.id,3,230.00 FROM v JOIN producto p ON p.nombre='Comodín';

-- 19-Mar: Carlos Mamani â€” Velador x5
WITH v AS (INSERT INTO venta (fecha,cliente_id,tipo_venta_id,usuario_id)
VALUES ('2026-01-19',(SELECT id FROM cliente WHERE documento='87654321'),
        (SELECT id FROM tipo_venta WHERE nombre='Contado'),
        (SELECT id FROM usuario WHERE email='luis@muebleria.com')) RETURNING id)
INSERT INTO detalle_venta (venta_id,producto_id,cantidad,precio_unitario)
SELECT v.id,p.id,5,90.00 FROM v JOIN producto p ON p.nombre='Velador';

-- 20-Mar: Ana Torres â€” Ropero x2
WITH v AS (INSERT INTO venta (fecha,cliente_id,tipo_venta_id,usuario_id)
VALUES ('2026-01-20',(SELECT id FROM cliente WHERE documento='12345678'),
        (SELECT id FROM tipo_venta WHERE nombre='Contado'),
        (SELECT id FROM usuario WHERE email='juan@muebleria.com')) RETURNING id)
INSERT INTO detalle_venta (venta_id,producto_id,cantidad,precio_unitario)
SELECT v.id,p.id,2,760.00 FROM v JOIN producto p ON p.nombre='Ropero';

-- 21-Mar: Luis Condori â€” Velador x3
WITH v AS (INSERT INTO venta (fecha,cliente_id,tipo_venta_id,usuario_id)
VALUES ('2026-01-21',(SELECT id FROM cliente WHERE documento='23456789'),
        (SELECT id FROM tipo_venta WHERE nombre='Contado'),
        (SELECT id FROM usuario WHERE email='luis@muebleria.com')) RETURNING id)
INSERT INTO detalle_venta (venta_id,producto_id,cantidad,precio_unitario)
SELECT v.id,p.id,3,90.00 FROM v JOIN producto p ON p.nombre='Velador';

-- 23-Mar: Muebles El Norte (mayorista contado) â€” Ropero x5
WITH v AS (INSERT INTO venta (fecha,cliente_id,tipo_venta_id,usuario_id)
VALUES ('2026-01-23',(SELECT id FROM cliente WHERE documento='20111222333'),
        (SELECT id FROM tipo_venta WHERE nombre='Contado'),
        (SELECT id FROM usuario WHERE email='juan@muebleria.com')) RETURNING id)
INSERT INTO detalle_venta (venta_id,producto_id,cantidad,precio_unitario)
SELECT v.id,p.id,5,730.00 FROM v JOIN producto p ON p.nombre='Ropero';

-- 24-Mar: Carlos Mamani â€” Cómoda x4
WITH v AS (INSERT INTO venta (fecha,cliente_id,tipo_venta_id,usuario_id)
VALUES ('2026-01-24',(SELECT id FROM cliente WHERE documento='87654321'),
        (SELECT id FROM tipo_venta WHERE nombre='Contado'),
        (SELECT id FROM usuario WHERE email='luis@muebleria.com')) RETURNING id)
INSERT INTO detalle_venta (venta_id,producto_id,cantidad,precio_unitario)
SELECT v.id,p.id,4,480.00 FROM v JOIN producto p ON p.nombre='Cómoda';

-- 25-Mar: Rosa Quispe â€” Velador x6
WITH v AS (INSERT INTO venta (fecha,cliente_id,tipo_venta_id,usuario_id)
VALUES ('2026-01-25',(SELECT id FROM cliente WHERE documento='45678901'),
        (SELECT id FROM tipo_venta WHERE nombre='Contado'),
        (SELECT id FROM usuario WHERE email='juan@muebleria.com')) RETURNING id)
INSERT INTO detalle_venta (venta_id,producto_id,cantidad,precio_unitario)
SELECT v.id,p.id,6,90.00 FROM v JOIN producto p ON p.nombre='Velador';

-- 26-Mar: Luis Condori â€” Ropero x1
WITH v AS (INSERT INTO venta (fecha,cliente_id,tipo_venta_id,usuario_id)
VALUES ('2026-01-26',(SELECT id FROM cliente WHERE documento='23456789'),
        (SELECT id FROM tipo_venta WHERE nombre='Contado'),
        (SELECT id FROM usuario WHERE email='luis@muebleria.com')) RETURNING id)
INSERT INTO detalle_venta (venta_id,producto_id,cantidad,precio_unitario)
SELECT v.id,p.id,1,760.00 FROM v JOIN producto p ON p.nombre='Ropero';

-- 27-Mar: Ana Torres â€” Comodín x3
WITH v AS (INSERT INTO venta (fecha,cliente_id,tipo_venta_id,usuario_id)
VALUES ('2026-01-27',(SELECT id FROM cliente WHERE documento='12345678'),
        (SELECT id FROM tipo_venta WHERE nombre='Contado'),
        (SELECT id FROM usuario WHERE email='juan@muebleria.com')) RETURNING id)
INSERT INTO detalle_venta (venta_id,producto_id,cantidad,precio_unitario)
SELECT v.id,p.id,3,230.00 FROM v JOIN producto p ON p.nombre='Comodín';

-- 28-Mar: Carlos Mamani â€” Velador x5
WITH v AS (INSERT INTO venta (fecha,cliente_id,tipo_venta_id,usuario_id)
VALUES ('2026-01-28',(SELECT id FROM cliente WHERE documento='87654321'),
        (SELECT id FROM tipo_venta WHERE nombre='Contado'),
        (SELECT id FROM usuario WHERE email='luis@muebleria.com')) RETURNING id)
INSERT INTO detalle_venta (venta_id,producto_id,cantidad,precio_unitario)
SELECT v.id,p.id,5,90.00 FROM v JOIN producto p ON p.nombre='Velador';

-- 30-Mar: Mueblería Centro (mayorista crédito) â€” Ropero x4 + Cómoda x2
WITH v AS (INSERT INTO venta (fecha,cliente_id,tipo_venta_id,usuario_id)
VALUES ('2026-01-30',(SELECT id FROM cliente WHERE documento='20777888999'),
        (SELECT id FROM tipo_venta WHERE nombre='Crédito'),
        (SELECT id FROM usuario WHERE email='juan@muebleria.com')) RETURNING id)
INSERT INTO detalle_venta (venta_id,producto_id,cantidad,precio_unitario)
SELECT v.id,p.id,d.c,d.pr FROM v,
(VALUES ('Ropero',4,730.00),('Cómoda',2,450.00)) AS d(nm,c,pr)
JOIN producto p ON p.nombre=d.nm;

-- ============================================================
--  14. CUENTAS POR COBRAR â€” ventas a crédito (30 días plazo)
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
--  15. PAGOS DE CLIENTES â€” abonos registrados en enero
-- ============================================================

-- Muebles El Norte abona S/1,500 el 20-Mar
INSERT INTO pago_cliente (cuenta_cobrar_id, fecha, monto, metodo_pago, referencia, usuario_id)
SELECT cc.id,'2026-01-20',1500.00,'transferencia','TRF-BN-20260320',
       (SELECT id FROM usuario WHERE email='maria@muebleria.com')
FROM cuentas_cobrar cc
JOIN venta v ON v.id = cc.venta_id
JOIN cliente c ON c.id = v.cliente_id
WHERE c.documento = '20111222333' AND cc.saldo_pendiente > 0
LIMIT 1;

-- Distribuidora Altiplano abona S/2,220 el 25-Mar
INSERT INTO pago_cliente (cuenta_cobrar_id, fecha, monto, metodo_pago, referencia, usuario_id)
SELECT cc.id,'2026-01-25',2220.00,'transferencia','TRF-BCP-20260325',
       (SELECT id FROM usuario WHERE email='maria@muebleria.com')
FROM cuentas_cobrar cc
JOIN venta v ON v.id = cc.venta_id
JOIN cliente c ON c.id = v.cliente_id
WHERE c.documento = '20444555666' AND cc.saldo_pendiente > 0
LIMIT 1;

-- ============================================================
--  16. GASTOS OPERATIVOS â€” MARZO 2026
-- ============================================================

INSERT INTO gasto (fecha, categoria_id, monto, detalle, comprobante, usuario_id)
SELECT g.fecha, cg.id, g.monto, g.detalle, g.comprobante,
       (SELECT id FROM usuario WHERE email='maria@muebleria.com')
FROM (VALUES
    ('2026-01-01'::date, 'Alquiler local + servicios',        2800.00, 'Alquiler taller + agua + luz',             'REC-001'),
    ('2026-01-01'::date, 'Servicios (luz, agua, internet)',    320.00,  'Internet taller',                          'REC-002'),
    ('2026-01-10'::date, 'Compra Melamina y accesorios',      4200.00, 'Compra materiales primera quincena',        'F-VARS-01'),
    ('2026-01-15'::date, 'Mano de Obra (eventual)',           6800.00, 'Pago 3 operarios + maestro (quincena)',     'PL-001'),
    ('2026-01-20'::date, 'Compra Melamina y accesorios',      4150.00, 'Compra materiales segunda quincena',        'F-VARS-02'),
    ('2026-01-22'::date, 'Transporte y delivery',              980.00, 'Entregas a clientes y recojo materiales',   'REC-003'),
    ('2026-01-28'::date, 'Otros (herramientas, etc.)',         650.00, 'Mantenimiento maquinaria y herramientas',   'REC-004'),
    ('2026-01-29'::date, 'Marketing y publicidad',             350.00, 'Publicidad Facebook e Instagram',           'REC-005'),
    ('2026-01-31'::date, 'Mano de Obra (eventual)',           6800.00, 'Pago 3 operarios + maestro (fin de mes)',   'PL-002'),
    ('2026-01-31'::date, 'Servicios (luz, agua, internet)',    280.00, 'Luz y agua - cierre mes',                   'REC-006')
) AS g(fecha, categoria, monto, detalle, comprobante)
JOIN categoria_gasto cg ON cg.nombre = g.categoria;

-- ============================================================
--  17. MOVIMIENTOS DE CAJA â€” MARZO 2026
-- ============================================================

INSERT INTO movimiento_caja
    (caja_id, fecha, tipo, concepto, monto, metodo_pago, referencia_tabla, usuario_id)
SELECT
    (SELECT id FROM caja WHERE fecha_apertura='2026-01-01' LIMIT 1),
    mc.fecha, mc.tipo, mc.concepto, mc.monto, mc.metodo_pago, mc.ref_tabla,
    (SELECT id FROM usuario WHERE email='maria@muebleria.com')
FROM (VALUES
    -- INGRESOS
    ('2026-01-02'::timestamptz,'ingreso','Venta contado - Ana Torres (Ropero x2 + Velador x3)',          2060.00,'efectivo',    'venta'),
    ('2026-01-03'::timestamptz,'ingreso','Venta contado - Ana Torres (Velador x2)',                        180.00,'efectivo',    'venta'),
    ('2026-01-04'::timestamptz,'ingreso','Venta contado - Carlos Mamani (Ropero x3 + Comodín x2)',        2740.00,'efectivo',    'venta'),
    ('2026-01-05'::timestamptz,'ingreso','Venta contado - Ana Torres (Velador x4)',                        360.00,'efectivo',    'venta'),
    ('2026-01-06'::timestamptz,'ingreso','Venta contado - Carlos Mamani (Cómoda x1)',                      480.00,'efectivo',    'venta'),
    ('2026-01-08'::timestamptz,'ingreso','Venta contado - Rosa Quispe (Velador x5)',                       450.00,'efectivo',    'venta'),
    ('2026-01-09'::timestamptz,'ingreso','Venta contado - Ana Torres (Ropero x1)',                         760.00,'efectivo',    'venta'),
    ('2026-01-09'::timestamptz,'ingreso','Venta contado - Carlos Mamani (Ropero x3 + Comodín x2)',        2740.00,'efectivo',    'venta'),
    ('2026-01-11'::timestamptz,'ingreso','Venta contado - Ana Torres (Velador x6 + Cómoda x2)',           1500.00,'efectivo',    'venta'),
    ('2026-01-12'::timestamptz,'ingreso','Venta contado - Luis Condori (Ropero x1)',                       760.00,'efectivo',    'venta'),
    ('2026-01-13'::timestamptz,'ingreso','Venta contado - Rosa Quispe (Velador x4)',                       360.00,'efectivo',    'venta'),
    ('2026-01-15'::timestamptz,'ingreso','Venta contado - Carlos Mamani (Cómoda x3)',                     1440.00,'efectivo',    'venta'),
    ('2026-01-16'::timestamptz,'ingreso','Venta contado - Ana Torres (Velador x7)',                        630.00,'efectivo',    'venta'),
    ('2026-01-17'::timestamptz,'ingreso','Venta contado - Luis Condori (Ropero x3)',                      2280.00,'efectivo',    'venta'),
    ('2026-01-18'::timestamptz,'ingreso','Venta contado - Rosa Quispe (Comodín x3)',                       690.00,'efectivo',    'venta'),
    ('2026-01-19'::timestamptz,'ingreso','Venta contado - Carlos Mamani (Velador x5)',                     450.00,'efectivo',    'venta'),
    ('2026-01-20'::timestamptz,'ingreso','Venta contado - Ana Torres (Ropero x2)',                        1520.00,'efectivo',    'venta'),
    ('2026-01-20'::timestamptz,'ingreso','Pago crédito - Muebles El Norte (abono)',                       1500.00,'transferencia','pago_cliente'),
    ('2026-01-21'::timestamptz,'ingreso','Venta contado - Luis Condori (Velador x3)',                      270.00,'efectivo',    'venta'),
    ('2026-01-23'::timestamptz,'ingreso','Venta contado - Muebles El Norte (Ropero x5)',                  3650.00,'transferencia','venta'),
    ('2026-01-24'::timestamptz,'ingreso','Venta contado - Carlos Mamani (Cómoda x4)',                     1920.00,'efectivo',    'venta'),
    ('2026-01-25'::timestamptz,'ingreso','Venta contado - Rosa Quispe (Velador x6)',                       540.00,'efectivo',    'venta'),
    ('2026-01-25'::timestamptz,'ingreso','Pago crédito - Distribuidora Altiplano (abono)',                2220.00,'transferencia','pago_cliente'),
    ('2026-01-26'::timestamptz,'ingreso','Venta contado - Luis Condori (Ropero x1)',                       760.00,'efectivo',    'venta'),
    ('2026-01-27'::timestamptz,'ingreso','Venta contado - Ana Torres (Comodín x3)',                        690.00,'efectivo',    'venta'),
    ('2026-01-28'::timestamptz,'ingreso','Venta contado - Carlos Mamani (Velador x5)',                     450.00,'efectivo',    'venta'),
    -- EGRESOS
    ('2026-01-01'::timestamptz,'egreso', 'Alquiler local + servicios - enero',                            2800.00,'efectivo',    'gasto'),
    ('2026-01-01'::timestamptz,'egreso', 'Internet taller - enero',                                        320.00,'transferencia','gasto'),
    ('2026-01-10'::timestamptz,'egreso', 'Compra materiales primera quincena',                            4200.00,'efectivo',    'gasto'),
    ('2026-01-15'::timestamptz,'egreso', 'Pago planilla operarios - quincena',                            6800.00,'efectivo',    'gasto'),
    ('2026-01-20'::timestamptz,'egreso', 'Compra materiales segunda quincena',                            4150.00,'efectivo',    'gasto'),
    ('2026-01-22'::timestamptz,'egreso', 'Transporte y delivery enero',                                    980.00,'efectivo',    'gasto'),
    ('2026-01-28'::timestamptz,'egreso', 'Mantenimiento herramientas y maquinaria',                        650.00,'efectivo',    'gasto'),
    ('2026-01-29'::timestamptz,'egreso', 'Publicidad redes sociales',                                      350.00,'transferencia','gasto'),
    ('2026-01-31'::timestamptz,'egreso', 'Pago planilla operarios - fin de mes',                          6800.00,'efectivo',    'gasto'),
    ('2026-01-31'::timestamptz,'egreso', 'Luz y agua - cierre mes',                                        280.00,'efectivo',    'gasto')
) AS mc(fecha, tipo, concepto, monto, metodo_pago, ref_tabla);

-- Cierre de caja al 31 de enero
UPDATE caja
SET fecha_cierre      = '2026-01-31',
    estado            = 'cerrada',
    saldo_final       = saldo_inicial + total_ingresos - total_egresos,
    usuario_cierre_id = (SELECT id FROM usuario WHERE email='admin@muebleria.com')
WHERE fecha_apertura  = '2026-01-01' AND estado = 'abierta';

-- ============================================================
--  18. DEVOLUCIÃ“N â€” Carlos Mamani devuelve 1 velador (28-Mar)
-- ============================================================

INSERT INTO devolucion_venta
    (venta_id, detalle_venta_id, fecha, cantidad, motivo, monto_reembolsado, usuario_id)
SELECT
    dv.venta_id, dv.id,
    '2026-01-29', 1,
    'Producto con defecto en la superficie',
    90.00,
    (SELECT id FROM usuario WHERE email='juan@muebleria.com')
FROM detalle_venta dv
JOIN venta v    ON v.id  = dv.venta_id
JOIN cliente c  ON c.id  = v.cliente_id
JOIN producto p ON p.id  = dv.producto_id
WHERE c.documento = '87654321'
  AND p.nombre    = 'Velador'
  AND v.fecha     = '2026-01-28'
LIMIT 1;

-- ============================================================
--  19. VERIFICACIONES FINALES â€” ejecutar para confirmar carga
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
