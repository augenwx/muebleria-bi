# Calidad y Control de Datos

## 11. Validacion multinivel y calidad de datos

La validacion se plantea en cuatro niveles: origen transaccional, transformacion dbt, DataMart y Power BI. El objetivo es demostrar que las cifras de negocio conservan simetria entre SQL y visualizacion, especialmente ventas, unidades, transacciones y margen.

## 11.1 Estrategia de reconciliacion financiera

1. Comparar conteo de ventas OLTP contra `marts.fact_ventas`.
2. Comparar suma de `total_venta` OLTP contra suma de `importetotal` en DW.
3. Comparar unidades vendidas OLTP contra `SUM(cantidad)` en DW.
4. Recalcular margen desde `importetotal - costomattotal - costomototal`.
5. Repetir los mismos KPIs en Power BI con DAX y exigir diferencia 0.00%.

## 11.2 Consultas SQL de validacion

```sql
SELECT
    COUNT(*) AS transacciones,
    SUM(cantidad) AS unidades,
    SUM(total_venta) AS ventas_totales
FROM transaccional.venta
WHERE fecha BETWEEN DATE '2026-03-01' AND DATE '2026-03-31';
```

```sql
SELECT
    COUNT(*) AS transacciones,
    SUM(cantidad) AS unidades,
    SUM(importetotal) AS ventas_totales,
    SUM(costomattotal) AS costo_material,
    SUM(margencontrib) AS margen_total,
    ROUND(SUM(margencontrib) / NULLIF(SUM(importetotal), 0) * 100, 2) AS pct_margen
FROM marts.fact_ventas
WHERE idfecha BETWEEN 20260301 AND 20260331;
```

```sql
SELECT
    p.dsproducto,
    SUM(f.cantidad) AS unidades,
    SUM(f.importetotal) AS ventas,
    SUM(f.margencontrib) AS margen
FROM marts.fact_ventas f
JOIN marts.dim_producto p ON p.idproducto = f.idproducto
GROUP BY p.dsproducto
ORDER BY ventas DESC;
```

## 11.3 Matriz de validacion cruzada

| Control | Query SQL Data Warehouse | Valor SQL esperado | Valor Power BI esperado | Diferencia | Error |
| --- | --- | ---: | ---: | ---: | ---: |
| Ventas totales | `SUM(importetotal)` | S/ 40,730.00 | S/ 40,730.00 | S/ 0.00 | 0.00% |
| Cantidad de transacciones | `COUNT(*)` | 31 | 31 | 0 | 0.00% |
| Unidades vendidas | `SUM(cantidad)` | 109 | 109 | 0 | 0.00% |
| Costo material total | `SUM(costomattotal)` | S/ 7,475.00 | S/ 7,475.00 | S/ 0.00 | 0.00% |
| Margen de contribucion | `SUM(margencontrib)` | S/ 33,255.00 | S/ 33,255.00 | S/ 0.00 | 0.00% |
| Margen contribucion % | `SUM(margencontrib) / SUM(importetotal)` | 81.65% | 81.65% | 0.00 pp | 0.00% |
| Ventas Ropero | filtro `dsproducto = 'Ropero'` | S/ 29,130.00 | S/ 29,130.00 | S/ 0.00 | 0.00% |
| Ventas Retail | filtro `tipocliente = 'Retail'` | S/ 26,800.00 | S/ 26,800.00 | S/ 0.00 | 0.00% |
| Ventas Mayorista | filtro `tipocliente = 'Mayorista'` | S/ 13,930.00 | S/ 13,930.00 | S/ 0.00 | 0.00% |

## 11.4 Controles dbt

| Control | Tabla / campo | Regla | Resultado esperado |
| --- | --- | --- | --- |
| Unicidad | `dim_fecha.idfecha` | Sin duplicados | `unique` |
| Completitud | `dim_fecha.idfecha` | No nulo | `not_null` |
| Unicidad | `dim_producto.idproducto` | Sin duplicados | `unique` |
| Completitud | `fact_ventas.importetotal` | No nulo | `not_null` |
| Integridad referencial | `fact_ventas.idproducto` | Existe en `dim_producto` | `relationships` |
| Integridad referencial | `fact_ventas.idcliente` | Existe en `dim_cliente` | `relationships` |
| Integridad referencial | `fact_ventas.idfecha` | Existe en `dim_fecha` | `relationships` |
| Margen positivo | `fact_ventas.margencontrib` | `margencontrib >= 0` | `assert_positive_margen.sql` |

## 11.5 Nota de consistencia de fuentes

El archivo `data.xlsx` y el script transaccional coinciden en ventas: 31 transacciones, 109 unidades y S/ 40,730.00. La hoja `gastos mes` del Excel registra S/ 23,970.00 de gastos, mientras que el SQL transaccional registra S/ 16,470.00 por tener `Compra Melamina y accesorios` en S/ 5,240.00. Para validacion financiera de ventas se usa la fuente coincidente OLTP/DataMart/Power BI; para analisis de gastos debe elegirse una unica fuente oficial antes de publicar margen operativo.
