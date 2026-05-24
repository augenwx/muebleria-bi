WITH fechas AS (
    SELECT generate_series(
        '2026-01-01'::date,
        '2026-12-31'::date,
        '1 day'::interval
    ) AS fecha
)

SELECT
    CAST(TO_CHAR(fecha, 'YYYYMMDD') AS INT) AS idfecha,
    fecha,
    EXTRACT(DAY FROM fecha)::INT             AS dia,
    EXTRACT(MONTH FROM fecha)::INT           AS mes,
    TO_CHAR(fecha, 'TMMonth')                AS mesnombre,
    EXTRACT(QUARTER FROM fecha)::INT         AS trimestre,
    EXTRACT(YEAR FROM fecha)::INT            AS anio,
    CASE EXTRACT(MONTH FROM fecha)
        WHEN 9 THEN 'Alta'
        WHEN 10 THEN 'Alta'
        WHEN 12 THEN 'Alta'
        ELSE 'Normal'
    END                                      AS temporada,
    EXTRACT(MONTH FROM fecha) IN (9, 10, 12) AS es_pico
FROM fechas
