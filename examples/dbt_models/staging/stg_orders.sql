{{
    config(
        materialized='view',
        schema='staging'
    )
}}

/*
================================================================================
STAGING: ORDERS
================================================================================
Descrição:
    Staging layer para pedidos da Olist
    
Source: 
    olist_silver.orders (99.441 orders)
    
Grain: 
    1 linha = 1 pedido único
    
Relação com Problema de Negócio:
    - Análise de tempo de entrega vs reviews negativos
    - Hipótese: 38% dos reviews negativos mencionam "atraso"
    - Comparação: pedidos entregues no prazo vs atrasados
    
Uso Posterior:
    - JOIN com stg_order_reviews para análise de satisfação
    - Cálculo de SLA de entrega (entrega prevista vs real)
    - Identificar pedidos com alto risco de review negativo
    
Autor: Hyego Jarllys
Data: 2025-02-10
================================================================================
*/

WITH source AS (
    
    SELECT *
    FROM {{ source('olist_silver', 'orders') }}

),

renamed AS (

    SELECT
        -- === IDENTIFICADORES ===
        order_id,
        customer_id,
        
        -- === STATUS DO PEDIDO ===
        order_status,
        
        -- === TIMESTAMPS DO FLUXO ===
        order_purchase_timestamp,
        order_approved_at,
        order_delivered_carrier_date,
        order_delivered_customer_date,
        order_estimated_delivery_date,
        
        -- === FLAGS DE QUALIDADE ===
        is_approved,
        is_shipped,
        is_delivered,
        
        -- === METADADOS DE PROCESSAMENTO ===
        processed_at,
        created_at,
        updated_at

    FROM source

)

SELECT * FROM renamed