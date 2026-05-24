WITH clientes AS (
    SELECT * FROM {{ ref('stg_clientes') }}
),
tipos_cliente AS (
    SELECT * FROM {{ ref('stg_tipo_cliente') }}
)

SELECT
    c.cliente_id                                AS idcliente,
    'CLI_' || c.cliente_id                      AS cdcliente,
    c.nombre,
    c.documento,
    tc.tipocliente                              AS tipocliente,
    CASE tc.tipocliente
        WHEN 'Retail'     THEN 'Tienda directa'
        WHEN 'Mayorista'  THEN 'Pedido especial'
    END                                         AS canal,
    c.direccion,
    c.telefono,
    c.email,
    c.limite_credito,
    c.saldo_pendiente,
    c.estado,
    CURRENT_DATE                                AS fecha_desde,
    '9999-12-31'::date                          AS fecha_hasta,
    TRUE                                        AS es_vigente
FROM clientes c
JOIN tipos_cliente tc ON tc.tipo_cliente_id = c.tipo_cliente_id
