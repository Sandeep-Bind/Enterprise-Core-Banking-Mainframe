-- =========================================================================
-- DATABASE: DB2P (Production Core Banking)
-- TABLE   : CORE_ACCOUNTS
-- DESC    : Stores primary account holder financial metrics and balances
-- =========================================================================

DROP TABLE CORE_ACCOUNTS;

CREATE TABLE CORE_ACCOUNTS (
    ACCOUNT_ID       CHAR(12) NOT NULL,
    CUSTOMER_NAME    VARCHAR(50) NOT NULL,
    ACCOUNT_TYPE     CHAR(3) NOT NULL, -- 'SAV' or 'CUR'
    BALANCE          DECIMAL(13, 2) NOT NULL,
    INTEREST_ACCRUED DECIMAL(11, 4) DEFAULT 0.0000,
    STATUS           CHAR(1) NOT NULL, -- 'A' = Active, 'I' = Inactive
    LAST_UPDATED     TIMESTAMP NOT NULL,
    PRIMARY KEY (ACCOUNT_ID)
);

CREATE INDEX IDX_ACC_STATUS ON CORE_ACCOUNTS(STATUS);
