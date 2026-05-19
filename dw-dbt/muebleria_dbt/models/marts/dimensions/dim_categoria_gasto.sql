-- dim_categoria_gasto.sql
-- Dimensión de categorías de gasto (fijo / variable)

select
    id      as categoria_id,
    nombre  as categoria,
    tipo    as tipo_gasto     -- 'fijo' / 'variable'

from {{ source('raw', 'categoria_gasto') }}
