WITH fechas AS (
    SELECT generate_series(
        '2025-01-01'::date,  -- Cambiado a 2025 para soportar los datos simulados interanuales
        '2026-12-31'::date,
        '1 day'::interval
    )::date AS fecha         -- Casteamos a ::date directamente aquí para evitar inconsistencias
)

SELECT
    CAST(TO_CHAR(fecha, 'YYYYMMDD') AS INT) AS idfecha,
    fecha,
    EXTRACT(DAY FROM fecha)::INT             AS dia,
    EXTRACT(MONTH FROM fecha)::INT           AS mes,                 -- Úsalo en Power BI como columna de ordenación
    TO_CHAR(fecha, 'TMMonth')                AS mesnombre,
    EXTRACT(QUARTER FROM fecha)::INT         AS trimestre,
    EXTRACT(YEAR FROM fecha)::INT            AS anio,
    
    -- NUEVOS CAMPOS REQUERIDOS PARA TU POWER BI:
    EXTRACT(ISODOW FROM fecha)::INT          AS dia_semana_num,      -- 1 para Lunes, 7 para Domingo
    TO_CHAR(fecha, 'TMDay')                  AS dia_semana_desc,     -- Genera 'lunes', 'martes', 'domingo', etc.
    EXTRACT(WEEK FROM fecha)::INT            AS semana_anio,         -- Útil para análisis semanales si te lo piden
    
    -- Tu lógica de negocio adaptada
    CASE EXTRACT(MONTH FROM fecha)
        WHEN 7 THEN 'Alta'   -- Añadido Julio (pico de gratificaciones en Perú, ideal para retail/muebles)
        WHEN 9 THEN 'Alta'   -- Tus pases originales
        WHEN 10 THEN 'Alta'
        WHEN 12 THEN 'Alta'  -- Navidad
        ELSE 'Normal'
    END                                      AS temporada,
    EXTRACT(MONTH FROM fecha) IN (7, 9, 10, 12) AS es_pico
FROM fechas