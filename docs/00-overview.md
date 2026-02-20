# Project Overview

## Executive Summary

The Olist Data Platform is a production-style data platform built using a real public e-commerce dataset.  
The project simulates a real-world scenario where a company needs to move from raw operational data to reliable business insights with full automation, data quality and operational monitoring.

Beyond traditional data engineering, this platform also includes an **AI-powered DataOps agent** that monitors pipelines, detects failures and suggests corrective actions automatically.

This project demonstrates how modern organizations can build a **reliable, scalable and observable data environment** without relying on manual processes.

---

## Business Context

Many organizations face common data challenges:

- Reports built manually in Excel or exported systems
- Inconsistent numbers across teams
- Data pipelines that fail silently
- Dashboards that become outdated without warning
- Lack of data ownership and monitoring

When data reliability is low, decision-making becomes slow and risky.

This project addresses these problems by implementing a full end-to-end data platform using modern industry practices.

---

## Project Objectives

The platform was designed to:

- Automate data ingestion and processing
- Create a single source of truth for analytics
- Ensure data quality across all layers
- Deliver business-ready datasets for reporting
- Provide operational visibility into pipeline health
- Detect and diagnose failures automatically
- Reduce manual operational effort

---

## Dataset

Source: **Olist Brazilian E-commerce Public Dataset**

Scope:

- ~850,000+ records
- Customers, Orders, Sellers, Products, Payments, Reviews and Geolocation
- Real transactional e-commerce data
- Suitable for operational and analytical scenarios

---

## End-to-End Flow

CSV Sources
↓
Bronze (Raw - Data Lake)
↓
Silver (Clean & Validated)
↓
Gold (Star Schema + Aggregations)
↓
Power BI Dashboards
↓
OpenClaw Monitoring & AI Incident Response


---

## Architecture Highlights

### Medallion Data Architecture
- **Bronze:** Raw immutable data for audit and reprocessing
- **Silver:** Cleaned, standardized and enriched datasets
- **Gold:** Business-ready models (Star Schema + KPIs)

### Data Engineering Stack
- Apache Airflow (orchestration)
- BigQuery (data warehouse)
- Google Cloud Storage (data lake)
- dbt (transformations, testing and lineage)

### Data Quality & Governance
- 300+ automated tests (unique, not_null, relationships, freshness)
- Fail-fast pipeline strategy
- Full lineage and documentation via dbt

---

## Analytics Layer

The Gold layer feeds **Power BI dashboards** designed for operational and executive analysis, including:

- Customer satisfaction and NPS trends
- Seller performance monitoring
- Risk indicators and operational issues
- Revenue and order behavior

The focus is not only visualization, but **actionable insights** for decision-making.

---

## AI-Powered DataOps (OpenClaw)

The OpenClaw Agent adds an advanced operational layer:

**Capabilities**
- Monitors dbt and Airflow executions in near real-time
- Detects failures within ~5 minutes
- Classifies incidents as P1 or P2
- Diagnoses root cause using deterministic rules
- Enriches context using RAG with operational runbooks
- Generates **Top 3 corrective actions** using Gemini
- Sends alerts via Discord
- Stores full incident history in BigQuery

Deployment:
- Cloud Run (serverless, scale-to-zero)

This transforms the platform from a simple pipeline into a **self-monitoring data system**.

---

## Project Scale

- 46+ Airflow DAGs  
- 20+ dbt models  
- 300+ data quality tests  
- Star Schema + Aggregation Layer  
- 4 Power BI dashboards  
- AI-powered DataOps agent in production  

---

## Why This Project Matters

Most portfolio projects stop at dashboards.

This project demonstrates:

- Production-style architecture
- Data quality and governance
- Observability and incident management
- Cloud deployment
- Integration of Data Engineering + AI + DataOps

This type of solution is especially valuable for:

- Small and mid-size companies growing beyond spreadsheets
- E-commerce and operations teams
- Public sector data modernization
- Organizations without dedicated data engineering teams

---

## What This Demonstrates

Capabilities represented in this project:

- End-to-end Data Engineering
- BigQuery Data Warehouse implementation
- dbt Analytics Engineering
- Data Quality and Observability
- Cloud architecture on GCP
- AI applied to Data Operations (LLMOps)