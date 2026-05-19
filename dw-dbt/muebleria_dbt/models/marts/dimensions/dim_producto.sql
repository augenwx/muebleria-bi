-- dim_producto.sql
-- Dimensión de productos terminados con precios y costo estándar

with productos as (
    select * from {{ ref('stg_producto') }}
)

select
    producto_id,
    nombre,
    costo_estandar,
    precio_venta_retail,
    precio_venta_mayorista,
    -- margen estándar calculado
    round(precio_venta_retail    - costo_estandar, 2)  as margen_retail,
    round(precio_venta_mayorista - costo_estandar, 2)  as margen_mayorista,
    activo

from productos
