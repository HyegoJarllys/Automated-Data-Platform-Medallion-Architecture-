{{
    config(
        materialized='table',
        schema='olist_gold_marts'
    )
}}

WITH orders_base AS (
    SELECT
        order_id,
        customer_id,
        order_status,
        order_purchase_timestamp,
        order_approved_at,
        order_delivered_carrier_date,
        order_delivered_customer_date,
        order_estimated_delivery_date,
        is_delivered
    FROM {{ ref('stg_orders') }}
),

order_items_agg AS (
    SELECT
        order_id,
        COUNT(*) AS total_items,
        SUM(price) AS total_product_value,
        SUM(freight_value) AS total_freight_value,
        SUM(item_total_value) AS order_total_value,
        (ARRAY_AGG(seller_id ORDER BY item_total_value DESC))[1] AS main_seller_id
    FROM {{ ref('stg_order_items') }}
    GROUP BY order_id
),

order_payments_agg AS (
    SELECT
        order_id,
        COUNT(*) AS total_payment_installments,
        SUM(payment_value) AS total_payment_value,
        STRING_AGG(DISTINCT payment_type, ', ' ORDER BY payment_type) AS payment_methods
    FROM {{ ref('stg_order_payments') }}
    GROUP BY order_id
),

order_risk AS (
    SELECT
        order_id,
        risk_score,
        risk_category,
        is_high_risk,
        risk_factors_count,
        days_late,
        is_cross_state,
        seller_nps,
        max_item_price,
        product_weight_g
    FROM {{ ref('int_order_risk_factors') }}
),

fact_orders_enriched AS (
    SELECT
        o.order_id,
        MD5(o.customer_id) AS customer_key,
        TO_CHAR(o.order_purchase_timestamp, 'YYYYMMDD')::INTEGER AS date_key,
        MD5(oi.main_seller_id) AS seller_key,
        
        o.order_status,
        o.order_purchase_timestamp,
        o.order_approved_at,
        o.order_delivered_carrier_date,
        o.order_delivered_customer_date,
        o.order_estimated_delivery_date,
        o.is_delivered,
        CASE WHEN COALESCE(r.days_late, 0) <= 0 THEN TRUE ELSE FALSE END AS is_on_time,
        COALESCE(r.days_late, 0) AS delivery_delay_days,
        
        COALESCE(oi.total_items, 0) AS total_items,
        COALESCE(oi.total_product_value, 0) AS total_product_value,
        COALESCE(oi.total_freight_value, 0) AS total_freight_value,
        COALESCE(oi.order_total_value, 0) AS order_total_value,
        
        COALESCE(op.total_payment_installments, 0) AS total_payment_installments,
        COALESCE(op.total_payment_value, 0) AS total_payment_value,
        COALESCE(op.payment_methods, 'unknown') AS payment_methods,
        
        COALESCE(r.risk_score, 0) AS risk_score,
        COALESCE(r.risk_category, 'low') AS risk_category,
        COALESCE(r.is_high_risk, FALSE) AS is_high_risk,
        COALESCE(r.risk_factors_count, 0) AS risk_factors_count,
        COALESCE(r.is_cross_state, FALSE) AS is_cross_state,
        
        CASE WHEN o.order_status IN ('canceled', 'unavailable') THEN TRUE ELSE FALSE END AS is_problematic_order,
        CASE WHEN COALESCE(oi.order_total_value, 0) > 500 THEN TRUE ELSE FALSE END AS is_high_value_order
        
    FROM orders_base o
    LEFT JOIN order_items_agg oi ON o.order_id = oi.order_id
    LEFT JOIN order_payments_agg op ON o.order_id = op.order_id
    LEFT JOIN order_risk r ON o.order_id = r.order_id
)

SELECT * FROM fact_orders_enriched ORDER BY order_purchase_timestamp DESC
