

ODS PDF FILE="/home/u64327440/Project_1_DM_AE/Safety_Report.pdf" 
         STYLE=HTMLBlue;
/*TASK 1: Import & Inspect Data*/

/*Import demog dataset*/

proc import datafile= '/home/u64327440/Project_1_DM_AE/PROJECT - DATASET.xls' dbms=xls out=demog replace;
sheet = "DM"; 
getnames=yes;
run;
proc sort data=demog out = demog;
BY USUBJID;
RUN;
proc print data= demog;title Demog; run;


/*Import AE dataset*/

proc import datafile= '/home/u64327440/Project_1_DM_AE/PROJECT - DATASET.xls' dbms=xls out=adevent replace;
sheet = "AE"; 
getnames=yes;
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
Perform the following checks in both Base SAS and PROC SQL:
1. AEs with missing AEDECOD
2. AEs where AESTDTC > AEENDTC
3. AEs for subjects <18 years old
4. Identify duplicate AEs using (USUBJID + AEDECOD + AESTDTC)
5. Identify missing values in:
o AESTDTC
o AEENDTC
o AESER
o SEVERITY
Deliverables:
 A cleaned AE dataset
 A report listing all data discrepancies
*/


title "Data Cleaning Report";
/* Check 1: Missing AEDECOD */
proc sql;
select USUBJID, AESTDTC from adevent where missing(AEDECOD);
quit;

/* Check 2: Start Date > End Date :are there any starting date is greater than ending date "--NO--"*/
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

/* Check 5: missing values 
5. Identify missing values in:
o AESTDTC
o AEENDTC
o AESER
o SEVERITY*/

proc sql;
create table Records_With_Missing as
select USUBJID, AESTDTC, AEENDTC, AESER, SEVERITY
from adevent
where missing(AESTDTC) or  missing(AEENDTC) or missing(AESER) or missing(SEVERITY);
quit;



/*---TASK 3: Subject Reconciliation---*/

/*Use PROC SQL JOINs to identify:
1. Subjects in AE but not in DM
2. Subjects in DM with no AEs
3. Count of subjects in each category
Deliverables:
 Reconciliation report table
 List of unmatched subjects*/


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

/*Generate summary outputs:*/
/*---A. Subject-Level AE Summary
1. Total number of subjects*/

title "Total number of subjects in adverse event [AE] dataset";
proc sql;
select count(distinct(USUBJID)) as  total_num_subj
from adevent;
quit;

/*2. Number of subjects with ≥1 AE*/

title "Number of subjects with ≥1 AE";
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

/*---B. Event-Level Summary 
/*Total number of AEs*/ /*Total serious AEs*/ /*Total severe AEs*/

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
/*Join DM and AE datasets.

For each ARM (Drug A / Drug B / Placebo), generate:
| ARM | Total Subjects | Subjects with ≥1 AE | % Subjects with AE |

Deliverables:
 Table generated using PROC SQL*/

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

/*Create a listing of all subjects with AESER = Yes, sorted by:
1. USUBJID
2. AESTDTC

Include columns:
 USUBJID
 AEDECOD
 Severity
 Start/End dates

Deliverables:
 Serious AE Listing in PROC PRINT*/

proc sort data=adevent out=serious_AE;
where upcase(AESER) = "YES";
by USUBJID AESTDTC;
run;

title "Serious AE Listing with AESER = Yes";
proc print data=serious_AE;
var USUBJID AEDECOD SEVERITY AESTDTC AEENDTC;
run;

/*----TASK 7: Country-wise AE Distribution----*/

/*Generate a summary of events by Country using DM+AE merge.

Deliverables:
 Table showing AE counts per country*/


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


/*----TASK 8: Create Final Safety Report Dataset
Create a combined dataset including for each subject:
 USUBJID
 AGE
 SEX
 ARM
 Total AEs
 Serious AEs
 Severe AEs
Deliverables:
 Final ANALYSIS dataset named AE_SUMMARY-----*/



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

/*----BONUS TASK----------------------- how to add rank*/
/*Create a Top Most Common AEs table using SQL:
| Rank | AEDECOD | Count |*/

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
