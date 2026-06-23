# Unidad 1 - Requerimientos BI y Modelado Dimensional

## 1. Problema de negocio

La empresa analizada fabrica y vende muebles de melamina como roperos, reposteros, comodas, veladores y comodines. Su operacion combina produccion para stock y pedidos especiales, pero el control historico se realizaba de forma manual con Excel, cuadernos y registros dispersos.

El principal problema es la falta de visibilidad sobre la rentabilidad real de los lotes de produccion, especialmente del ropero, identificado desde la Unidad 1 como producto estrella. Esta situacion se agrava por una gestion limitada de inventarios, compras de melamina no siempre alineadas con demanda real, estacionalidad sin capacidad predictiva y acumulacion de recortes o material sobrante.

| Elemento | Descripcion |
| --- | --- |
| Contexto | Fabricacion y venta de muebles de melamina con modelo mixto: stock y pedidos especiales |
| Dolor principal | Gestion manual de ventas, costos, inventario y produccion |
| Producto critico | Ropero |
| Riesgo operativo | Stock ocioso, compras urgentes de melamina, desperdicio y margen no medido |
| Areas involucradas | Gestion Comercial, Operaciones, Almacen y Finanzas |

## 2. Decisiones a mejorar

| Decision | Impacto esperado |
| --- | --- |
| Optimizar compras de melamina y accesorios segun demanda real | Reducir sobrestock, urgencias de compra y capital inmovilizado |
| Programar produccion segun estacionalidad y capacidad | Evitar quiebres de stock y acumulacion de producto terminado |
| Ajustar precios con base en costos reales | Proteger margen por producto y canal |
| Evaluar rentabilidad retail vs mayorista | Priorizar clientes y condiciones comerciales mas convenientes |
| Controlar material sobrante | Transformar recortes en productos complementarios o reducir desperdicio |

## 3. Objetivo analitico

Analizar la rentabilidad por categoria de producto, eficiencia en el uso de insumos frente a la demanda estacional y desempeno de canales de venta retail y mayorista.

## 4. Preguntas clave

| Pregunta | KPI relacionado | Usuario |
| --- | --- | --- |
| Cual es el margen real del ropero considerando desperdicio de melamina y mano de obra eventual? | Margen de utilidad por lote | Gerente General |
| En que meses la demanda mayorista supera la capacidad de stock disponible? | Rotacion de inventario | Encargado de ventas |
| Cuanto material sobrante se acumula sin transformar? | Indice de desperdicio de melamina | Jefe de Taller |
| Cual es la rentabilidad comparativa entre retail y mayorista? | Margen por canal | Gerente General |
| Cuantos recursos se invierten en produccion frente a la venta real? | Costo de produccion vs venta | Finanzas |

## 5. Matriz de requerimientos BI

| Stakeholder | KPI | Proceso | Fuente original |
| --- | --- | --- | --- |
| Gerente General | Margen de utilidad por lote | Finanzas / Produccion | Excel costos / cuaderno ventas |
| Jefe de Taller | Indice de desperdicio de melamina | Almacen / Produccion | Notas de corte manuales |
| Encargado de Ventas | Rotacion de stock de roperos | Ventas / Almacen | Excel ventas |
| Gerente General | Cumplimiento de pedidos especiales | Ventas / Despacho | Cuaderno de pedidos |

## 6. KPIs definidos en Unidad 1

| Indicador | Definicion | Formula de negocio | Frecuencia | Usuario |
| --- | --- | --- | --- | --- |
| Margen de utilidad por lote | Ganancia obtenida por lote despues de restar costos totales | `(Ingresos del lote - Costos del lote) / Ingresos del lote * 100` | Por lote / mensual | Gerente General |
| Indice de desperdicio de melamina | Porcentaje de material desperdiciado en corte | `Material sobrante / Material total usado * 100` | Diario / semanal | Jefe de Taller |
| Rotacion de inventario de roperos | Veces que el stock se vende en un periodo | `Ventas / Inventario promedio` | Mensual | Encargado de ventas |
| Cumplimiento de pedidos especiales | Pedidos entregados a tiempo sobre pedidos pactados | `Pedidos a tiempo / Total pedidos * 100` | Semanal | Gerente General |

## 7. Matriz objetivo-indicador

| Objetivo | Subobjetivo | Indicadores asociados |
| --- | --- | --- |
| Mejorar la rentabilidad de la produccion | Optimizar costos reales por lote | Margen de utilidad por lote, indice de desperdicio |
| Incrementar margen del ropero | Monitorear rentabilidad por lote y canal | Margen de utilidad por lote, rotacion de inventario |
| Administrar recursos e inventario | Controlar stock de roperos y productos derivados | Rotacion de inventario |
| Optimizar plan de compra de melamina | Ajustar compra segun demanda estacional | Indice de desperdicio, rotacion |
| Mejorar nivel de servicio | Cumplir pedidos especiales en fecha pactada | Cumplimiento de pedidos especiales |

## 8. Modelo dimensional propuesto en Unidad 1

| Proceso | Medidas | Dimensiones |
| --- | --- | --- |
| Ventas | Ventas S/, cantidad vendida, margen por lote | Tiempo, Producto, Canal Venta, Cliente |
| Produccion | Costos de lote, material usado, material sobrante | Tiempo, Producto, Lote Produccion, Material, Trabajador |
| Compras / Inventario | Cantidad comprada, stock, costo material | Tiempo, Material, Producto |
| Costos / Gastos | Gastos, costo de mano de obra, costo indirecto | Tiempo, Tipo Gasto, Trabajador |

## 9. Tablas candidatas del modelo inicial

| Tabla | Tipo | Descripcion | Claves |
| --- | --- | --- | --- |
| `HVENTAS` | Hecho | Transacciones de venta por producto, cliente y periodo | FK: fecha, producto, cliente, tipo venta, canal |
| `HPRODUCCION` | Hecho | Produccion por lote y uso de materiales | FK: fecha, producto, lote, material |
| `HCOMPRAS_MATERIAL` | Hecho | Compra e inventario de materia prima | FK: fecha, material, proveedor |
| `HGASTOS_MES` | Hecho | Gastos operativos por periodo y categoria | FK: fecha, categoria gasto |
| `DTIEMPO` | Dimension | Calendario de analisis | PK: fecha |
| `DPRODUCTO` | Dimension | Catalogo de muebles | PK: producto |
| `DCLIENTE` | Dimension | Clientes retail y mayoristas | PK: cliente |
| `DMATERIAL` | Dimension | Melamina y accesorios | PK: material |

