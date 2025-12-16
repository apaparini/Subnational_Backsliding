
//Running the correlation between both datasets (Perez Sandoval vs Grumbach)

use "ised_data.dta", clear
rename state_name state
keep if country_id == 8
merge 1:1 state year using "democracy_full_factanal.dta"
keep if _merge==3
corr ised democracy_full_factanal


//Argentina's stats analysis as in Perez Sandoval (2023)

use "ised_data.dta", clear
keep if country_name == "Argentina"
	
	//Defining frame
xtset statecode year

	//Plotting line graph for each province
xtline ised_i competition_i participation_i, label(state_label) legend(label(1 "ISED") label(2 "Competition") label(3 "Participation"))

	//Plotting scatterplot for the covered period (1983-2019) -> REVIEW
twoway (scatter ised_i year if year>=1983 & year<=2019), ///
       xlabel(1983(5)2019) xtitle("Year") ytitle("ISED Index")

//Plotting Grumbach(2023) dataset overall trend for the US 2000-2018
use "democracy_full_factanal.dta", clear
preserve
	collapse (mean) democracy_full_factanal, by(year)
twoway line democracy_full_factanal year, ytitle("National Avg Democracy") xtitle("Year")
restore
