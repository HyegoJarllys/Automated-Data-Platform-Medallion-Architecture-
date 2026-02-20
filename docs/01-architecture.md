# Architecture

This project implements a production-style data platform using a layered architecture focused on reliability, data quality and operational observability.

The design follows modern Data Engineering principles:
- Separation of concerns
- Modular pipelines
- Fail-fast data quality
- Operational monitoring
- Cloud-native components

---

## High-Level Architecture
CSV Sources
↓
Google Cloud Storage (Bronze - Parquet)
↓
PostgreSQL (Silver & Gold)
↓
Power BI Dashboards

Operational Layer (DataOps)
Airflow + dbt → Events → BigQuery → OpenClaw → Alerts

---

## Architecture Layers

### 1. Source Layer

Public **Olist E-commerce Dataset**

Data domains:
- Customers
- Orders
- Products
- Sellers
- Payments
- Reviews
- Geolocation

Total volume:
- ~850k+ records
- Real transactional data

---

### 2. Bronze Layer (Raw Data Lake)

**Storage:** Google Cloud Storage  
**Format:** Parquet  

Purpose:
- Immutable raw data
- Audit and reprocessing capability
- Schema preservation
- Cost-efficient storage

Characteristics:
- Append-only
- No transformations
- Partitioned by processing date

---

### 3. Silver Layer (Clean & Standardized)

**Primary Warehouse:** PostgreSQL  

Purpose:
- Data cleaning and normalization
- Type standardization
- Deduplication
- Technical enrichment
- Data quality validation

Transformations include:
- Timestamp parsing
- Standardized categorical values
- NULL handling (semantic preservation)
- Geographic enrichment
- Technical flags (is_delivered, has_geolocation, etc.)

Silver represents the **single source of truth** for validated operational data.

---

### 4. Gold Layer (Business Models)

**Storage:** PostgreSQL  
**Transformation Tool:** dbt

Purpose:
- Business-ready datasets
- Dimensional modeling (Star Schema)
- Metrics and KPIs
- Aggregations optimized for BI

Structure:

**Marts (Star Schema)**
- Dimensions: customers, sellers, products, date
- Facts: orders, reviews

**Aggregations (Semantic Layer)**
- Pre-calculated KPIs
- Performance optimization for dashboards
- Reduced query complexity

This layer feeds the **Power BI dashboards**.

---

## Data Processing & Orchestration

### Airflow

Responsibilities:
- Data ingestion orchestration
- Bronze → Silver workflows
- Pipeline scheduling
- Monitoring DAG execution

### dbt

Execution:
- Runs separately from Airflow
- Used for Gold layer transformations
- Provides:
  - Model versioning
  - Lineage
  - Documentation
  - Automated testing

A dedicated Airflow monitoring DAG evaluates dbt execution artifacts for operational analysis (used by OpenClaw).

---

## Data Quality Strategy

Data quality is enforced across layers:

- Great Expectations (Bronze/Silver)
- dbt tests (Gold)
- Types of tests:
  - unique
  - not_null
  - relationships
  - accepted_values
  - freshness

Total coverage:
- 300+ automated tests

Pipelines follow a **fail-fast strategy** — invalid data prevents downstream execution.

---

## Data Export & Hybrid Integration

Silver/Gold tables are exported as **partitioned Parquet files** to Google Cloud Storage.

This enables:
- External analytics workloads
- BigQuery integration when needed
- Cost-efficient large-scale querying
- Decoupling between operational warehouse and cloud analytics

---

## DataOps & Observability Layer

### Event Store

**BigQuery Dataset:** `olist_ops`

Tables:
- `ops_events` – pipeline incidents
- `ops_runs` – execution history

Events include:
- dbt run failures
- dbt test failures
- Source freshness issues

---

## OpenClaw (AI DataOps Agent)

Deployment:
- Cloud Run (serverless)

Capabilities:
- Polls BigQuery every 5 minutes
- Detects new incidents
- Classifies severity (P1 / P2)
- Root cause diagnosis (deterministic rules)
- Context enrichment via RAG (runbooks)
- Generates **Top 3 corrective actions** using Gemini
- Sends alerts via Discord
- Maintains full incident history

This transforms the platform into a **self-monitoring data system**.

---

## Design Principles

**Modularity**
Each layer can evolve independently.

**Observability First**
Operational visibility is built into the architecture.

**Separation of Operational vs Analytical Workloads**
- PostgreSQL → core warehouse
- BigQuery → operational event store

**Cloud Efficiency**
- Parquet storage
- Serverless components (Cloud Run)
- Scale-to-zero for AI agent

---

## Technology Stack

| Layer | Technology |
|------|------------|
| Orchestration | Apache Airflow |
| Transformations | dbt |
| Warehouse | PostgreSQL |
| Data Lake | Google Cloud Storage |
| Event Store | BigQuery |
| Observability | OpenClaw (Python + Gemini) |
| Deployment | Cloud Run |
| BI | Power BI |

---

## Why This Architecture Matters

This design demonstrates:

- Production-style Medallion architecture
- Hybrid cloud data strategy
- Strong data quality governance
- Operational observability
- AI applied to Data Operations
- End-to-end pipeline ownership