-- stg_usuario.sql
-- Usuarios del sistema

with source as (
    select * from {{ source('raw', 'usuario') }}
)

select
    id                              as usuario_id,
    nombre,
    email,
    rol,
    activo,
    created_at

from source
