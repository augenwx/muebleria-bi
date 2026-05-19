-- stg_proveedor.sql
-- Maestro de proveedores

with source as (
    select * from {{ source('raw', 'proveedor') }}
)

select
    id                              as proveedor_id,
    ruc,
    nombre,
    contacto,
    telefono,
    email,
    direccion,
    activo,
    created_at

from source
