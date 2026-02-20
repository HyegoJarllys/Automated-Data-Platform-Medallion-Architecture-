# Observability & Alerts

Modern data platforms require more than pipelines and dashboards.  
They require operational visibility.

This project implements a full **Data Observability layer** that monitors pipeline execution, detects failures, stores operational history and uses AI to support incident response.

The core of this layer is the **OpenClaw Agent**, an autonomous DataOps system deployed on Google Cloud Run.

---

## Observability Objectives

screenshots/data_quality_dashboard.png

The monitoring layer was designed to:

- Detect pipeline failures as early as possible
- Identify data quality and freshness issues
- Provide historical visibility of incidents
- Reduce manual log investigation
- Suggest corrective actions automatically
- Prevent silent failures that impact dashboards

Detection latency:
- **< 5 minutes**

---

## Observability Architecture

![OpenClaw Flow](../diagrams/openclaw_flow.png)

Airflow / dbt execution
↓
Monitoring DAG parses artifacts
↓
Events stored in BigQuery (olist_ops)
↓
OpenClaw Agent (Cloud Run)
↓
Diagnosis + RAG + LLM
↓
Discord Alert (P1 / P2)

---

## Event Store (BigQuery)

Dataset: `olist_ops`

### Tables

**ops_events**
- event_id
- event_type
- severity (P1 / P2)
- resource_name
- message
- status (NEW / NOTIFIED)
- created_at
- notified_at

Purpose:
Central queue for operational incidents.

---

**ops_runs**
- run_id
- start_time
- end_time
- status
- number_of_events

Purpose:
Execution history and audit trail.

---

## Detected Incident Types

The monitoring process captures:

- `DBT_RUN_FAILED`
- `DBT_TEST_FAILED`
- `DBT_FRESHNESS_STALE`
- Pipeline execution failures
- Data quality violations

Severity classification:

| Severity | Meaning |
|---------|---------|
| P1 | Critical – pipeline or business impact |
| P2 | Warning – degradation or risk |

---

## Monitoring Workflow

### Step 1 – Pipeline Execution
Airflow runs ingestion and monitoring workflows.

### Step 2 – Artifact Parsing
A dedicated DAG:
- Executes dbt run / test / freshness
- Parses `run_results.json` and `sources.json`
- Extracts failures and warnings

### Step 3 – Event Registration
Detected issues are inserted into:
- `BigQuery olist_ops.ops_events`
- Status = NEW

---

## OpenClaw Agent

Deployment:
- **Cloud Run (serverless, scale-to-zero)**
- Polling interval: 300 seconds

Responsibilities:

### 1. Event Detection
- Reads NEW events from BigQuery

### 2. Root Cause Diagnosis
Deterministic rules based on:
- Event type
- Resource affected
- Failure pattern

This ensures fast and predictable analysis.

---

### 3. Context Enrichment (RAG)

Runbooks stored as Markdown are used as a knowledge base.

Process:
- Keyword extraction from event
- Relevant runbook retrieval
- Context added to analysis

This allows knowledge reuse across incidents.

---

### 4. AI Corrective Actions

Model:
- **Gemini 2.5 Flash-Lite**

Output:
- Exactly **Top 3 recommended actions**
- Short, operational guidance
- Fallback rules if the model fails

---

### 5. Alert Delivery

### Example Alert

![OpenClaw Alert](../screenshots/openclaw_alert.png)

Notifications sent via:
- **Discord Webhook**

Alert includes:
- Severity (P1 / P2)
- Affected model or resource
- Error summary
- Root cause diagnosis
- Recommended actions

---

## Incident Lifecycle
Event detected
↓
Stored in BigQuery (NEW)
↓
OpenClaw processes event
↓
Alert sent
↓
Status updated to NOTIFIED

All incidents remain stored for:
- Audit
- Trend analysis
- Operational metrics

---

## Design Principles

**Observability First**  
Operational visibility is built into the platform, not added later.

**Determinism Before AI**  
Rule-based diagnosis ensures reliability before LLM usage.

**Cost Efficiency**  
- Cloud Run scale-to-zero  
- Gemini Flash-Lite (low cost)  

**Auditability**  
All incidents and runs stored in BigQuery.

---

## Operational Metrics

- Models monitored: 20+ dbt models
- Data quality tests: 300+
- Detection latency: < 5 minutes
- Incident history stored indefinitely
- Serverless deployment (no idle cost)

---

## Why This Matters

Most data platforms fail silently.

This implementation demonstrates:

- Production-grade data observability
- Automated incident detection
- Operational audit trail
- Integration between Data Engineering and AI
- Practical application of LLMs for DataOps

The platform evolves from a simple pipeline into a **self-monitoring data system**.
