       IDENTIFICATION DIVISION.
       PROGRAM-ID. CBINT01.
      *----------------------------------------------------------------*
      * MODULE: CBINT01                                                *
      * DESC  : CORE BANKING DAILY INTEREST ACCRUAL & DB2 BATCH UPDATE *
      * AUTHOR: ENTERPRISE MAINFRAME ENGINEERING TEAM                  *
      *----------------------------------------------------------------*
       ENVIRONMENT DIVISION.
       DATA DIVISION.
       WORKING-STORAGE SECTION.
       01  WS-CONSTANTS.
           05  WS-INTEREST-RATE    PIC V999 VALUE .0485.
       01  WS-COUNTERS.
           05  WS-READ-COUNT       PIC 9(7) COMP VALUE ZERO.
           05  WS-UPDATE-COUNT     PIC 9(7) COMP VALUE ZERO.
       01  WS-CALCS.
           05  WS-COMPUTED-INT     PIC S9(9)V99 COMP-3 VALUE ZERO.

      * DB2 SQL Communication Area & Host Variables
           EXEC SQL INCLUDE SQLCA END-EXEC.

       01  HB-ACCOUNT.
           05  HB-ACCOUNT-ID       PIC X(12).
           05  HB-BALANCE          PIC S9(11)V99 COMP-3.
           05  HB-INTEREST         PIC S9(9)V99 COMP-3.
           05  HB-STATUS           PIC X(1).

       PROCEDURE DIVISION.
       0000-MAIN-LOGIC.
           DISPLAY '=================================================='.
           DISPLAY 'CBINT01: BATCH INTEREST CALCULATION STARTED'.
           DISPLAY '=================================================='.

           PERFORM 1000-OPEN-CURSOR.
           PERFORM 2000-PROCESS-ACCOUNTS UNTIL SQLCODE < 0 OR SQLCODE = 100.
           PERFORM 3000-CLOSE-CURSOR.

           DISPLAY '--------------------------------------------------'.
           DISPLAY 'TOTAL ACCOUNTS READ    : ', WS-READ-COUNT.
           DISPLAY 'TOTAL ACCOUNTS UPDATED : ', WS-UPDATE-COUNT.
           DISPLAY 'CBINT01: BATCH PROCESSING COMPLETED SUCCESSFULLY'.
           DISPLAY '=================================================='.
           GOBACK.

       1000-OPEN-CURSOR.
           EXEC SQL
               DECLARE C1 CURSOR FOR
               SELECT ACCOUNT_ID, BALANCE, STATUS
               FROM CORE_ACCOUNTS
               WHERE STATUS = 'A' AND BALANCE > 0
               FOR UPDATE OF INTEREST_ACCRUED, BALANCE
           END-EXEC.

           EXEC SQL OPEN C1 END-EXEC.
           IF SQLCODE NOT = ZERO
               DISPLAY 'ERROR: FAILED TO OPEN CURSOR C1. SQLCODE: ' SQLCODE
               PERFORM 9999-ABEND-ROUTINE
           END-IF.

       2000-PROCESS-ACCOUNTS.
           EXEC SQL
               FETCH C1 INTO :HB-ACCOUNT-ID, :HB-BALANCE, :HB-STATUS
           END-EXEC.

           IF SQLCODE = 100
               NEXT SENTENCE
           ELSE IF SQLCODE = ZERO
               ADD 1 TO WS-READ-COUNT
               
               * Computation Work: Calculate Daily Accrued Interest using COMP-3
               COMPUTE WS-COMPUTED-INT ROUNDED = 
                   HB-BALANCE * WS-INTEREST-RATE / 365
               
               * DB2 Update Operation
               EXEC SQL
                   UPDATE CORE_ACCOUNTS
                   SET INTEREST_ACCRUED = INTEREST_ACCRUED + :WS-COMPUTED-INT,
                       BALANCE = BALANCE + :WS-COMPUTED-INT,
                       LAST_UPDATED = CURRENT TIMESTAMP
                   WHERE CURRENT OF C1
               END-EXEC

               IF SQLCODE = ZERO
                   ADD 1 TO WS-UPDATE-COUNT
               ELSE
                   DISPLAY 'ERROR: UPDATE FAILED FOR ACC: ' HB-ACCOUNT-ID 
                           ' SQLCODE: ' SQLCODE
                   PERFORM 9999-ABEND-ROUTINE
               END-IF
           ELSE
               DISPLAY 'ERROR: FETCH FAILED. SQLCODE: ' SQLCODE
               PERFORM 9999-ABEND-ROUTINE
           END-IF.

       3000-CLOSE-CURSOR.
           EXEC SQL CLOSE C1 END-EXEC.

       9999-ABEND-ROUTINE.
           DISPLAY 'CRITICAL ABEND IN CBINT01. ISSUING U9999.'
           MOVE 9999 TO RETURN-CODE
           GOBACK.
