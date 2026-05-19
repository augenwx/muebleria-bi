-- dim_tipo_venta.sql
-- Dimensión de tipo de venta (Contado / Crédito)

select
    id      as tipo_venta_id,
    nombre  as tipo_venta

from {{ source('raw', 'tipo_venta') }}
