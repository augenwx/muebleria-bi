# Solucion End-to-End de BI para la Optimizacion de Ventas, Produccion y Costos en Muebleria

## 1. Datos Generales del Proyecto

| Campo | Valor |
| --- | --- |
| Nombre del proyecto BI | Solucion End-to-End de BI para la Optimizacion de Ventas, Produccion y Costos en Muebleria |
| Autores | Grimaldo Arredondo Martinez y Jose Miguel Condo Huamani |
| Universidad | Universidad Peruana Union |
| Ciclo | 8 |
| Proceso de negocio analizado | Ventas, produccion, inventario de materiales, costos operativos y rentabilidad comercial |
| Fuente transaccional usada | PostgreSQL OLTP `muebleria_db`, puerto `5433`, esquema `transaccional` |
| Data Warehouse / DataMart | PostgreSQL DW `muebleria_dw`, puerto `5434`, esquemas `raw`, `staging` y `marts` |
| Transformacion | dbt, modelos en `transform/models/staging` y `transform/models/marts` |
| Modelo semantico y dashboard | Power BI, archivo `Powerbi/S4 Muebleria v1.pbix` |
| Rama de GitHub | Rama de trabajo del proyecto en el repositorio de entrega |
| Sitio MkDocs | Carpeta `docs/` generada en este repositorio |

## 2. Resumen Ejecutivo

El proyecto aborda una empresa de fabricacion y venta de muebles de melamina con productos como roperos, comodas, veladores y comodines. El negocio opera con un modelo mixto de produccion para stock y pedidos especiales, pero arrastra una gestion manual basada en Excel y cuadernos. Esto limita la visibilidad sobre ventas, costos, rentabilidad por producto, compras de melamina y uso real de materiales.

El problema critico identificado es la falta de control analitico sobre la rentabilidad real del ropero, considerado producto estrella. La empresa no solo necesita conocer cuanto vende, sino cuanto margen deja despues de considerar materia prima, mano de obra, stock ocioso, desperdicio de melamina y costos variables. Tambien existe una preocupacion operativa por compras de melamina y accesorios que no siempre se alinean con la demanda real, generando capital inmovilizado y posibles recortes sin transformacion en productos complementarios.

La solucion BI implementa una arquitectura de punta a punta: una base transaccional PostgreSQL, una capa raw en un Data Warehouse separado, transformaciones dbt para staging y marts, un modelo estrella orientado a ventas y un dashboard Power BI para analizar KPIs comerciales y de rentabilidad. Con el dataset deterministico de marzo 2026 usado en `data.xlsx` y en el script transaccional, se validan 31 transacciones, 109 unidades vendidas y S/ 40,730.00 de ventas totales.

El hallazgo comercial principal es que el ropero concentra S/ 29,130.00, equivalente al 71.52% de las ventas del periodo, con 39 unidades vendidas. La recomendacion es priorizar el control de costos y abastecimiento de melamina para roperos, monitorear mayoristas por su volumen de compra y mantener validaciones cruzadas entre SQL y Power BI para que las decisiones se basen en cifras reconciliadas.

## 3. Problema de Negocio y Objetivo Analitico

### 3.1 Problema de negocio heredado de U1

| Elemento | Descripcion |
| --- | --- |
| Area o proceso involucrado | Gestion Comercial, Produccion, Almacen y Finanzas |
| Problema identificado | Gestion manual de ventas, stock, costos de produccion, compras de melamina y rentabilidad por producto |
| Usuarios principales | Gerente General, Jefe de Taller, Encargado de Ventas y Finanzas |
| Decisiones que se buscan mejorar | Compra de melamina, programacion de produccion, precios por canal, evaluacion de rentabilidad retail vs mayorista |
| Impacto esperado | Reducir stock ocioso, mejorar margen, anticipar demanda estacional y controlar desperdicio de material |

### 3.2 Objetivo analitico

Analizar la rentabilidad por categoria y producto, la eficiencia en el uso de insumos frente a la demanda estacional y el desempeno de los canales de venta retail y mayorista, usando un DataMart validado y consumido desde Power BI.

### 3.3 Matriz de preguntas de negocio

| Pregunta de negocio | KPI relacionado | Usuario | Pestaña / visual Power BI |
| --- | --- | --- | --- |
| Cual es el margen real del ropero considerando costos de materia prima y mano de obra? | Margen Total, Margen Bruto %, Costo Total | Gerente General | DAX |
| Que productos concentran la mayor venta y contribucion? | Total Ventas, Cantidad Unidades, Margen Total | Encargado de Ventas | Detalle Producto |
| Como se comportan las ventas por periodo y temporada? | Total Ventas, Ventas Año Anterior, Variacion YoY | Gerente General | OLAP |
| Que segmento aporta mas ingresos: retail o mayorista? | Total Ventas por Tipo Cliente, Ticket Promedio | Finanzas / Ventas | Detalle Cliente |
| Existe simetria entre SQL del Data Warehouse y Power BI? | Diferencia %, Error de Reconciliacion | Equipo BI | TT Ventas |

### 3.4 KPIs base del periodo validado

| KPI | Valor real del dataset base | Fuente |
| --- | ---: | --- |
| Ventas totales | S/ 40,730.00 | `data.xlsx` hoja `venta` y `OLTP-Postgre/base_datos_transaccional.sql` |
| Transacciones | 31 | Filas de venta marzo 2026 |
| Unidades vendidas | 109 | Suma de `cantidad` |
| Ticket promedio por transaccion | S/ 1,313.87 | S/ 40,730.00 / 31 |
| Costo material total estandar | S/ 7,475.00 | `cantidad * costo_estandar` |
| Margen de contribucion | S/ 33,255.00 | `importetotal - costomattotal - costomototal` |
| Margen de contribucion % | 81.65% | S/ 33,255.00 / S/ 40,730.00 |
| Gastos operativos Excel | S/ 23,970.00 | `data.xlsx` hoja `gastos mes` |

