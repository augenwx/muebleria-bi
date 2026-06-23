-- ============================================================
-- 2_G_pasos.sql  — v4.0
-- VISTA INTERMEDIA PARA POBLAR fact_ventas
-- Compatible con el nuevo esquema marts (antes: esquema estrella)
--
-- CAMBIOS respecto a versión anterior:
--   - Esquema cambiado de 'estrella' a 'marts'
--   - Usa tablas dim_* en lugar de D* (e.g. dim_producto en vez de DPRODUCTO)
--   - Columnas de salida alineadas con fact_ventas del dbt:
--     detalle_venta_id, tiempo_key, cliente_id, producto_id,
--     tipo_venta_id, usuario_id, venta_id_oltp, cantidad,
--     precio_unitario, subtotal, costo_estandar, costo_total,
--     margen_bruto, pct_margen
--   - Ya no calcula alquiler prorrateado ni devoluciones
--     (simplificación alineada con el modelo dbt)
-- ============================================================

SET search_path TO marts, transaccional, public;

DROP VIEW IF EXISTS vw_fact_ventas_prep CASCADE;

CREATE OR REPLACE VIEW vw_fact_ventas_prep AS
SELECT
    -- PK
    dv.id                                                AS detalle_venta_id,

    -- FK dimensional: tiempo
    dt.fecha_key                                         AS tiempo_key,

    -- FKs dimensionales directas
    v.cliente_id,
    dv.producto_id,
    v.tipo_venta_id,
    v.usuario_id,

    -- Referencia OLTP
    v.id                                                 AS venta_id_oltp,

    -- Métricas de venta
    dv.cantidad,
    dv.precio_unitario,
    dv.subtotal,

    -- Métricas de costo y margen
    p.costo_estandar,
    ROUND(p.costo_estandar * dv.cantidad, 2)             AS costo_total,

    ROUND(dv.subtotal - (p.costo_estandar * dv.cantidad), 2)
                                                         AS margen_bruto,

    CASE WHEN dv.subtotal > 0
         THEN ROUND(
             ((dv.subtotal - (p.costo_estandar * dv.cantidad))
              / dv.subtotal) * 100, 2)
         ELSE 0
    END                                                  AS pct_margen

FROM detalle_venta     dv
-- cabecera de venta
JOIN venta             v   ON v.id   = dv.venta_id
-- producto (para costo_estandar)
JOIN producto          p   ON p.id   = dv.producto_id
-- dimensión tiempo
JOIN dim_tiempo        dt  ON dt.fecha = v.fecha;

-- Validación rápida: ver 5 filas
SELECT * FROM vw_fact_ventas_prep LIMIT 5;

-- ============================================================
-- FIN 2_G_pasos.sql
-- ============================================================