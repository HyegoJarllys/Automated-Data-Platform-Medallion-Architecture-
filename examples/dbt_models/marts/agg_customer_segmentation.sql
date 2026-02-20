{{
    config(
        materialized='view',
        schema='aggregations'
    )
}}

-- ===================================================================
-- Aggregation: Customer Segmentation (RFM Analysis)
-- ===================================================================
-- GRAIN: 1 row per customer (dim_customer)
-- PURPOSE: Customer lifetime value, RFM segmentation, retention analysis
-- USAGE: Dashboards de marketing, programas de retenção, campanhas
-- DEPENDENCIES: dim_customer, fact_orders
-- ===================================================================

WITH customer_orders AS (
    -- Métricas de pedidos por cliente
    SELECT
        customer_key,
        COUNT(*) AS total_orders,
        SUM(order_total_value) AS total_spent,
        ROUND(AVG(order_total_value)::numeric, 2) AS avg_order_value,
        MIN(order_purchase_timestamp::DATE) AS first_order_date,
        MAX(order_purchase_timestamp::DATE) AS last_order_date,
        
        -- Recency (dias desde último pedido)
        -- Nota: Usando '2018-10-17' como data de referência (última data no dataset)
        ('2018-10-17'::DATE - MAX(order_purchase_timestamp::DATE)) 
            AS days_since_last_order,
        
        -- Frequency (pedidos por mês ativo)
        CASE 
            WHEN MIN(order_purchase_timestamp::DATE) = MAX(order_purchase_timestamp::DATE) 
                THEN 1.0
            ELSE ROUND(
                (COUNT(*)::numeric / NULLIF(
                    EXTRACT(EPOCH FROM (
                        MAX(order_purchase_timestamp) - MIN(order_purchase_timestamp)
                    ))::numeric / 2592000, 0
                ))::numeric, 2
            )
        END AS order_frequency_per_month,
        
        -- Métricas de risco
        COUNT(CASE WHEN is_high_risk THEN 1 END) AS high_risk_orders,
        ROUND(AVG(risk_score)::numeric, 2) AS avg_risk_score,
        
        -- Métricas de entrega
        COUNT(CASE WHEN is_delivered THEN 1 END) AS delivered_orders,
        COUNT(CASE WHEN is_problematic_order THEN 1 END) AS problematic_orders
        
    FROM {{ ref('fact_orders') }}
    GROUP BY customer_key
),

customer_reviews AS (
    -- Métricas de reviews por cliente
    SELECT
        customer_key,
        COUNT(*) AS total_reviews,
        COUNT(CASE WHEN sentiment = 'negative' THEN 1 END) AS negative_reviews,
        ROUND(AVG(review_score)::numeric, 2) AS avg_review_score
    FROM {{ ref('fact_reviews') }}
    GROUP BY customer_key
),

final AS (
    -- Combinar dimensão customer com métricas RFM
    SELECT
        c.customer_key,
        c.customer_id,
        c.customer_city,
        c.customer_state,
        c.is_major_city,
        
        -- Métricas de pedidos (Frequency & Monetary)
        COALESCE(o.total_orders, 0) AS total_orders,
        COALESCE(o.total_spent, 0) AS total_spent,
        COALESCE(o.avg_order_value, 0) AS avg_order_value,
        
        -- Datas (Recency)
        o.first_order_date,
        o.last_order_date,
        COALESCE(o.days_since_last_order, 999) AS days_since_last_order,
        COALESCE(o.order_frequency_per_month, 0) AS order_frequency_per_month,
        
        -- Métricas de qualidade
        COALESCE(o.high_risk_orders, 0) AS high_risk_orders,
        COALESCE(o.avg_risk_score, 0) AS avg_risk_score,
        COALESCE(o.delivered_orders, 0) AS delivered_orders,
        COALESCE(o.problematic_orders, 0) AS problematic_orders,
        
        -- Métricas de reviews
        COALESCE(r.total_reviews, 0) AS total_reviews,
        COALESCE(r.negative_reviews, 0) AS negative_reviews,
        COALESCE(r.avg_review_score, 0) AS avg_review_score,
        
        -- Percentuais
        CASE 
            WHEN COALESCE(o.total_orders, 0) = 0 THEN 0
            ELSE ROUND(100.0 * o.delivered_orders / o.total_orders, 2)
        END AS delivery_success_rate,
        
        CASE 
            WHEN COALESCE(r.total_reviews, 0) = 0 THEN 0
            ELSE ROUND(100.0 * r.negative_reviews / r.total_reviews, 2)
        END AS negative_review_rate,
        
        -- RFM Scores (1-5, sendo 5 o melhor)
        CASE
            WHEN COALESCE(o.days_since_last_order, 999) <= 30 THEN 5
            WHEN COALESCE(o.days_since_last_order, 999) <= 60 THEN 4
            WHEN COALESCE(o.days_since_last_order, 999) <= 90 THEN 3
            WHEN COALESCE(o.days_since_last_order, 999) <= 180 THEN 2
            ELSE 1
        END AS recency_score,
        
        CASE
            WHEN COALESCE(o.total_orders, 0) >= 5 THEN 5
            WHEN COALESCE(o.total_orders, 0) >= 3 THEN 4
            WHEN COALESCE(o.total_orders, 0) >= 2 THEN 3
            WHEN COALESCE(o.total_orders, 0) = 1 THEN 2
            ELSE 1
        END AS frequency_score,
        
        CASE
            WHEN COALESCE(o.total_spent, 0) >= 1000 THEN 5
            WHEN COALESCE(o.total_spent, 0) >= 500 THEN 4
            WHEN COALESCE(o.total_spent, 0) >= 200 THEN 3
            WHEN COALESCE(o.total_spent, 0) >= 100 THEN 2
            WHEN COALESCE(o.total_spent, 0) > 0 THEN 1
            ELSE 0
        END AS monetary_score,
        
        -- Segmentação de clientes
        CASE
            -- High Value: Recente, frequente, gasta muito
            WHEN COALESCE(o.days_since_last_order, 999) <= 60 
                AND COALESCE(o.total_orders, 0) >= 3 
                AND COALESCE(o.total_spent, 0) >= 500 
                THEN 'High Value'
            
            -- Regular: Comportamento médio
            WHEN COALESCE(o.days_since_last_order, 999) <= 90 
                AND COALESCE(o.total_orders, 0) >= 2 
                AND COALESCE(o.total_spent, 0) >= 200 
                THEN 'Regular'
            
            -- At Risk: Não compra há muito tempo mas já foi bom cliente
            WHEN COALESCE(o.days_since_last_order, 999) > 90 
                AND COALESCE(o.total_orders, 0) >= 2 
                THEN 'At Risk'
            
            -- Churned: Mais de 180 dias sem comprar
            WHEN COALESCE(o.days_since_last_order, 999) > 180 
                THEN 'Churned'
            
            -- One-Time: Comprou apenas uma vez
            WHEN COALESCE(o.total_orders, 0) = 1 
                THEN 'One-Time'
            
            ELSE 'New'
        END AS customer_segment,
        
        -- Lifetime Value Tier
        CASE
            WHEN COALESCE(o.total_spent, 0) >= 1000 THEN 'Premium'
            WHEN COALESCE(o.total_spent, 0) >= 500 THEN 'Gold'
            WHEN COALESCE(o.total_spent, 0) >= 200 THEN 'Silver'
            WHEN COALESCE(o.total_spent, 0) > 0 THEN 'Bronze'
            ELSE 'No Purchase'
        END AS ltv_tier
        
    FROM {{ ref('dim_customer') }} c
    LEFT JOIN customer_orders o ON c.customer_key = o.customer_key
    LEFT JOIN customer_reviews r ON c.customer_key = r.customer_key
)

SELECT * FROM final
ORDER BY total_spent DESC
