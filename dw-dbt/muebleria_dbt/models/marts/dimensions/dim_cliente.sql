-- dim_cliente.sql
-- Dimensión de clientes con tipo (Retail / Mayorista)

with clientes as (
    select * from {{ ref('stg_cliente') }}
),

tipos as (
    select
        id   as tipo_cliente_id,
        nombre as tipo_cliente
    from {{ source('raw', 'tipo_cliente') }}
)

select
    c.cliente_id,
    c.documento,
    c.nombre,
    coalesce(c.razon_social, c.nombre)      as razon_social,
    t.tipo_cliente,
    c.direccion,
    c.telefono,
    c.email,
    c.limite_credito,
    c.estado,
    c.activo

from clientes c
left join tipos t on t.tipo_cliente_id = c.tipo_cliente_id
