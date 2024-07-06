  
***************************************************************; 
****    Dly_PreFunding_Fraud_Detection_Rpt.sas                  ;                   
****                                                           ;  
****    At-Task Ref. # 430333   ;  
****
****    /* * Purpose: Create prefunding fraud detection tool using Fraud DB
            MeDB, GAAR & CL data. 
            Data set is exported to Excel.  */;
****    Frequency: Daily including holidays and weekends ;                            
****                                                           
****    Files Used:  PUCA Table - From - \\Ga016a502\dorsshare\QC_Prefunding_Audit_Log ;         
****                 medb1.t_ln;
****                 medb.v_pivot_ln_stat;
****                 medb.t_brrwr;
****                 medb.t_prpty;
****                 medb.t_brrwr_addr;
****                 medb.t_ctr;
****                 medb.t_pgm;
****                 medb.t_mkt_area;
****                 medb.t_rgn;
****                 medb.t_thrd_party_orig;
****                 medb.t_disb;
****                 medb.t_risk_mnge;
****                 medb.t_purps;
****                 medb.t_prpty_ty;
****                 medb.t_uw;
****                 medb.t_relat_party_ln_role;
****                 medb.t_relat_party;
****                 UWTrack.uwt_EmployeeExtract;
****                 LZ_EMP_MRTG_EMPOWER_RDX.LN_CODES ;
****                 LZ_EMP_MRTG_EMPOWER_RDX.LN_CURRADDR;
****                 LZ_EMP_MRTG_EMPOWER_RDX.LN_DECLARES;
****                 FCRM_Rpt.vw_originators;
****                 fncinc.FIRSTRecv_CMS_Loan_Data;
****                 fncinc.GAAR_Loan_Data;
****                 sashelp.zipcode;  
****                     
****    Change Notes  														;
****    Created 07/19/2016 Nirav Shah								        ;   
****    Modified 02/06/2018 Nirav Shah - Modified for First Time Home Buyer Flag - Reference # 1256697 ; 
****    Modified 06/13/2022 Shraddha changed UWTrack to MCRM
***************************************************************;

/* below comments was from Linda D from CRMA before automation */

************************************************************************;
* Program: Daily PreFunding Fraud Detection Report
* Created By: Linda DeGaust
* Created Date: 12/2011 
* Requested By: Fraud and Coll Risk Mgmt (FCRM)
* Purpose: Create prefunding fraud detection tool using Fraud DB
            MeDB, GAAR & CL data. 
            Data set is exported to Excel. 
* Output File Names: 
                  "Loan_Level_Details" is exported into
                  "S:\MORTGAGE_SHARED\SHARED\FCRM_DB\Tool_Live\PreFunding Fraud Detection Reports\PreFundingFraudDetection_asof_&outfilenm..xlsx
                  and Loan_Level_Details_Archive is exported as sas dataset into
                  S:\MORTGAGE_SHARED\SHARED\FCRM_DB\Tool_Live\PreFunding Fraud Detection Reports\HistoricalList
                  as an historical copy
************************************************************************;
************************************************************************;
************************************************************************;
************************************************************************;
* Change Log:
****11/9/2015 added DTI & Process type to the data pull and then three flags--Risky_State_Potential_Flg, Prop_Dist_Potential_Flg &
DTI_Potential_Flg based on EMiner research
****7/10/15 added three queries just above medb6a data set to get empower campus data
also added the three campuses to medb6 query and down in the varlists at the bottom
****7/9/2015 replaced a.frst_tm_hme_buyer_flg with
case when input(substr(a.ln_nbr,1,1),1.) eq 4 and a.frst_tm_hme_buyer_flg = '' then "N" else a.frst_tm_hme_buyer_flg end as frst_tm_hme_buyer_flg, 
when creating table dataset. Empower doesn't populate field w/Y or N like MLCS did, It is either Y or "". Need ln_nbr parameter until all production is in Empower
****7/9/2015 added field to calculate borrower age since Empower is not populated consistently where "dataset5" is created--also added to select statement
**at join--also removed "input" in final_dataset7 since creating number in dataset5
****4/14/2015 changed path for colo_daily file from dshare to d_corelogic_nt since appears dshare stopped being 
updated as of 1/1/2015.
****10/30/2014 changed path for log to 
"/F01/CreditRisk/Private/COMMON/LindaD/Reports--Recurring/PreFundLog&outfilenm..txt". 
didn't work 1st couple of times but changed folder properties to wide open 
and then it seemed to work.  
****added FHA_FLAG to first query so they can do some targeted reviews.
****added Scnd_Hm_LT10Mi flag to weighting data step but did not add to score yet.
****10/02/2014 changed path for active employee file from my folder on R to Common folder 
in CRM's Private drive. 
****10/01/2014 changed path for active employee file from DaveH folder to mine. 
****05/8/2014 moved Est Closed Date to the end per 4/21/2014 email from Donna. 
****04/09/2014 this code replaced previous daily report. First report date run using
new logic is the 4/7/2014 report "PreFundingFraudDetection_asof_2014-04-07.xlsb"
****03/12/2014 recvd approval to changes and answers to questions from FCRM
****02/10/2014 added HUB, UW Vendor, settlement agent name, and a Y/N institutional
seller flag (there is a 1/0 one now used for code). Also added some "place holder"
fields, removed some other fields and changed order of remaining fields for 
FCRM's export (all above requested by FCRM via email on 1/7/2014). This is all
to make it easier to import of all the "detection reports" (prefunding, postfunding, 
CL closed loan audit, etc.) into the new, single FCRM audit Access DB. 
****12/06/2013 changed score for Renter_2ndHome & Renter_Investor_YN from 2 
to 9 per Larry's request (through Maria). 
****07/30/2013 EG now working for this code. Moved archive to S and changed 
code to hit decan2 
****05/29/2013 moved archive to c until can get EG to work (pending access to
S). Can't move to decan2 now since that needs access to unix and automated 
code can't hit unix. Once it is in eminer, I can hit decan2 in automated code.  
****04/23/2013 changed overall score % denominator from 36 to 30 to remove
all instances of mutually exclusive parameters. 
EXAMPLE: Refi_2ndHome and Refi_Inv cannot exist on the same loan
****04/05/2013 changed compare to archive logic to use scoring # instead of percentage
percentage wasn't always finding match. 
****02/19/2013 added logic if "purps_desc = "Purchase" or cp_flg = "Y" then addr_match_score = 0
in Weighting section since these fields don't exist b4 Addr Match Score section 
****01/03/2013 changed logic to use approved entry date instead of approved date
****12/28/2012 added new CoreLogic_Flag 
****10/31/2012 added parameters for borr/prop distance & changed over to new
        ls_fraud_score
****09/25/2012 added property/mailing address compare
;

/*to manually set export file name
%let outfilenm=PreFundingFraudDetectionTest_2011-12_v3;
*/

/***automatically limits & names report to previous CALENDAR day
/****NOTE: if just use "month(today())-1 ge 10" in if statement,
****       it messes up at the end of the year and adds 0 before the 12 
****       because today's month (01) minus 1 = 0. 
****       Does not mess up if use intnx since that understands calendar*/

/* above comments was from Linda D from CRMA before automation */
/*Please email to john.e.pagels@truist.com,Christopher.Matteo@truist.com if the file v2_PR_UW_CL_Mgt_Table_ is not available*/

%macro rpt();

%let counterr=0; /* initialize error counter */

****************Place this at top of code start - macro for error *************************;
%Macro runquit; /* create a macro to use at end of data and proc steps. */

; run; quit;

%if %eval(&syserr > 4) %then %do ;
	%let counterr = %eval(&counterr. + 1);
%end;

%Mend runquit ;

%let Rundate=&Rundate;    

data _NULL_;
	call symput('Tdate',input(&currdate_sql,yymmdd10.));
%runquit;

%put "Current date: &currdate_sql &Tdate";
%let year = %sysfunc(Year(&Tdate)); 

data _null_;
call symput('asof_dt',trim(left(put(intnx('day',&Rundate.,-1,'e'),worddate18.))));
call SYMPUT('end_dt', put(intnx('day',&Rundate,-1,'e'),YYMMDDN8.));
call symput('outfilenm',put(intnx('day',&Rundate,-1),yymmddd10.));
call symput('rptdate',intnx('day',&Rundate,-1));

CALL symput("InDt_C",trim(left(put(&Tdate.,yymmn6.))));
CALL symput("InDt_P",trim(left(put(&month_end_date.,yymmn6.))));

%runquit;  

%put &end_dt;  
%put &asof_dt;
%put &outfilenm;
%put &rptdate.;
%put &outfilenm.;
%put &InDt_C;
%put &InDt_P;

***************************************************************;
****  Inputs;
***************************************************************;  
%LET st = %SYSFUNC(DATE(),MMDDYY10.) %SYSFUNC(TIME(),TOD.);
%PUT Start Time:	&st;
%put OUTDIR=&outdir;
***** Standard footnotes for reporting;
/*%LET FNote1	=Confidential and Proprietary Information. Property of SunTrust Banks, Inc. For Internal Use Only.;
%Let FNote2 = Dly_PreFunding_Fraud_Detection_Rpt;  */
***** Name of the report;
%LET ReportName	= Dly_PreFunding_Fraud_Detection_Rpt_;
%LET ReportOut=&ReportName.&end_dt;
%LET VERSION = V1;
%PUT REPORTNAME=&ReportName;
%PUT REPORTOUT=&ReportOut;   

options fmtsearch=(work);
%let x= %sysfunc(getoption(work));
filename fmt %str("&x./formats.sas7bcat");
%put &syshostname. %sysfunc(datetime(), datetime22.);

options fullstimer mlogic msglevel=i notes threads compress=yes symbolgen;
%put &syshostname. %sysfunc(datetime(), datetime22.);

/*%Let InPath_QC     = /dorsshare/QC_Prefunding_Audit_Log;*/
%Let InPath_QC     = %str(&dorsshare.\Public_Originations\QC_Prefunding_Audit_Log);
%global InFileName;

/*libname MPRDPref '/R4/rskanl07/mbio_prod/PreFunding_Fraud_Detection';  
this can be removed - dataset now stored in rptdata/mortgage */ 

%macro FileExist;
	%if %sysfunc(fileexist(&InPath_QC./v2_PR_UW_CL_Mgt_Table_&InDt_C..xlsx)) %then
		%Let InFileName = v2_PR_UW_CL_Mgt_Table_&InDt_C..xlsx;
	%else
		%Let InFileName = v2_PR_UW_CL_Mgt_Table_&InDt_P..xlsx;
%mend FileExist;
%FileExist;
%put InFileName= &InFileName;

options symbolgen validvarname=v7;  
 
libname xlsfile pcfiles type=excel server=&pcfilesvr.  port=9621  
SERVERUSER=&suserid. SERVERPASS=&mypass.
path="&InPath_QC.\&InFileName.";
data CL;
set xlsfile.'CL$'n; 
%runquit;
data UW;
set xlsfile.'UW$'n; 
%runquit;
data PR;
set xlsfile.'PR$'n; 
%runquit;
data AA;
set xlsfile.'AA$'n; 
%runquit;
data LO;
set xlsfile.'LO$'n; 
%runquit;
data LSS;
set xlsfile.'LSS$'n; 
%runquit;
data LOS;
set xlsfile.'LOS$'n; 
%runquit;
/*
proc import 
	out=CL 
	datafile="&InPath_QC./&InFileName" 
	dbms=xls 
	replace; 
	sheet='CL'; 
%runquit;

proc import 
	out=UW
	datafile="&InPath_QC./&InFileName" 
	dbms=xls 
	replace; 
	sheet='UW'; 
%runquit; 
proc import 
	out=PR
	datafile="&InPath_QC./&InFileName" 
	dbms=xls 
	replace; 
	sheet='PR'; 
%runquit;
proc import 
	out=AA
	datafile="&InPath_QC./&InFileName" 
	dbms=xls 
	replace; 
	sheet='AA'; 
%runquit;

proc import 
	out=LO
	datafile="&InPath_QC./&InFileName" 
	dbms=xls 
	replace; 
	sheet='LO'; 
%runquit;
proc import 
	out=LSS
	datafile="&InPath_QC./&InFileName" 
	dbms=xls 
	replace; 
	sheet='LSS'; 
%runquit;
proc import 
	out=LOS
	datafile="&InPath_QC./&InFileName" 
	dbms=xls 
	replace; 
	sheet='LOS'; 
%runquit;*/

data PUCA (keep=name racfid rename=(racfid=racf_ID));
format racfid $10. name $40.;
set 
LO (keep=name racfid Active_Inactive)
AA (keep=name racfid Active_Inactive) 
CL (keep=name racfid Active_Inactive) 
UW (keep=name racfid Active_Inactive) 
PR (keep=name racfid Active_Inactive)
LSS (keep=name racfid Active_Inactive)
LOS (keep=name racfid Active_Inactive)
; 
if Active_Inactive = "Active" and racfid ne "";
%runquit;

proc sort data=puca nodupkey;
by racf_id;
%runquit;

Data ActiveSTM;
Set puca;
%runquit;  

/* Added for First Time Home Buyer Flag - Reference # 1256697 */


Proc Sql;
Create Table MeDB_T_LN_FTHB AS
Select
LN_ID,
LN_NBR,
PURPS_CD,
FRST_TM_HME_BUYER_FLG,
SYS_SRC_CD 
From
MeDB1.T_LN;
%runquit;

Proc Sql;
Create Table MeDB_T_PRPTY_FTHB AS
Select
LN_ID,
OCCPY_CD  
From
MeDB1.T_PRPTY;
%runquit;

proc sql;
connect to db2 (&cdblogin);
create table LN_CURRADDR_Borr_1  as 
select * from connection to db2
   ( SELECT 
LNKEY,
BORR_OWNRENT,
WHICHBORR 
     FROM LZ_EMP_MRTG_EMPOWER_RDX.LN_CURRADDR
	 Where WHICHBORR = 1
	 WITH UR
   );
disconnect from db2;
%runquit; 

proc sql;
connect to db2 (&cdblogin);
create table LN_DECLARES_Borr_1  as 
select * from connection to db2
   ( SELECT 
LNKEY,
OWN_INT,
WHICHBORR 
     FROM LZ_EMP_MRTG_EMPOWER_RDX.LN_DECLARES
	 Where WHICHBORR = 1
	 WITH UR
   );
disconnect from db2;
%runquit;  

Proc Sql;
Create Table FTHB_MeDB_EMP AS
Select
MeDB_T_LN_FTHB.LN_ID,
MeDB_T_LN_FTHB.LN_NBR,
MeDB_T_LN_FTHB.SYS_SRC_CD,
MeDB_T_LN_FTHB.PURPS_CD,
OCCPY_CD,
BORR_OWNRENT,
OWN_INT,
MeDB_T_LN_FTHB.FRST_TM_HME_BUYER_FLG AS MEDB_FRST_TM_HME_BUYER_FLG
From
MeDB_T_LN_FTHB
Left Join
MeDB_T_PRPTY_FTHB
On
MeDB_T_LN_FTHB.LN_ID = MeDB_T_PRPTY_FTHB.LN_ID
Left Join
LN_CURRADDR_Borr_1
On
MeDB_T_LN_FTHB.LN_NBR = LN_CURRADDR_Borr_1.LNKEY
LEft Join
LN_DECLARES_Borr_1
On
MeDB_T_LN_FTHB.LN_NBR = LN_DECLARES_Borr_1.LNKEY
Order by LN_NBR;
%runquit;

Data FTHB_MeDB_EMP_1;
Set FTHB_MeDB_EMP;
If MEDB_FRST_TM_HME_BUYER_FLG = 'Y' OR (OCCPY_CD IN ('S','N') AND PURPS_CD NE 'R' AND BORR_OWNRENT IN (2, 3) AND OWN_INT NE 'Y') Then CALC_FRST_TM_HME_BUYER_FLG = 'Y';
Else CALC_FRST_TM_HME_BUYER_FLG = 'N';
%runquit;

/* Added for First Time Home Buyer Flag - Reference # 1256697 */

/*Get data set from MeDB.*/
/*7/9/2015 replaced a.frst_tm_hme_buyer_flg with
case when input(substr(a.ln_nbr,1,1),1.) eq 4 and a.frst_tm_hme_buyer_flg = '' then "N" else a.frst_tm_hme_buyer_flg end as frst_tm_hme_buyer_flg, 
when creating table dataset. Empower doesn't populate field w/Y or N like MLCS did, It is either Y or "". Need ln_nbr parameter until all production is in Empower*/ 
proc sql;
create table dataset as
select
          a.ln_nbr,
    a.ln_id,
    a.thrd_party_orig_cd,
    a.gross_ln_amt,
    a.cp_flg,
    /* case when input(substr(a.ln_nbr,1,1),1.) eq 4 and a.frst_tm_hme_buyer_flg = '' then "N"
    else a.frst_tm_hme_buyer_flg end as frst_tm_hme_buyer_flg,  /* Removed this since, Legacy loans not flowing in report and now it's only Empower and LS loans - Reference # 1256697 */
    /* a.purps_cd, */
    case when a.LN_TY_CD = "F" then 1 else 0 end as FHA_FLAG,
    a.csh_out_flg,
    a.pgm_cd,
    a.brrwr_cnt,
    a.PROD_CTR_CD,
    a.proces_ctr_cd,
    a.COMBN_LTV_RATIO_PCT,
    a.orig_ltv_ratio_pct,
    a.emp_ln_flg,
    a.frgn_natl_flg,
    a.pri_ln_nbr,
      datepart(b.approved_date) as Approved_Dt format mmddyy10.,
      datepart(b.app_agg_ent_dt) as Approved_Dt_Entered format mmddyy10.,
	  FTHB_MeDB_EMP_1.SYS_SRC_CD,  /* Reference # 1256697 */
	  FTHB_MeDB_EMP_1.PURPS_CD,
	  FTHB_MeDB_EMP_1.OCCPY_CD,
	  FTHB_MeDB_EMP_1.BORR_OWNRENT,
	  FTHB_MeDB_EMP_1.OWN_INT,
	  FTHB_MeDB_EMP_1.MEDB_FRST_TM_HME_BUYER_FLG,
	  FTHB_MeDB_EMP_1.CALC_FRST_TM_HME_BUYER_FLG AS frst_tm_hme_buyer_flg  /* Reference # 1256697 -  Renamed Calc_ to frst_tm_hme_buyer_flg so, script does not break */
from medb1.t_ln a
inner join (select ln_id, approved_date, app_agg_ent_dt from medb1.v_pivot_ln_stat) b
on a.ln_id=b.ln_id
Left Join
FTHB_MeDB_EMP_1  /* Reference # 1256697 */
on
A.LN_ID = FTHB_MeDB_EMP_1.LN_ID
where datepart(b.app_agg_ent_dt) eq &rptdate. or datepart(b.approved_date) eq &rptdate.
;%runquit;

/*convert PRI_LN_NBR & to number*/
Data dataset (drop=pri_ln_nbr);
    set dataset;
    pri_ln_nbr1=input(pri_ln_nbr,10.);
%runquit;
/*drop garbage*/
data dataset2 (drop=pri_ln_nbr1);
    set dataset;
    if pri_ln_nbr1 in (111111111 0) then sec_ln_nbr=.;
    else sec_ln_nbr=pri_ln_nbr1;
%runquit;
/*convert back to 10 digit character*/
data dataset3 (drop=sec_ln_nbr);
    set dataset2;
    format scnd_ln_nbr $10.;
    scnd_ln_nbr=put(sec_ln_nbr,z10.);
%runquit;

proc sql;
create table dataset4 as
select
      a.*,
      datepart(b.FirstDraftReceived) as FirstDraftRecvd_CMS format mmddyy10.,
      datepart(c.DraftReceivedDateofApprasial) as DraftReceivedDt_GAAR format mmddyy10.

from dataset3 a
left join (select STMLoanNumber, FirstDraftReceived from fncinc.FIRSTRecv_CMS_Loan_Data) b
on a.ln_nbr=b.STMLoanNumber
left join (select LoanNumber, DraftReceivedDateofApprasial from fncinc.GAAR_Loan_Data) c
on a.ln_nbr=c.LoanNumber
;
%runquit;


/*added 2/10/2014--dedup multiple GAAR drafts*/
proc sort data=dataset4;
by ln_nbr DraftReceivedDt_GAAR;
%runquit;

data dataset4a;
set dataset4;
by ln_nbr;
if last.ln_nbr;
%runquit;

/*7/9/2015 added field to calculate borrower age since Empower is not populated consistently where "dataset5" is created--also added to select statement
**at join*/
/*2/10/2014 added emp_city_st_zip, coborr first name & proces_ctr_nm*/
proc sql;
create table dataset5 as
select
a.*,
b.brrwr_nbr,
b.biz_phn_nbr,
b.marr_stat_cd,
b.curr_emp_nm,
b.brrwr_age_nbr as brrwr_age_nbr_old,
floor((intck('month',datepart(brth_dt),&Rundate) - (day(&Rundate) < day(datepart(brth_dt)))) / 12) as brrwr_age_nbr_new,
datepart(b.brth_dt) as birth_dt format mmddyy10.,
b.curr_emp_yr_qty,
b.prfsn_emp_yr_qty,
b.emp_addr_txt,
b.EMP_CITY_ST_ZIP_TXT,
b.self_emp_flg,
b.brrwr_cred_scor,
b.brrwr_frst_nm,
b.brrwr_lst_nm,
b.brrwr_ssn,
c.addr_ty_cd,
c.addr_txt as brrwr_addr,
c.st_cd as brrwr_state,
c.zip_cd,
c.resid_yr_qty_txt,
d.ORIG_CHNL,
d.chnl,
d.ctr_cd,
d.ctr_nm,
d.mkt_cd,
d.rgn_cd,
e.brrwr_lst_nm as co_brrwr_lst_nm,
e.BRRWR_FRST_NM as co_BRRWR_FRST_NM,
e.brrwr_ssn as co_brrwr_ssn,
f.pgm_desc,
g.ctr_nm as proces_ctr_nm

from dataset4a a
left join (select ln_id, brrwr_nbr, biz_phn_nbr, marr_stat_cd, curr_emp_nm, brrwr_age_nbr,
curr_emp_yr_qty, prfsn_emp_yr_qty, emp_addr_txt, EMP_CITY_ST_ZIP_TXT, self_emp_flg, brrwr_cred_scor, brrwr_frst_nm, 
brrwr_lst_nm, brrwr_ssn, brth_dt from medb1.t_brrwr where brrwr_nbr=1) b
on a.ln_id=b.ln_id
left join (select ln_id, addr_ty_cd, addr_txt, st_cd, zip_cd, resid_yr_qty_txt 
from medb1.t_brrwr_addr where brrwr_nbr=1 and addr_ty_cd='P') c
on a.ln_id=c.ln_id
left join (select CTR_CD, RGN_CD, GRP_CD, ORIG_CHNL, CTR_NM, mkt_cd, chnl from medb1.t_ctr) d
on a.PROD_CTR_CD = d.CTR_CD
left join (select ln_id, brrwr_nbr, brrwr_lst_nm, BRRWR_FRST_NM, brrwr_ssn from medb1.t_brrwr 
where brrwr_nbr=2) e
on a.ln_id=e.ln_id
left join (select pgm_cd, pgm_desc from medb1.t_pgm) f
on a.pgm_cd = f.pgm_cd
left join (select CTR_CD, CTR_NM from medb1.t_ctr) g
on a.proces_ctr_cd = g.CTR_CD
;%runquit;


proc sql;
create table dataset6 as select

a.*,
b.addr_txt as mail_addr,
b.st_cd as mail_state,
b.zip_cd as mail_zip,
/*CORRECTION******added all items from medb2 proc sql below from c.T_Prpty except occpy_cd*/
c.yr_bld_nbr,
case when a.purps_cd = "P" then c.seller_nm else "" end as Seller_Nm,
c.nbr_of_unt,
c.Subj_prpty_addr_txt,
c.subj_prpty_city_Nm,
c.Subj_prpty_st_Cd,
c.Subj_prpty_zip_Cd,
c.occpy_cd,
c.apprsr_nm,
c.orig_apprs_amt,
c.prpty_ty_cd

from dataset5 a 
left join (select ln_id, addr_ty_cd, addr_txt, st_cd, zip_cd
from medb1.t_brrwr_addr where brrwr_nbr=1 and addr_ty_cd='MAILING') b
on a.ln_id=b.ln_id 
left join (select ln_id, yr_bld_nbr, seller_nm, nbr_of_unt, Subj_prpty_addr_txt, 
    Subj_prpty_st_Cd, subj_prpty_city_Nm, subj_prpty_zip_Cd, occpy_cd, apprsr_nm, 
    orig_apprs_amt, prpty_ty_cd from medb1.t_prpty) c
on a.ln_id=c.ln_id;
%runquit;


/*clean up Borrower Zip Code
**2/10/2014 changed propertyzip to subj_prpty_zip_cd
**and added employer zip clean up*/
data dataset7 (drop=zip_cd mail_zip);
set dataset6;
zip1= compress(zip_cd,'- .`ABCDEFGHIJKLMNOPQRSTUVWXYZ');
BorrowerZip=zip1; drop zip1;
if BorrowerZip in (' ', '.') then BorrowerZip='00000';
else if length(BorrowerZip)< 5 then BorrowerZip=cat(repeat('0', 5-length(BorrowerZip)-1), strip(BorrowerZip));
else BorrowerZip=substr(BorrowerZip,1,5);

zip2= compress(mail_zip,'- .`ABCDEFGHIJKLMNOPQRSTUVWXYZ');
MailingZip=zip2; drop zip2;
if MailingZip in (' ', '.') then MailingZip='00000';
else if length(MailingZip)< 5 then MailingZip=cat(repeat('0', 5-length(MailingZip)-1), strip(MailingZip));
else MailingZip=substr(MailingZip,1,5);

/*2/10/2014 changed from propertyzip to subj_prpty_zip_cd*/
zip3= compress(Subj_prpty_zip_Cd,'- .`ABCDEFGHIJKLMNOPQRSTUVWXYZ');
SUBJ_PRPTY_ZIP_CD=zip3; drop zip3;
if SUBJ_PRPTY_ZIP_CD in (' ', '.') then SUBJ_PRPTY_ZIP_CD='00000';
else if length(SUBJ_PRPTY_ZIP_CD)< 5 then SUBJ_PRPTY_ZIP_CD=cat(repeat('0', 5-length(SUBJ_PRPTY_ZIP_CD)-1), strip(SUBJ_PRPTY_ZIP_CD));
else SUBJ_PRPTY_ZIP_CD=substr(SUBJ_PRPTY_ZIP_CD,1,5);

/*added 2/10/2014*/
employerzip = scan(EMP_CITY_ST_ZIP_TXT,-1,", ");
if compress(employerzip,'-')*1 not in (0,.) and compress(employerzip,'-')*1 ge 10000 
then employerzip = substr(employerzip,1,5);
else if compress(employerzip,'-')*1 not in (0,.) and compress(employerzip,'-')*1 lt 10000 
then employerzip = put(compress(employerzip,'-')*1,z5.);
else employerzip = "";
%runquit;

/*CORRECTION******changed below from borrower address to subj_prpty_addr/
/*Address Match Score Section*/
data address_compare;
    set dataset7;
    Format AddrMatch_Outcome $48.;
    if compress(Subj_prpty_addr_txt," .-")=compress(mail_addr," .-") then 
    AddrMatch_Outcome="Match/Match/Match";
    %runquit;
/*CORRECTION******changed below from borrower address to subj_prpty_addr*/
Data address_compare2;
    set address_compare;
    AddrPart1Prpty=scan(strip(Subj_prpty_addr_txt),1,' ');
      AddrPart2Prpty=scan(strip(Subj_prpty_addr_txt),2,' ');
      AddrPart3Prpty=scan(strip(Subj_prpty_addr_txt),3,' ');
      AddrPart4Prpty=scan(strip(Subj_prpty_addr_txt),4,' ');
    AddrPart1Mail=scan(strip(mail_addr),1,' ');
      AddrPart2Mail=scan(strip(mail_addr),2,' ');
      AddrPart3Mail=scan(strip(mail_addr),3,' ');
      AddrPart4Mail=scan(strip(mail_addr),4,' ');
%runquit;

Data address_compare3;
    set address_compare2;
    AddrPart1PrptyTrim=scan(AddrPart1Prpty,1,'-');
    AddrPart1MailTrim=scan(AddrPart1Mail,1,'-');
%runquit;

data address_compare4;
    set address_compare3;
    Format NumberMatch $14.;
    if AddrPart1PrptyTrim=AddrPart1MailTrim then NumberMatch="Match";
    else if complev(AddrPart1PrptyTrim,AddrPart1MailTrim,2,'LI')=1 then NumberMatch="Close";
    else NumberMatch="NoMatch";
%runquit;


data address_compare5;
    set address_compare4;
    format StNmPrpty $200.;
    format StNmMail $200.;
    Format StreetMatch $15.;
    Format ConcatStreetMatch $15.;
    
    if upcase(AddrPart2Prpty) not in 
        ("N", "S", "E", "W", "NE", "NW", "SE", "SW", "N.", "S.", "E.", "W.", "N.E.", "N.W.", 
        "S.E.", "S.W.", "Box","WEST","NORTH","SOUTH","EAST","NORTHWEST","SOUTHWEST","NORTHEAST",
        "SOUTHEAST") then StNmPrpty=AddrPart2Prpty;
    if upcase(AddrPart2Prpty) in
        ("N", "S", "E", "W", "NE", "NW", "SE", "SW", "N.", "S.", "E.", "W.", "N.E.", "N.W.", 
        "S.E.", "S.W.", "Box","WEST","NORTH","SOUTH","EAST","NORTHWEST","SOUTHWEST","NORTHEAST",
        "SOUTHEAST") then StNmPrpty=AddrPart3Prpty;
    if upcase(AddrPart2Mail) not in 
        ("N", "S", "E", "W", "NE", "NW", "SE", "SW", "N.", "S.", "E.", "W.", "N.E.", "N.W.", 
        "S.E.", "S.W.", "Box","WEST","NORTH","SOUTH","EAST","NORTHWEST","SOUTHWEST","NORTHEAST",
        "SOUTHEAST") then StNmMail=AddrPart2Mail;
    if upcase(AddrPart2Mail) in
        ("N", "S", "E", "W", "NE", "NW", "SE", "SW", "N.", "S.", "E.", "W.", "N.E.", "N.W.", 
        "S.E.", "S.W.", "Box","WEST","NORTH","SOUTH","EAST","NORTHWEST","SOUTHWEST","NORTHEAST",
        "SOUTHEAST") then StNmMail=AddrPart3Mail;
    if upcase(StNmPrpty)=upcase(StNmMail) then StreetMatch="Match";
    else if complev(StNmPrpty,StNmMail,3,'LI')<3 then StreetMatch="Close";
    else StreetMatch="NoMatch";
    JoinedPrptyAddr=strip(AddrPart2Prpty)||strip(AddrPart3Prpty)||strip(AddrPart4Prpty);
    JoinedMailAddr=strip(AddrPart2Mail)||strip(AddrPart3Mail)||strip(AddrPart4Mail);
    if upcase(JoinedPrptyAddr)=upcase(JoinedMailAddr) then ConcatStreetMatch="Match";
    else if complev(JoinedPrptyAddr,JoinedMailAddr,5,'LI')<5 then ConcatStreetMatch="Close";
    else ConcatStreetMatch="NoMatch";
    if NumberMatch = "NoMatch" and StreetMatch = "NoMatch" and 
        ConcatStreetMatch = "NoMatch" then AddrMatch_Outcome="NoMatch/NoMatch/NoMatch";
    else AddrMatch_Outcome=compress(NumberMatch)||"/"||compress(StreetMatch)||"/"||compress(ConcatStreetMatch);
    
    if occpy_cd ne "O" then addr_match_score=0;
    else if AddrMatch_Outcome="NoMatch/NoMatch/NoMatch" then addr_match_score=9;
    else if AddrMatch_Outcome = "Match/Match/Match" then addr_match_score=0;
    else if AddrMatch_Outcome = "Close/Close/Close" then addr_match_score=3;
    else if AddrMatch_Outcome in ("Match/Match/Close", "Match/Close/Match",
    "Close/Match/Match") then addr_match_score=1;
    else if AddrMatch_Outcome in ("Match/Close/Close", "Close/Match/Close",
    "Close/Close/Match") then addr_match_score=2;
    else if AddrMatch_Outcome in ("Match/Match/NoMatch", "Match/NoMatch/Match",
    "NoMatch/Match/Match") then addr_match_score=3;
    else if AddrMatch_Outcome in ("Match/NoMatch/NoMatch", "NoMatch/Match/NoMatch",
    "NoMatch/NoMatch/Match") then addr_match_score=6;
    else if AddrMatch_Outcome in ("NoMatch/NoMatch/Close", "NoMatch/Close/NoMatch",
    "Close/NoMatch/NoMatch") then addr_match_score=7;
    else if AddrMatch_Outcome in ("NoMatch/Close/Close", "Close/NoMatch/Close",
    "Close/Close/NoMatch") then addr_match_score=5;
    else if AddrMatch_Outcome in ("Match/Close/NoMatch", "Match/NoMatch/Close",
    "Close/Match/NoMatch", "Close/NoMatch/Match", "NoMatch/Close/Match",
    "NoMatch/Match/Close") then addr_match_score=4;

%runquit;

proc sort data=address_compare5;
by ln_nbr;
%runquit;

data address_compare6;
set address_compare5;
by ln_nbr;
if last.ln_nbr;
%runquit;

proc sql;
create table medb1 as select

a.*,
b.addr_match_score

from dataset7 as a left join address_compare6 as b
on a.ln_nbr=b.ln_nbr;
%runquit;
/*End of Address Match Score Section*/

proc sql;
create table medb1a as
select
a.*,
b.mkt_nm,
c.rgn_nm

from medb1 a
left join (select mkt_cd, mkt_nm from medb1.t_mkt_area) b
on a.mkt_cd = b.mkt_cd
left join (select rgn_cd, rgn_nm from medb1.t_rgn) c
on a.rgn_cd = c.rgn_cd
;
%runquit;


/*2/10/2014 added settlement agent name*/
proc sql;
create table medb2 as
select
a.*,
/*CORRECTION******moved up so could use this in address compare
b.yr_bld_nbr,
b.seller_nm,
b.nbr_of_unt,
b.Subj_prpty_addr_txt,
b.subj_prpty_city_Nm,
b.Subj_prpty_st_Cd as PropertyState, 
b.Subj_prpty_zip_Cd,
b.occpy_cd,
b.apprsr_nm,
b.orig_apprs_amt,
b.prpty_ty_cd,*/
c.thrd_party_orig_nm,
c.zip_cd as SponsorZip,
d.est_clos_dt,
d.SETL_AGNT_NM,
e.lock_in_expr_dt,
f.purps_desc /*changed all ref to purpose_b to this*/

from medb1a a
/*left join (select ln_id, yr_bld_nbr, seller_nm, nbr_of_unt, Subj_prpty_addr_txt, 
    Subj_prpty_st_Cd, subj_prpty_city_Nm, subj_prpty_zip_Cd, occpy_cd, apprsr_nm, orig_apprs_amt, prpty_ty_cd from medb.t_prpty) b
on a.ln_id=b.ln_id*/
left join (select thrd_party_orig_cd, zip_cd, thrd_party_orig_nm from medb1.t_thrd_party_orig) c
on a.thrd_party_orig_cd=c.thrd_party_orig_cd
left join (select ln_id, est_clos_dt, SETL_AGNT_NM from medb1.t_disb) d
on a.ln_id=d.ln_id
left join (select ln_id, lock_in_expr_dt from medb1.t_risk_mnge) e
on a.ln_id=e.ln_id
left join (select purps_cd, purps_desc from medb1.t_purps) f
on a.purps_cd=f.purps_cd
;
%runquit;


/*CORRECTION******Moved to dataset7 data step so can be used in 
address compare code

*clean up Property Zip Code
data medb2 (drop=Subj_prpty_zip_Cd);
set medb2;
zip1= compress(Subj_prpty_zip_Cd,'- .`ABCDEFGHIJKLMNOPQRSTUVWXYZ');
PropertyZip=zip1; drop zip1;
if PropertyZip in (' ', '.') then PropertyZip='00000';
else if length(PropertyZip)< 5 then PropertyZip=cat(repeat('0', 5-length(PropertyZip)-1), strip(PropertyZip));
else PropertyZip=substr(PropertyZip,1,5);
%runquit;
*/

proc sql;
create table medb2a as
select
a.*,
b.prpty_ty_desc

from medb2 a
left join (select prpty_ty_cd, prpty_ty_desc from medb1.t_prpty_ty) b
on a.prpty_ty_cd=b.prpty_ty_cd
;
%runquit;


/*11/9/2015 added bk_end_ratio_pct & Proces_ty_cd to use in new flag titled DTI_Potential_Flg*/
proc sql;
create table medb3 as
select
a.*,
b.rpt_tot_incm_amt,
b.bk_end_ratio_pct,
b.Proces_ty_cd

from medb2a a
left join (select ln_id, rpt_tot_incm_amt, bk_end_ratio_pct, Proces_ty_cd from medb1.t_uw) b
on a.ln_id=b.ln_id
;
%runquit;

Data medb4;
    set medb3;
    format Bridge_Loan 1.;
    bridge_loan = (substr(pgm_cd,1,4) in ("BRDG","XRDG"));
%runquit;

/*dedup*********/
proc sort data=medb4; by ln_nbr marr_stat_cd; %runquit;

data medb5;
set medb4;
by ln_nbr marr_stat_cd;
if last.ln_nbr=1;
%runquit;

/*create table with loan officer, processor, closer, and underwriter name 
**2/10/2014 added "GRMA" will only be used for UW to get vendor name below*/
%macro role(val);
proc sql;
create table &VAL as select
a.ln_id,

upcase(compress(scan(b.Relat_Party_id,1,'-'))) as &VAL._GRMA,

Case
   when b.role_cd in ("&VAL") then c.relat_party_nm else " "
End as &VAL._nm,

Case
   when b.role_cd in ("&VAL") then c.relat_party_id else " "
End as &VAL._id

from medb5 a, medb1.t_relat_party_ln_role b, medb1.t_relat_party c
where  a.ln_id = b.ln_id and 
       b.RELAT_PARTY_ID = c.RELAT_PARTY_ID and
       b.role_cd = "&VAL";
%runquit;

proc  sort data =&VAL; by ln_id; %runquit;

%mend role;
 
%role (UW);
%role (PR);
%role (LO);
%role (CL);

Data relat_party;
 merge UW PR LO CL;
 by ln_id;
 if first.ln_id;
%runquit;


/*add Related Party info to main MeDB data set**
**changed how added 2/10/2014***/
proc sql;
create table Medb6 as
select 
a.*,
b.uw_id,
b.uw_nm,
b.uw_grma,
b.pr_id,
b.pr_nm,
b.lo_id,
b.lo_nm,
b.cl_id,
b.cl_nm
from medb5 a
left join relat_party b
on a.ln_id=b.ln_id;
%runquit;

/*2/10/2014**add Vendor_UW_Co_Nm*/
proc sql;
create table co_nm as select
a.uw_grma,
b.employername,
datepart(b.entrydate) as entrydate format mmddyy10.,
b.campusname,
b.branchname

from Medb6 a
/*left join UWTrack.uwt_EmployeeExtract b*/
left join MCRM.uwt_EmployeeExtract b
on a.uw_grma = b.grma
;%runquit;

proc sort data=co_nm;
by uw_grma descending entrydate;
%runquit;

data co_nm2;
set co_nm;
by uw_grma;
if employername ne "" and first.uw_grma;
%runquit;

Proc sql; 
	connect to DB2 (&cdblogin);
    CREATE TABLE LN_CODES  AS  
		(select * from connection to DB2( 
            select 
            lnkey,
            CODEDESC,
            IDX
			from LZ_EMP_MRTG_EMPOWER_RDX.LN_CODES 
			   with ur
));
    disconnect from db2;  
	%runquit; 

	
/*7/10/15 added to get empower campus data*/
proc sql; 
create table processing as 
select 
a.lnkey, 
CODEDESC as PROCESSINGCAMPUS 
from LN_CODES a where LN_CODES.IDX = 230; 
%runquit; 
/*7/10/15 added to get empower campus data*/
proc sql; 
create table underwriting as 
select 
a.lnkey, 
CODEDESC as UNDERWRITINGCAMPUS 
from LN_CODES a where LN_CODES.IDX = 231; 
%runquit; 
/*7/10/15 added to get empower campus data*/
proc sql; 
create table closing as 
select 
a.lnkey, 
CODEDESC AS CLOSINGCAMPUS 
from LN_CODES a where LN_CODES.IDX = 232; 
%runquit;


/*7/10/15 added empower campus data*/
proc sql;
create table Medb6a as select
a.*,
b.employername as Vendor_UW_Co_Nm,
b.campusname,
b.branchname,
c.PROCESSINGCAMPUS,
d.UNDERWRITINGCAMPUS,
e.CLOSINGCAMPUS

from Medb6 a
left join co_nm2 b
on a.uw_grma = b.uw_grma
left join processing c
on a.ln_nbr = c.lnkey
left join underwriting d
on a.ln_nbr = d.lnkey
left join closing e
on a.ln_nbr = e.lnkey
;%runquit;

/*add a # version of loannumber to medb dataset #********/
/*2/10/2014 add HUB & "place holder" fields*/
data Medb6a;
set Medb6a;
format Fulfillment_HUB $50.;
if orig_chnl = 'R' and uw_grma = ''  then Fulfillment_HUB = 'No UW';
else if orig_chnl = 'R' and campusname ne "" then Fulfillment_HUB = campusname;
else if orig_chnl = 'R' and campusname eq "" then Fulfillment_HUB = branchname;
else if orig_chnl in ('B', 'C') then Fulfillment_HUB = proces_ctr_nm;
else Fulfillment_HUB = 'Other';
loan_no=input(ln_nbr,10.);
/*place holder fields*/
ln_clos_dt="";
Vintage="";
Audit_Type="Pre-funding Datamining";
Fidelity_Mailing_Add="";
Fidelity_Mailing_City_Add="";
Fidelity_Mailing_State_Add="";
Fidelity_Mailing_Zip_Add="";
%runquit;

data Medb6a;
set Medb6a;
if substr(upcase(Fulfillment_HUB),1,9) = 'CHARLOTTE' or
substr(upcase(Fulfillment_HUB),1,12) = 'CHESTERBROOK' then Fulfillment_HUB = 'Charlotte';
else if substr(upcase(Fulfillment_HUB),1,12) = 'LAGUNA HILLS' or
substr(upcase(Fulfillment_HUB),1,7) = 'PHOENIX' then Fulfillment_HUB = 'Laguna Hills';
else if substr(upcase(Fulfillment_HUB),1,5) = 'TAMPA' or 
substr(upcase(Fulfillment_HUB),1,7) in ('HOUSTON', 'MAITLAND') then Fulfillment_HUB = 'Tampa';
else if substr(upcase(Fulfillment_HUB),1,12) = 'CORRESPONDEN' then Fulfillment_HUB = 'Correspondent';
else Fulfillment_HUB = Fulfillment_HUB;
%runquit;

/* Add Employee Active field */
proc sql;
create table final_dataset as
select
a.*,
case when b.racf_id is not null then 'ACTIVE' else 'INACTIVE' end as STMEmployee
from Medb6a a
left join (select * from activestm where racf_id is not null) b
on substr(a.lo_id,1,length(a.lo_id)-2)=b.racf_id;
%runquit;


/*get gaar scores*/
data gaar (rename=(appraisalscore=gaar_score draftreceiveddateofapprasial=draftreceiveddateofappraisal));
   set fncinc.gaar_Loan_Data;
   keep loannumber draftreceiveddateofapprasial appraisalscore;
%runquit;

proc sort data=gaar;
   by loannumber draftreceiveddateofappraisal;
%runquit;

data gaar2;
   set gaar;
   by loannumber;
   if last.loannumber=1;
%runquit; 

data gaar3;
set gaar2;
loan_no=input(loannumber,10.);
if gaar_score ge 400 or missing(gaar_score) then gaar_flg=0; else gaar_flg=1;
%runquit;


/*add GAAR scores to dataset********/
proc sql;
create table final_dataset2 as
select
a.*,
b.gaar_flg
from final_dataset a
left join gaar3 b
on a.loan_no=b.loan_no;
%runquit;

/*Get Core Logic Data*/
/*Note will get errors for CL_Score and GEO_avm_val for those records with blanks which is OK*/
data CL1;
set CORE.colo_Daily;
keep
cl_date
CL_Fraud_Score
loan_no
est_val
GEO_avm_val
variance
CL_GT799
CL_GT899
cl_avail;
CL_Fraud_Score=input(ls_fraud_Score,10.);
loan_no=input(STM_Loan_Number__CL_JOB_ID_1_,10.);
est_val=input(compress(Estimated_Value__Appraised_Value,'$,'),10.);
GEO_avm_val=input(compress(GEO_AVM_Value,'$,'),10.);
variance=abs((est_val-GEO_avm_val)/est_val);
format variance 10.2;
if CL_Fraud_Score = . then CL_GT799 = .; else if CL_Fraud_Score >= 800 then CL_GT799=1; else CL_GT799=0;
if CL_Fraud_Score = . then CL_GT899 = .; else if CL_Fraud_Score >= 900 then CL_GT899=1; else CL_GT899=0;
if CL_Fraud_Score = . then cl_avail = 0; else cl_avail = 1;
%runquit;

proc sort data=CL1; by loan_no cl_date; %runquit;


data CL2;
set CL1;
by loan_no cl_date;
if last.loan_no=1;
%runquit;

/*add corelogic data to dataset****/
proc sql;
create table final_dataset3 as
select
a.*,
b.CL_Fraud_Score,
b.est_val,
b.geo_avm_val,
b.variance,
b.CL_GT799,
b.cl_gt899,
b.cl_avail
from final_dataset2 a
left join CL2 b
on a.loan_no=b.loan_no;
%runquit;

/*add combined Originator field to dataset****/
data final_dataset3;
    length orig_id $15.;
    length orig_nm $40.;
    set final_dataset3;
    if orig_chnl='R' then orig_id=substr(lo_id,1,length(lo_id)-2);
    else orig_id=thrd_party_orig_cd;
    if orig_chnl='R' then orig_nm=LO_nm;
    else orig_nm=thrd_party_orig_nm;
%runquit;



/*find median for Originator scores in Fraud PostFunding Detection Tool*/
ods select BasicMeasures;
PROC UNIVARIATE DATA=FCRM_Rpt.vw_originators outtable=median (keep=_MEDIAN_);
var overallscore1;
%runquit;

/*add Median to dataset****/
data median2;
    set median;
    median_pre=1;
%runquit;
data final_dataset4;
    set final_dataset3;
    median_pre=1;
%runquit;

proc sql;
create table final_dataset5 as
select
a.*,
b._median_
from final_dataset4 a
left join median2 b
on a.median_pre = b.median_pre;
%runquit;

Data final_dataset5;
    set final_dataset5;
    label 
        _median_="Median of all Originator Scores";
%runquit;

   
proc sql;
create table final_dataset6 as
select
a.*,
b.Overallscore1 as Originator_Score
from final_dataset5 a
left join FCRM_Rpt.vw_originators b
on a.Orig_ID=b.orig_id;
%runquit;

proc sort data=final_dataset6 nodup;
    by _all_;
%runquit;
proc sort data=final_dataset6;
    by ln_nbr Originator_Score;
%runquit;
data final_dataset6;
    set final_dataset6;
    by ln_nbr;
    if last.ln_nbr;
%runquit; 
/*changed input format for zip code from 10. as originally in Dave H's code to Z5
**2/10/2014 added employer zip & changed propertyzip to subj_prpty_zip_cd*/
data final_dataset7;
set final_dataset6 (drop=median_pre);
curr_emp_years=input(curr_emp_yr_qty,10.);
/*7/9/2015 no longer need due to new way to get borrower age in datastep 5*/
/*brrwr_age_nbr_new=input(brrwr_age_nbr,10.);*/
resid_yr_qty=input(resid_yr_qty_txt,10.);
borrower_zip=input(borrowerzip,5.);
sponsor_zip=input(sponsorzip,5.);
property_zip=input(Subj_prpty_zip_Cd,5.);
employer_zip=input(employerzip,5.);
%runquit;

/*zip to zip distances
**2/10/2014 added employer info*/
proc sql;
create table final_dataset8 as
select 
a.*,
b.x as prpty_long,
b.y as prpty_lat,
c.x as brrwr_long,
c.y as brrwr_lat,
d.x as sponsor_long,
d.y as sponsor_lat,
e.x as employer_long,
e.y as employer_lat

from final_dataset7 a
left outer join (select zip,x,y from sashelp.zipcode) b
on a.property_zip = b.zip
left outer join (select zip,x,y from sashelp.zipcode) c
on a.borrower_zip = c.zip
left outer join (select zip,x,y from sashelp.zipcode) d
on a.sponsor_zip = d.zip
left outer join (select zip,x,y from sashelp.zipcode) e
on a.employer_zip = e.zip
;%runquit;

data final_dataset9;
   set final_dataset8;
   format PrptySponsorDist f8.2;
   format PrptyBrrwrDist f8.2;
   format BrrwrSponsorDist f8.2;
   format EmployerPrptyDist f8.2;
   PrptySponsorDist = 3963 * 
   arcos(
   sin(sponsor_lat*2*Constant('PI')/360) * sin(prpty_lat*2*Constant('PI')/360)
   + cos(sponsor_lat*2*Constant('PI')/360) * cos(prpty_lat*2*Constant('PI')/360) *
   cos(prpty_long*2*Constant('PI')/360 - sponsor_long*2*Constant('PI')/360));

   PrptyBrrwrDist = 3963 * 
   arcos(
   sin(brrwr_lat*2*Constant('PI')/360) * sin(prpty_lat*2*Constant('PI')/360)
   + cos(brrwr_lat*2*Constant('PI')/360) * cos(prpty_lat*2*Constant('PI')/360) *
   cos(prpty_long*2*Constant('PI')/360 - brrwr_long*2*Constant('PI')/360));

   BrrwrSponsorDist = 3963 * 
   arcos(
   sin(brrwr_lat*2*Constant('PI')/360) * sin(sponsor_lat*2*Constant('PI')/360)
   + cos(brrwr_lat*2*Constant('PI')/360) * cos(sponsor_lat*2*Constant('PI')/360) *
   cos(sponsor_long*2*Constant('PI')/360 - brrwr_long*2*Constant('PI')/360));

   EmployerPrptyDist = 3963 * 
   arcos(
   sin(employer_lat*2*Constant('PI')/360) * sin(prpty_lat*2*Constant('PI')/360)
   + cos(employer_lat*2*Constant('PI')/360) * cos(prpty_lat*2*Constant('PI')/360) *
   cos(prpty_long*2*Constant('PI')/360 - employer_long*2*Constant('PI')/360));
%runquit;

/*distance research
%MACRO geodist (lat1,long1,lat2,long2, unit) ;
%local ct ;
%let ct = constant('pi')/180 ;
%if %upcase(&unit) = KM %then %let radius = 6371 ;
%else %if %upcase(&unit) = MI %then %let radius = 3959 ;
&radius * ( 2 * arsin(min(1,sqrt( sin( ((&lat2 - &lat1)*&ct)/2 )**2 +
cos(&lat1*&ct) * cos(&lat2*&ct) * sin( ((&long2 - &long1)*&ct)/2 )**2)
)));
%MEND;

DATA pcs_dist;
set pcs;
distance = %geodist (lat1,long1,lat2,long2, KM);
%runquit;
*/

data final_dataset9a;
set final_dataset9;
InstInv=0;
InstInv2=0;
if index(upcase(seller_nm),"LLC")>0 then InstInv=1;
if index(upcase(seller_nm),"INVEST")>0 then InstInv=1;
if index(upcase(seller_nm),"INV ")>0 then InstInv=1;
if index(upcase(seller_nm),"INV.")>0 then InstInv=1;
if index(upcase(seller_nm),"PARTNER")>0 then InstInv=1;
if index(upcase(seller_nm),"GROUP")>0 then InstInv=1;
if index(upcase(seller_nm),"COMMUNIT")>0 then InstInv=1;
if index(upcase(seller_nm),"COMPANY")>0 then InstInv=1;
if index(upcase(seller_nm)," CO ")>0 then InstInv=1;
if index(upcase(seller_nm),"CO.")>0 then InstInv=1;
if index(upcase(seller_nm)," INC ")>0 then InstInv=1;
if index(upcase(seller_nm),"INC.")>0 then InstInv=1;
if index(upcase(seller_nm),"INCORP")>0 then InstInv=1;
if index(upcase(seller_nm),"BUILD")>0 then InstInv=1;
if index(upcase(seller_nm),"REHAB")>0 then InstInv=1;
if index(upcase(seller_nm),"CORPOR")>0 then InstInv=1;
if index(upcase(seller_nm),"CORP")>0 then InstInv=1;
if index(upcase(seller_nm),"INSTIT")>0 then InstInv=1;
if index(upcase(seller_nm),"VENTURE")>0 then InstInv=1;
if index(upcase(seller_nm),"CAPITAL")>0 then InstInv=1;
if index(upcase(seller_nm),"CONSTRUCT")>0 then InstInv=1;
if index(upcase(seller_nm),"CONST ")>0 then InstInv=1;
if index(upcase(seller_nm),"LIMIT")>0 then InstInv=1;
if index(upcase(seller_nm),"PROPERT")>0 then InstInv=1;
if index(upcase(seller_nm),"PROP ")>0 then InstInv=1;
if index(upcase(seller_nm),"PROP.")>0 then InstInv=1;
if index(upcase(seller_nm),"REALTY")>0 then InstInv=1;
if index(upcase(seller_nm),"REAL ESTATE")>0 then InstInv=1;
if index(upcase(seller_nm),"LTD")>0 then InstInv=1;
if index(upcase(seller_nm),"HOME ")>0 then InstInv=1;
if index(upcase(seller_nm),"REMODEL")>0 then InstInv=1;
if index(upcase(seller_nm),"RENOVAT")>0 then InstInv=1;
if index(upcase(seller_nm),"SERV ")>0 then InstInv=1;
if index(upcase(seller_nm),"SERV.")>0 then InstInv=1;
if index(upcase(seller_nm),"SERVICE")>0 then InstInv=1;
if index(upcase(seller_nm),"SVC")>0 then InstInv=1;
if index(upcase(seller_nm),"DEVELOP")>0 then InstInv=1;
if index(upcase(seller_nm),"BUSINESS")>0 then InstInv=1;
if index(upcase(seller_nm),"RESIDEN")>0 then InstInv=1;
if index(upcase(seller_nm),"ASSOC")>0 then InstInv=1;
if index(upcase(seller_nm),"MANAGE")>0 then InstInv=1;
if index(upcase(seller_nm),"1 ")>0 then InstInv=1;
if index(upcase(seller_nm),"2 ")>0 then InstInv=1;
if index(upcase(seller_nm),"3 ")>0 then InstInv=1;
if index(upcase(seller_nm),"4 ")>0 then InstInv=1;
if index(upcase(seller_nm),"5 ")>0 then InstInv=1;
if index(upcase(seller_nm),"6 ")>0 then InstInv=1;
if index(upcase(seller_nm),"7 ")>0 then InstInv=1;
if index(upcase(seller_nm),"8 ")>0 then InstInv=1;
if index(upcase(seller_nm),"9 ")>0 then InstInv=1;
if index(upcase(seller_nm),"0 ")>0 then InstInv=1;

if index(upcase(seller_nm),"SUNTRUST")>0 then InstInv2=1;
if index(upcase(seller_nm),"WELLS FARGO")>0 then InstInv2=1;
if index(upcase(seller_nm),"REAL ESTATE")>0 then InstInv2=1;
if index(upcase(seller_nm),"CHASE MORT")>0 then InstInv2=1;
if index(upcase(seller_nm),"CHASE MANHAT")>0 then InstInv2=1;
if index(upcase(seller_nm),"JP CHASE")>0 then InstInv2=1;
if index(upcase(seller_nm),"CITI")>0 then InstInv2=1;
if index(upcase(seller_nm),"COUNTRYWIDE")>0 then InstInv2=1;
if index(upcase(seller_nm),"BOA")>0 then InstInv2=1;
if index(upcase(seller_nm),"BANK OF")>0 then InstInv2=1;
if index(upcase(seller_nm),"WACHOVIA")>0 then InstInv2=1;
if index(upcase(seller_nm),"FNMA")>0 then InstInv2=1;
if index(upcase(seller_nm),"FANNIE")>0 then InstInv2=1;
if index(upcase(seller_nm),"FHLM")>0 then InstInv2=1;
if index(upcase(seller_nm),"FREDDIE")>0 then InstInv2=1;
if index(upcase(seller_nm),"FEDERAL")>0 then InstInv2=1;
if index(upcase(seller_nm),"VETERANS")>0 then InstInv2=1;
if index(upcase(seller_nm),"HOUSING AND")>0 then InstInv2=1;
if index(upcase(seller_nm),"HUD")>0 then InstInv2=1;
if index(upcase(seller_nm),"GNMA")>0 then InstInv2=1;
if index(upcase(seller_nm),"GINNIE")>0 then InstInv2=1;
if index(upcase(seller_nm),"GOVERNMENT NATIONAL")>0 then InstInv2=1;
%runquit;


/* create scoring fields at loan level 
**2/10/2014 changed references from propertystate to Subj_prpty_st_Cd*/
data LoanLevelDetail;
set final_dataset9a;

if emp_addr_txt = '' then EmpPOBox_YN = .;
    else if index(emp_addr_txt,"P.O.")>0 or index(emp_addr_txt," PO ")>0 or index(emp_addr_txt,"BOX")>0 
        then EmpPOBox_YN = 1;
    else EmpPOBox_YN = 0;
Age_Income = (rpt_tot_incm_amt/brrwr_age_nbr_new);
format age_income 10.2;

if resid_yr_qty = . then Refi_Inv_LT_1Yr = .; 
    else if resid_yr_qty <= 1 and purps_desc='Refinance' and Occpy_Cd='N' then Refi_Inv_LT_1Yr=1;
    else Refi_Inv_LT_1Yr = 0;

if resid_yr_qty = . then Refi_2ndHome_LT_1Yr = .; 
    else if resid_yr_qty <= 1 and purps_desc='Refinance' and Occpy_Cd='S' then Refi_2ndHome_LT_1Yr=1;
    else Refi_2ndHome_LT_1Yr = 0;

if resid_yr_qty = . then CshOut_OO_LT_1Yr = .; 
    else if resid_yr_qty <= 1 and csh_out_flg='Y' and Occpy_Cd='O' then CshOut_OO_LT_1Yr=1;
    else CshOut_OO_LT_1Yr = 0;

if purps_desc='Refinance' and Occpy_Cd='N' then Refi_Inv=1; else Refi_Inv=0;
if purps_desc='Refinance' and Occpy_Cd='S' then Refi_2ndHome=1; else Refi_2ndHome=0;

if (brrwr_state = '' or Subj_prpty_st_Cd = '') then BrrwrStPropStMismatch = .;
    else if (brrwr_state ne '' and  Subj_prpty_st_Cd ne '') and brrwr_state ne Subj_prpty_st_Cd then BrrwrStPropStMismatch = 1;
    else BrrwrStPropStMismatch = 0;

if (brrwr_state = '' or SponsorState = '') then BrrwrStSponsorStMismatch = .;
    else if (brrwr_state ne '' and  SponsorState ne '') and brrwr_state ne SponsorState then BrrwrStSponsorStMismatch = 1;
    else BrrwrStSponsorStMismatch = 0;

if (Subj_prpty_st_Cd = '' or SponsorState = '') then PropStSponsorStMismatch = .;
    else if (Subj_prpty_st_Cd ne '' and  SponsorState ne '') and Subj_prpty_st_Cd ne SponsorState then PropStSponsorStMismatch = 1;
    else PropStSponsorStMismatch = 0;

if cp_flg='Y' then cp_flg_new=1; else cp_flg_new=0;

if self_emp_flg eq '' then self_emp_flg= .; else if self_emp_flg='Y' then self_emp_new=1; else self_emp_new=0;

/* if frst_tm_hme_buyer_flg = '' then renter = .; else if frst_tm_hme_buyer_flg = 'Y' then renter = 1; else renter = 0;

if frst_tm_hme_buyer_flg = '' then Renter_2ndHome_YN = .;
    else if frst_tm_hme_buyer_flg = 'Y' and occpy_cd='S' then Renter_2ndHome_YN = 1;
    else Renter_2ndHome_YN = 0;

if frst_tm_hme_buyer_flg = '' then Renter_Investor_YN = .;
    else if frst_tm_hme_buyer_flg = 'Y' and occpy_cd='N' then Renter_Investor_YN = 1;
    else Renter_Investor_YN = 0; */

/* Reference # 1256697 */

if ( frst_tm_hme_buyer_flg = ''  OR frst_tm_hme_buyer_flg = 'N') then renter = .; else if frst_tm_hme_buyer_flg = 'Y' then renter = 1; else renter = 0;

if ( frst_tm_hme_buyer_flg = ''  OR frst_tm_hme_buyer_flg = 'N') then Renter_2ndHome_YN = .;
    else if frst_tm_hme_buyer_flg = 'Y' and occpy_cd='S' then Renter_2ndHome_YN = 1;
    else Renter_2ndHome_YN = 0;

if ( frst_tm_hme_buyer_flg = ''  OR frst_tm_hme_buyer_flg = 'N') then Renter_Investor_YN = .;
    else if frst_tm_hme_buyer_flg = 'Y' and occpy_cd='N' then Renter_Investor_YN = 1;
    else Renter_Investor_YN = 0;

/* Reference # 1256697 */ 

if occpy_cd='S' then SecondHome_YN = 1; else SecondHome_YN = 0;

if occpy_cd='N' then Investor_YN = 1; else Investor_YN = 0;

if InstInv=1 and InstInv2=0 and (yr_bld_nbr<=2011 or yr_bld_nbr=.) then Seller_Flag = 1;
else Seller_Flag=0;

if InstInv=1 and InstInv2=0 and (yr_bld_nbr<=2011 or yr_bld_nbr=.) then Institutional_Seller = "Y";
else Institutional_Seller = "N";

/*11/9/2015 added three below as potential flags*/
If Subj_prpty_st_Cd in ("NY", "SC", "NJ", "AL", "MS", "OH") then Risky_State_Potential_Flg = 1; else Risky_State_Potential_Flg = 0;

If purps_desc='Refinance' and Occpy_Cd='O' and cp_flg not in ("Y") and PrptyBrrwrDist ge 47 then Prop_Dist_Potential_Flg = 1; else Prop_Dist_Potential_Flg = 0;

If proces_ty_cd not in ("FAD", "PS+", "PS", "FD") then DTI_Potential_Flg = 0;
else if proces_ty_cd in ("FAD", "PS+", "PS", "FD") and (bk_end_ratio_pct ge 49.15 or bk_end_ratio_pct lt 4.35) then DTI_Potential_Flg = 1;
else DTI_Potential_Flg = 0;

%runquit;

/*add weighting*/
data loanleveldetaila;
set loanleveldetail;
IF purps_desc = "Purchase" or cp_flg = "Y" then OverallScoreNbr=0; 
else OverallScoreNbr=addr_match_score;
format OverallScorePercentage percentn10.;
If Originator_Score >= _median_*3 then OverallScoreNbr+5;
else If Originator_Score > _median_*1.5 then OverallScoreNbr+3;
If Bridge_Loan > 0 then OverallScoreNbr+1;
If BrrwrStPropStMismatch > 0 then OverallScoreNbr+2;
If CL_GT799 > 0 then OverallScoreNbr+1;
If cl_gt899 > 0 then OverallScoreNbr+2;
If CshOut_OO_LT_1Yr > 0 then OverallScoreNbr+1;
If EmpPOBox_YN > 0 then OverallScoreNbr+1;
If gaar_flg > 0 then OverallScoreNbr+1;
If Investor_YN > 0 then OverallScoreNbr+2;
If (SecondHome_YN = 1 and PrptyBrrwrDist > 300) or  (Investor_YN = 1 and PrptyBrrwrDist > 200) then OverallScoreNbr+1;
If Refi_2ndHome > 0 then OverallScoreNbr+1;
If Refi_2ndHome_LT_1Yr > 0 then OverallScoreNbr+2;
If Refi_Inv > 0 then OverallScoreNbr+1;
If Refi_inv_LT_1Yr > 0 then OverallScoreNbr+2;
If Renter > 0 then OverallScoreNbr+1;
If Renter_2ndHome_YN > 0 then OverallScoreNbr+9;
If Renter_Investor_YN > 0 then OverallScoreNbr+9;
If SecondHome_YN > 0 then OverallScoreNbr+1;
if Seller_Flag > 0 then OverallScoreNbr+2;
OverallScorePercentage=1-(OverallScoreNbr/30);
If (SecondHome_YN = 1 and PrptyBrrwrDist lt 10) then Scnd_Hm_LT10Mi = 1;
else Scnd_Hm_LT10Mi = 0;
%runquit;

data loanleveldetailb;
set loanleveldetaila;
format CoreLogic_Flag $10.; 
format Report_Dt mmddyy10.; /* Added for Automation */
LoanAttribScore=0;
If Bridge_Loan > 0 then LoanAttribScore+1;
If BrrwrStPropStMismatch > 0 then LoanAttribScore+2;
If CL_GT799 > 0 then LoanAttribScore+1;
If cl_gt899 > 0 then LoanAttribScore+2;
If CshOut_OO_LT_1Yr > 0 then LoanAttribScore+1;
If EmpPOBox_YN > 0 then LoanAttribScore+1;
If gaar_flg > 0 then LoanAttribScore+1;
If Investor_YN > 0 then LoanAttribScore+2;
If (SecondHome_YN = 1 and PrptyBrrwrDist > 300) or  (Investor_YN = 1 and PrptyBrrwrDist > 200) then LoanAttribScore+1;
If Refi_2ndHome > 0 then LoanAttribScore+1;
If Refi_2ndHome_LT_1Yr > 0 then LoanAttribScore+2;
If Refi_Inv > 0 then LoanAttribScore+1;
If Refi_inv_LT_1Yr > 0 then LoanAttribScore+2;
If Renter > 0 then LoanAttribScore+1;
If Renter_2ndHome_YN > 0 then LoanAttribScore+9;
If Renter_Investor_YN > 0 then LoanAttribScore+9;
If SecondHome_YN > 0 then LoanAttribScore+1;
if Seller_Flag > 0 then LoanAttribScore+2;
if BRRWR_CRED_SCOR ge 720 and ORIG_LTV_RATIO_PCT le 60 and PURPS_CD = "R" 
    then CoreLogic_Flag="Lowest";
if BRRWR_CRED_SCOR ge 780 and ORIG_LTV_RATIO_PCT gt 60 and ORIG_LTV_RATIO_PCT le 65 
    and PURPS_CD = "R" then CoreLogic_Flag="2nd Lowest";
if (BRRWR_CRED_SCOR ge 780 and ORIG_LTV_RATIO_PCT gt 65 and ORIG_LTV_RATIO_PCT le 80 
    and PURPS_CD = "R") or 
   (BRRWR_CRED_SCOR ge 720 and BRRWR_CRED_SCOR lt 780 and ORIG_LTV_RATIO_PCT gt 60 
    and ORIG_LTV_RATIO_PCT le 70 and PURPS_CD = "R")then CoreLogic_Flag="3rd Lowest";

	Report_Dt = input(put(intnx('day',&Rundate,-1),yymmddd10.),yymmdd10.); /* Added for Automation */

%runquit;
   
Proc Sql;
Create Table LD_Preftool_history_SAS_DS AS
Select
*
From
rptdata.LD_Preftool_history;
%runquit;    

Proc Sql;
Create Table LD_Preftool_history_SAS_DS_1 AS
Select
*
From
LD_Preftool_history_SAS_DS
Where
Report_Dt Not in 
(Select Distinct Report_Dt From loanleveldetailb);
%runquit;

Proc Sql;
Create Table Distinct_Rpt_Dt_Preftool AS
Select
distinct Report_Dt
From
LD_Preftool_history_SAS_DS_1
Order By Report_Dt;
%runquit;  

proc sql;
create table loanleveldetailc as
select 
    a.*,
    b.LN_NBR as LN_NBR_Prev,
    b.Approved_Dt as Approved_Dt_Prev,
    b.Approved_Dt_Entered as Approved_Dt_Entered_Prev,
    b.overallscorenbr as overallscorenbr_prev
from loanleveldetailb a
left join LD_Preftool_history_SAS_DS_1 b
on         a.LN_NBR = b.LN_NBR
;%runquit;

/*drops loans with the a ln # & overall score that already appears in the archive
**only diff (if any) would be approved date entered*/
data loanleveldetaild (drop=LN_NBR_Prev Approved_Dt_Prev Approved_Dt_Entered_Prev overallscorenbr_prev);
    set loanleveldetailc;
    /* format Report_Dt mmddyy10.;
    Report_Dt = input(put(intnx('day',today(),-1),yymmddd10.),yymmdd10.); */ /* Removed in Automation */
    if     (ln_nbr_prev ne "" and overallscorenbr ne overallscorenbr_prev)or 
        (LN_NBR_Prev = "") then output;
%runquit;

proc sort data=loanleveldetaild ;
    by OverallScorePercentage;
%runquit;

/*7/10/15 added empower campus data*/
/*11/9/15 added 3 potential flags to end*/
%let varList=
Audit_Type
Vintage
LN_NBR
scnd_ln_nbr
Report_dt
Approved_Dt
ln_clos_dt
BRRWR_LST_NM
BRRWR_FRST_NM
co_brrwr_lst_nm
co_brrwr_frst_nm
brrwr_age_nbr_new
RPT_TOT_INCM_AMT
SELF_EMP_FLG
SUBJ_PRPTY_ADDR_TXT
SUBJ_PRPTY_CITY_NM
SUBJ_PRPTY_ST_CD
SUBJ_PRPTY_ZIP_CD
mail_addr
mail_state
MailingZip
Fidelity_Mailing_Add
Fidelity_Mailing_City_Add
Fidelity_Mailing_State_Add
Fidelity_Mailing_Zip_Add
OCCPY_CD
PRPTY_TY_DESC
GROSS_LN_AMT
PURPS_CD
CP_FLG
Bridge_Loan
Refi_2ndHome
Refi_Inv
PGM_DESC
FRST_TM_HME_BUYER_FLG
Renter_2ndHome_YN
Renter_Investor_YN
CHNL
PROCESSINGCAMPUS
UNDERWRITINGCAMPUS
CLOSINGCAMPUS
Fulfillment_HUB
RGN_NM
MKT_NM
LO_nm
UW_nm
Vendor_UW_Co_Nm
PR_nm
CL_nm
THRD_PARTY_ORIG_NM
THRD_PARTY_ORIG_CD
SELLER_NM
Institutional_Seller
APPRSR_NM
SETL_AGNT_NM
ORIG_APPRS_AMT
BRRWR_CRED_SCOR
ORIG_LTV_RATIO_PCT
COMBN_LTV_RATIO_PCT
Age_Income
CL_Fraud_Score
CshOut_OO_LT_1Yr
EmpPOBox_YN
YR_BLD_NBR
addr_match_score
PrptyBrrwrDist
EmployerPrptyDist
OverallScorePercentage
OverallScoreNbr
LoanAttribScore
Originator_Score
CoreLogic_Flag
/*keeping the below at the end*/
uw_grma
emp_addr_txt
EMP_CITY_ST_ZIP_TXT
brrwr_addr
brrwr_state
borrowerzip
EST_CLOS_DT
FHA_FLAG
Scnd_Hm_LT10Mi
Risky_State_Potential_Flg
Prop_Dist_Potential_Flg
DTI_Potential_Flg
;

Data Loan_Level_Details (keep=&varList);
    retain &varList;
    set loanleveldetaild;
%runquit;    

/*7/10/15 added empower campus data*/
/*11/9/15 added 3 potential flags to end*/
%let varList2=
LN_NBR
scnd_ln_nbr
OverallScorePercentage
OverallScoreNbr
LoanAttribScore
Originator_Score
addr_match_score
Approved_Dt
Approved_Dt_Entered
DraftReceivedDt_GAAR
FirstDraftRecvd_CMS
LOCK_IN_EXPR_DT
EST_CLOS_DT
BRRWR_LST_NM
BRRWR_FRST_NM
SUBJ_PRPTY_ADDR_TXT
SUBJ_PRPTY_CITY_NM
Subj_prpty_st_Cd
Subj_prpty_zip_Cd
mail_addr
mail_state
MailingZip
/*added 4/9/2014*/brrwr_addr
/*added 4/9/2014*/brrwr_state
/*added 4/9/2014*/borrowerzip
/*added 4/9/2014*/PrptyBrrwrDist
OCCPY_CD
GROSS_LN_AMT
PGM_CD
PGM_DESC
PURPS_CD
PRPTY_TY_DESC
ORIG_CHNL
CHNL
/*added 7/10/2015*/PROCESSINGCAMPUS
/*added 7/10/2015*/UNDERWRITINGCAMPUS
/*added 7/10/2015*/CLOSINGCAMPUS
/*added 4/9/2014*/Fulfillment_HUB
CTR_CD
CTR_NM
MKT_NM
RGN_NM
PROCES_CTR_CD
Orig_ID
Orig_Nm
THRD_PARTY_ORIG_CD
THRD_PARTY_ORIG_NM
LO_id
LO_nm
UW_id
UW_nm
/*added 4/9/2014*/Vendor_UW_Co_Nm
/*added 4/9/2014*/uw_grma
ORIG_APPRS_AMT
APPRSR_NM
/*added 4/9/2014*/SETL_AGNT_NM
GEO_avm_val
est_val
ORIG_LTV_RATIO_PCT
COMBN_LTV_RATIO_PCT
CP_FLG
CSH_OUT_FLG
SELLER_NM
CURR_EMP_NM
/*added 4/9/2014*/emp_addr_txt
/*added 4/9/2014*/EMP_CITY_ST_ZIP_TXT
/*added 4/9/2014*/EmployerPrptyDist
EMP_LN_FLG
BIZ_PHN_NBR
BRRWR_CNT
BRRWR_CRED_SCOR
BRRWR_SSN
co_brrwr_lst_nm
/*added 4/9/2014*/co_brrwr_frst_nm
co_brrwr_ssn
Age_Income
FRGN_NATL_FLG
FRST_TM_HME_BUYER_FLG
MARR_STAT_CD
SELF_EMP_FLG
CL_Fraud_Score
variance
Bridge_Loan
BrrwrStPropStMismatch
CL_GT799
cl_GT899
CshOut_OO_LT_1Yr
EmpPOBox_YN
gaar_flg
Investor_YN
InstInv
InstInv2
/*added 4/9/2014*/Institutional_Seller
PrptyBrrwrDist
Refi_2ndHome
Refi_2ndHome_LT_1Yr
Refi_Inv
Refi_Inv_LT_1Yr
renter
Renter_2ndHome_YN
Renter_Investor_YN
SecondHome_YN
Seller_Flag
CoreLogic_Flag
ln_id
/*added 4/9/2014*/_median_
Report_dt
FHA_FLAG
Scnd_Hm_LT10Mi
/*added 11/9/2015*/Risky_State_Potential_Flg
/*added 11/9/2015*/Prop_Dist_Potential_Flg
/*added 11/9/2015*/DTI_Potential_Flg
;
/*
%macro FileExist;
%if %sysfunc(fileexist(&dorsshare.\FRM_Prefunding_Report\&ReportOut..xlsb)) %then 
  x rm "&dorsshare.\FRM_Prefunding_Report\&ReportOut..xlsb";                                          
%mend;
%FileExist;
*/
/* Removed on 10/25/2016

%Macro ExpFiles(DSName,Sname);
	proc export data=&DSName.
	outfile="&dorsshare.\FRM_Prefunding_Report\&ReportOut..xlsb" 
	dbms=ExcelCS replace;
	Sheet="&SName.";
	server='GA016A744'; 
	%runquit;
%Mend ExpFiles;
%ExpFiles(Loan_Level_Details,Loan Level Data);

%let InPath     = /dorsshare/FRM_Prefunding_Report/;
x cp "&InPath.&ReportOut..xlsb" "&OutDir/&ReportOut..xlsb";  

*/           
/*
Proc export 
data=Loan_Level_Details 
OUTFILE="&dorsshare\FRM_Prefunding_Report\PreFundingFraudDetection_asof_&outfilenm..xlsb"   
dbms=EXCELCS 
replace; 
sheet = "Loan Level Data";
server='saspcff';
/*server='GA016A744'; 
port=9621;*
%runquit;    
*/

%let trixpath1 = \\P1H-NAS-06A\trixprod-portfolio8\DORS\Mortgage\Mtg_Originations-Main\Dly_PreFunding_Fraud_Detection_Rpt_BICP0005032;

PROC EXPORT 
     DATA=Loan_Level_Details
     OUTFILE="&trixpath1.\PreFundingFraudDetection_asof_&outfilenm..xlsb"
     DBMS=EXCELCS 
     REPLACE /*label*/;
     Sheet="Loan Level Data";
     SERVER= &pcfilesvr. ;
PORT = 9621; 
SERVERUSER="&suserid.";
SERVERPASS="&mypass.";
%runquit; 

Data loanleveldetaildE (keep=&varList2);
    retain &varList2;
    set loanleveldetaild;
%runquit;

/* Data LD_Preftool_history (keep=&varList2);  Code from Linda - change dataset name here 
    retain &varList2;
    set loanleveldetaild;
%runquit; */

/*move copy of data to the archive table in MPROD SAS Datasets */
data rptdata.LD_Preftool_history;
    set LD_Preftool_history_SAS_DS_1 loanleveldetaildE;
%runquit;

/* data decan2.LD_Preftool_history;
    set decan2.LD_Preftool_history LD_Preftool_history;  Code from Linda for reference
*/   


/********************to Trix ******************************************************************/;

data _null_;
rc=sleep(50000);
%runquit;



%if %eval(&counterr >0) %then %do;


	
filename outbox EMAIL;
data _null_;
  FILE outbox
           to=("DL.RF.MORTGAGEESPJOBS@truist.com")  
           subject="&ReportOut error";
		;
           file outbox;
     PUT ;
  today = put(date(),worddate18.);
  PUT ' ' today;
  PUT 'Check log. Report failed'; 
  Put 'This e-mail is an automated notification!';
 run; 

%end;

%mend rpt();

%rpt();

%LET et = %SYSFUNC(DATE(),MMDDYY10.) %SYSFUNC(TIME(),TOD.);  
%PUT End Time:		&et;
%PUT Start Time:	&st;        

      
   



  

      

  

