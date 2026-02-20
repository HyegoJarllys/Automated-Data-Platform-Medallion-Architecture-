{{
    config(
        materialized='view',
        schema='staging'
    )
}}

/*
=======================================================================
STAGING: CUSTOMERS
=======================================================================
Descrição:
    Staging layer para clientes da plataforma Olist
    
Source: 
    olist_silver.customers (~99.441 customers)
    
Grain: 
    1 linha = 1 customer_id único
    
Relação com Problema de Negócio:
    - Perfil demográfico de clientes insatisfeitos
    - Análise regional: quais estados têm mais reviews negativos?
    - Identificar padrões geográficos de insatisfação
    - Cross-region deliveries = mais problemas?
    
Uso Posterior:
    - JOIN com orders e reviews para análise regional
    - Identificar estados com maior taxa de insatisfação
    - Análise de distância seller-customer vs satisfação
    
Autor: Hyego Jarllys
Data: 2025-02-10
=======================================================================
*/

WITH source AS (
    
    SELECT *
    FROM {{ source('olist_silver', 'customers') }}

),

renamed AS (

    SELECT
        -- === IDENTIFICADORES ===
        customer_id,
        customer_unique_id,
        
        -- === LOCALIZAÇÃO ===
        customer_zip_code_prefix,
        customer_city,
        customer_state,
        
        -- === GEOLOCALIZAÇÃO ===
        geolocation_lat,
        geolocation_lng,
        has_geolocation,
        
        -- === METADADOS ===
        processed_at,
        created_at,
        updated_at

    FROM source

)

SELECT * FROM renamed