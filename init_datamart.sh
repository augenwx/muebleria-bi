#!/bin/bash
# =============================================================
# init_datamart.sh
# Ejecuta los 4 scripts SQL en el orden correcto dentro del
# contenedor Docker. Corre esto desde la carpeta del proyecto.
# =============================================================

CONTAINER="postgres_bi"
DB="muebleria_db"
USER="admin"

echo ">>> [1/5] Creando esquemas transaccional y estrella..."
docker exec -it $CONTAINER psql -U $USER -d $DB -c "
  CREATE SCHEMA IF NOT EXISTS transaccional;
  CREATE SCHEMA IF NOT EXISTS estrella;
  SET search_path TO estrella, transaccional, public;
"

echo ">>> [2/5] Cargando base transaccional..."
docker exec -it $CONTAINER psql -U $USER -d $DB \
  -v ON_ERROR_STOP=1 \
  -f /scripts/base_datos_transaccional.sql

echo ">>> [3/5] Creando estructura del DataMart (DDL)..."
docker exec -it $CONTAINER psql -U $USER -d $DB \
  -v ON_ERROR_STOP=1 \
  -f /scripts/1_dm.sql

echo ">>> [4/5] Creando Vista G (logica analitica)..."
docker exec -it $CONTAINER psql -U $USER -d $DB \
  -v ON_ERROR_STOP=1 \
  -f /scripts/2_G_pasos.sql

echo ">>> [5/5] Poblando dimensiones y hechos (ETL)..."
docker exec -it $CONTAINER psql -U $USER -d $DB \
  -v ON_ERROR_STOP=1 \
  -f /scripts/3_poblar.sql

echo ""
echo "=== DataMart listo. Verificacion rapida ==="
docker exec -it $CONTAINER psql -U $USER -d $DB -c "
  SET search_path TO estrella, transaccional, public;
  SELECT 'HVENTAS'           AS tabla, COUNT(*) AS filas FROM HVENTAS
  UNION ALL
  SELECT 'HPRODUCCION',                COUNT(*)          FROM HPRODUCCION
  UNION ALL
  SELECT 'HCOMPRAS_MATERIAL',          COUNT(*)          FROM HCOMPRAS_MATERIAL
  UNION ALL
  SELECT 'HGASTOS_MES',                COUNT(*)          FROM HGASTOS_MES;
"
