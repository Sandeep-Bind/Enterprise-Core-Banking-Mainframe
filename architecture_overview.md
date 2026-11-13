# Enterprise Core Banking Architecture & Design

## 1. Overview
This document outlines the architecture of the core banking batch processing framework, utilizing IBM z/OS mainframes, COBOL computational engines, and DB2 databases.

## 2. Batch Execution Lifecycle
* **Scheduling:** Managed via Control-M / OPC dependency graphs.
* **Execution:** 10-step JCL stream (`CBATCH01.jcl`) handling dataset cleanup, stats collection, sorting, interest computation, DB2 loading, and tape backups.
