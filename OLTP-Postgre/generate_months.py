import os
import re

base_dir = r"c:\Users\Usuario\Documents\muebleria-bi\OLTP-Postgre"

def read_file(name):
    with open(os.path.join(base_dir, name), 'r', encoding='utf-8') as f:
        return f.read()

def write_file(name, content):
    with open(os.path.join(base_dir, name), 'w', encoding='utf-8') as f:
        f.write(content)

# 1. Update March (already extracted) to use dynamic saldo_inicial
marzo_sql = read_file('datos_marzo_2026.sql')
marzo_sql = re.sub(
    r"VALUES \(\s*'2026-03-01',\s*2000\.00,\s*'abierta',", 
    "VALUES (\n    '2026-03-01', COALESCE((SELECT saldo_final FROM caja WHERE fecha_cierre = '2026-02-28'), 2000.00), 'abierta',", 
    marzo_sql
)
write_file('datos_marzo_2026.sql', marzo_sql)

# 2. Build January from March
enero_sql = marzo_sql.replace('2026-03', '2026-01').replace('Marzo', 'Enero').replace('marzo', 'enero')
enero_sql = enero_sql.replace('datos_febrero_2026.sql', 'base_datos_transaccional.sql')
# Fix the dynamic saldo for January (defaults to 10000 to have some initial capital, or 2000)
enero_sql = re.sub(r"fecha_cierre = '2026-02-28'", "fecha_cierre = '2025-12-31'", enero_sql)

# Adjust Jan sales to ~39.2k:
# Ropero x8 (5840.00) -> Ropero x5 (3650.00) => reduction of 2190
enero_sql = enero_sql.replace('Ropero x8', 'Ropero x5')
enero_sql = enero_sql.replace(',8,730.00', ',5,730.00')
enero_sql = enero_sql.replace('5840.00', '3650.00')

write_file('datos_enero_2026.sql', enero_sql)

# 3. Build February from January
febrero_sql = enero_sql.replace('2026-01', '2026-02').replace('Enero', 'Febrero').replace('enero', 'febrero')
febrero_sql = febrero_sql.replace('base_datos_transaccional.sql', 'datos_enero_2026.sql')
febrero_sql = re.sub(r"fecha_cierre = '2025-12-31'", "fecha_cierre = '2026-01-31'", febrero_sql)

# Feb has 28 days.
febrero_sql = re.sub(r'2026-02-29', '2026-02-28', febrero_sql)
febrero_sql = re.sub(r'2026-02-30', '2026-02-28', febrero_sql)
febrero_sql = re.sub(r'2026-02-31', '2026-02-28', febrero_sql)

# Adjust Feb sales to ~36.9k:
# Ropero x3 + Comodín x2 on day 09 -> Comodín x1
febrero_sql = febrero_sql.replace('Ropero x3 + Comodín x2', 'Comodín x1')
febrero_sql = febrero_sql.replace("('Ropero',3,760.00),('Comodín',2,230.00)", "('Comodín',1,230.00)")
febrero_sql = febrero_sql.replace('2740.00', '230.00')

write_file('datos_febrero_2026.sql', febrero_sql)

# 4. Update April to use dynamic saldo_inicial
abril_sql = read_file('datos_abril_2026.sql')
abril_sql = re.sub(
    r"VALUES \(\s*'2026-04-01',\s*8260\.00,\s*'abierta',", 
    "VALUES (\n    '2026-04-01', COALESCE((SELECT saldo_final FROM caja WHERE fecha_cierre = '2026-03-31'), 8260.00), 'abierta',", 
    abril_sql
)
write_file('datos_abril_2026.sql', abril_sql)

# 5. Build May from April
mayo_sql = abril_sql.replace('2026-04', '2026-05').replace('Abril', 'Mayo').replace('abril', 'mayo')
mayo_sql = mayo_sql.replace('datos_marzo_2026.sql', 'datos_abril_2026.sql')
mayo_sql = mayo_sql.replace('base_datos_transaccional.sql', 'datos_abril_2026.sql')
mayo_sql = re.sub(r"fecha_cierre = '2026-03-31'", "fecha_cierre = '2026-04-30'", mayo_sql)

# May has 31 days. Add a sale to reach ~49.8k
add_sale = """
-- 31-May: Venta Día de la Madre - Ana Torres — Tocador x3 + Cómoda x2
WITH v AS (INSERT INTO venta (fecha,cliente_id,tipo_venta_id,usuario_id)
VALUES ('2026-05-31',(SELECT id FROM cliente WHERE documento='12345678'),
        (SELECT id FROM tipo_venta WHERE nombre='Contado'),
        (SELECT id FROM usuario WHERE email='juan@muebleria.com')) RETURNING id)
INSERT INTO detalle_venta (venta_id,producto_id,cantidad,precio_unitario)
SELECT v.id,p.id,d.c,d.pr FROM v,
(VALUES ('Tocador',3,650.00),('Cómoda',2,480.00)) AS d(nm,c,pr)
JOIN producto p ON p.nombre=d.nm;
"""
mayo_sql = mayo_sql.replace('-- ============================================================\n--  7. CUENTAS POR COBRAR', add_sale + '\n-- ============================================================\n--  7. CUENTAS POR COBRAR')

add_mov = "    ('2026-05-31'::timestamptz,'ingreso','Venta contado - Ana Torres (Tocador x3 + Cómoda x2)',          2910.00,'efectivo',    'venta'),\n"
mayo_sql = mayo_sql.replace('    -- EGRESOS', add_mov + '    -- EGRESOS')

# Fix the dates of clients to May
mayo_sql = mayo_sql.replace('2026-03-30', '2026-05-31')

write_file('datos_mayo_2026.sql', mayo_sql)

print("All scripts generated successfully!")
