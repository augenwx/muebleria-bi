-- dim_proveedor.sql
-- Dimensión de proveedores

with proveedores as (
    select * from {{ ref('stg_proveedor') }}
)

select
    proveedor_id,
    ruc,
    nombre,
    contacto,
    telefono,
    email,
    direccion,
    activo

from proveedores
