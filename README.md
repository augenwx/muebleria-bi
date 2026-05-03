Mueblería BI
Proyecto de Business Intelligence para optimizar la rentabilidad, la gestión de inventarios y la producción estacional de una empresa de fabricación y venta de muebles de melamina.

Flujo general del proyecto
Actualmente el proyecto se encuentra en la Fase 1 (Origen Transaccional). El roadmap completo planificado es el siguiente:

Plaintext
[FASE ACTUAL] PostgreSQL OLTP -> [FUTURO] ETL Manual / Herramientas -> [FUTURO] PostgreSQL DW -> [FUTURO] Power BI
Arquitectura global planificada
Aunque actualmente estamos en la base transaccional, la visión a futuro del flujo de datos es esta:

Fragmento de código
flowchart LR
    A[PostgreSQL OLTP<br/>muebleria] --> B[ETL<br/>Scripts SQL]
    B --> C[PostgreSQL DW<br/>Modelo Estrella]
    C --> D[Power BI<br/>Consumo analitico]
Estructura del proyecto
Por el momento, la estructura refleja la etapa inicial del sistema:

Plaintext
muebleria-bi/
├── oltp-postgres/
│   ├── base_datos_transaccional.sql
│   └── README.md
└── arbyte
Configuración clave del entorno
Motor de Base de Datos: PostgreSQL

Nombre de la Base de Datos: muebleria

Script de Inicialización: base_datos_transaccional.sql

Estructura del Modelo Transaccional (OLTP)
La base de datos está normalizada para la operación diaria de la carpintería y se divide en dos grandes grupos. Las Tablas de Catálogo definen las entidades de negocio. Incluyen tipo_cliente, tipo_venta, producto, destino_produccion, unidad_medida y categoria_gasto.

Las tablas transaccionales registran los eventos del día a día:


venta: Registro individual de productos vendidos por fecha, cliente y precio.


produccion: Lotes fabricados con sus costos de materia prima y mano de obra.


inventario: Compras de insumos a proveedores.


gasto_mes: Registro de gastos operativos fijos y variables.