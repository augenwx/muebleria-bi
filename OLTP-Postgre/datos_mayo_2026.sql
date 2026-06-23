-- ============================================================
--  MUEBLERÍA / CARPINTERÍA — DATOS ABRIL 2026
--
--  Motor:   PostgreSQL 14+
--  Esquema: transaccional
--  Período: Mayo 2026
--
--  EJECUTAR DESPUÉS DE: datos_abril_2026.sql
-- ============================================================
--  RESUMEN DEL MES:
--    Ventas totales:          ~S/ 47,310
--    Gastos operativos:       ~S/ 28,720
--    Producto estrella:        Ropero (32 und — reducido de 39 en marzo)
--    Producto en alza:         Cómoda (21 und — sube de 12 en marzo)
--    Nuevos en venta:          Tocador (6 und), Estante (8 und)
--    Días sin venta:           Domingos (5,12,19,26) + 3 días (7,14,23)
--    Clientes minoristas:      21 nuevos + 2 repiten de marzo (1 sola vez)
--    Ventas a crédito:         2 (mayoristas)
--    Ventas contado:           24 (mayoría minoristas)
-- ============================================================

SET search_path TO transaccional, public;

-- ============================================================
--  0. NUEVOS CLIENTES MINORISTAS — ABRIL 2026
--     Personas que compran muebles por primera y única vez
-- ============================================================

INSERT INTO cliente (tipo_cliente_id, documento, nombre, razon_social, direccion, telefono, email, limite_credito) VALUES
    ((SELECT id FROM tipo_cliente WHERE nombre='Retail'), '34567890', 'María Huanca',        NULL, 'Jr. San Martín 45, Juliaca',         '987555001', NULL,                    0),
    ((SELECT id FROM tipo_cliente WHERE nombre='Retail'), '56789012', 'José Flores',          NULL, 'Av. Circunvalación 234, Juliaca',    '987555002', 'jose.flores@gmail.com', 0),
    ((SELECT id FROM tipo_cliente WHERE nombre='Retail'), '67890123', 'Pedro Ticona',         NULL, 'Calle Moquegua 67, Juliaca',         '987555003', NULL,                    0),
    ((SELECT id FROM tipo_cliente WHERE nombre='Retail'), '78901234', 'Carmen Apaza',         NULL, 'Jr. Huancané 89, Juliaca',           '987555004', NULL,                    0),
    ((SELECT id FROM tipo_cliente WHERE nombre='Retail'), '89012345', 'Jorge Ccama',          NULL, 'Av. El Sol 156, Juliaca',            '987555005', NULL,                    0),
    ((SELECT id FROM tipo_cliente WHERE nombre='Retail'), '90123456', 'Luisa Choque',         NULL, 'Calle Tacna 23, Juliaca',            '987555006', NULL,                    0),
    ((SELECT id FROM tipo_cliente WHERE nombre='Retail'), '01234567', 'Roberto Pari',         NULL, 'Jr. Lampa 340, Juliaca',             '987555007', 'rpari@gmail.com',       0),
    ((SELECT id FROM tipo_cliente WHERE nombre='Retail'), '11223344', 'Sonia Mamani C.',      NULL, 'Av. Néstor Cáceres 78, Juliaca',     '987555008', NULL,                    0),
    ((SELECT id FROM tipo_cliente WHERE nombre='Retail'), '22334455', 'Diego Quispe R.',      NULL, 'Calle Cusco 112, Juliaca',           '987555009', NULL,                    0),
    ((SELECT id FROM tipo_cliente WHERE nombre='Retail'), '33445566', 'Francisca Cano',       NULL, 'Jr. Independencia 56, Juliaca',      '987555010', NULL,                    0),
    ((SELECT id FROM tipo_cliente WHERE nombre='Retail'), '44556677', 'Alberto Ramos',        NULL, 'Av. Ferrocarril 89, Juliaca',        '987555011', NULL,                    0),
    ((SELECT id FROM tipo_cliente WHERE nombre='Retail'), '55667788', 'Teresa Vilca',         NULL, 'Calle Ayacucho 45, Juliaca',         '987555012', NULL,                    0),
    ((SELECT id FROM tipo_cliente WHERE nombre='Retail'), '66778899', 'Miguel Sucari',        NULL, 'Jr. Piérola 23, Juliaca',            '987555013', NULL,                    0),
    ((SELECT id FROM tipo_cliente WHERE nombre='Retail'), '77889900', 'Patricia Luna',        NULL, 'Av. Manuel Núñez 67, Juliaca',       '987555014', 'pat.luna@gmail.com',    0),
    ((SELECT id FROM tipo_cliente WHERE nombre='Retail'), '88990011', 'Raúl Coila',           NULL, 'Calle Mariano Melgar 34, Juliaca',   '987555015', NULL,                    0),
    ((SELECT id FROM tipo_cliente WHERE nombre='Retail'), '99001122', 'Elena Machaca',        NULL, 'Jr. Sandia 78, Juliaca',             '987555016', NULL,                    0),
    ((SELECT id FROM tipo_cliente WHERE nombre='Retail'), '10203040', 'Fernando Turpo',       NULL, 'Av. Huancané 123, Juliaca',          '987555017', NULL,                    0),
    ((SELECT id FROM tipo_cliente WHERE nombre='Retail'), '20304050', 'Gloria Condori M.',    NULL, 'Calle Bolívar 56, Juliaca',          '987555018', NULL,                    0),
    ((SELECT id FROM tipo_cliente WHERE nombre='Retail'), '30405060', 'Andrés Cuti',          NULL, 'Jr. Carabaya 89, Juliaca',           '987555019', NULL,                    0),
    ((SELECT id FROM tipo_cliente WHERE nombre='Retail'), '40506070', 'Beatriz Sulla',        NULL, 'Av. Triunfo 12, Juliaca',            '987555020', NULL,                    0),
    ((SELECT id FROM tipo_cliente WHERE nombre='Retail'), '50607080', 'Víctor Alanoca',       NULL, 'Calle Azángaro 34, Juliaca',         '987555021', NULL,                    0)
ON CONFLICT (documento) DO NOTHING;

-- ============================================================
--  1. COMPLETAR ORDEN OP-2026-507 (pendiente de marzo)
--     Estante ×8, iniciada 28-Mar, completada 02-Abr
-- ============================================================

UPDATE orden_produccion
SET fecha_fin_real     = '2026-05-02',
    cantidad_producida = 8,
    estado             = 'completada'
WHERE numero_orden = 'OP-2026-507';

INSERT INTO produccion
    (orden_produccion_id, fecha_produccion, producto_id, cantidad_producida,
     costo_materia_prima, mano_de_obra, destino_id, notas)
SELECT op.id, '2026-05-02'::date, p.id, 8, 960.00, 400.00, d.id, 'Completado inicio mayo'
FROM orden_produccion op
JOIN producto          p ON p.nombre      = 'Estante'
JOIN destino_produccion d ON d.descripcion = 'Stock'
WHERE op.numero_orden = 'OP-2026-507';

-- Consumo de materiales: OP-2026-507 → Estante ×8
INSERT INTO consumo_material (produccion_id, material_id, cantidad_consumida, costo_unitario)
SELECT p.id, m.id, cons.cantidad, cons.precio
FROM produccion p
JOIN orden_produccion op ON op.id = p.orden_produccion_id
CROSS JOIN (VALUES
    ('Melamina Blanco 18mm', 12.0, 152.00),
    ('Mapresa (fondo)',        4.0, 100.00),
    ('Tapacanto (rollo)',      1.2,  35.00),
    ('Tornillos (caja 1000)', 0.24,  80.00),
    ('Patitas',              32.0,   0.40)
) AS cons(material_nombre, cantidad, precio)
JOIN material m ON m.nombre = cons.material_nombre
WHERE op.numero_orden = 'OP-2026-507';

-- ============================================================
--  2. COMPRAS DE MATERIALES — ABRIL 2026
--     Los triggers actualizan stock_actual y movimiento_material
-- ============================================================

INSERT INTO compra_material
    (fecha, proveedor_id, material_id, cantidad, precio_unitario, factura_numero, notas, usuario_id)
SELECT
    cm.fecha, pr.id, m.id, cm.cantidad, cm.precio_unit,
    cm.factura, cm.notas,
    (SELECT id FROM usuario WHERE email='admin@muebleria.com')
FROM (VALUES
    ('2026-05-01'::date, 'Melaminas del Perú S.A.C.', 'Melamina Blanco 18mm',   10,   152.00, 'F001-005', 'Compra inicio mes'),
    ('2026-05-02'::date, 'Ferretodo S.A.C.',          'Mapresa (fondo)',          6,   100.00, 'F002-009', 'Stock inicio mayo'),
    ('2026-05-03'::date, 'Ferretodo S.A.C.',          'Tornillos (caja 1000)',    2,    82.00, 'F002-010', 'Reposición tornillos'),
    ('2026-05-05'::date, 'Melaminas del Perú S.A.C.', 'Melamina Color 18mm',     5,   182.00, 'F001-006', 'Para cómodas mayo'),
    ('2026-05-07'::date, 'Maderas Noble E.I.R.L.',    'Tapacanto (rollo)',        4,    36.00, 'F003-004', 'Varios colores'),
    ('2026-05-08'::date, 'Ferretodo S.A.C.',          'Jaladores',             200,     1.00, 'F002-011', 'Surtido modelos'),
    ('2026-05-10'::date, 'Maderas Noble E.I.R.L.',    'Correderas (30cm)',       40,    20.00, 'F003-005', 'Stock correderas'),
    ('2026-05-12'::date, 'Ferretodo S.A.C.',          'Bisagras (caja 100)',      1,    92.00, 'F002-012', 'Reposición bisagras'),
    ('2026-05-14'::date, 'Acabados y Más S.A.C.',     'Laca selladora',           8,    28.00, 'F004-003', 'Para acabados'),
    ('2026-05-15'::date, 'Acabados y Más S.A.C.',     'Pegamento contacto',      12,    12.50, 'F004-004', 'Pegamento contacto'),
    ('2026-05-16'::date, 'Ferretodo S.A.C.',          'Patitas',               250,     0.40, 'F002-013', 'Surtido tamaños'),
    ('2026-05-18'::date, 'Melaminas del Perú S.A.C.', 'Melamina Blanco 18mm',    8,   155.00, 'F001-007', 'Reposición urgente'),
    ('2026-05-22'::date, 'Ferretodo S.A.C.',          'Mapresa (fondo)',          5,   102.00, 'F002-014', 'Reposición fondo'),
    ('2026-05-24'::date, 'Melaminas del Perú S.A.C.', 'Melamina Color 18mm',     4,   182.00, 'F001-008', 'Reposición color'),
    ('2026-05-25'::date, 'Ferretodo S.A.C.',          'Tornillos (caja 1000)',    1,    82.00, 'F002-015', 'Reposición'),
    ('2026-05-28'::date, 'Maderas Noble E.I.R.L.',    'Tapacanto (rollo)',        3,    36.00, 'F003-006', 'Reposición cierre mes'),
    ('2026-05-29'::date, 'Ferretodo S.A.C.',          'Jaladores',             100,     1.00, 'F002-016', 'Reposición jaladores')
) AS cm(fecha, proveedor_nombre, material_nombre, cantidad, precio_unit, factura, notas)
JOIN proveedor pr ON pr.nombre = cm.proveedor_nombre
JOIN material   m ON  m.nombre = cm.material_nombre;

-- ============================================================
--  3. ÓRDENES DE PRODUCCIÓN — ABRIL 2026
-- ============================================================

INSERT INTO orden_produccion
    (numero_orden, fecha_inicio, fecha_fin_estimada, fecha_fin_real,
     producto_id, cantidad_ordenada, cantidad_producida, estado, responsable_id,
     costo_mp_estimado, costo_mo_estimado, notas)
VALUES
    ('OP-2026-508','2026-05-01','2026-05-05','2026-05-04',
     (SELECT id FROM producto WHERE nombre='Ropero'),  10,10,'completada',
     (SELECT id FROM usuario WHERE email='pedro@muebleria.com'), 3600.00,1050.00,'Lote inicio mes'),

    ('OP-2026-509','2026-05-03','2026-05-08','2026-05-07',
     (SELECT id FROM producto WHERE nombre='Velador'), 30,30,'completada',
     (SELECT id FROM usuario WHERE email='pedro@muebleria.com'), 1350.00, 750.00,'Alta rotación veladores'),

    ('OP-2026-510','2026-05-08','2026-05-12','2026-05-11',
     (SELECT id FROM producto WHERE nombre='Ropero'),  12,12,'completada',
     (SELECT id FROM usuario WHERE email='pedro@muebleria.com'), 4320.00,1260.00,'Pedido mayoristas'),

    ('OP-2026-511','2026-05-10','2026-05-15','2026-05-14',
     (SELECT id FROM producto WHERE nombre='Velador'), 25,25,'completada',
     (SELECT id FROM usuario WHERE email='pedro@muebleria.com'), 1125.00, 625.00,'Reposición veladores'),

    ('OP-2026-512','2026-05-15','2026-05-20','2026-05-19',
     (SELECT id FROM producto WHERE nombre='Cómoda'),  10,10,'completada',
     (SELECT id FROM usuario WHERE email='pedro@muebleria.com'), 1800.00, 600.00,'Reposición cómodas'),

    ('OP-2026-513','2026-05-20','2026-05-25','2026-05-24',
     (SELECT id FROM producto WHERE nombre='Ropero'),  12,12,'completada',
     (SELECT id FROM usuario WHERE email='pedro@muebleria.com'), 4320.00,1260.00,'Cierre mes roperos'),

    ('OP-2026-514','2026-05-25','2026-05-30','2026-05-29',
     (SELECT id FROM producto WHERE nombre='Estante'), 10,10,'completada',
     (SELECT id FROM usuario WHERE email='pedro@muebleria.com'), 1200.00, 500.00,'Reposición estantes'),

    ('OP-2026-515','2026-05-28','2026-05-03',NULL,
     (SELECT id FROM producto WHERE nombre='Tocador'),  5, 0,'en_proceso',
     (SELECT id FROM usuario WHERE email='pedro@muebleria.com'), 1520.00, 600.00,'Orden en curso - tocadores');

-- ============================================================
--  4. PRODUCCIÓN REAL — ABRIL 2026
--     costo_materia_prima y mano_de_obra = TOTALES DEL LOTE
-- ============================================================

INSERT INTO produccion
    (orden_produccion_id, fecha_produccion, producto_id, cantidad_producida,
     costo_materia_prima, mano_de_obra, destino_id, notas)
SELECT op.id, pr.fecha, p.id, pr.cantidad, pr.costo_mp, pr.mano_obra, d.id, pr.notas
FROM (VALUES
    ('OP-2026-508','2026-05-04'::date,'Ropero',  10, 3600.00,1050.00,'Stock + pedidos','Lote 1 mayo'),
    ('OP-2026-509','2026-05-07'::date,'Velador', 30, 1350.00, 750.00,'Retail',         'Alta rotación'),
    ('OP-2026-510','2026-05-11'::date,'Ropero',  12, 4320.00,1260.00,'Mayoristas',     'Pedido mayoristas'),
    ('OP-2026-511','2026-05-14'::date,'Velador', 25, 1125.00, 625.00,'Retail',         'Reposición'),
    ('OP-2026-512','2026-05-19'::date,'Cómoda',  10, 1800.00, 600.00,'Stock',          'Reposición cómodas'),
    ('OP-2026-513','2026-05-24'::date,'Ropero',  12, 4320.00,1260.00,'Pedidos finales','Cierre mes'),
    ('OP-2026-514','2026-05-29'::date,'Estante', 10, 1200.00, 500.00,'Stock',          'Reposición estantes')
) AS pr(orden_numero, fecha, producto, cantidad, costo_mp, mano_obra, destino, notas)
JOIN orden_produccion   op ON op.numero_orden   = pr.orden_numero
JOIN producto            p ON  p.nombre          = pr.producto
JOIN destino_produccion  d ON  d.descripcion     = pr.destino;

-- ============================================================
--  5. CONSUMO DE MATERIALES POR PRODUCCIÓN
--     Los triggers descuentan stock_actual y generan movimiento_material
-- ============================================================

-- Consumo: OP-2026-508 → Ropero ×10
INSERT INTO consumo_material (produccion_id, material_id, cantidad_consumida, costo_unitario)
SELECT p.id, m.id, cons.cantidad, cons.precio
FROM produccion p
JOIN orden_produccion op ON op.id = p.orden_produccion_id
CROSS JOIN (VALUES
    ('Melamina Blanco 18mm', 25.0, 150.00),
    ('Mapresa (fondo)',       10.0, 100.00),
    ('Tapacanto (rollo)',      2.5,  35.00),
    ('Tornillos (caja 1000)', 0.50,  80.00),
    ('Jaladores',            40.0,   1.00),
    ('Correderas (30cm)',    20.0,  20.00),
    ('Patitas',              40.0,   0.40)
) AS cons(material_nombre, cantidad, precio)
JOIN material m ON m.nombre = cons.material_nombre
WHERE op.numero_orden = 'OP-2026-508';

-- Consumo: OP-2026-509 → Velador ×30
INSERT INTO consumo_material (produccion_id, material_id, cantidad_consumida, costo_unitario)
SELECT p.id, m.id, cons.cantidad, cons.precio
FROM produccion p
JOIN orden_produccion op ON op.id = p.orden_produccion_id
CROSS JOIN (VALUES
    ('Melamina Blanco 18mm', 24.0, 150.00),
    ('Mapresa (fondo)',        9.0, 100.00),
    ('Tapacanto (rollo)',      1.8,  35.00),
    ('Tornillos (caja 1000)', 0.60,  80.00),
    ('Jaladores',            30.0,   1.00),
    ('Patitas',             120.0,   0.40)
) AS cons(material_nombre, cantidad, precio)
JOIN material m ON m.nombre = cons.material_nombre
WHERE op.numero_orden = 'OP-2026-509';

-- Consumo: OP-2026-510 → Ropero ×12
INSERT INTO consumo_material (produccion_id, material_id, cantidad_consumida, costo_unitario)
SELECT p.id, m.id, cons.cantidad, cons.precio
FROM produccion p
JOIN orden_produccion op ON op.id = p.orden_produccion_id
CROSS JOIN (VALUES
    ('Melamina Blanco 18mm', 30.0, 152.00),
    ('Mapresa (fondo)',       12.0, 100.00),
    ('Tapacanto (rollo)',      3.0,  35.00),
    ('Tornillos (caja 1000)', 0.60,  80.00),
    ('Jaladores',            48.0,   1.00),
    ('Correderas (30cm)',    24.0,  20.00),
    ('Patitas',              48.0,   0.40)
) AS cons(material_nombre, cantidad, precio)
JOIN material m ON m.nombre = cons.material_nombre
WHERE op.numero_orden = 'OP-2026-510';

-- Consumo: OP-2026-511 → Velador ×25
INSERT INTO consumo_material (produccion_id, material_id, cantidad_consumida, costo_unitario)
SELECT p.id, m.id, cons.cantidad, cons.precio
FROM produccion p
JOIN orden_produccion op ON op.id = p.orden_produccion_id
CROSS JOIN (VALUES
    ('Melamina Blanco 18mm', 20.0, 152.00),
    ('Mapresa (fondo)',        7.5, 100.00),
    ('Tapacanto (rollo)',      1.5,  35.00),
    ('Tornillos (caja 1000)', 0.50,  80.00),
    ('Jaladores',            25.0,   1.00),
    ('Patitas',             100.0,   0.40)
) AS cons(material_nombre, cantidad, precio)
JOIN material m ON m.nombre = cons.material_nombre
WHERE op.numero_orden = 'OP-2026-511';

-- Consumo: OP-2026-512 → Cómoda ×10
INSERT INTO consumo_material (produccion_id, material_id, cantidad_consumida, costo_unitario)
SELECT p.id, m.id, cons.cantidad, cons.precio
FROM produccion p
JOIN orden_produccion op ON op.id = p.orden_produccion_id
CROSS JOIN (VALUES
    ('Melamina Color 18mm',  20.0, 180.00),
    ('Mapresa (fondo)',        8.0, 100.00),
    ('Tapacanto (rollo)',      2.0,  35.00),
    ('Tornillos (caja 1000)', 0.40,  80.00),
    ('Bisagras (caja 100)',   0.20,  90.00),
    ('Jaladores',            30.0,   1.00),
    ('Correderas (30cm)',    20.0,  20.00)
) AS cons(material_nombre, cantidad, precio)
JOIN material m ON m.nombre = cons.material_nombre
WHERE op.numero_orden = 'OP-2026-512';

-- Consumo: OP-2026-513 → Ropero ×12
INSERT INTO consumo_material (produccion_id, material_id, cantidad_consumida, costo_unitario)
SELECT p.id, m.id, cons.cantidad, cons.precio
FROM produccion p
JOIN orden_produccion op ON op.id = p.orden_produccion_id
CROSS JOIN (VALUES
    ('Melamina Blanco 18mm', 30.0, 155.00),
    ('Mapresa (fondo)',       12.0, 102.00),
    ('Tapacanto (rollo)',      3.0,  36.00),
    ('Tornillos (caja 1000)', 0.60,  82.00),
    ('Jaladores',            48.0,   1.00),
    ('Correderas (30cm)',    24.0,  20.00),
    ('Patitas',              48.0,   0.40)
) AS cons(material_nombre, cantidad, precio)
JOIN material m ON m.nombre = cons.material_nombre
WHERE op.numero_orden = 'OP-2026-513';

-- Consumo: OP-2026-514 → Estante ×10
INSERT INTO consumo_material (produccion_id, material_id, cantidad_consumida, costo_unitario)
SELECT p.id, m.id, cons.cantidad, cons.precio
FROM produccion p
JOIN orden_produccion op ON op.id = p.orden_produccion_id
CROSS JOIN (VALUES
    ('Melamina Blanco 18mm', 15.0, 155.00),
    ('Mapresa (fondo)',        5.0, 102.00),
    ('Tapacanto (rollo)',      1.5,  36.00),
    ('Tornillos (caja 1000)', 0.30,  82.00),
    ('Patitas',              40.0,   0.40)
) AS cons(material_nombre, cantidad, precio)
JOIN material m ON m.nombre = cons.material_nombre
WHERE op.numero_orden = 'OP-2026-514';

-- ============================================================
--  6. VENTAS — ABRIL 2026
--     26 transacciones | 24 contado + 2 crédito
--     21 clientes nuevos + 2 repiten de marzo (Ana Torres, Carlos Mamani)
--     Días sin venta: 5(dom), 7, 12(dom), 14, 19(dom), 23, 26(dom)
--     El trigger trg_total_venta recalcula total_venta automáticamente
-- ============================================================

-- 01-Abr: María Huanca — Cómoda ×2 + Velador ×3
WITH v AS (INSERT INTO venta (fecha,cliente_id,tipo_venta_id,usuario_id)
VALUES ('2026-05-01',(SELECT id FROM cliente WHERE documento='34567890'),
        (SELECT id FROM tipo_venta WHERE nombre='Contado'),
        (SELECT id FROM usuario WHERE email='juan@muebleria.com')) RETURNING id)
INSERT INTO detalle_venta (venta_id,producto_id,cantidad,precio_unitario)
SELECT v.id,p.id,d.c,d.pr FROM v,
(VALUES ('Cómoda',2,480.00),('Velador',3,90.00)) AS d(nm,c,pr)
JOIN producto p ON p.nombre=d.nm;

-- 02-Abr: José Flores — Velador ×5 + Tocador ×1
WITH v AS (INSERT INTO venta (fecha,cliente_id,tipo_venta_id,usuario_id)
VALUES ('2026-05-02',(SELECT id FROM cliente WHERE documento='56789012'),
        (SELECT id FROM tipo_venta WHERE nombre='Contado'),
        (SELECT id FROM usuario WHERE email='luis@muebleria.com')) RETURNING id)
INSERT INTO detalle_venta (venta_id,producto_id,cantidad,precio_unitario)
SELECT v.id,p.id,d.c,d.pr FROM v,
(VALUES ('Velador',5,90.00),('Tocador',1,650.00)) AS d(nm,c,pr)
JOIN producto p ON p.nombre=d.nm;

-- 03-Abr: Pedro Ticona — Ropero ×1 + Velador ×2
WITH v AS (INSERT INTO venta (fecha,cliente_id,tipo_venta_id,usuario_id)
VALUES ('2026-05-03',(SELECT id FROM cliente WHERE documento='67890123'),
        (SELECT id FROM tipo_venta WHERE nombre='Contado'),
        (SELECT id FROM usuario WHERE email='juan@muebleria.com')) RETURNING id)
INSERT INTO detalle_venta (venta_id,producto_id,cantidad,precio_unitario)
SELECT v.id,p.id,d.c,d.pr FROM v,
(VALUES ('Ropero',1,760.00),('Velador',2,90.00)) AS d(nm,c,pr)
JOIN producto p ON p.nombre=d.nm;

-- 04-Abr: Carmen Apaza — Cómoda ×1 + Comodín ×2
WITH v AS (INSERT INTO venta (fecha,cliente_id,tipo_venta_id,usuario_id)
VALUES ('2026-05-04',(SELECT id FROM cliente WHERE documento='78901234'),
        (SELECT id FROM tipo_venta WHERE nombre='Contado'),
        (SELECT id FROM usuario WHERE email='luis@muebleria.com')) RETURNING id)
INSERT INTO detalle_venta (venta_id,producto_id,cantidad,precio_unitario)
SELECT v.id,p.id,d.c,d.pr FROM v,
(VALUES ('Cómoda',1,480.00),('Comodín',2,230.00)) AS d(nm,c,pr)
JOIN producto p ON p.nombre=d.nm;

-- 05-Abr: DOMINGO — sin ventas

-- 06-Abr: Jorge Ccama — Ropero ×2 + Velador ×4
WITH v AS (INSERT INTO venta (fecha,cliente_id,tipo_venta_id,usuario_id)
VALUES ('2026-05-06',(SELECT id FROM cliente WHERE documento='89012345'),
        (SELECT id FROM tipo_venta WHERE nombre='Contado'),
        (SELECT id FROM usuario WHERE email='juan@muebleria.com')) RETURNING id)
INSERT INTO detalle_venta (venta_id,producto_id,cantidad,precio_unitario)
SELECT v.id,p.id,d.c,d.pr FROM v,
(VALUES ('Ropero',2,760.00),('Velador',4,90.00)) AS d(nm,c,pr)
JOIN producto p ON p.nombre=d.nm;

-- 06-Abr: Luisa Choque — Tocador ×1
WITH v AS (INSERT INTO venta (fecha,cliente_id,tipo_venta_id,usuario_id)
VALUES ('2026-05-06',(SELECT id FROM cliente WHERE documento='90123456'),
        (SELECT id FROM tipo_venta WHERE nombre='Contado'),
        (SELECT id FROM usuario WHERE email='luis@muebleria.com')) RETURNING id)
INSERT INTO detalle_venta (venta_id,producto_id,cantidad,precio_unitario)
SELECT v.id,p.id,1,650.00 FROM v JOIN producto p ON p.nombre='Tocador';

-- 07-Abr: sin ventas (día libre)

-- 08-Abr: Muebles El Norte (mayorista crédito) — Ropero ×5 + Estante ×2
WITH v AS (INSERT INTO venta (fecha,cliente_id,tipo_venta_id,usuario_id)
VALUES ('2026-05-08',(SELECT id FROM cliente WHERE documento='20111222333'),
        (SELECT id FROM tipo_venta WHERE nombre='Crédito'),
        (SELECT id FROM usuario WHERE email='juan@muebleria.com')) RETURNING id)
INSERT INTO detalle_venta (venta_id,producto_id,cantidad,precio_unitario)
SELECT v.id,p.id,d.c,d.pr FROM v,
(VALUES ('Ropero',5,730.00),('Estante',2,260.00)) AS d(nm,c,pr)
JOIN producto p ON p.nombre=d.nm;

-- 09-Abr: Sonia Mamani C. — Cómoda ×2 + Velador ×4
WITH v AS (INSERT INTO venta (fecha,cliente_id,tipo_venta_id,usuario_id)
VALUES ('2026-05-09',(SELECT id FROM cliente WHERE documento='11223344'),
        (SELECT id FROM tipo_venta WHERE nombre='Contado'),
        (SELECT id FROM usuario WHERE email='juan@muebleria.com')) RETURNING id)
INSERT INTO detalle_venta (venta_id,producto_id,cantidad,precio_unitario)
SELECT v.id,p.id,d.c,d.pr FROM v,
(VALUES ('Cómoda',2,480.00),('Velador',4,90.00)) AS d(nm,c,pr)
JOIN producto p ON p.nombre=d.nm;

-- 10-Abr: Roberto Pari — Ropero ×2 + Velador ×3
WITH v AS (INSERT INTO venta (fecha,cliente_id,tipo_venta_id,usuario_id)
VALUES ('2026-05-10',(SELECT id FROM cliente WHERE documento='01234567'),
        (SELECT id FROM tipo_venta WHERE nombre='Contado'),
        (SELECT id FROM usuario WHERE email='luis@muebleria.com')) RETURNING id)
INSERT INTO detalle_venta (venta_id,producto_id,cantidad,precio_unitario)
SELECT v.id,p.id,d.c,d.pr FROM v,
(VALUES ('Ropero',2,760.00),('Velador',3,90.00)) AS d(nm,c,pr)
JOIN producto p ON p.nombre=d.nm;

-- 11-Abr: Diego Quispe R. — Ropero ×2
WITH v AS (INSERT INTO venta (fecha,cliente_id,tipo_venta_id,usuario_id)
VALUES ('2026-05-11',(SELECT id FROM cliente WHERE documento='22334455'),
        (SELECT id FROM tipo_venta WHERE nombre='Contado'),
        (SELECT id FROM usuario WHERE email='juan@muebleria.com')) RETURNING id)
INSERT INTO detalle_venta (venta_id,producto_id,cantidad,precio_unitario)
SELECT v.id,p.id,2,760.00 FROM v JOIN producto p ON p.nombre='Ropero';

-- 12-Abr: DOMINGO — sin ventas

-- 13-Abr: Carlos Mamani (repite de marzo) — Tocador ×1 + Velador ×3
WITH v AS (INSERT INTO venta (fecha,cliente_id,tipo_venta_id,usuario_id)
VALUES ('2026-05-13',(SELECT id FROM cliente WHERE documento='87654321'),
        (SELECT id FROM tipo_venta WHERE nombre='Contado'),
        (SELECT id FROM usuario WHERE email='luis@muebleria.com')) RETURNING id)
INSERT INTO detalle_venta (venta_id,producto_id,cantidad,precio_unitario)
SELECT v.id,p.id,d.c,d.pr FROM v,
(VALUES ('Tocador',1,650.00),('Velador',3,90.00)) AS d(nm,c,pr)
JOIN producto p ON p.nombre=d.nm;

-- 13-Abr: Francisca Cano — Comodín ×2 + Estante ×1
WITH v AS (INSERT INTO venta (fecha,cliente_id,tipo_venta_id,usuario_id)
VALUES ('2026-05-13',(SELECT id FROM cliente WHERE documento='33445566'),
        (SELECT id FROM tipo_venta WHERE nombre='Contado'),
        (SELECT id FROM usuario WHERE email='juan@muebleria.com')) RETURNING id)
INSERT INTO detalle_venta (venta_id,producto_id,cantidad,precio_unitario)
SELECT v.id,p.id,d.c,d.pr FROM v,
(VALUES ('Comodín',2,230.00),('Estante',1,280.00)) AS d(nm,c,pr)
JOIN producto p ON p.nombre=d.nm;

-- 14-Abr: sin ventas (día libre)

-- 15-Abr: Alberto Ramos — Ropero ×2 + Cómoda ×1
WITH v AS (INSERT INTO venta (fecha,cliente_id,tipo_venta_id,usuario_id)
VALUES ('2026-05-15',(SELECT id FROM cliente WHERE documento='44556677'),
        (SELECT id FROM tipo_venta WHERE nombre='Contado'),
        (SELECT id FROM usuario WHERE email='luis@muebleria.com')) RETURNING id)
INSERT INTO detalle_venta (venta_id,producto_id,cantidad,precio_unitario)
SELECT v.id,p.id,d.c,d.pr FROM v,
(VALUES ('Ropero',2,760.00),('Cómoda',1,480.00)) AS d(nm,c,pr)
JOIN producto p ON p.nombre=d.nm;

-- 16-Abr: Teresa Vilca — Velador ×6 + Cómoda ×2
WITH v AS (INSERT INTO venta (fecha,cliente_id,tipo_venta_id,usuario_id)
VALUES ('2026-05-16',(SELECT id FROM cliente WHERE documento='55667788'),
        (SELECT id FROM tipo_venta WHERE nombre='Contado'),
        (SELECT id FROM usuario WHERE email='juan@muebleria.com')) RETURNING id)
INSERT INTO detalle_venta (venta_id,producto_id,cantidad,precio_unitario)
SELECT v.id,p.id,d.c,d.pr FROM v,
(VALUES ('Velador',6,90.00),('Cómoda',2,480.00)) AS d(nm,c,pr)
JOIN producto p ON p.nombre=d.nm;

-- 17-Abr: Miguel Sucari — Ropero ×2 + Cómoda ×2
WITH v AS (INSERT INTO venta (fecha,cliente_id,tipo_venta_id,usuario_id)
VALUES ('2026-05-17',(SELECT id FROM cliente WHERE documento='66778899'),
        (SELECT id FROM tipo_venta WHERE nombre='Contado'),
        (SELECT id FROM usuario WHERE email='luis@muebleria.com')) RETURNING id)
INSERT INTO detalle_venta (venta_id,producto_id,cantidad,precio_unitario)
SELECT v.id,p.id,d.c,d.pr FROM v,
(VALUES ('Ropero',2,760.00),('Cómoda',2,480.00)) AS d(nm,c,pr)
JOIN producto p ON p.nombre=d.nm;

-- 18-Abr: Distribuidora Altiplano (mayorista crédito) — Ropero ×5 + Cómoda ×4
WITH v AS (INSERT INTO venta (fecha,cliente_id,tipo_venta_id,usuario_id)
VALUES ('2026-05-18',(SELECT id FROM cliente WHERE documento='20444555666'),
        (SELECT id FROM tipo_venta WHERE nombre='Crédito'),
        (SELECT id FROM usuario WHERE email='juan@muebleria.com')) RETURNING id)
INSERT INTO detalle_venta (venta_id,producto_id,cantidad,precio_unitario)
SELECT v.id,p.id,d.c,d.pr FROM v,
(VALUES ('Ropero',5,730.00),('Cómoda',4,450.00)) AS d(nm,c,pr)
JOIN producto p ON p.nombre=d.nm;

-- 19-Abr: DOMINGO — sin ventas

-- 20-Abr: Patricia Luna — Velador ×6 + Comodín ×3
WITH v AS (INSERT INTO venta (fecha,cliente_id,tipo_venta_id,usuario_id)
VALUES ('2026-05-20',(SELECT id FROM cliente WHERE documento='77889900'),
        (SELECT id FROM tipo_venta WHERE nombre='Contado'),
        (SELECT id FROM usuario WHERE email='juan@muebleria.com')) RETURNING id)
INSERT INTO detalle_venta (venta_id,producto_id,cantidad,precio_unitario)
SELECT v.id,p.id,d.c,d.pr FROM v,
(VALUES ('Velador',6,90.00),('Comodín',3,230.00)) AS d(nm,c,pr)
JOIN producto p ON p.nombre=d.nm;

-- 21-Abr: Raúl Coila — Ropero ×2 + Estante ×2
WITH v AS (INSERT INTO venta (fecha,cliente_id,tipo_venta_id,usuario_id)
VALUES ('2026-05-21',(SELECT id FROM cliente WHERE documento='88990011'),
        (SELECT id FROM tipo_venta WHERE nombre='Contado'),
        (SELECT id FROM usuario WHERE email='luis@muebleria.com')) RETURNING id)
INSERT INTO detalle_venta (venta_id,producto_id,cantidad,precio_unitario)
SELECT v.id,p.id,d.c,d.pr FROM v,
(VALUES ('Ropero',2,760.00),('Estante',2,280.00)) AS d(nm,c,pr)
JOIN producto p ON p.nombre=d.nm;

-- 22-Abr: Elena Machaca — Tocador ×2 + Velador ×4
WITH v AS (INSERT INTO venta (fecha,cliente_id,tipo_venta_id,usuario_id)
VALUES ('2026-05-22',(SELECT id FROM cliente WHERE documento='99001122'),
        (SELECT id FROM tipo_venta WHERE nombre='Contado'),
        (SELECT id FROM usuario WHERE email='juan@muebleria.com')) RETURNING id)
INSERT INTO detalle_venta (venta_id,producto_id,cantidad,precio_unitario)
SELECT v.id,p.id,d.c,d.pr FROM v,
(VALUES ('Tocador',2,650.00),('Velador',4,90.00)) AS d(nm,c,pr)
JOIN producto p ON p.nombre=d.nm;

-- 23-Abr: sin ventas (día libre)

-- 24-Abr: Ana Torres (repite de marzo) — Ropero ×1 + Cómoda ×2
WITH v AS (INSERT INTO venta (fecha,cliente_id,tipo_venta_id,usuario_id)
VALUES ('2026-05-24',(SELECT id FROM cliente WHERE documento='12345678'),
        (SELECT id FROM tipo_venta WHERE nombre='Contado'),
        (SELECT id FROM usuario WHERE email='juan@muebleria.com')) RETURNING id)
INSERT INTO detalle_venta (venta_id,producto_id,cantidad,precio_unitario)
SELECT v.id,p.id,d.c,d.pr FROM v,
(VALUES ('Ropero',1,760.00),('Cómoda',2,480.00)) AS d(nm,c,pr)
JOIN producto p ON p.nombre=d.nm;

-- 25-Abr: Fernando Turpo — Velador ×5 + Ropero ×2
WITH v AS (INSERT INTO venta (fecha,cliente_id,tipo_venta_id,usuario_id)
VALUES ('2026-05-25',(SELECT id FROM cliente WHERE documento='10203040'),
        (SELECT id FROM tipo_venta WHERE nombre='Contado'),
        (SELECT id FROM usuario WHERE email='luis@muebleria.com')) RETURNING id)
INSERT INTO detalle_venta (venta_id,producto_id,cantidad,precio_unitario)
SELECT v.id,p.id,d.c,d.pr FROM v,
(VALUES ('Velador',5,90.00),('Ropero',2,760.00)) AS d(nm,c,pr)
JOIN producto p ON p.nombre=d.nm;

-- 26-Abr: DOMINGO — sin ventas

-- 27-Abr: Gloria Condori M. — Ropero ×2 + Comodín ×3
WITH v AS (INSERT INTO venta (fecha,cliente_id,tipo_venta_id,usuario_id)
VALUES ('2026-05-27',(SELECT id FROM cliente WHERE documento='20304050'),
        (SELECT id FROM tipo_venta WHERE nombre='Contado'),
        (SELECT id FROM usuario WHERE email='juan@muebleria.com')) RETURNING id)
INSERT INTO detalle_venta (venta_id,producto_id,cantidad,precio_unitario)
SELECT v.id,p.id,d.c,d.pr FROM v,
(VALUES ('Ropero',2,760.00),('Comodín',3,230.00)) AS d(nm,c,pr)
JOIN producto p ON p.nombre=d.nm;

-- 28-Abr: Andrés Cuti — Tocador ×1 + Velador ×5
WITH v AS (INSERT INTO venta (fecha,cliente_id,tipo_venta_id,usuario_id)
VALUES ('2026-05-28',(SELECT id FROM cliente WHERE documento='30405060'),
        (SELECT id FROM tipo_venta WHERE nombre='Contado'),
        (SELECT id FROM usuario WHERE email='luis@muebleria.com')) RETURNING id)
INSERT INTO detalle_venta (venta_id,producto_id,cantidad,precio_unitario)
SELECT v.id,p.id,d.c,d.pr FROM v,
(VALUES ('Tocador',1,650.00),('Velador',5,90.00)) AS d(nm,c,pr)
JOIN producto p ON p.nombre=d.nm;

-- 29-Abr: Beatriz Sulla — Cómoda ×2 + Estante ×2 + Velador ×3
WITH v AS (INSERT INTO venta (fecha,cliente_id,tipo_venta_id,usuario_id)
VALUES ('2026-05-29',(SELECT id FROM cliente WHERE documento='40506070'),
        (SELECT id FROM tipo_venta WHERE nombre='Contado'),
        (SELECT id FROM usuario WHERE email='juan@muebleria.com')) RETURNING id)
INSERT INTO detalle_venta (venta_id,producto_id,cantidad,precio_unitario)
SELECT v.id,p.id,d.c,d.pr FROM v,
(VALUES ('Cómoda',2,480.00),('Estante',2,280.00),('Velador',3,90.00)) AS d(nm,c,pr)
JOIN producto p ON p.nombre=d.nm;

-- 30-Abr: Mueblería Centro (mayorista contado) — Ropero ×3 + Cómoda ×3 + Estante ×1
WITH v AS (INSERT INTO venta (fecha,cliente_id,tipo_venta_id,usuario_id)
VALUES ('2026-05-30',(SELECT id FROM cliente WHERE documento='20777888999'),
        (SELECT id FROM tipo_venta WHERE nombre='Contado'),
        (SELECT id FROM usuario WHERE email='juan@muebleria.com')) RETURNING id)
INSERT INTO detalle_venta (venta_id,producto_id,cantidad,precio_unitario)
SELECT v.id,p.id,d.c,d.pr FROM v,
(VALUES ('Ropero',3,730.00),('Cómoda',3,450.00),('Estante',1,260.00)) AS d(nm,c,pr)
JOIN producto p ON p.nombre=d.nm;

-- 30-Abr: Víctor Alanoca — Velador ×4 + Ropero ×1
WITH v AS (INSERT INTO venta (fecha,cliente_id,tipo_venta_id,usuario_id)
VALUES ('2026-05-30',(SELECT id FROM cliente WHERE documento='50607080'),
        (SELECT id FROM tipo_venta WHERE nombre='Contado'),
        (SELECT id FROM usuario WHERE email='luis@muebleria.com')) RETURNING id)
INSERT INTO detalle_venta (venta_id,producto_id,cantidad,precio_unitario)
SELECT v.id,p.id,d.c,d.pr FROM v,
(VALUES ('Velador',4,90.00),('Ropero',1,760.00)) AS d(nm,c,pr)
JOIN producto p ON p.nombre=d.nm;


-- 31-May: Venta Día de la Madre - Ana Torres — Tocador x3 + Cómoda x2
WITH v AS (INSERT INTO venta (fecha,cliente_id,tipo_venta_id,usuario_id)
VALUES ('2026-05-31',(SELECT id FROM cliente WHERE documento='12345678'),
        (SELECT id FROM tipo_venta WHERE nombre='Contado'),
        (SELECT id FROM usuario WHERE email='juan@muebleria.com')) RETURNING id)
INSERT INTO detalle_venta (venta_id,producto_id,cantidad,precio_unitario)
SELECT v.id,p.id,d.c,d.pr FROM v,
(VALUES ('Tocador',3,650.00),('Cómoda',2,480.00)) AS d(nm,c,pr)
JOIN producto p ON p.nombre=d.nm;

-- ============================================================
--  7. CUENTAS POR COBRAR — ventas a crédito mayo (30 días plazo)
-- ============================================================

INSERT INTO cuentas_cobrar
    (venta_id, fecha_emision, fecha_vencimiento, monto_total, saldo_pendiente, estado, numero_cuota, total_cuotas)
SELECT
    v.id, v.fecha,
    v.fecha + INTERVAL '30 days',
    v.total_venta, v.total_venta,
    'pendiente', 1, 1
FROM venta v
WHERE v.tipo_venta_id = (SELECT id FROM tipo_venta WHERE nombre='Crédito')
  AND v.fecha BETWEEN '2026-05-01' AND '2026-05-30'
  AND NOT EXISTS (SELECT 1 FROM cuentas_cobrar cc WHERE cc.venta_id = v.id);

-- ============================================================
--  8. PAGOS DE CLIENTES — ABRIL 2026
--     Liquidan saldos de marzo + abono parcial Mueblería Centro
-- ============================================================

-- Muebles El Norte liquida saldo marzo (S/2,150) el 10-Abr
INSERT INTO pago_cliente (cuenta_cobrar_id, fecha, monto, metodo_pago, referencia, usuario_id)
SELECT cc.id,'2026-05-10',2150.00,'transferencia','TRF-BN-20260410',
       (SELECT id FROM usuario WHERE email='maria@muebleria.com')
FROM cuentas_cobrar cc
JOIN venta v ON v.id = cc.venta_id
JOIN cliente c ON c.id = v.cliente_id
WHERE c.documento = '20111222333' AND cc.saldo_pendiente > 0
ORDER BY cc.fecha_emision
LIMIT 1;

-- Distribuidora Altiplano liquida saldo marzo (S/2,220) el 15-Abr
INSERT INTO pago_cliente (cuenta_cobrar_id, fecha, monto, metodo_pago, referencia, usuario_id)
SELECT cc.id,'2026-05-15',2220.00,'transferencia','TRF-BCP-20260415',
       (SELECT id FROM usuario WHERE email='maria@muebleria.com')
FROM cuentas_cobrar cc
JOIN venta v ON v.id = cc.venta_id
JOIN cliente c ON c.id = v.cliente_id
WHERE c.documento = '20444555666' AND cc.saldo_pendiente > 0
ORDER BY cc.fecha_emision
LIMIT 1;

-- Mueblería Centro abona S/2,000 a deuda de marzo (S/3,820) el 20-Abr
INSERT INTO pago_cliente (cuenta_cobrar_id, fecha, monto, metodo_pago, referencia, usuario_id)
SELECT cc.id,'2026-05-20',2000.00,'transferencia','TRF-IBK-20260420',
       (SELECT id FROM usuario WHERE email='maria@muebleria.com')
FROM cuentas_cobrar cc
JOIN venta v ON v.id = cc.venta_id
JOIN cliente c ON c.id = v.cliente_id
WHERE c.documento = '20777888999' AND cc.saldo_pendiente > 0
ORDER BY cc.fecha_emision
LIMIT 1;

-- ============================================================
--  9. GASTOS OPERATIVOS — ABRIL 2026
-- ============================================================

INSERT INTO gasto (fecha, categoria_id, monto, detalle, comprobante, usuario_id)
SELECT g.fecha, cg.id, g.monto, g.detalle, g.comprobante,
       (SELECT id FROM usuario WHERE email='maria@muebleria.com')
FROM (VALUES
    ('2026-05-01'::date, 'Alquiler local + servicios',        2800.00, 'Alquiler taller + agua + luz mayo',        'REC-007'),
    ('2026-05-01'::date, 'Servicios (luz, agua, internet)',    320.00,  'Internet taller mayo',                     'REC-008'),
    ('2026-05-10'::date, 'Compra Melamina y accesorios',      4500.00, 'Compra materiales primera quincena',        'F-VARS-03'),
    ('2026-05-15'::date, 'Mano de Obra (eventual)',           7200.00, 'Pago 3 operarios + maestro (quincena)',     'PL-003'),
    ('2026-05-18'::date, 'Compra Melamina y accesorios',      4300.00, 'Compra materiales segunda quincena',        'F-VARS-04'),
    ('2026-05-20'::date, 'Transporte y delivery',             1100.00, 'Entregas a clientes y recojo materiales',   'REC-009'),
    ('2026-05-25'::date, 'Otros (herramientas, etc.)',         580.00, 'Mantenimiento maquinaria y herramientas',   'REC-010'),
    ('2026-05-28'::date, 'Marketing y publicidad',             420.00, 'Publicidad Facebook, Instagram y volantes', 'REC-011'),
    ('2026-05-30'::date, 'Mano de Obra (eventual)',           7200.00, 'Pago 3 operarios + maestro (fin de mes)',   'PL-004'),
    ('2026-05-30'::date, 'Servicios (luz, agua, internet)',    300.00, 'Luz y agua - cierre mes',                   'REC-012')
) AS g(fecha, categoria, monto, detalle, comprobante)
JOIN categoria_gasto cg ON cg.nombre = g.categoria;

-- ============================================================
--  10. APERTURA DE CAJA — ABRIL 2026
--      Saldo inicial = saldo final de marzo (2000 + 33590 - 27330 = 8260)
-- ============================================================

INSERT INTO caja (fecha_apertura, saldo_inicial, estado, usuario_apertura_id)
VALUES (
    '2026-05-01', COALESCE((SELECT saldo_final FROM caja WHERE fecha_cierre = '2026-04-30'), 8260.00), 'abierta',
    (SELECT id FROM usuario WHERE email='admin@muebleria.com')
);

-- ============================================================
--  11. MOVIMIENTOS DE CAJA — ABRIL 2026
-- ============================================================

INSERT INTO movimiento_caja
    (caja_id, fecha, tipo, concepto, monto, metodo_pago, referencia_tabla, usuario_id)
SELECT
    (SELECT id FROM caja WHERE fecha_apertura='2026-05-01' LIMIT 1),
    mc.fecha, mc.tipo, mc.concepto, mc.monto, mc.metodo_pago, mc.ref_tabla,
    (SELECT id FROM usuario WHERE email='maria@muebleria.com')
FROM (VALUES
    -- INGRESOS — ventas contado (cada cliente compra 1 sola vez)
    ('2026-05-01'::timestamptz,'ingreso','Venta contado - María Huanca (Cómoda ×2 + Velador ×3)',            1230.00,'efectivo',    'venta'),
    ('2026-05-02'::timestamptz,'ingreso','Venta contado - José Flores (Velador ×5 + Tocador ×1)',            1100.00,'efectivo',    'venta'),
    ('2026-05-03'::timestamptz,'ingreso','Venta contado - Pedro Ticona (Ropero ×1 + Velador ×2)',             940.00,'efectivo',    'venta'),
    ('2026-05-04'::timestamptz,'ingreso','Venta contado - Carmen Apaza (Cómoda ×1 + Comodín ×2)',             940.00,'efectivo',    'venta'),
    ('2026-05-06'::timestamptz,'ingreso','Venta contado - Jorge Ccama (Ropero ×2 + Velador ×4)',             1880.00,'efectivo',    'venta'),
    ('2026-05-06'::timestamptz,'ingreso','Venta contado - Luisa Choque (Tocador ×1)',                         650.00,'efectivo',    'venta'),
    ('2026-05-09'::timestamptz,'ingreso','Venta contado - Sonia Mamani C. (Cómoda ×2 + Velador ×4)',         1320.00,'efectivo',    'venta'),
    ('2026-05-10'::timestamptz,'ingreso','Venta contado - Roberto Pari (Ropero ×2 + Velador ×3)',            1790.00,'efectivo',    'venta'),
    ('2026-05-11'::timestamptz,'ingreso','Venta contado - Diego Quispe R. (Ropero ×2)',                      1520.00,'efectivo',    'venta'),
    ('2026-05-13'::timestamptz,'ingreso','Venta contado - Carlos Mamani (Tocador ×1 + Velador ×3)',           920.00,'efectivo',    'venta'),
    ('2026-05-13'::timestamptz,'ingreso','Venta contado - Francisca Cano (Comodín ×2 + Estante ×1)',          740.00,'efectivo',    'venta'),
    ('2026-05-15'::timestamptz,'ingreso','Venta contado - Alberto Ramos (Ropero ×2 + Cómoda ×1)',            2000.00,'efectivo',    'venta'),
    ('2026-05-16'::timestamptz,'ingreso','Venta contado - Teresa Vilca (Velador ×6 + Cómoda ×2)',            1500.00,'efectivo',    'venta'),
    ('2026-05-17'::timestamptz,'ingreso','Venta contado - Miguel Sucari (Ropero ×2 + Cómoda ×2)',            2480.00,'efectivo',    'venta'),
    ('2026-05-20'::timestamptz,'ingreso','Venta contado - Patricia Luna (Velador ×6 + Comodín ×3)',          1230.00,'efectivo',    'venta'),
    ('2026-05-21'::timestamptz,'ingreso','Venta contado - Raúl Coila (Ropero ×2 + Estante ×2)',             2080.00,'efectivo',    'venta'),
    ('2026-05-22'::timestamptz,'ingreso','Venta contado - Elena Machaca (Tocador ×2 + Velador ×4)',          1660.00,'efectivo',    'venta'),
    ('2026-05-24'::timestamptz,'ingreso','Venta contado - Ana Torres (Ropero ×1 + Cómoda ×2)',               1720.00,'efectivo',    'venta'),
    ('2026-05-25'::timestamptz,'ingreso','Venta contado - Fernando Turpo (Velador ×5 + Ropero ×2)',          1970.00,'efectivo',    'venta'),
    ('2026-05-27'::timestamptz,'ingreso','Venta contado - Gloria Condori M. (Ropero ×2 + Comodín ×3)',      2210.00,'efectivo',    'venta'),
    ('2026-05-28'::timestamptz,'ingreso','Venta contado - Andrés Cuti (Tocador ×1 + Velador ×5)',            1100.00,'efectivo',    'venta'),
    ('2026-05-29'::timestamptz,'ingreso','Venta contado - Beatriz Sulla (Cómoda ×2 + Estante ×2 + Velador ×3)', 1790.00,'efectivo','venta'),
    ('2026-05-30'::timestamptz,'ingreso','Venta contado - Mueblería Centro (Ropero ×3 + Cómoda ×3 + Estante ×1)', 3800.00,'transferencia','venta'),
    ('2026-05-30'::timestamptz,'ingreso','Venta contado - Víctor Alanoca (Velador ×4 + Ropero ×1)',          1120.00,'efectivo',    'venta'),
    -- INGRESOS — cobros de créditos marzo
    ('2026-05-10'::timestamptz,'ingreso','Pago crédito - Muebles El Norte (saldo marzo)',                    2150.00,'transferencia','pago_cliente'),
    ('2026-05-15'::timestamptz,'ingreso','Pago crédito - Distribuidora Altiplano (saldo marzo)',             2220.00,'transferencia','pago_cliente'),
    ('2026-05-20'::timestamptz,'ingreso','Pago crédito - Mueblería Centro (abono parcial marzo)',            2000.00,'transferencia','pago_cliente'),
    ('2026-05-31'::timestamptz,'ingreso','Venta contado - Ana Torres (Tocador x3 + Cómoda x2)',          2910.00,'efectivo',    'venta'),
    -- EGRESOS
    ('2026-05-01'::timestamptz,'egreso', 'Alquiler local + servicios - mayo',                               2800.00,'efectivo',    'gasto'),
    ('2026-05-01'::timestamptz,'egreso', 'Internet taller - mayo',                                           320.00,'transferencia','gasto'),
    ('2026-05-10'::timestamptz,'egreso', 'Compra materiales primera quincena',                               4500.00,'efectivo',    'gasto'),
    ('2026-05-15'::timestamptz,'egreso', 'Pago planilla operarios - quincena',                               7200.00,'efectivo',    'gasto'),
    ('2026-05-18'::timestamptz,'egreso', 'Compra materiales segunda quincena',                               4300.00,'efectivo',    'gasto'),
    ('2026-05-20'::timestamptz,'egreso', 'Transporte y delivery mayo',                                      1100.00,'efectivo',    'gasto'),
    ('2026-05-25'::timestamptz,'egreso', 'Mantenimiento herramientas y maquinaria',                           580.00,'efectivo',    'gasto'),
    ('2026-05-28'::timestamptz,'egreso', 'Publicidad redes sociales y volantes',                               420.00,'transferencia','gasto'),
    ('2026-05-30'::timestamptz,'egreso', 'Pago planilla operarios - fin de mes',                             7200.00,'efectivo',    'gasto'),
    ('2026-05-30'::timestamptz,'egreso', 'Luz y agua - cierre mes',                                           300.00,'efectivo',    'gasto')
) AS mc(fecha, tipo, concepto, monto, metodo_pago, ref_tabla);

-- Cierre de caja al 30 de mayo
UPDATE caja
SET fecha_cierre      = '2026-05-30',
    estado            = 'cerrada',
    saldo_final       = saldo_inicial + total_ingresos - total_egresos,
    usuario_cierre_id = (SELECT id FROM usuario WHERE email='admin@muebleria.com')
WHERE fecha_apertura  = '2026-05-01' AND estado = 'abierta';

-- ============================================================
--  12. DEVOLUCIÓN — Teresa Vilca devuelve 1 Velador (compra 16-Abr)
--      Producto con rayón en la superficie
-- ============================================================

INSERT INTO devolucion_venta
    (venta_id, detalle_venta_id, fecha, cantidad, motivo, monto_reembolsado, usuario_id)
SELECT
    dv.venta_id, dv.id,
    '2026-05-18', 1,
    'Producto con rayón en la superficie',
    90.00,
    (SELECT id FROM usuario WHERE email='juan@muebleria.com')
FROM detalle_venta dv
JOIN venta v    ON v.id  = dv.venta_id
JOIN cliente c  ON c.id  = v.cliente_id
JOIN producto p ON p.id  = dv.producto_id
WHERE c.documento = '55667788'
  AND p.nombre    = 'Velador'
  AND v.fecha     = '2026-05-16'
LIMIT 1;

-- ============================================================
--  13. VERIFICACIONES FINALES — ejecutar para confirmar carga
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

-- Estado de caja mayo
SELECT fecha_apertura, fecha_cierre, saldo_inicial,
       total_ingresos, total_egresos,
       saldo_inicial + total_ingresos - total_egresos AS saldo_calculado,
       saldo_final, estado
FROM caja
WHERE fecha_apertura = '2026-05-01';

-- ============================================================
--  FIN DEL SCRIPT DE DATOS — ABRIL 2026
-- ============================================================
