# Automated Data Platform (Medallion Architecture)

Production-style data platform that automates data pipelines, ensures data quality and includes an AI-powered monitoring agent that detects failures and suggests corrective actions.

This project demonstrates how companies can move from manual spreadsheets to a reliable, automated and monitored data environment.

---

## Business Problem

Many small and mid-size organizations face the same challenges:

- Reports built manually in Excel
- Data coming from multiple sources
- Numbers that don’t match
- Pipeline failures discovered too late
- No monitoring or data ownership

When data breaks, dashboards become outdated and decisions are made using incorrect information.

---

## Solution

This platform provides:

- Automated data ingestion and transformation
- Clean and standardized datasets (Medallion: Bronze → Silver → Gold)
- Business-ready models (Star Schema)
- Pre-aggregated KPIs for dashboards
- Data quality tests across all layers
- Real-time monitoring with intelligent alerts
- AI-powered incident diagnosis and corrective suggestions

---

## Key Features

### Automated Data Pipelines
- Scheduled workflows using Airflow
- Incremental and modular transformations with dbt
- End-to-end orchestration

### Medallion Architecture
- **Bronze:** raw data for audit and recovery  
- **Silver:** cleaned and validated data  
- **Gold:** business metrics and analytics models  

### Data Quality & Governance
- 300+ automated tests (unique, not_null, relationships, freshness)
- Schema validation and lineage tracking
- Fail-fast pipeline strategy

### Observability with AI (OpenClaw Agent)
- Detects pipeline failures in less than 5 minutes
- Stores operational events in BigQuery
- Diagnoses root cause using deterministic rules
- Uses RAG + Gemini to generate **Top 3 corrective actions**
- Sends P1/P2 alerts via Discord
- Full incident history for audit

---

## Architecture Overview

Pipeline flow:
Sources → Bronze → Silver → Gold(DBT) → Dashboards
↓
Monitoring Layer
OpenClaw


Technologies:

- BigQuery (Data Warehouse)
- dbt (Transformations & testing)
- Apache Airflow (Orchestration)
- Google Cloud Storage (Data Lake)
- Cloud Run (OpenClaw deployment)
- Gemini AI (LLM for incident guidance)

See `/docs/01-architecture.md` for detailed diagrams.

---

## Business Impact (What this enables)

- Eliminate manual reporting work
- Ensure reliable and consistent metrics
- Detect issues before stakeholders notice
- Reduce operational risk
- Scale data operations without a dedicated data team

This type of platform is ideal for:
- Small companies growing beyond Excel
- E-commerce and operations teams
- Public sector data modernization
- Organizations without a data engineering team

---

## Project Scale

- 46+ Airflow DAGs  
- 20+ dbt models  
- 300+ data quality tests  
- Star Schema + Aggregation Layer  
- AI-powered DataOps monitoring agent  

---

## Repository Structure

docs/ → Architecture and design documentation
examples/ → Sample models and SQL
diagrams/ → Architecture diagrams
screenshots/ → Dashboards and monitoring examples

## Services this project represents

This portfolio demonstrates capabilities to deliver:

- Data pipeline automation (Airflow + dbt)
- BigQuery data warehouse implementation
- Excel/Sheets → automated data workflows
- Data quality and monitoring setup
- AI-powered operational monitoring
- Analytics-ready data models

---

## About

Data Engineer focused on building automated, reliable and scalable data platforms for small businesses and public sector organizations.

Contact: see GitHub profile.