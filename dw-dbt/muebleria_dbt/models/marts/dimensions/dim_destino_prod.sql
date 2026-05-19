-- dim_destino_prod.sql
-- Dimensión de destino de producción (Stock, Mayoristas, Pedidos, etc.)

select
    id              as destino_id,
    descripcion     as destino

from {{ source('raw', 'destino_produccion') }}
