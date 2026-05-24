WITH productos AS (
    SELECT * FROM {{ ref('stg_productos') }}
)

SELECT
    producto_id                                             AS idproducto,
    UPPER(REPLACE(nombre, ' ', '_'))                        AS cdproducto,
    nombre                                                  AS dsproducto,
    'Mueble de Melamina'                                    AS cdcategoria,
    COALESCE(precio_venta_retail, precio_venta_mayorista)   AS precioventa,
    costo_estandar                                          AS costomaterial,
    0                                                       AS costomanoobra,
    FALSE                                                   AS es_estrella
FROM productos
ORDER BY nombre
