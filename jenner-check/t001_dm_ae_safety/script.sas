/*
  Project_DM_AE.sas -- adapted for a self-contained Jenner run.

  The original imports the DM and AE sheets from an Excel workbook via
  PROC IMPORT and writes the safety report to an absolute ODS PDF path.
  For a portable run, the two PROC IMPORT steps are replaced with DATA
  steps that carry the same DM/AE columns and rows, and the ODS PDF path
  is made relative. Everything downstream -- the PROC SQL cleaning and
  reconciliation, the PROC FREQ summaries, PROC RANK, and the
  %select_arm macro -- is unchanged repo logic.
*/

ODS PDF FILE="Safety_Report.pdf"
         STYLE=HTMLBlue;

/*TASK 1: Import & Inspect Data*/

/* DM (Demographics) -- same columns/rows as the "DM" sheet */
data demog;
  length STUDYID $8 USUBJID $12 SEX $1 RACE $10 ARM $8 COUNTRY $14;
  infile datalines dsd dlm=',';
  input STUDYID $ USUBJID $ AGE SEX $ RACE $ ARM $ COUNTRY $;
  datalines;
ONC101,ONC101-001,54,F,ASIAN,Drug A,India
ONC101,ONC101-002,62,M,WHITE,Drug B,USA
ONC101,ONC101-003,47,F,ASIAN,Drug A,India
ONC101,ONC101-004,58,M,BLACK,Drug B,Kenya
ONC101,ONC101-005,39,F,HISPANIC,Placebo,Brazil
ONC101,ONC101-006,66,F,WHITE,Drug A,Germany
ONC101,ONC101-007,51,M,ASIAN,Placebo,India
ONC101,ONC101-008,45,F,WHITE,Drug B,Greece
ONC101,ONC101-009,72,M,BLACK,Drug A,South Africa
ONC101,ONC101-010,57,F,ASIAN,Drug B,India
;
run;

proc sort data=demog out = demog;
BY USUBJID;
RUN;
proc print data= demog;title Demog; run;


/* AE (Adverse Events) -- same columns/rows as the "AE" sheet */
data adevent;
  length STUDYID $8 USUBJID $12 AEDECOD $20 AESTDTC $10 AEENDTC $10 AESER $3 SEVERITY $8;
  infile datalines dsd dlm=',';
  input STUDYID $ USUBJID $ AEDECOD $ AESTDTC $ AEENDTC $ AESER $ SEVERITY $;
  datalines;
ONC101,ONC101-001,HEADACHE,2023-03-04,2023-03-06,No,Mild
ONC101,ONC101-001,NAUSEA,2023-04-01,2023-04-02,No,Moderate
ONC101,ONC101-002,ANEMIA,2023-03-15,2023-03-20,Yes,Severe
ONC101,ONC101-003,VOMITING,2023-02-10,2023-02-12,No,Mild
ONC101,ONC101-003,FATIGUE,2023-02-25,2023-03-01,No,Moderate
ONC101,ONC101-004,PYREXIA,2023-03-10,2023-03-12,No,Mild
ONC101,ONC101-004,NEUTROPENIA,2023-03-15,2023-03-18,Yes,Severe
ONC101,ONC101-005,HEADACHE,2023-01-05,2023-01-06,No,Mild
ONC101,ONC101-007,INJECTION SITE PAIN,2023-03-20,2023-03-21,No,Mild
ONC101,ONC101-009,LOSS OF APPETITE,2023-02-18,2023-02-25,No,Moderate
;
run;

proc sort data=adevent out = adevent;
BY USUBJID;
RUN;
proc print data= adevent;title Adverse event; run;


/*PROC CONTENTS output*/
proc contents data=demog;run;
proc contents data = adevent;run;


/*
TASK 2: Data Cleaning & Validation
*/


title "Data Cleaning Report";
/* Check 1: Missing AEDECOD */
proc sql;
select USUBJID, AESTDTC from adevent where missing(AEDECOD);
quit;

/* Check 2: Start Date > End Date */
proc sql;
select USUBJID, AEDECOD, AESTDTC, AEENDTC
from adevent
where AESTDTC > AEENDTC;
quit;

/* Check 3: Age < 18 (Protocol Violation) */
proc sql;
select USUBJID, AGE
from demog
where AGE < 18;
quit;

/* Check 4: Duplicates */
proc sort data=adevent nodupkey out=DUP_CHECK dupout=dup_ae_records;
by USUBJID AEDECOD AESTDTC;
run;

/* Check 5: missing values */

proc sql;
create table Records_With_Missing as
select USUBJID, AESTDTC, AEENDTC, AESER, SEVERITY
from adevent
where missing(AESTDTC) or  missing(AEENDTC) or missing(AESER) or missing(SEVERITY);
quit;



/*---TASK 3: Subject Reconciliation---*/

/* 1. Subjects in AE but not in DM */

title "Subjects in AE but not in DM";
proc sql;
create table subj_in_AE_not_DM as
select distinct a.USUBJID
from adevent as a
left join demog as d
on a.USUBJID = d.USUBJID
where d.USUBJID is null;
quit;

proc print data = subj_in_AE_not_DM;run;

/* 2. Subjects in DM with no AEs */

title "Subjects in DM with no AEs ";
proc sql;
create table subj_in_DM_no_AE as
select distinct d.USUBJID
from demog as d
left join adevent as a
on d.USUBJID = a.USUBJID
where a.USUBJID is null;
quit;

proc print data = subj_in_DM_no_AE;run;


/*----3. Count of subjects in each category----*/
title "Count of subjects in each category";
proc sql;
select count(distinct(DM.USUBJID)) as SUBJECT_COUNT_IN_DEMOG,
count(distinct(AE.USUBJID)) as SUBJECT_COUNT_IN_AE
from demog as DM, adevent as AE;
quit;


/*TASK 4: Summary of AEs*/

title "Total number of subjects in adverse event [AE] dataset";
proc sql;
select count(distinct(USUBJID)) as  total_num_subj
from adevent;
quit;

/*2. Number of subjects with >=1 AE*/

title "Number of subjects with >=1 AE";
proc sql;
select USUBJID, count(USUBJID) as num_of_AE_per_subj
from adevent
group by USUBJID
having count(USUBJID) >= 1;
quit;


/*3. % of subjects with AEs*/

title "% of subjects with AEs";
proc freq data = adevent;
tables USUBJID /nocol nocum nofreq;
run;

/*---B. Event-Level Summary */

title "Event-Level Summary if AESER = 'Yes' and SEVERITY = 'Severe ";
proc sql;
select count(*) as Total_AEs,
sum(AESER = 'Yes') as Total_serious_AEs,
sum(SEVERITY = 'Severe') as Total_severe_AEs
from adevent;
quit;


/* AE counts by Preferred Term (AEDECOD) */

title "AE counts by Preferred Term (AEDECOD)";
proc freq data=adevent;
tables AEDECOD / nocum nopercent nocol;
run;

/* AE counts by Severity */
title "AE Counts by Severity";
proc freq data=adevent;
tables SEVERITY / nocum nopercent nocol;
run;


/*----TASK 5: AE Incidence by Treatment Arm----*/

proc sql;
create table arm_total as
select ARM, count(distinct (USUBJID)) as Total_Subjects
from demog
group by ARM;
quit;


proc sql;
create table arm_with_ae as
select dm.ARM, count(distinct dm.USUBJID) as Subjects_with_AE
from demog dm
inner join adevent ae
on dm.USUBJID = ae.USUBJID
group by dm.ARM;
quit;


proc sql;
create table AE_Incidence_by_ARM as
select t.ARM, t.Total_Subjects, w.Subjects_with_AE,
    (w.Subjects_with_AE / t.Total_Subjects)*100
        as Pct_Subjects_with_AE format=6.2
from arm_total t
left join arm_with_ae w
on t.ARM = w.ARM
order by t.ARM;
quit;

proc print data=AE_Incidence_by_ARM;
title "AE Incidence by Treatment Arm";
run;



/*----TASK 6: Serious AE Listing----*/

proc sort data=adevent out=serious_AE;
where upcase(AESER) = "YES";
by USUBJID AESTDTC;
run;

title "Serious AE Listing with AESER = Yes";
proc print data=serious_AE;
var USUBJID AEDECOD SEVERITY AESTDTC AEENDTC;
run;

/*----TASK 7: Country-wise AE Distribution----*/


DATA merge_DM_AE;
MERGE demog adevent;
BY USUBJID;
RUN;

PROC PRINT DATA=merge_DM_AE;
title merge dataset of demog and AE ;
RUN;

title "Country-wise AE Distribution";
proc freq data = merge_DM_AE;
table country*AEDECOD / nocol nocum nopercent norow ;
run;


/*----TASK 8: Create Final Safety Report Dataset----*/


proc sql;
create table AE_SUMMARY as
select dm.USUBJID, dm.AGE, dm.SEX, dm.ARM,
	count(ae.AEDECOD) as Total_AEs,
	sum(upcase(ae.AESER) = "YES") as Serious_AEs,
	sum(upcase(ae.SEVERITY) = "SEVERE") as Severe_AEs
from demog dm left join adevent ae on dm.USUBJID = ae.USUBJID
group by dm.USUBJID, dm.AGE, dm.SEX, dm.ARM;
quit;

proc print data = AE_SUMMARY;
title "Final Safety Report Dataset";
run;

/*----BONUS TASK: how to add rank----*/

title "Top Most Frequent Adverse Events";
proc sql;
create table common_AE as
select AEDECOD, count(*) as Event_Count
from adevent
group by AEDECOD
order by Event_Count desc;
quit;

proc sort data=common_AE out=ranked_AE;
by descending Event_Count;
run;

proc rank data=ranked_AE out=ranked_AE ties = dense descending;
var Event_Count;
ranks Rank;
run;

data ranked_AE;
retain Rank AEDECOD Count; /* Desired order */
set ranked_AE;
run;
proc print data = ranked_AE;run;

ODS PDF CLOSE;




/*1. generate AE listings for all treatment arms using macro*/

proc sql;
create table dm_ae_data as
select *
from demog dm
full join adevent ae
on dm.USUBJID = ae.USUBJID;
quit;
proc print data = dm_ae_data;run;

data dm_ae_data_std;
set dm_ae_data;
ARM_STD = tranwrd(upcase(strip(ARM)),' ','_');
run;

proc print data=dm_ae_data_std;
title "ARM standardized";
run;

%macro select_arm(E);

proc sql;
create table &E._arm as
select AEDECOD
from dm_ae_data_std
where Upcase(ARM_STD)= "&E.";
quit;

proc print data = &E._arm;
title "AE Listing for &E";run;

%mend;

/*arm are :DRUG_A, DRUG_B, PLACEBO */


%select_arm(DRUG_A);

%select_arm(DRUG_B);

%select_arm(PLACEBO);
