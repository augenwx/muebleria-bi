# Mueblería BI

Proyecto de **Business Intelligence** orientado a optimizar la rentabilidad, la gestión de inventarios y la producción estacional en una empresa de fabricación y venta de muebles de melamina.

---

---

## Roadmap del Proyecto

```text
[FASE ACTUAL] PostgreSQL OLTP 
    -> [FUTURO] ETL (Manual / Herramientas como Airbyte)
    -> [FUTURO] PostgreSQL Data Warehouse (Modelo Estrella)
    -> [FUTURO] Power BI (Visualización)
```

---

## Arquitectura Objetivo

```mermaid
flowchart LR
    A[PostgreSQL OLTP<br/>muebleria] --> B[ETL<br/>Scripts SQL / Airbyte]
    B --> C[PostgreSQL DW<br/>Modelo Estrella]
    C --> D[Power BI<br/>Consumo Analítico]
```

---

## Estructura del Proyecto

```text
muebleria-bi/
├── oltp-postgres/
│   ├── base_datos_transaccional.sql
│   └── README.md
└── airbyte/  # (Pendiente de implementación)
```

---

## Configuración del Entorno

* **Motor de Base de Datos:** PostgreSQL
* **Base de Datos:** `muebleria`
* **Script inicial:** `base_datos_transaccional.sql`

---

## Modelo Transaccional (OLTP)

La base de datos está diseñada bajo principios de **normalización**, enfocada en soportar la operación diaria del negocio.

### Tablas de Catálogo

* `tipo_cliente`
* `tipo_venta`
* `producto`
* `destino_produccion`
* `unidad_medida`
* `categoria_gasto`

### Tablas Transaccionales

* **venta:** Registro de productos vendidos por fecha, cliente y precio.
* **produccion:** Lotes fabricados con costos de materia prima y mano de obra.
* **inventario:** Compras de insumos a proveedores.
* **gasto_mes:** Gastos operativos fijos y variables.

---
