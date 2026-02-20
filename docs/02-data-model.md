# Data Model

This project implements a layered data modeling approach designed to support reliable analytics and business decision-making.

The modeling strategy follows the Medallion pattern and evolves data through three levels of maturity:

- Silver: Clean and standardized operational data  
- Intermediate: Business logic and enrichment  
- Gold: Dimensional model (Star Schema) and aggregated metrics  

The goal is to ensure:
- Consistent definitions across the organization
- High query performance
- Clear data lineage
- Business-ready structures for BI tools

---

## Modeling Layers Overview
Silver (Clean tables)
↓
Intermediate (Business logic & enrichment)
↓
Gold - Marts (Star Schema)
↓
Gold - Aggregations (Semantic layer)


---

## Silver Layer – Operational Truth

**Grain:** Same as source (transactional level)

Purpose:
- Cleaning and normalization
- Type standardization
- Deduplication
- Technical enrichment
- Preservation of business meaning

Examples:
- Standardized timestamps
- Boolean flags (`is_delivered`, `has_comment`)
- Geographic enrichment
- Monetary type conversion

Silver represents the **validated operational foundation**.

---

## Intermediate Layer – Business Logic

The Intermediate layer introduces advanced analytical logic.

**Grain:** 1 row per business entity

Key models:

### `int_review_analysis`
- NLP-based text classification
- Complaint category detection
- Sentiment indicators

### `int_seller_reputation`
- NPS calculation per seller
- Negative review rate
- Reputation ranking
- Pareto analysis (problematic sellers)

### `int_order_risk_factors`
- Predictive risk score (0–100)
- Risk classification: low / medium / high / critical
- Multiple operational risk signals

### `int_product_satisfaction`
- Product-level NPS
- Complaint rate
- Category performance

This layer transforms raw data into **decision-support intelligence**.

---

## Gold Layer – Dimensional Model (Star Schema)

The Gold layer is designed for BI consumption.

### Design Principles

- Star Schema for performance and simplicity
- Surrogate keys for consistency
- Atomic fact tables
- Type 1 Slowly Changing Dimensions
- Business-oriented naming

---

### Dimensions

#### `dim_customers`
Customer geographic and segmentation attributes.

#### `dim_sellers`
Seller location and performance context.

#### `dim_products`
Product category and physical attributes.

#### `dim_date`
Calendar dimension with:
- Year / Month / Week
- Weekend flags
- Seasonality indicators (e.g., Black Friday)

---

### Fact Tables

#### `fact_orders`
**Grain:** 1 row per order

Metrics:
- Order value
- Delivery status
- Risk score
- Operational timestamps

#### `fact_reviews`
**Grain:** 1 row per review

Metrics:
- Review score
- Sentiment classification
- Complaint category

Facts connect all dimensions via foreign keys.

---

## Aggregations Layer (Semantic Layer)

Pre-aggregated views optimized for dashboard performance.

Examples:

- Daily revenue and order trends
- Seller performance summary
- Customer segmentation metrics
- Regional performance indicators
- Risk distribution dashboards

Benefits:
- 10–50x faster queries
- Simplified BI logic
- Consistent KPI definitions

---

## Grain Strategy

| Table | Grain |
|------|------|
| Silver tables | Transaction level |
| Intermediate models | Entity level |
| fact_orders | 1 order |
| fact_reviews | 1 review |
| Aggregations | Business summary level |

Maintaining explicit grain prevents:
- Double counting
- Incorrect joins
- Inconsistent metrics

---

## Data Volume (Approx.)

- Customers: ~99k  
- Orders: ~99k  
- Reviews: ~98k  
- Sellers: ~3k  
- Products: ~33k  

Optimized with:
- Indexing (PostgreSQL)
- Pre-aggregations
- Partitioned exports to Parquet

---

## Why This Model Matters

This design demonstrates:

- Production-grade dimensional modeling
- Integration of NLP and advanced business logic
- Performance-oriented analytics structure
- Clear separation between operational and analytical data
- End-to-end ownership from raw data to business insights