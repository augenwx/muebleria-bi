-- Verifica que ninguna venta tenga margen negativo
-- (ventas a pérdida)

SELECT *
FROM {{ ref('fact_ventas') }}
WHERE margencontrib < 0
