# Metricas DAX y Visualizacion

## 9. Metricas del negocio e implementacion DAX

Las medidas DAX se derivan de `fact_ventas` para mantener simetria con las consultas SQL del Data Warehouse.

```dax
Total Ventas :=
SUM(fact_ventas[importetotal])
```

Mide los ingresos totales. Para el dataset base validado debe devolver S/ 40,730.00.

```dax
Cantidad Unidades :=
SUM(fact_ventas[cantidad])
```

Mide el volumen total vendido. Para marzo 2026 debe devolver 109 unidades.

```dax
Cantidad Transacciones :=
COUNTROWS(fact_ventas)
```

Cuenta las filas de venta cargadas al DataMart. Para la carga base debe devolver 31.

```dax
Margen Bruto :=
SUM(fact_ventas[margencontrib])
```

Agrega el margen calculado desde dbt como venta menos costo material y mano de obra.

```dax
Margen Bruto % :=
DIVIDE(
    [Margen Bruto],
    [Total Ventas],
    0
)
```

Devuelve el porcentaje de margen sobre ventas. Con el costo estandar del mart base equivale a 81.65%.

```dax
Ticket Promedio :=
DIVIDE(
    [Total Ventas],
    [Cantidad Transacciones],
    0
)
```

Permite evaluar el ingreso promedio por transaccion. Para la carga base es S/ 1,313.87.

```dax
Costo Total :=
SUM(fact_ventas[costomattotal])
    + SUM(fact_ventas[costomototal])
```

Consolida costos directos de material y mano de obra registrados en el DataMart.

```dax
Ventas Año Anterior :=
CALCULATE(
    [Total Ventas],
    SAMEPERIODLASTYEAR(dim_fecha[fecha])
)
```

Sirve para comparativos YoY cuando se carga el script `OLTP-Postgre/4_simular_ventas_2025.sql`.

```dax
Variacion Ventas YoY % :=
DIVIDE(
    [Total Ventas] - [Ventas Año Anterior],
    [Ventas Año Anterior],
    0
)
```

Mide la variacion porcentual de ventas frente al mismo periodo del ano anterior.

## 10. Dashboard interactivo

### 10.1 Objetivo analitico del dashboard

El dashboard permite monitorear ventas, unidades, margen, clientes y productos para decidir compras de melamina, priorizacion de produccion, precios por canal y control de rentabilidad.

### 10.2 Pestañas diseñadas

| Pestaña | Objetivo | Componentes esperados | Captura |
| --- | --- | --- | --- |
| DAX | Validar KPIs principales y medidas de negocio | Tarjetas de Total Ventas, Unidades, Margen Bruto %, Ticket Promedio y Costo Total | `docs/assets/dashboard_dax.png` |
| OLAP | Analizar ventas por jerarquia temporal | Matriz Año > Trimestre > Mes > Dia, grafico de tendencia y comparativo YoY | `docs/assets/dashboard_olap.png` |
| Detalle Producto | Identificar productos de mayor venta y margen | Ranking de productos, barras por ventas, tabla de unidades y margen | `docs/assets/dashboard_detalle_producto.png` |
| Detalle Cliente | Evaluar clientes y segmentos retail/mayorista | Ventas por cliente, tipo cliente, canal y ticket promedio | `docs/assets/dashboard_detalle_cliente.png` |
| TT Ventas | Control tabular y reconciliacion | Tabla de ventas, importes, costos, margen y filtros por fecha/producto/cliente | `docs/assets/dashboard_tt_ventas.png` |

### 10.3 Lectura ejecutiva de la carga base

| Indicador | Valor |
| --- | ---: |
| Producto lider | Ropero |
| Ventas de Ropero | S/ 29,130.00 |
| Participacion de Ropero | 71.52% |
| Segmento retail | S/ 26,800.00 |
| Segmento mayorista | S/ 13,930.00 |
| Ventas contado | S/ 32,640.00 |
| Ventas credito | S/ 8,090.00 |

