{{
    config(
        materialized='table',
        schema='olist_gold_marts'
    )
}}

-- Dimensão Cliente: 1 linha por cliente único
-- Fonte: stg_customers (atributos geográficos apenas)
-- Grain: 1 cliente
-- Uso: FK em fact_reviews e fact_orders

WITH customer_base AS (
    SELECT
        customer_id,
        customer_unique_id,
        customer_zip_code_prefix,
        customer_city,
        customer_state
    FROM {{ ref('stg_customers') }}
),

customer_attributes AS (
    SELECT
        -- Surrogate Key (hash MD5 para consistência)
        {{ dbt_utils.generate_surrogate_key(['customer_id']) }} AS customer_key,
        
        -- Natural Keys
        customer_id,
        customer_unique_id,
        
        -- Atributos Geográficos
        customer_zip_code_prefix,
        customer_city,
        customer_state,
        
        -- Flags Geográficas (baseadas em análise do Intermediate)
        CASE 
            WHEN customer_state IN ('SP', 'RJ', 'MG') THEN TRUE
            ELSE FALSE
        END AS is_southeast_region,  -- Sudeste concentra ~75% dos clientes
        
        CASE 
            WHEN customer_state IN ('AC', 'RO', 'AM', 'RR', 'PA', 'AP', 'TO') THEN TRUE
            ELSE FALSE
        END AS is_north_region,  -- Norte tem maiores custos de frete
        
        CASE 
            WHEN customer_state IN ('MA', 'PI', 'CE', 'RN', 'PB', 'PE', 'AL', 'SE', 'BA') THEN TRUE
            ELSE FALSE
        END AS is_northeast_region,  -- Nordeste
        
        CASE 
            WHEN customer_state IN ('PR', 'SC', 'RS') THEN TRUE
            ELSE FALSE
        END AS is_south_region,  -- Sul
        
        CASE 
            WHEN customer_state IN ('MS', 'MT', 'GO', 'DF') THEN TRUE
            ELSE FALSE
        END AS is_midwest_region,  -- Centro-Oeste
        
        -- Flag capital (principais cidades)
        CASE 
            WHEN customer_city IN (
                'sao paulo', 'rio de janeiro', 'belo horizonte', 'brasilia',
                'curitiba', 'porto alegre', 'salvador', 'fortaleza', 'recife',
                'manaus', 'belem', 'goiania', 'campinas', 'sao bernardo do campo'
            ) THEN TRUE
            ELSE FALSE
        END AS is_major_city
        
    FROM customer_base
)

SELECT
    customer_key,
    customer_id,
    customer_unique_id,
    customer_zip_code_prefix,
    customer_city,
    customer_state,
    is_southeast_region,
    is_north_region,
    is_northeast_region,
    is_south_region,
    is_midwest_region,
    is_major_city
FROM customer_attributes
ORDER BY customer_key