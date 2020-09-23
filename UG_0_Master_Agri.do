*-----------------------------------------------------------------------------
* Titel: The Impact of Rainfall on Agriculture Labor Supply
* Akito Kamei
*-----------------------------------------------------------------------------
* To do

clear all
global Path   "/Users/akitokamei/Desktop/Dropbox/Agri_Labor/"
global Data   "${Path}Data/"
global Table  "${Path}Paper/Table/"
global Figure "${Path}Paper/Figure/"
global do     "${Path}Do/"
global Temp   "${Data}Temp/"
global Final   "${Data}Final/"
cd "${Path}" 
set graph on
* set graph off

use "${Data}Rainfall/UG_GEO_Outut_Mon.dta", clear
foreach i in 1 2 3 4 5 {
	local j=`i'*12
	gen     Lag_Drought`i'=Dry_Ln_2012_2002_10[_n-`j']
	* replace Lag_Drought`i'=Dry_Ln_2012_2002_10[_n-`j'+1]
	* replace Lag_Drought`i'=Dry_Ln_2012_2002_10[_n-`j'+2]
	}
	
br Lag_Drought* Dry_Ln_2012_2002_10 lat_mod lon_mod Int_Year Int_Mon

										********************************************
										*** Merge & Append + Variable Selection ****
										********************************************										
* do "${do}UG_1_Prep.do"

*** Merge: Uganda
foreach i in 2009 2010 2011 {
use "${Temp}UG_`i'_HH_edit.dta", clear  // Need this info for all (Date of the interview)
merge 1:1 HHID using "${Temp}UG_`i'_Shock_edit.dta", gen(Merge_Shock)
	drop if Merge_Shock==2 // Recorded only for shock
merge 1:1 HHID using "${Temp}UG_`i'_Expend_edit.dta", gen(Merge_Water_Cons)
	drop if Merge_Water_Cons==2 // Recorded only for consumption
merge 1:1 HHID using "${Temp}UG_`i'_Water_edit.dta", gen(Merge_Water)
	drop if Merge_Water==2 // Recorded only for shock
merge 1:1 HHID using "${Temp}UG_`i'_Geo_edit.dta"  , gen(Merge_Geo)   // Need this info for all (Geo-Location)
	drop if Merge_Geo==2 // Recorded only for shock
merge 1:1 HHID using "${Temp}UG_`i'_Agri_edit.dta" , gen(Merge_Agri)
	drop if Merge_Agri==2              // Recorded only for agriculture
	replace Ag_Land=0 if Merge_Agri==1 // If the data is not recorded.... that means agri-land is zero
merge 1:1 HHID using "${Temp}UG_`i'_Agri2_edit.dta" , gen(Merge_Agri2)
 	drop if Merge_Agri2==2              // Recorded only for agriculture
 	replace Ag_Land2=0 if Merge_Agri2==1 // If the data is not recorded.... that means agri-land is zero
merge 1:m HHID using "${Temp}UG_`i'_Labor_edit.dta", gen(Merge_Labor) // Adding Individual Data
	drop if Merge_Labor==2 // Recorded only for shock
	* keep if Merge_Labor!=1 // Dropping the data if the individual data do not have household info
drop if PID=="" // Some has no PID? 
* Check
duplicates drop PID, force
merge 1:1 PID using "${Temp}UG_`i'_Indiv_edit.dta"    , gen(Merge_Indiv) // Sex and Age
	drop if Merge_Indiv==2 // Recorded only for Individual  (Dropping many sample with no labor info: 72% are less than age 5) Consider if the no record should be zero or replace to 0
merge 1:1 PID using "${Temp}UG_`i'_Indiv_edit2.dta"   , gen(Merge_Indiv2) // Migration Reason
	* drop if Merge_Indiv2==2 // Recorded only for Individual2 (Dropping many sample who is has record of going somewhere: Want to keep and analyze)
merge 1:1 PID using "${Temp}UG_`i'_Edu_edit.dta"      , gen(Merge_Edu)    // Education
	drop if Merge_Edu==2 // Recorded only for Education
merge 1:m PID using "${Temp}UG_`i'_Health_edit.dta", gen(Merge_Health) // Health
	drop if Merge_Health==2 // Recorded only for shock
gen Year=`i'
gen Country=1
gen PID_UNI_PANEL=PID
drop PID
save "${Temp}UG_`i'.dta", replace
}
* So far: I am dropping the sample that is not recorded for labor section

*** Append All
use          "${Temp}UG_2009.dta", clear
append using "${Temp}UG_2010.dta"
append using "${Temp}UG_2011.dta"

* Replace No as zero
foreach i in Illness Water_Paid Water_safe_com {
replace `i'=0 if `i'==2
}

* Rainfall of the last 7 days
	rename lat_mod lat_mod_orig
	rename lon_mod lon_mod_orig
	foreach i in lat_mod lon_mod {
	tostring `i'_orig, gen(`i'_str) force
	split `i'_str, p(".")
	replace lat_mod_str1="0"  if lat_mod_str1==""
	replace lat_mod_str1="-0" if lat_mod_str1=="-"
	gen `i'_str3=substr(`i'_str2,1,3)
	gen `i'=`i'_str1+"."+`i'_str3
	}
	
	* False Specification
	* use "${Data}Rainfall/UG_GEO_Output_False.dta"
	* reshape i() j ()
	* replace Int_Year=Int_Year+3
	
	* 7 Days Rainfall
	merge m:1 Int_Day Int_Mon Int_Year lat_mod lon_mod using "${Temp}Output_UG_FINAL_Geo_Date.dta", gen(Merge_Rain)
	* Monthly Rainfall
	merge m:1 Int_Mon Int_Year lat_mod lon_mod using "${Data}Rainfall/UG_GEO_Outut_Mon.dta", gen(Merge_Rain_Mon)
	
	foreach i in 1 2 3 4 5 {
	local j=`i'*12
	gen     Lag_Drought`i'=Dry_Ln_2012_2002_10[_n-`j']
	* replace Lag_Drought`i'=Dry_Ln_2012_2002_10[_n-`j'-1]
	* replace Lag_Drought`i'=Dry_Ln_2012_2002_10[_n-`j'-2]
	* replace Lag_Drought`i'=Dry_Ln_2012_2002_10[_n-`j'+1]
	* replace Lag_Drought`i'=Dry_Ln_2012_2002_10[_n-`j'+2]
	}
	gen Drought_Sum=Lag_Drought1+Lag_Drought2+Lag_Drought3+Lag_Drought4+Lag_Drought5
	
	drop if Merge_Rain_Mon==2 // Record only for rainfall data (okay to drop)
	* 10 Years Rainfall
	merge m:1 Int_Day Int_Mon Int_Year lat_mod lon_mod using "${Temp}Output_UG_FINAL_Geo_10_Years.dta",gen(Merge_Rain_10)
	drop if Merge_Rain_10==2  // Record only for rainfall data (okay to drop)

	* Econ Wage Job
	foreach i in Econ_Sun Econ_Mon Econ_Tue Econ_Wed Econ_Thu Econ_Fri Econ_Sat {
	replace `i'=0 if `i'==.
	}
	gen Econ_Hour=Econ_Sun+Econ_Mon+Econ_Tue+Econ_Wed+Econ_Thu+Econ_Fri+Econ_Sat
	* gen Econ_Hour=Econ_Mon+Econ_Tue+Econ_Wed+Econ_Thu+Econ_Fri
	* gen Econ_Hour=Econ_Sun+Econ_Sat

save "${Temp}Africa_merged.dta", replace

do "${do}UG_2_Label.do"
save "${Final}UG_FINAL_Diarrhea.dta", replace

do "${do}UG_3_Attrition.do"

* Final Data Set
use "${Final}Africa_Attrition.dta", clear

gen Rain_Season=0
replace Rain_Season=1 if (Int_Mon==1 | Int_Mon==2   | Int_Mon==3  | Int_Mon==4 | Int_Mon==8 | Int_Mon==9 | Int_Mon==10)
gen Dry_Season=0
replace Dry_Season=1  if (Int_Mon==5 | Int_Mon==6 | Int_Mon==7 | Int_Mon==11 | Int_Mon==12)

	* Water Paid For
	rename Water_Paid Water_Paid0
	gen Water_Paid1=0
	replace Water_Paid1=1 if Water_Paid_For==1
	gen Water_Paid2=0
	replace Water_Paid2=1 if Water_Paid_For==2
	
	* Water Paid For (Amount)
	rename Water_Shillings Water_Shillings0
	gen Water_Shillings1=0
	replace Water_Shillings1=Water_Shillings0 if Water_Paid_For==1
	gen Water_Shillings2=0
	replace Water_Shillings2=Water_Shillings0 if Water_Paid_For==2
	replace Water_Purchase=0 if Water_Purchase==.
	replace Water_Received=0 if Water_Received==.
	
save "${Final}UG_FINAL.dta", replace

use "${Final}UG_FINAL.dta", clear
rename LH_fetch_water fetch_water

	* Drought Categorical: 
	foreach i in Ln_2012_2002 Z_2012_2002 {
	gen `i'_Categ=.
	replace `i'_Categ=5 if `i'_100  > 90
	replace `i'_Categ=4 if `i'_100 <= 90 & `i'_100 > 70
	replace `i'_Categ=3 if `i'_100 <= 70 & `i'_100 > 30
	replace `i'_Categ=2 if `i'_100 <= 30 & `i'_100 > 10
	replace `i'_Categ=1 if `i'_100 <= 10
	}
	
	* Create Dummy
	recode Marital 99=5
	foreach v in Demo_group Region_categ Issue_Water Marital Water_safe_com {
	levelsof `v'
	foreach value in `r(levels)' {
		gen     `v'_`value'=0
		replace `v'_`value'=1 if `v'==`value'
		replace `v'_`value'=. if `v'==.
		label var `v'_`value' "`: label (`v') `value''"
	}
	}
	
	* Having other household member
	foreach i in 1 2 3 4 5 {
	* replace Demo_group_`i'=0 if Age<13
	bys HHID Year: egen Treat_Temp=sum(Demo_group_`i')
	gen Other_Treat_`i'=Treat_Temp-Demo_group_`i'
	recode Other_Treat_`i' 0=0 1/10=1
	drop Treat_Temp
	}
	
	foreach i in 1 2 3 4 {
	gen Econ_Type_`i'_18=Econ_Type_`i'
	replace Econ_Type_`i'_18=0 if Age<18
	bys HHID Year: egen Treat_Temp=sum(Econ_Type_`i'_18)
	gen Other_Econ_`i'=Treat_Temp-Econ_Type_`i'_18
	recode Other_Econ_`i' 0=0 1/30=1
	drop Treat_Temp
	}
	
	foreach i in 1 2 3 4 5 {
	bys HHID Year: egen Demo_group_`i'_Other=max(Demo_group_`i')
	}
	
	*Exchange Rate 
	foreach i in Water_Shillings0 Water_Shillings1 Water_Shillings2 Water_Purchase Water_Received Econ_Cash Econ_Inkind Earnings_month {
	* Source for exchange rate: World Bank
	replace `i'=`i'/1961.592464 if Int_Year==2009
	replace `i'=`i'/2028.8813 if Int_Year==2010
	replace `i'=`i'/2252.328556  if Int_Year==2011
	replace `i'=`i'/2430.509956 if Int_Year==2012
	replace `i'=`i'*100
	}

	* Dealing with Extreme Value:
	foreach i in LH_agri_hour fetch_water LH_firewood Ag_Land Edu_School_Dist Econ_Hour Time_Water ///
	              Water_Shillings1 Water_Shillings2 Water_Cons Distance_Water Wait_Water Water_Purchase Water_Received /// 
				  Earnings_month {
	summarize `i' if `i'!=0, detail
	replace `i'=. if `i'>= r(p99)
	}
		
	* Binary
	foreach i in LH_firewood fetch_water LH_agri_hour Water_Purchase Water_Received Econ_Hour {
	gen `i'_Bi=`i'
	recode `i'_Bi 0=0 0.001/500000000000000=1 
	}
	
	gen fetch_water_P=fetch_water
	replace fetch_water_P=. if fetch_water_P==0
	gen LH_agri_hour_P=LH_agri_hour
	replace LH_agri_hour_P=. if LH_agri_hour_P==0
	gen LH_firewood_P=LH_firewood
	replace LH_firewood_P=. if LH_firewood_P==0
	
	foreach i in Female Male Girl Boy {
	gen fetch_water_Bi_`i'=0
	}
	replace fetch_water_Bi_Female=1 if fetch_water_Bi==1 & Male==0
	replace fetch_water_Bi_Male=1   if fetch_water_Bi==1 & Male==1
	replace fetch_water_Bi_Girl=1   if fetch_water_Bi==1 & Demo_group==2
	replace fetch_water_Bi_Boy=1    if fetch_water_Bi==1 & Demo_group==1
	
	label var fetch_water_P "Hours (Participated)"
	label var fetch_water_Bi "Participation Total"
	label var fetch_water_Bi_Male "Participation Male"
	label var fetch_water_Bi_Female "Participation Female"
	label var fetch_water_Bi_Boy "Participation Boy"
	label var fetch_water_Bi_Girl "Participation Girl"
	
	label define Ln_2012_2002_Categl 5 "Abundance" 4 `" "Moderate"  "Abundance" "' 3 "Normal" 2 `" "Moderate"  "Scarcity" "' 1 "Drought", modify
	label values Ln_2012_2002_Categ Ln_2012_2002_Categl
	
	label define Urbanl 0 "Rural" 1 "Urban", modify
	label values Urban Urbanl
	
	* Domestic Work
	gen DM_hour=fetch_water+LH_agri_hour+LH_firewood
	label var DM_hour "Hours for Domestic Work"
	
	* Grouping HH by Drought Experience
	gen flag=1
	bys PID: egen Num_drought=sum(Dry_Ln_2012_2002_10)
	bys PID: egen Num_flag   =sum(flag)
	
	* Diarrhea
	gen Diarrhea=0
	replace Diarrhea=1 if (h5q7a==1 | h5q7b==1 | h5q7a==2 | h5q7b==2 | h5q7a==12 | h5q7b==12)
	
	* Filling the same community code if the location was the same
	bys lat_mod_str lon_mod_str Year: replace comcod=comcod[_n-1] if comcod==""
	sort lat_mod_str lon_mod_str Year
	forval i= 1/13 {
	bys lat_mod_str lon_mod_str: replace comcod=comcod[_n+`i'] if comcod==""
	bys lat_mod_str lon_mod_str: replace comcod=comcod[_n-`i'] if comcod==""
	}
	sort lat_mod lon_mod Year
	forval i= 1/4 {
	bys lat_mod lon_mod: replace comcod=comcod[_n+`i'] if comcod==""
	}	
	
save "${Final}UG_FINAL_Fetch.dta", replace

* Household Level Data
use "${Final}UG_FINAL_Fetch.dta", clear
	
 foreach v of var * {
 local l`v' : variable label `v'
 if `"`l`v''"' == "" {
 local l`v' "`v'"
 }
 }
 
collapse Baby_Num IHS_* Distance_Water Ln_2012_2002* Z_2012_2002* Wet* Dry* Water* Time_Water Wait_Water Mean10YRS Urban Drough* Year Edu* Wage_Work Region_categ Int_Mon_* Normal* Region_categ_* ///
         Issue_* Ave* regurb HH_Size regurb_* Ag_Land Ag_Land2 Merge_Agri av_LH_agri_hour=LH_agri_hour av_LH_firewood=LH_firewood av_fetch_water=fetch_water Cons_* ///
		 (sum) Econ* fetch_water LH_agri_hour LH_firewood fetch_water_Bi fetch_water_Bi_* Demo_group_1 Demo_group_2 Demo_group_3 Demo_group_4 Demo_group_5 ///
		 (max) LH_agri_hour_Bi LH_firewood_Bi,by(HHID Int_Year Int_Mon lat_mod lon_mod comcod lat_mod_str lon_mod_str)
		 
foreach v of var * {
label var `v' "`l`v''"
}
label var av_LH_agri_hour "Per person total weekly labor hours"
label var av_LH_firewood  "Per person total weekly labor hours"
label var av_fetch_water  "Per person total weekly labor hours"

	label values Water_Source Water_Sourcel
	label values Issue_Water Issue_Waterl
	
	* Consistent water source
	bys HHID: egen Mean_Source=mean(Water_Source)
	gen Water_Source_Diff=Water_Source-Mean_Source
	recode Water_Source_Diff 0=0 -1000000/-0.000000001 0.000000001/10000000=1
	drop Mean_Source
	bys HHID: egen Mean_Source=sum(Water_Source_Diff)
	drop Water_Source_Diff
	recode Mean_Source 0=0 1/8=1
	
	destring HHID, replace
	gen flag=1
	* Grouping HH by Drought Experience
	bys HHID: egen Num_drought=sum(Dry_Ln_2012_2002_10)
	bys HHID: egen Num_flag   =sum(flag)
	
	* Drop Duplicate with no comcode data
	duplicates drop HHID Int_Mon  Int_Year, force

	* Check in the clearning process
	save "${Final}UG_FINAL_Fetch_HH_temp.dta", replace
	drop if Num_flag==1
	drop if HHID==1083001608
	drop if HHID==2053001706
	drop if HHID==4123000501	
	drop if mod(HH_Size,1) > 0
	replace HH_Size = round(HH_Size,1)
	
	* Per person stats
	gen Water_Cons_Ave=Water_Cons/HH_Size
	gen Hour_Per=fetch_water/fetch_water_Bi
	
	label define Ln_2012_2002_Categl 5 "Abundance" 4 `" "Moderate"  "Abundance" "' 3 "Normal" 2 `" "Moderate"  "Scarcity" "' 1 "Drought", modify
	label values Ln_2012_2002_Categ Ln_2012_2002_Categl
	label define Z_2012_2002_Categl 5 `" "Abundance"  "(Z-score)" "' 4 `" "Moderate"  "Abundance" "(Z-score)" "' 3 `" "Normal" "(Z-score)" "' 2 `" "Moderate"  "Scarcity" "(Z-score)" "' 1 `" "Drought" "(Z-score)" "', modify
	label values Z_2012_2002_Categ Z_2012_2002_Categl
	
	* Household Size
	gen HH_Size_categ=HH_Size
	recode HH_Size_categ 1=1 2=2 3=3 4/8=4 9/14=5 15/23=6
	label define HH_Size_categl 1 "HH Size: 1" 2 "HH Size: 2" 3 "HH Size: 3" 4 "HH Size: 4-8" 5 "HH Size: 9-14" 6 "HH Size: 15-23", modify
	label values HH_Size_categ HH_Size_categl
	
	label define Urbanl 0 "Rural" 1 "Urban", modify
	label values Urban Urbanl
	
	* Among Variable
	foreach i in Water_Shillings1 Water_Purchase {
	gen `i'_AM=`i'
	replace `i'_AM=. if `i'_AM==0
	}

	label var fetch_water "Household total weekly hours for fetch water"
	label var av_fetch_water "Weekly hours for fetch water per person "
	label var Hour_Per       "Weekly hours for fetch water among participated"
	label var Drought_Shock "Reported Experience of Drought"
	label var Water_Paid1 "Pay user fee (0/1)"
	label var Water_Shillings1 "Pay user fee (Cents: including zero)"
	label var Water_Shillings1_AM "Pay user fee (among paid)"
	label var Water_Cons_Ave "Daily consumption per person (ltr)"
	label var fetch_water_Bi "Number of people participated"
	
	label var Water_Purchase_Bi "Water Purchase in the last 30 days (0/1)"
	label var Water_Purchase "Water Purchase in the last 30 days (including zero)"
	label var Water_Purchase_AM "Amount used in the last 30 days among paid (cents)"
	
save "${Final}UG_FINAL_Fetch_HH.dta", replace

use "${Final}UG_FINAL_Fetch_HH.dta", clear

 foreach v of var * {
 local l`v' : variable label `v'
 if `"`l`v''"' == "" {
 local l`v' "`v'"
 }
 }
collapse Water_Source_96 Water_Source_4 Water_Source_3 Water_Source_2 Water_Source_1 Urban HH_Size Water_Cons_Ave Water_Paid1 fetch_water Distance_Water Dry_Ln_2012_2002_10 (sum) flag ,by(comcod Year)

foreach v of var * {
label var `v' "`l`v''"
}
	foreach i in  Water_Source_96 Water_Source_4 Water_Source_3 Water_Source_2 Water_Source_1 {
	gen Com`i'=`i'
	recode Com`i' 0=0 0.0000001/1=1
	}
	label var flag "Number of household recorded"
	label var ComWater_Source_1 "At least one household using private tap"
	label var ComWater_Source_2 "At least one household using public tap"
	label var ComWater_Source_3 "At least one household using ground water"
	label var ComWater_Source_4 "At least one household using surface water"
	
save "${Final}UG_FINAL_Fetch_Com.dta", replace

use  "${Final}UG_FINAL_Fetch_Com.dta", clear
drop if comcod==""
global AllCom flag Dry_Ln_2012_2002_10 Urban HH_Size Water_Cons_Ave Water_Paid1 fetch_water Distance_Water ComWater_Source_1 ComWater_Source_2 ComWater_Source_3 ComWater_Source_4  Water_Source_1 Water_Source_2 Water_Source_3 Water_Source_4 Water_Source_96
tab  flag ComWater_Source_1

local TitleAllCom "Community Variable"

gen     Comm_Type=2
replace Comm_Type=1 if ComWater_Source_1==1
* replace Comm_Type=1 if ComWater_Source_2==1

save "${Final}Community_Class.dta", replace

END
* Whole Final
use "${Final}UG_FINAL.dta", clear
keep lat_mod lon_mod Country
destring  lat_mod lon_mod, replace
save "${Final}UG_FINAL_Geo_Date.dta", replace

* do "${do}UG_4_Stats.do"
* do "${do}UG_5_Analysis.do"
* do "${do}7_Map.do"

END

										*****************
										*** Diarrhea ****
										*****************

										
use "${Final}UG_FINAL_Fetch.dta", clear
keep Dry_Ln_2012_2002_10 HHID Year Dry_10
duplicates drop HHID Year, force
save "${Final}Rainfall_Simple.dta", replace

*** Merge: Uganda
foreach i in 2009 2010 2011 {
use "${Temp}UG_`i'_Indiv_edit.dta", clear
merge 1:1 PID using "${Temp}UG_`i'_DIARRHEA_edit.dta"
drop if _merge==1
drop _merge
gen Year=`i'
save "${Temp}UG_`i'_Diarrhea.dta", replace
}

use          "${Temp}UG_2009_Diarrhea.dta", clear
append using "${Temp}UG_2010_Diarrhea.dta"
append using "${Temp}UG_2011_Diarrhea.dta"
drop if Diarrhea==.
merge m:1 HHID Year using "${Final}Rainfall_Simple.dta", gen(Merge_Diarrhea)
keep if Merge_Diarrhea==3

* Create Dummy
foreach v in Diarrhea {
levelsof `v'
foreach value in `r(levels)' {
	gen     `v'_`value'=0
	replace `v'_`value'=1 if `v'==`value'
	replace `v'_`value'=. if `v'==.
	label var `v'_`value' 
	
	
	
	
}
}
eststo: reg Diarrhea_1 i.Dry_Ln_2012_2002_10 Male i.Age
eststo: reg Diarrhea_1 i.Dry_Ln_2012_2002_10 Male i.Age i.Year
eststo: reg Diarrhea_1 i.Dry_Ln_2012_2002_10 Male i.Age i.Year if Year==2009 |  Year==2010
estadd ysumm
esttab using "${Table}Main_Diarrhea.tex",label se ar2 title("Diarrhea" \label{wage}) nonotes ///
			 stats(N r2_a ymean, fmt(%8.3g) labels(`"Observation"' `"Adjusted \(R^{2}\)"' `"Mean"')) ///
			 starlevels(\sym{*} 0.10 \sym{**} 0.05 \sym{***} 0.010) ///
			 addnote("Standard errors in parentheses, $\sym{*} p<.10,\sym{**} p<.05,\sym{***} p<.01$" ///
			 "Total is the summation of hours for all household member (Household Level Sample). " ///
			 "The All is the individual data for whole sample.") ///
			 mtitle("Total" "All" "Boy" "Girl" "Man" "Woman" "Senior") replace
eststo clear

replace Diarrhea_1=Diarrhea_1*100
graph bar Dry_Ln_2012_2002_10, over(Year)
graph bar Diarrhea_1, over(Year)
graph bar Diarrhea_1, over(Age)


END


use "${Temp}TZ_2012_Indiv_edit.dta", clear
drop HHID
rename y2_hhid HHID
drop if  HHID==""
* Household that split into two needs line number to be re-assigned
duplicates drop HHID PID, force
merge 1:1 HHID PID using "${Temp}TZ_2010_Indiv_edit.dta"

		                                ***************************
										*** Generate Variables ****
										***************************
do "${do}1_2_Gen_Variable.do"

										**********************************
										** Filling data with reasoning  **
										**********************************
/*										
**** Comm variable: Filling missing since household does not migrate
sort round ID_Initial
bys  HHID: egen comm_mean=mean(comm)
replace comm=comm_mean if comm==.
drop comm_mean

**** Education: If the observation is sandwitched with never attended, missing should be never attended
sort round ID_Initial
bys ID_Initial: replace School=1 if School[_n-1]==1 & School[_n+1]==1 &  School==.

**** Missing for Working Hours:
foreach i in Econ_Sun Econ_Mon Econ_Tue Econ_Wed Econ_Thu Econ_Fri Econ_Sat {
replace `i'=0 if `i'==. & h8q17!=.
}

*/										
		                                ***********************
										*** Rainfall Merge ****
										***********************
										
* Age: Drop the sample with Age greater than 98
bys PID: egen Age_99=max(Age)
drop if Age_99>98
drop Age_99                                                                     // Drop if Age has no information or older than 99 (Hard to tell if it is missing or actual 99):  19
sort PID round                                                                  
bys PID: gen age_diff=Age-Age[_n-1]

* Interview partially saved 
drop if interview_result==2 & agri_hour==.                                      // Drop 36 interview is partially saved and did not reached to the labor section

* Not able to identify their sex
bys PID: egen Male_mean=mean(Male)

* If mean sex is leaning toward male, make the missing to male, vice versa: But only if they are considered to be the same person with age information
replace Male=0 if Male_mean>0.3 & Male_mean<0.4
replace Male=1 if Male_mean>0.6 & Male_mean<0.7

drop Male_mean                                                                  
bys PID: egen Male_mean=mean(Male)

keep if Male_mean==0 | Male_mean==1                                             
drop Male_mean                                                                  // Drop 40

* No Subcounty Name
drop if subcounty==""                                                           // 3,295 observations deleted. 5% (Think about what is happening (Standarize Subcounty Name))

* Same ID in same round
bys PID round: gen ID_N=_N
drop if ID_N>1                                                                  // 6 Obs

* Fix Mere Typo on string variable
do "${do}Sub_do/2_1_3_Typo"

* Merge with Rainfall Data
merge m:1 subcounty edate using "${data}Rainfall/Rainfall_final_merge.dta"
drop if _merge==1                                                               // 2215
drop if _merge==2
drop _merge

* Dry Spell Quintile
xtile Dry_Spell_Q=Dry_Spell if Dry_Spell>6, n(5)
replace Dry_Spell_Q=0 if Dry_Spell_Q==.

* IHS Transformation
foreach i in Distance_Water Edu_School_Dist Ave_7 Ave_14 Ave_21 Mean_Ave_7 Mean_Ave_14 Mean_Ave_21 {
gen IHS_`i'=log(`i' + sqrt(`i'^2 + 1))
gen Log_`i'=log(`i')
}
label var IHS_Ave_7 "1-7 Days (IHS)"
label var IHS_Ave_14 "8-14 Days (IHS)"
label var IHS_Ave_21 "15-21 Days (IHS)"
label var IHS_Mean_Ave_7 "1-7 Days (IHS: 10 Years)"
label var IHS_Mean_Ave_14 "8-14 Days (IHS: 10 Years)"
label var IHS_Mean_Ave_21 "15-21 Days (IHS: 10 Years)"

* Mean Water
gen Ave_7_14=(Ave_7+Ave_14)/2
label var Ave_7_14 "1-14 Days"
		                                ******************
										*** Drop Data ****
										******************

* Cleaning Hours
tab agri_hour,m
							
drop if Total_hours_All>106 &  Total_hours_All<500                              // 195 drop

bys PID: gen Num=_N

save "${data}Analysis_Sample_temp", replace
		                                ******************
										*** Attrition ****
										******************
do "${do}1_3_Attrition.do"


end

* Data Cleaning: Mere data entry isssue and Filling data with reasoning (e.g. Same sex all round for same Personal ID)
do "Do/Sub_do/2_1_2_cleaning"

										**********************
										*** Restricit Data ***
										**********************
* 4th Round has some issue, no data less than 10 years old, and Attrition
drop if round==4



* Descriptive statistics
* collapse _merge Rain, by (subcounty edate)
* twoway (scatter Rain edate if _merge==2) (scatter Rain edate if _merge==3, msymbol(Sh) mc(gs14)), legend(label(1 "No Interview") label(2 "Interview")) 
* graph save "Paper/Figure/hist_z_match", replace
* graph export "Paper/Figure/hist_z_match.eps", replace
* graph export "Paper/Figure/hist_z_match.png", replace

drop if _merge ==1                                                              // 1827 does not have rain data?
drop if _merge ==2                                                              
save "Data/2_Merge_Append_Restict", replace
