//CBATCH01 JOB (ACCT#),'CORE BANKING DAILY BATCH',CLASS=A,MSGCLASS=X,
//             NOTIFY=&SYSUID,REGION=0M
//*------------------------------------------------------------------*
//* MODULE: CBATCH01                                                 *
//* DESC  : 10-STEP END-TO-END CORE BANKING BATCH PROCESSING STREAM  *
//* AUTHOR: MAINFRM_ENGINEER / TCS CLIENT BANKING                    *
//*------------------------------------------------------------------*
//JOBLIB   DD DSN=PROD.APPL.LOADLIB,DISP=SHR
//         DD DSN=SYS1.DB2.RUNLIB.LOAD,DISP=SHR
//         DD DSN=SYS1.SORT.MODLIB,DISP=SHR
//*------------------------------------------------------------------*
//* STEP 01: DELETE TEMPORARY SORT WORK DATASETS FROM PREVIOUS RUNS  *
//*------------------------------------------------------------------*
//STEP01   EXEC PGM=IEFBR14
//DEL01    DD DSN=PROD.TEMP.SORTWK01,DISP=(MOD,DELETE,DELETE),
//            SPACE=(CYR,(50,10),,,ROUND),UNIT=SYSDA
//DEL02    DD DSN=PROD.TEMP.INTEXT.REPORT,DISP=(MOD,DELETE,DELETE),
//            SPACE=(CYR,(20,5),,,ROUND),UNIT=SYSDA
//*------------------------------------------------------------------*
//* STEP 02: DB2 UTILITY - RUNSTATS ON CORE ACCOUNTS TABLE           *
//*------------------------------------------------------------------*
//STEP02   EXEC PGM=IKJEFT01,DYNAMNBR=50,REGION=4M
//STEPLIB  DD DSN=DSN.V12R1M0.SDSNLOAD,DISP=SHR
//SYSTSPRT DD SYSOUT=*
//SYSPRINT DD SYSOUT=*
//SYSUDUMP DD SYSOUT=*
//SYSTSIN  DD *
  DSN SYSTEM(DB2P)
  RUN PROGRAM(DSNUTILB) PLAN(DSNUTILS) PARMS('RUNSTATS TABLE(CORE_ACCOUNTS)')
  END
/*
//*------------------------------------------------------------------*
//* STEP 03: EXTRACT ACTIVE ACCOUNTS INTO TEMPORARY FLAT FILE        *
//*------------------------------------------------------------------*
//STEP03   EXEC PGM=IKJEFT01,DYNAMNBR=50,REGION=4M
//SYSTSPRT DD SYSOUT=*
//SYSPRINT DD SYSOUT=*
//SYSUDUMP DD SYSOUT=*
//EXTOUT   DD DSN=PROD.TEMP.INTEXT.REPORT,DISP=(NEW,PASS),
//            UNIT=SYSDA,SPACE=(TRK,(100,50),RLSE),
//            DCB=(RECFM=FB,LRECL=120,BLKSIZE=0)
//SYSTSIN  DD *
  DSN SYSTEM(DB2P)
  RUN PROGRAM(CBEXTRACT) PLAN(CBPLAN01) END
/*
//*------------------------------------------------------------------*
//* STEP 04: SORT EXTRACTED ACCOUNTS BY BALANCE DESCENDING            *
//*------------------------------------------------------------------*
//STEP04   EXEC PGM=SORT,REGION=4M
//SORTIN   DD DSN=PROD.TEMP.INTEXT.REPORT,DISP=(OLD,PASS)
//SORTOUT  DD DSN=PROD.SORT.ACCBAL.SRT,DISP=(NEW,CATLG,DELETE),
//            UNIT=SYSDA,SPACE=(TRK,(100,50),RLSE),
//            DCB=(RECFM=FB,LRECL=120,BLKSIZE=0)
//SYSOUT   DD SYSOUT=*
//SYSIN    DD *
  SORT FIELDS=(50,13,CH,D)
/*
//*------------------------------------------------------------------*
//* STEP 05: COBOL CALCULATION - DAILY INTEREST ACCRUAL ENGINE      *
//*------------------------------------------------------------------*
//STEP05   EXEC PGM=CBINT01,REGION=0M
//STEPLIB  DD DSN=PROD.APPL.LOADLIB,DISP=SHR
//ACCTIN   DD DSN=PROD.SORT.ACCBAL.SRT,DISP=SHR
//ACCUPDT  DD DSN=PROD.CORE.ACCOUNTS.UPDATED,DISP=(NEW,CATLG,DELETE),
//            UNIT=SYSDA,SPACE=(TRK,(150,50),RLSE),
//            DCB=(RECFM=FB,LRECL=150,BLKSIZE=0)
//SYSPRINT DD SYSOUT=*
//SYSUDUMP DD SYSOUT=*
//*------------------------------------------------------------------*
//* STEP 06: CONDITIONAL STEP - CHECK PREVIOUS STEP RETURN CODE      *
//*------------------------------------------------------------------*
//STEP06   EXEC PGM=IEBGENER,COND=(4,LT,STEP05)
//SYSUT1   DD *
  *** INTEREST ACCRUAL COMPLETED SUCCESSFULLY - GENERATING NOTICES ***
/*
//SYSUT2   DD SYSOUT=*
//SYSPRINT DD SYSOUT=*
//*------------------------------------------------------------------*
//* STEP 07: DB2 LOAD UTILITY - POST ACCRUED INTEREST TO DB2 TABLES  *
//*------------------------------------------------------------------*
//STEP07   EXEC PGM=IKJEFT01,DYNAMNBR=50,REGION=4M,COND=(0,NE,STEP05)
//SYSTSPRT DD SYSOUT=*
//SYSPRINT DD SYSOUT=*
//SYSUDUMP DD SYSOUT=*
//SYSREC   DD DSN=PROD.CORE.ACCOUNTS.UPDATED,DISP=SHR
//SYSTSIN  DD *
  DSN SYSTEM(DB2P)
  RUN PROGRAM(DSNUTILB) PLAN(DSNUTILS) 
      PARMS('LOAD DATA INDSN(SYSREC) REPLACE INTO TABLE CORE_ACCOUNTS')
  END
/*
//*------------------------------------------------------------------*
//* STEP 08: GENERATE AUDIT TRAIL REPORT FOR COMPLETED BATCH         *
//*------------------------------------------------------------------*
//STEP08   EXEC PGM=CBAUDITR,REGION=4M
//AUDITIN  DD DSN=PROD.CORE.ACCOUNTS.UPDATED,DISP=SHR
//AUDITOUT DD DSN=PROD.BATCH.AUDIT.REPORT(+1),DISP=(NEW,CATLG,DELETE),
//            UNIT=SYSDA,SPACE=(TRK,(50,20),RLSE),
//            DCB=(RECFM=FB,LRECL=133,BLKSIZE=0)
//SYSPRINT DD SYSOUT=*
//SYSUDUMP DD SYSOUT=*
//*------------------------------------------------------------------*
//* STEP 09: BACKUP CRITICAL LEDGER DATASET TO OFFSITE TAPE          *
//*------------------------------------------------------------------*
//STEP09   EXEC PGM=IEBGENER
//SYSUT1   DD DSN=PROD.CORE.ACCOUNTS.UPDATED,DISP=SHR
//SYSUT2   DD DSN=BACKUP.CORE.ACCOUNTS.G0001V00,DISP=(NEW,CATLG,DELETE),
//            UNIT=(TAPE,,DEFER),VOL=(,,SER=TAPE01),
//            DCB=(RECFM=FB,LRECL=150,BLKSIZE=27900)
//SYSPRINT DD SYSOUT=*
//*------------------------------------------------------------------*
//* STEP 10: HOUSEKEEPING - PURGE TEMPORARY WORK FILES              *
//*------------------------------------------------------------------*
//STEP10   EXEC PGM=IEFBR14
//PURGE01  DD DSN=PROD.SORT.ACCBAL.SRT,DISP=(OLD,DELETE,DELETE)
//PURGE02  DD DSN=PROD.TEMP.INTEXT.REPORT,DISP=(OLD,DELETE,DELETE)
