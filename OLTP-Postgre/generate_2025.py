import os
import random
import calendar

base_dir = r"c:\Users\Usuario\Documents\muebleria-bi\OLTP-Postgre"

targets = {
    1: 33300, 2: 31400, 3: 35300, 4: 40200, 
    5: 43300, 6: 40200, 7: 38300, 8: 42200, 
    9: 56900, 10: 43100, 11: 38300, 12: 35300
}

products = [
    (1, 'Ropero', 760.00),
    (2, 'Velador', 90.00),
    (3, 'Cómoda', 480.00),
    (4, 'Comodín', 230.00),
    (5, 'Tocador', 650.00),
    (6, 'Estante', 280.00)
]

sql = ""
sql += "-- ============================================================\n"
sql += "-- DATOS HISTÓRICOS 2025\n"
sql += "-- ============================================================\n\n"
sql += "SET search_path TO transaccional, public;\n\n"

sql += "-- Limpieza de datos previos de 2025 para idempotencia\n"
sql += "DELETE FROM movimiento_caja WHERE caja_id IN (SELECT id FROM caja WHERE EXTRACT(YEAR FROM fecha_apertura) = 2025);\n"
sql += "DELETE FROM detalle_venta WHERE venta_id IN (SELECT id FROM venta WHERE EXTRACT(YEAR FROM fecha) = 2025);\n"
sql += "DELETE FROM venta WHERE EXTRACT(YEAR FROM fecha) = 2025;\n"
sql += "DELETE FROM produccion WHERE EXTRACT(YEAR FROM fecha_produccion) = 2025;\n"
sql += "DELETE FROM orden_produccion WHERE EXTRACT(YEAR FROM fecha_inicio) = 2025;\n"
sql += "DELETE FROM gasto WHERE EXTRACT(YEAR FROM fecha) = 2025;\n"
sql += "DELETE FROM caja WHERE EXTRACT(YEAR FROM fecha_apertura) = 2025;\n\n"

for month in range(1, 13):
    _, last_day = calendar.monthrange(2025, month)
    
    start_date = f"2025-{month:02d}-01"
    end_date = f"2025-{month:02d}-{last_day:02d}"
    
    sql += f"-- ================== MES: {month:02d}/2025 ==================\n"
    
    if month == 1:
        saldo_inicial = "2000.00"
    else:
        prev_end_date = f"2025-{month-1:02d}-{calendar.monthrange(2025, month-1)[1]:02d}"
        saldo_inicial = f"COALESCE((SELECT saldo_final FROM caja WHERE fecha_cierre = '{prev_end_date}'), 2000.00)"
        
    sql += f"INSERT INTO caja (fecha_apertura, saldo_inicial, estado, usuario_apertura_id) VALUES ('{start_date}', {saldo_inicial}, 'abierta', (SELECT id FROM usuario WHERE email='admin@muebleria.com'));\n"
    
    total_ventas = 0
    day = 1
    target = targets[month]
    
    # 1. Gastos y Compras para dar vida al data mart
    # Gastos
    sql += f"INSERT INTO gasto (categoria_id, fecha, monto, detalle, usuario_id) VALUES ((SELECT id FROM categoria_gasto LIMIT 1), '{start_date}', 1500.00, 'Alquiler local', (SELECT id FROM usuario LIMIT 1));\n"
    sql += f"INSERT INTO movimiento_caja (caja_id, fecha, tipo, concepto, monto, metodo_pago, referencia_tabla) VALUES ((SELECT id FROM caja WHERE fecha_apertura='{start_date}' ORDER BY id DESC LIMIT 1), '{start_date}'::timestamptz, 'egreso', 'Pago alquiler', 1500.00, 'transferencia', 'gasto');\n"
    
    # Producción (dummy para no dejar vacío fact_produccion)
    op_num = f"OP-2025-{month:02d}01"
    sql += f"INSERT INTO orden_produccion (numero_orden, fecha_inicio, fecha_fin_estimada, estado, producto_id, cantidad_ordenada, cantidad_producida, responsable_id, costo_mp_estimado, costo_mo_estimado) VALUES ('{op_num}', '{start_date}', '{end_date}', 'completada', 1, 20, 20, (SELECT id FROM usuario LIMIT 1), 2000.00, 800.00);\n"
    sql += f"INSERT INTO produccion (orden_produccion_id, fecha_produccion, producto_id, cantidad_producida, costo_materia_prima, mano_de_obra, destino_id) VALUES ((SELECT id FROM orden_produccion WHERE numero_orden='{op_num}'), '{end_date}', 1, 20, 2000.00, 800.00, (SELECT id FROM destino_produccion LIMIT 1));\n"

    # Ventas iterativas
    while total_ventas < target:
        sale_date = f"2025-{month:02d}-{day:02d}"
        
        prod = random.choice(products)
        qty = random.randint(1, 5)
        
        if total_ventas + (prod[2]*qty) > target + 500: 
            qty = 1
            
        subtotal = prod[2] * qty
        total_ventas += subtotal
        
        sql += f"WITH v AS (INSERT INTO venta (fecha, cliente_id, tipo_venta_id, usuario_id) VALUES ('{sale_date}', (SELECT id FROM cliente ORDER BY random() LIMIT 1), (SELECT id FROM tipo_venta WHERE nombre='Contado'), (SELECT id FROM usuario LIMIT 1)) RETURNING id) "
        sql += f"INSERT INTO detalle_venta (venta_id, producto_id, cantidad, precio_unitario) SELECT id, {prod[0]}, {qty}, {prod[2]} FROM v;\n"
        
        sql += f"INSERT INTO movimiento_caja (caja_id, fecha, tipo, concepto, monto, metodo_pago, referencia_tabla) VALUES ((SELECT id FROM caja WHERE fecha_apertura='{start_date}' ORDER BY id DESC LIMIT 1), '{sale_date}'::timestamptz, 'ingreso', 'Venta {prod[1]}', {subtotal}, 'efectivo', 'venta');\n"
        
        day += 1
        if day > last_day:
            day = 1
            
    # Cierre de Caja
    sql += f"UPDATE caja SET estado='cerrada', fecha_cierre='{end_date}', total_ingresos=(SELECT COALESCE(SUM(monto),0) FROM movimiento_caja WHERE caja_id=caja.id AND tipo='ingreso'), total_egresos=(SELECT COALESCE(SUM(monto),0) FROM movimiento_caja WHERE caja_id=caja.id AND tipo='egreso'), saldo_final=saldo_inicial + (SELECT COALESCE(SUM(monto),0) FROM movimiento_caja WHERE caja_id=caja.id AND tipo='ingreso') - (SELECT COALESCE(SUM(monto),0) FROM movimiento_caja WHERE caja_id=caja.id AND tipo='egreso') WHERE fecha_apertura='{start_date}';\n\n"

with open(os.path.join(base_dir, 'datos_historicos_2025.sql'), 'w', encoding='utf-8') as f:
    f.write(sql)

print("2025 History SQL Generated!")
