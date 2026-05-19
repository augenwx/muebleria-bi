-- dim_usuario.sql
-- Dimensión de usuarios del sistema

with usuarios as (
    select * from {{ ref('stg_usuario') }}
)

select
    usuario_id,
    nombre,
    email,
    rol,
    activo

from usuarios
