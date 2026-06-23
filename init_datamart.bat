@echo off
set CONTAINER=postgres_bi
set DB=muebleria_db
set USER=admin

echo ^>^>^> [1/5] Creando esquemas transaccional y estrella...
docker exec %CONTAINER% psql -U %USER% -d %DB% -c "DROP SCHEMA IF EXISTS transaccional CASCADE; DROP SCHEMA IF EXISTS estrella CASCADE; DROP SCHEMA IF EXISTS marts CASCADE; CREATE SCHEMA transaccional; CREATE SCHEMA estrella; CREATE SCHEMA marts; SET search_path TO estrella, transaccional, marts, public;"

echo ^>^>^> [2/5] Cargando base transaccional y meses (2025 y Enero a Mayo 2026)...
docker exec %CONTAINER% psql -U %USER% -d %DB% -v ON_ERROR_STOP=1 -f /scripts/base_datos_transaccional.sql
docker exec %CONTAINER% psql -U %USER% -d %DB% -v ON_ERROR_STOP=1 -f /scripts/datos_historicos_2025.sql
docker exec %CONTAINER% psql -U %USER% -d %DB% -v ON_ERROR_STOP=1 -f /scripts/datos_enero_2026.sql
docker exec %CONTAINER% psql -U %USER% -d %DB% -v ON_ERROR_STOP=1 -f /scripts/datos_febrero_2026.sql
docker exec %CONTAINER% psql -U %USER% -d %DB% -v ON_ERROR_STOP=1 -f /scripts/datos_marzo_2026.sql
docker exec %CONTAINER% psql -U %USER% -d %DB% -v ON_ERROR_STOP=1 -f /scripts/datos_abril_2026.sql
docker exec %CONTAINER% psql -U %USER% -d %DB% -v ON_ERROR_STOP=1 -f /scripts/datos_mayo_2026.sql

echo ^>^>^> [3/5] Creando estructura del DataMart (DDL)...
docker exec %CONTAINER% psql -U %USER% -d %DB% -v ON_ERROR_STOP=1 -f /scripts/1_dm.sql

echo ^>^>^> [4/5] Creando Vista G (logica analitica)...
docker exec %CONTAINER% psql -U %USER% -d %DB% -v ON_ERROR_STOP=1 -f /scripts/2_G_pasos.sql

echo ^>^>^> [5/5] Poblando dimensiones y hechos (ETL)...
docker exec %CONTAINER% psql -U %USER% -d %DB% -v ON_ERROR_STOP=1 -f /scripts/3_poblar.sql

echo.
echo === DataMart listo. Verificacion rapida ===
docker exec -it %CONTAINER% psql -U %USER% -d %DB% -c "SET search_path TO estrella, transaccional, public; SELECT 'HVENTAS' AS tabla, COUNT(*) AS filas FROM HVENTAS UNION ALL SELECT 'HPRODUCCION', COUNT(*) FROM HPRODUCCION UNION ALL SELECT 'HCOMPRAS_MATERIAL', COUNT(*) FROM HCOMPRAS_MATERIAL UNION ALL SELECT 'HGASTOS', COUNT(*) FROM HGASTOS;"

pause