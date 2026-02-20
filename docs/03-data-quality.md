# Data Quality

Reliable data is critical for decision-making.  
This project implements a multi-layer data quality strategy to ensure that business metrics remain accurate, consistent and trustworthy.

Data validation is applied across the entire pipeline using automated tests, contracts and fail-fast execution.

---

## Quality Strategy Overview

Quality controls are implemented at multiple levels:

| Layer | Tool | Purpose |
|------|------|---------|
| Bronze / Silver | Great Expectations | Structural and technical validation |
| Gold | dbt Tests | Business integrity and relational consistency |
| Operations | OpenClaw | Failure detection and incident monitoring |

Total coverage:
- **300+ automated tests**
- Validation across ingestion, transformation and business layers

---

## Bronze Layer Quality

Purpose:
Ensure raw data integrity before processing.

Validation examples:
- File existence and completeness
- Schema validation
- Row count checks
- Data type consistency
- Primary key uniqueness

Why it matters:
Early detection prevents corrupted data from propagating downstream.

---

## Silver Layer Quality

### Validation Example

![Great Expectations Validation](../screenshots/ge_validation.png)

The Silver layer represents the **operational source of truth**, so strict validation is applied.

Validation types:

### Structural Checks
- Primary key uniqueness
- Not null constraints
- Accepted values for categorical fields

### Semantic Checks
- Geographic coordinates within Brazil range
- Timestamp validity
- Monetary values ≥ 0
- Status standardization

### Transformation Validation
- Deduplication success
- Join integrity
- Enrichment completeness (e.g., geolocation coverage)

Silver validation ensures data is **clean, standardized and analytics-ready**.

---

## Gold Layer Quality (dbt)

dbt enforces relational and business-level quality.

Test categories:

### Generic Tests
- `unique`
- `not_null`
- `relationships`
- `accepted_values`

### Business Integrity Examples
- Facts reference valid dimension keys
- One row per business grain (order, review)
- Aggregations reconcile with base tables

### Coverage

- 20+ dbt models
- 300+ total tests across pipeline
- 100% passing rate

dbt also provides:
- Model lineage
- Documentation
- Version control for transformations

---

## Freshness Monitoring

Source freshness is monitored through dbt.

Checks include:
- Last update timestamp
- Expected update frequency
- Detection of stale sources

Freshness failures generate operational events consumed by the OpenClaw agent.

---

## Fail-Fast Principle

The pipeline follows a **fail-fast strategy**:

If a validation fails:
- Downstream tasks are blocked
- The issue is logged
- An operational event is generated
- OpenClaw evaluates the incident

This prevents incorrect data from reaching dashboards.

---

## Data Contracts

Quality rules act as implicit data contracts:

- Defined schemas
- Controlled value domains
- Stable grain definitions
- Relationship enforcement

This ensures consistency even as the platform evolves.

---

## Quality Metrics (Examples)

- Bronze integrity: 100% file validation
- Silver tables: fully validated (8 core tables)
- Gold layer: 300+ tests
- Aggregations reconciliation checks
- Pipeline success rate monitored via Airflow

---

## Integration with DataOps (OpenClaw)

When a quality test fails:

1. dbt or Airflow generates an error artifact  
2. A monitoring DAG parses the results  
3. An event is stored in **BigQuery (`olist_ops`)**  
4. OpenClaw:
   - Classifies severity (P1 / P2)
   - Diagnoses root cause
   - Retrieves relevant runbook context (RAG)
   - Generates Top 3 corrective actions (Gemini)
   - Sends alert via Discord  

This enables **automated incident response for data quality issues**.

---

## Why This Matters

Most data projects focus only on dashboards.

This project demonstrates:

- End-to-end quality enforcement
- Automated validation at scale
- Governance and data contracts
- Operational monitoring
- Integration between Data Engineering and AI-driven DataOps