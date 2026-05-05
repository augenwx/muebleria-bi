## 1. datawarehouse Airbyte
Implementación de una réplica batch desde un sistema transaccional PostgreSQL hacia un Data Warehouse en PostgreSQL usando Airbyte.

## 2. Objetivo
Configurar y validar una réplica automática desde la base transaccional `muebleria_db` hacia la capa `raw` de la base `muebleria_dw`, utilizando Airbyte (abctl) sobre Kubernetes local.

Al finalizar la sesión, el alumno debe poder:
- Levantar el origen OLTP y el destino DW en contenedores separados.
- Acceder al panel de Airbyte local.
- Crear un *Source* de PostgreSQL apuntando al puerto 5433.
- Crear un *Destination* de PostgreSQL apuntando al puerto 5434.
- Construir una conexión de réplica para las tablas de la mueblería.
- Ejecutar una sincronización inicial y validar los datos en el esquema `raw`.

## 3. Herramientas utilizadas
- Docker Desktop
- Airbyte (abctl / local Kubernetes)
- PostgreSQL 15 (OLTP)
- PostgreSQL 16 (DW)
- pgAdmin 4 / Terminal (CLI)

## 4. Entorno de trabajo
- **PostgreSQL Fuente (OLTP):** `localhost:5433`
- **PostgreSQL Destino (DW):** `localhost:5434`
- **Base fuente:** `muebleria_db` (Esquema: `transaccional`)
- **Base destino:** `muebleria_dw` (Esquema de aterrizaje: `raw`)
- **Airbyte local:** `http://localhost:8000`

**Credenciales:**
- **Usuario:** `admin`
- **Contraseña:** `password123`

## 5. Flujo de la práctica
```text
PostgreSQL (muebleria_db.transaccional) -> Airbyte (host.docker.internal) -> PostgreSQL (muebleria_dw.raw)
```

## 6. Fundamento teórico breve
- **Source:** Origen que Airbyte lee (nuestro sistema de ventas).
- **Destination:** Destino donde Airbyte escribe (nuestro Data Warehouse).
- **Connection:** El "puente" configurado con frecuencia y reglas de negocio.
- **Sync (Full Refresh | Overwrite):** Modo de carga que borra el destino y lo reemplaza con la foto actual del origen.
- **Raw:** Capa inicial de la Arquitectura Medallón donde aterrizan los datos crudos.

## 7. Mapa del OLTP `muebleria_db`
Tablas fuente a sincronizar:

- **Hechos:** `venta`, `produccion`, `inventario`, `gasto_mes`
- **Dimensiones:** `producto`, `tipo_cliente`, `tipo_venta`, `destino_produccion`, `unidad_medida`, `categoria_gasto`

## 8. Desarrollo de la práctica

### 8.1 Levanta la infraestructura
Asegúrate de que tus contenedores están corriendo:

```bash
# En la carpeta del proyecto
docker compose up -d
docker compose ps
```

### 8.2 Verifica los Schemas en el DW

```bash
docker exec -it muebleria-dw-pg psql -U admin -d muebleria_dw -c "\dn"
```

Deberías ver: `raw`, `staging`, `marts`.

### 8.3 Configura el Source en Airbyte

- **Name:** `Postgre-Muebleria-db`
- **Host:** `host.docker.internal`
- **Port:** `5433`
- **Database:** `muebleria_db`
- **Schemas:** `transaccional` (Importante para que Airbyte vea las tablas)
- **Username/Password:** `admin / password123`
- **SSL:** `disable`

### 8.4 Configura el Destination en Airbyte

- **Name:** `Postgre-Muebleria-raw`
- **Host:** `host.docker.internal`
- **Port:** `5434`
- **Database:** `muebleria_dw`
- **Default Schema:** `raw`
- **Username/Password:** `admin / password123`

### 8.5 Crea la Conexión de réplica

- **Select Streams:** Selecciona las 10 tablas (omite las vistas `v_`)
- **Sync Mode:** `Incremental | Append + Deduped` (Recomendado para esta práctica inicial)
- **Frecuencia:** `Manual`

### 8.6 Ejecución y Validación

Haz clic en **Sync Now** en Airbyte.

Espera al estado **Succeeded**.

Verifica en el destino:

```sql
-- Ejecutar en el puerto 5434 (DW)
SELECT * FROM raw.venta LIMIT 10;
```
