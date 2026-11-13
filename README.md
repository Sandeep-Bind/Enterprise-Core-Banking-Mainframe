# Enterprise Core Banking Mainframe Processing & Batch Automation Framework

An institutional-grade mainframe engineering architecture simulating high-volume core retail banking operations. This framework integrates **IBM z/OS JCL 10-step job streams**, **COBOL computational modules (COMP-3 decimals)**, and **DB2 relational storage** to execute automated daily interest accruals, account balance updates, sorting, utilities, and 24x7 Global Operations Centre (GOC) monitoring.

---

## 🏗️ Architectural Overview & Data Flow

```
+--------------------+      Control-M / OPC      +--------------------+
|  Control-M / OPC   | ------------------------> |    10-Step JCL     |
| Scheduler Workflow |                           |    (CBATCH01.jcl)  |
+--------------------+                           +--------------------+
                                                           |
                                                           v
+--------------------+      DB2 SQL Queries      +--------------------+
|   DB2 Relational   | <------------------------ |   COBOL Program    |
| Table: CORE_ACCT   |      (COMP-3 Decimals)    |  (CBINT01.cbl)     |
+--------------------+                           +--------------------+
```

1. **Scheduling Layer:** Enterprise schedulers (Control-M and OPC) trigger daily batch windows based on dependency graphs.
2. **Execution Layer (JCL):** Job Control Language allocates datasets, configures `STEPLIB` concatenations, invokes DFSORT, and runs DB2 CAF/TSO attachment facility (`IKJEFT01`) across 10 structured steps.
3. **Computation Layer (COBOL):** High-performance COBOL programs process financial records using packed decimal arithmetic (`COMP-3`) to prevent rounding errors during interest computations.
4. **Persistence Layer (DB2):** DB2 SQL statements update relational account ledgers transactionally with committed unit-of-work boundaries.

---

## 📂 Repository Structure & Modules

* **`cobol/`**: Contains core banking source programs handling business logic, interest calculations, and error handling.
* **`jcl/`**: Production-ready 10-step job streams containing JOB cards, EXEC statements, conditional code handling (`COND`), and DB2 runner definitions.
* **`db2/`**: DDL schema definitions and database migration scripts for core account ledgers.
* **`config/`**: Scheduler topology rules and GOC incident escalation matrices.
* **`docs/`**: Comprehensive runbooks for 24x7 production support and major incident management.
* **`.github/workflows/`**: CI/CD pipelines for automated syntax and pipeline validation.

---

## ⚙️ Key Technical Specifications
* **Mainframe Environment:** IBM z/OS, DB2 Universal Database, CICS TS.
* **Batch Scheduling:** Control-M, IBM OPC (Operations Planning and Control), Splunk Log Monitoring.
* **Data Representation:** COMP-3 packed decimals for precise financial calculations, PIC X(n) strings, and zoned decimals.
