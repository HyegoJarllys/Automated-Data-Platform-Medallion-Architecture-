# Demo Walkthrough

This document provides a quick guide to explore the project and understand its main components.

Estimated time: **2–3 minutes**

The goal is to show how the platform works end-to-end without requiring a full local setup.

---

## 1. Architecture Overview

Start here:

`docs/01-architecture.md`

This explains:

- Medallion structure (Bronze → Silver → Gold)
- PostgreSQL as the analytical warehouse
- BigQuery as operational event store
- OpenClaw deployment on Cloud Run
- End-to-end data flow

---

## 2. Data Modeling

Open:

`docs/02-data-model.md`

Key points to review:

- Star Schema design
- Fact tables: orders and reviews
- Dimensions: customers, sellers, products, date
- Intermediate layer with:
  - NLP analysis
  - Risk scoring
  - NPS calculation

This shows how raw data becomes business-ready models.

---

## 3. Data Quality

Open:

`docs/03-data-quality.md`

Highlights:

- 300+ automated tests
- Great Expectations (Bronze/Silver)
- dbt tests (Gold)
- Fail-fast pipeline strategy
- Data contracts and freshness checks

This ensures reliability before data reaches dashboards.

---

## 4. Observability & AI Monitoring

Open:

`docs/04-observability-alerts.md`

What to look for:

- BigQuery event store (`olist_ops`)
- Incident tracking (`ops_events`, `ops_runs`)
- OpenClaw architecture
- RAG-based runbook retrieval
- AI-generated corrective actions
- Discord alert workflow

This is the operational intelligence layer of the platform.

---

## 5. Sample Models

Explore:

`examples/dbt_models/`

Suggested order:

- `staging/` → source normalization
- `marts/` → dimensional models
- `aggregations/` → KPI views

Also check:

`examples/sql/ddl_star_schema.sql`

This shows the physical design of the Gold layer.

---

## 6. Sample Data

Location:

`examples/sample_data/`

Files:
- `customers.csv`
- `orders.csv`

These small datasets illustrate the structure used by the platform.

---

## 7. Orchestration Example

![Airflow DAGs](../screenshots/airflow_dags.png)

Open:

`examples/airflow_dags/example_dag.py`

This demonstrates:
- DAG structure
- Scheduling logic
- Task dependencies

The full production DAGs are maintained in a private repository.

---

## 8. Dashboards

Open the folder:

`screenshots/`

Recommended screenshots to include:

- Executive dashboard (revenue / orders)
- Seller performance / NPS
- Risk or operational indicators
- OpenClaw alert example

The Gold layer feeds **Power BI dashboards** designed for operational and executive analysis.

---

## 9. Operational Flow (Quick Summary)
CSV Sources
↓
GCS Bronze (Parquet)
↓
PostgreSQL Silver & Gold
↓
Power BI
↓
Airflow + dbt Monitoring
↓
BigQuery Events
↓
OpenClaw (Cloud Run)
↓
Discord Alerts


---

## 10. What This Demo Shows

This walkthrough demonstrates:

- End-to-end data pipeline design
- Production-style architecture
- Dimensional modeling
- Automated data quality
- Cloud-based deployment
- Operational observability
- AI applied to DataOps

The project simulates a real environment where data must be reliable, monitored and ready for decision-making.