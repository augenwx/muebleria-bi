# Unidad 2 - DataMart, Pipeline BI y Modelo Semantico

## 1. Datos generales de la Unidad 2

| Campo | Valor |
| --- | --- |
| Documento base | `PLANTILLA - ENTREGABLE UNIDAD 2` |
| Proyecto | Implementacion de Data Mart Analitico para Muebleria |
| Autores | Grimaldo Arredondo Martinez y Jose Miguel Condo Huamani |
| Docente | Abel Angel Sullon Macalupu |
| Universidad | Universidad Peruana Union |
| Ciclo | 8 |
| Repositorio | `https://github.com/augenwx/muebleria-bi.git` |

## 2. Contexto heredado de Unidad 1

La Unidad 2 parte del problema definido en Unidad 1: desconexion entre planificacion de produccion y demanda real. El ropero mantiene un rol central por su margen y peso comercial, pero su rotacion variable genera riesgo de stock ocioso. La compra de melamina tambien requiere planificacion basada en demanda historica y estacionalidad.

| Decision buscada | Descripcion |
| --- | --- |
| Optimizar stock terminado | Evitar capital inmovilizado en tienda fisica |
| Planificar compras de melamina | Considerar estacionalidad de septiembre, octubre y diciembre |
| Separar operacion y analitica | Evitar que Power BI consulte la base transaccional en vivo |
| Automatizar pipeline | Pasar de scripts manuales a Airbyte/dbt |

## 3. Sesion 6 - Implementacion manual del DataMart

### 3.1 Diseño fisico inicial

| Tabla DataMart | Tipo | Descripcion | PK | FK |
| --- | --- | --- | --- | --- |
| `fact_ventas` | Hecho | Lineas de detalle de ventas realizadas | `detalle_venta_id` | `tiempo_key`, `cliente_id`, `producto_id`, `tipo_venta_id`, `usuario_id` |
| `dim_tiempo` | Dimension | Calendario para analisis temporal | `fecha_key` | - |
| `dim_cliente` | Dimension | Clientes retail y mayoristas | `cliente_id` | - |
| `dim_producto` | Dimension | Catalogo de muebles, precios y costos | `producto_id` | - |
| `dim_tipo_venta` | Dimension | Modalidad de transaccion | `tipo_venta_id` | - |
| `dim_usuario` | Dimension | Empleado o vendedor que registra la venta | `usuario_id` | - |

### 3.2 Script de tabla de hechos documentado

```sql
CREATE TABLE marts.fact_ventas (
    detalle_venta_id BIGINT PRIMARY KEY,
    tiempo_key       INT    NOT NULL REFERENCES marts.dim_tiempo(fecha_key),
    cliente_id       BIGINT REFERENCES marts.dim_cliente(cliente_id),
    producto_id      BIGINT REFERENCES marts.dim_producto(producto_id),
    tipo_venta_id    BIGINT REFERENCES marts.dim_tipo_venta(tipo_venta_id),
    usuario_id       BIGINT REFERENCES marts.dim_usuario(usuario_id),
    venta_id_oltp    BIGINT,
    cantidad         BIGINT,
    precio_unitario  NUMERIC,
    subtotal         NUMERIC,
    costo_estandar   NUMERIC,
    costo_total      NUMERIC,
    margen_bruto     NUMERIC,
    pct_margen       NUMERIC
);
```

### 3.3 ETL manual por fases

| Fase | Descripcion | Entidades origen | Entidades destino | Reglas clave |
| --- | --- | --- | --- | --- |
| Extraccion | Lectura de entidades operativas | `venta`, `detalle_venta`, `producto`, `cliente` | Vista o capa preparatoria | Joins para evitar lineas huerfanas |
| Transformacion | Limpieza, casteo y calculos de negocio | Datos crudos extraidos | `vw_fact_ventas_prep` | `tiempo_key`, margen bruto, `CASE WHEN` para evitar division por cero |
| Carga dimensiones | Poblamiento de catalogos | OLTP desnormalizado | `dim_cliente`, `dim_producto`, `dim_tiempo`, `dim_tipo_venta`, `dim_usuario` | `INSERT INTO ... SELECT DISTINCT`, idempotencia |
| Carga hechos | Insercion de transacciones consolidadas | Vista preparatoria | `fact_ventas` | Grano minimo: articulo vendido en una orden |

### 3.4 Evidencia de carga manual

| Tabla | Registros esperados | Registros cargados | Observacion |
| --- | ---: | ---: | --- |
| `dtiempo` / `dim_fecha` | 28 | 28 | Rango temporal historico evaluado |
| `dproducto` / `dim_producto` | 4 | 4 | Ropero, Comoda, Velador, Comodin |
| `dcliente` / `dim_cliente` | 4 | 4 | Clientes mayoristas y minoristas |
| `hventas` / `fact_ventas` | 31 | 31 | Transacciones historicas consolidadas |

## 4. Sesion 7 - Pipeline BI con herramientas

### 4.1 Arquitectura implementada

| Componente | Motor / herramienta | Servicio | Rol |
| --- | --- | --- | --- |
| BD origen OLTP | PostgreSQL | Docker, puerto 5433 | Sistema transaccional de la muebleria |
| Ingesta | Airbyte | UI puerto 8000 | Replicacion de datos crudos |
| BD destino DW | PostgreSQL | Docker, puerto 5434 | Base analitica con `raw`, `staging`, `marts` |
| Transformacion | dbt CLI | Entorno local | Limpieza, tests y modelado SQL |
| Consumo BI | Power BI | Desktop | Modelo semantico, DAX y dashboards |

### 4.2 Estrategia de ingesta

| Origen | Destino | Herramienta | Modo | Estado documentado |
| --- | --- | --- | --- | --- |
| PostgreSQL OLTP, tablas maestras | PostgreSQL DW, esquema `raw` | Airbyte | Full Refresh - Overwrite | OK |
| PostgreSQL OLTP, tablas transaccionales | PostgreSQL DW, esquema `raw` | Airbyte | Incremental - Append | OK |

### 4.3 Evidencias de Airbyte

| Elemento | Evidencia documentada | Estado |
| --- | --- | --- |
| Source OLTP | Conector Postgres apuntando al esquema transaccional | Aprobado |
| Destination DW | Destino PostgreSQL hacia esquema `raw` | Aprobado |
| Frecuencia | Replication frequency diaria | Aprobado |
| Resultado | Tablas sincronizadas en verde | Aprobado |
| Carga incremental / CDC | Captura de ventas nuevas sin reprocesar todo el historico | Aprobado |

## 5. Transformacion con dbt

### 5.1 Artefactos principales

| Artefacto | Funcion |
| --- | --- |
| `sources.yml` | Declara tablas crudas inyectadas en `raw` y habilita `{{ source() }}` |
| Modelos staging | Renombrado, casteo, limpieza y estandarizacion |
| Modelos marts | Materializacion fisica del modelo estrella |
| Tests dbt | `unique`, `not_null`, `relationships` y pruebas personalizadas |
| Documentacion dbt | Diccionario tecnico automatizado |

### 5.2 Transformaciones staging

| Modelo | Origen | Transformacion | Justificacion |
| --- | --- | --- | --- |
| `stg_ventas` | `raw.venta` y `raw.detalle_venta` | Renombrado, casteo de fecha, llave temporal | Preparar transacciones para calculos |
| `stg_productos` | `raw.producto` | Casteo numerico, `COALESCE`, estandarizacion | Evitar errores de margen por nulos |
| `stg_clientes` | `raw.cliente` | `TRIM`, unificacion de razon social, filtros | Evitar duplicados o slicers vacios |
| `stg_tiempo` | Calendario | Dia, mes, trimestre, año | Jerarquias temporales consistentes |

### 5.3 Marts construidos

| Modelo marts | Tipo | Regla de negocio | KPI soportado |
| --- | --- | --- | --- |
| `dim_fecha` | Dimension | Jerarquia Año > Trimestre > Mes > Dia | Tendencia, MoM, YoY |
| `dim_producto` | Dimension | Catalogo de muebles y costo estandar | Ranking, margen por producto |
| `dim_cliente` | Dimension | Segmentacion cliente / canal | Ventas retail vs mayorista |
| `fact_ventas` | Hecho | Subtotal, costo total, margen bruto, `% margen` | Ventas, ticket promedio, rentabilidad |

### 5.4 Materializacion

| Modelo | Materializacion | Motivo |
| --- | --- | --- |
| Staging | `view` | Evita duplicar raw y aplica limpieza al consultar |
| Dimensiones marts | `table` | Mejor rendimiento para filtros frecuentes |
| `fact_ventas` | `table` o incremental futuro | Tabla central del analisis BI |

## 6. Validacion multinivel documentada en Unidad 2

| Nivel | Que se valida | Evidencia |
| --- | --- | --- |
| OLTP vs raw | Conservacion de registros y campos principales | Conteo de ventas replicadas |
| raw vs staging | Limpieza, renombrado y casteo sin perdida | Modelos dbt staging |
| staging vs marts | Respeto de llaves, grano y reglas de negocio | `dbt run`, `dbt test` |
| DataMart analitico | Agregaciones SQL confiables | `SUM(importetotal)`, `SUM(margencontrib)` |
| Power BI vs SQL | Medidas DAX iguales a SQL | Matriz de reconciliacion |

### 6.1 Controles de calidad

| Control | Tabla / campo | Regla | Resultado documentado |
| --- | --- | --- | --- |
| Completitud | `fact_ventas` | Llaves e importes no nulos | 0 nulos |
| Unicidad | `dim_producto`, `dim_cliente` | PK sin duplicados | 0 duplicados |
| Integridad referencial | FK de `fact_ventas` | Deben existir en dimensiones | 0 huerfanos |
| Consistencia | `importetotal`, `margencontrib` | Margenes economicamente coherentes | Test positivo |
| Rango valido | Fechas, precios y cantidades | Valores dentro de rango de negocio | Validado |

## 7. Sesion 8 - Modelo semantico y metricas BI

### 7.1 Conexion a Power BI

| Elemento | Descripcion |
| --- | --- |
| Motor | PostgreSQL en contenedor |
| Base de datos | `muebleria_dw`, puerto 5434 |
| Esquema | `marts` |
| Modo | Import para maximo rendimiento VertiPaq |
| Tablas | `fact_ventas`, `dim_tiempo`, `dim_producto`, `dim_cliente` |

### 7.2 Relaciones semanticas

| Dimension | Hecho | Campo dimension | Campo hecho | Cardinalidad | Direccion |
| --- | --- | --- | --- | --- | --- |
| `dim_tiempo` | `fact_ventas` | `fecha_key` | `tiempo_key` | 1:* | Unica |
| `dim_producto` | `fact_ventas` | `producto_id` | `producto_id` | 1:* | Unica |
| `dim_cliente` | `fact_ventas` | `cliente_id` | `cliente_id` | 1:* | Unica |

### 7.3 Medidas DAX documentadas

```dax
Total Ventas = SUM(fact_ventas[subtotal])
```

```dax
Total Unidades = SUM(fact_ventas[cantidad])
```

```dax
Margen = SUM(fact_ventas[margen_bruto])
```

```dax
% Margen = DIVIDE([Margen], [Total Ventas], 0)
```

## 8. Nota de control de cifras

El documento historico de Unidad 2 reporta una validacion Power BI vs SQL de S/ 41,510.00 en ventas, 111 unidades, S/ 15,945.00 de margen y 38.41% de margen. La version actual del repositorio validada en `data.xlsx` y `OLTP-Postgre/base_datos_transaccional.sql` contiene 31 ventas, 109 unidades y S/ 40,730.00. Por trazabilidad, el sitio mantiene los valores actuales del repositorio en la pagina de validacion y conserva aqui los valores historicos de Unidad 2 como evidencia documental previa.

| Metrica historica Unidad 2 | Valor reportado |
| --- | ---: |
| Total Ventas | S/ 41,510.00 |
| Total Unidades | 111 |
| Margen | S/ 15,945.00 |
| Margen % | 38.41% |

## 9. Conclusiones de Unidad 2

| Pregunta | Respuesta sintetizada |
| --- | --- |
| El DataMart soporta los KPIs de Unidad 1? | Si, el modelo estrella permite calcular ingresos, margenes, rentabilidad y volumen sin joins complejos para el usuario final |
| Como se evidencia la separacion OLTP-DW? | Dos contenedores y puertos distintos: OLTP `5433`, DW `5434` |
| Que mejora Airbyte/dbt frente al ETL manual? | Menos codigo manual, escalabilidad, versionamiento y pruebas automatizadas |
| Que problemas de calidad se encontraron? | Espacios en blanco, formatos incorrectos, nulos y riesgos de consulta directa al OLTP |
| Coinciden Power BI y SQL? | El documento U2 reporta coincidencia exacta; la version actual del repositorio tambien documenta reconciliacion exacta con sus datos vigentes |
