# Cost & Performance Strategy

This project was designed with a production mindset, balancing performance, scalability and cloud cost efficiency.

The architecture follows a **cost-aware approach**, using the right technology for each workload and avoiding unnecessary resource consumption.

---

## Design Principles

**Use the right engine for the right job**
- PostgreSQL for core analytical workloads
- BigQuery only for operational event storage
- Parquet for efficient cloud storage

**Avoid unnecessary compute**
- Pre-aggregations for BI
- Incremental processing where possible
- Serverless components for variable workloads

**Minimize idle cost**
- Cloud Run scale-to-zero
- Event-driven processing
- Lightweight monitoring intervals

---

## Storage Optimization

### Parquet Format (Bronze & Exports)

Used for:
- Raw data storage in GCS
- Partitioned exports from Silver/Gold

Benefits:
- Columnar compression
- Reduced storage size (~50–70% vs CSV)
- Faster analytical reads
- Efficient integration with BigQuery

Partition strategy:
/table_name/year=YYYY/month=MM/

This enables:
- Selective queries
- Reduced scan cost
- Time-based data access

---

## Warehouse Performance (PostgreSQL)

The analytical warehouse was optimized using:

### Indexing Strategy
- Primary keys on all core tables
- Foreign key indexes for joins
- Additional indexes on:
  - Date fields
  - High-filter columns
  - Fact table join keys

### Star Schema Design

Benefits:
- Reduced join complexity
- Predictable query performance
- Optimized for BI workloads

### Grain Control

Atomic fact tables:
- `fact_orders` → 1 row per order
- `fact_reviews` → 1 row per review

Prevents:
- Double counting
- Large intermediate joins

---

## Aggregation Layer (BI Optimization)

Pre-aggregated views were created to reduce dashboard latency.

Examples:
- Daily revenue trends
- Seller performance summaries
- Regional metrics
- Risk distribution

Performance gains:
- **10–50x faster queries** compared to raw fact joins
- Simplified BI logic
- Consistent KPI definitions

Aggregation materialization:
- Views (current scale)
- Can evolve to tables if volume increases

---

## BigQuery Cost Control

BigQuery is used only for operational observability:

Dataset:
`olist_ops`

Stored data:
- Pipeline events
- Execution history

Why this approach:
- Very low data volume
- Minimal query frequency
- Avoids analytical query costs in BigQuery

This separation keeps operational monitoring scalable and inexpensive.

---

## Serverless Components

### OpenClaw Deployment

Platform:
- Cloud Run

Cost optimization features:
- Scale-to-zero when idle
- Pay-per-request model
- No infrastructure management
- Lightweight polling (300s interval)

### LLM Cost Strategy

Model:
- Gemini 2.5 Flash-Lite

Reasons:
- Low latency
- High throughput
- Cost-efficient for operational use
- Used only when incidents occur

---

## Pipeline Efficiency

### Fail-Fast Execution

If a validation fails:
- Downstream tasks are stopped
- No unnecessary processing
- Reduces wasted compute

### Monitoring Separation

Operational monitoring runs independently from core pipelines, preventing unnecessary load on the warehouse.

---

## Scalability Considerations

The architecture supports growth through:

- Parquet-based data lake (GCS)
- Partitioned exports
- Star Schema modeling
- Aggregation layer for BI
- Serverless operational components

Future evolution options:
- Incremental dbt models
- Materialized aggregation tables
- BigQuery analytical migration if volume increases

---

## Why This Matters

This project demonstrates:

- Cost-aware cloud architecture
- Performance-oriented data modeling
- Efficient use of serverless services
- Separation between operational and analytical workloads
- Scalable design for growing data environments

The platform is designed not only to work — but to work efficiently at scale.