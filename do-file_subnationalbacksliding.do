
//1. Creating the Haggard & Kaufman (2021) - Backsliding episodes database

input str30 country_name year backsliding
"Bolivia" 2007 1
"Bolivia" 2008 1
"Bolivia" 2009 1
"Bolivia" 2010 1
"Bolivia" 2011 1
"Bolivia" 2012 1
"Bolivia" 2013 1
"Bolivia" 2014 1
"Bolivia" 2015 1
"Bolivia" 2016 1
"Bolivia" 2017 1
"Brazil" 2016 1
"Brazil" 2017 1
"Dominican Republic" 2014 1
"Dominican Republic" 2015 1
"Dominican Republic" 2016 1
"Dominican Republic" 2017 1
"Ecuador" 2009 1
"Ecuador" 2010 1
"Ecuador" 2011 1
"Ecuador" 2012 1
"Ecuador" 2013 1
"Ecuador" 2014 1
"Ecuador" 2015 1
"Ecuador" 2016 1
"Ecuador" 2017 1
"Greece" 2017 1
"Hungary" 2011 1
"Hungary" 2012 1
"Hungary" 2013 1
"Hungary" 2014 1
"Hungary" 2015 1
"Hungary" 2016 1
"Hungary" 2017 1
"North Macedonia" 2010 1
"North Macedonia" 2011 1
"North Macedonia" 2012 1
"North Macedonia" 2013 1
"North Macedonia" 2014 1
"North Macedonia" 2015 1
"North Macedonia" 2016 1
"Nicaragua" 2005 1
"Nicaragua" 2006 1
"Nicaragua" 2007 1
"Nicaragua" 2008 1
"Nicaragua" 2009 1
"Nicaragua" 2010 1
"Nicaragua" 2011 1
"Nicaragua" 2012 1
"Nicaragua" 2013 1
"Nicaragua" 2014 1
"Nicaragua" 2015 1
"Nicaragua" 2016 1
"Nicaragua" 2017 1
"Nicaragua" 2018 1
"Nicaragua" 2019 1
"Poland" 2016 1
"Poland" 2017 1
"Russia" 2000 1
"Russia" 2001 1
"Russia" 2002 1
"Russia" 2003 1
"Russia" 2004 1
"Russia" 2005 1
"Russia" 2006 1
"Russia" 2007 1
"Russia" 2008 1
"Russia" 2009 1
"Russia" 2010 1
"Russia" 2011 1
"Russia" 2012 1
"Russia" 2013 1
"Russia" 2014 1
"Russia" 2015 1
"Russia" 2016 1
"Russia" 2017 1
"Serbia" 2013 1
"Serbia" 2014 1
"Serbia" 2015 1
"Serbia" 2016 1
"Serbia" 2017 1
"Türkiye" 2010 1
"Türkiye" 2011 1
"Türkiye" 2012 1
"Türkiye" 2013 1
"Türkiye" 2014 1
"Türkiye" 2015 1
"Türkiye" 2016 1
"Türkiye" 2017 1
"Ukraine" 2010 1
"Ukraine" 2011 1
"Ukraine" 2012 1
"Ukraine" 2013 1
"Ukraine" 2014 1
"Ukraine" 2015 1
"Ukraine" 2016 1
"Ukraine" 2017 1
"United States of America" 2016 1
"United States of America" 2017 1
"Venezuela" 1998 1
"Venezuela" 1999 1
"Venezuela" 2000 1
"Venezuela" 2001 1
"Venezuela" 2002 1
"Venezuela" 2003 1
"Venezuela" 2004 1
"Venezuela" 2005 1
"Venezuela" 2006 1
"Venezuela" 2007 1
"Venezuela" 2008 1
"Venezuela" 2009 1
"Venezuela" 2010 1
"Venezuela" 2011 1
"Venezuela" 2012 1
"Venezuela" 2013 1
"Venezuela" 2014 1
"Venezuela" 2015 1
"Venezuela" 2016 1
"Venezuela" 2017 1
"Zambia" 2016 1
"Zambia" 2017 1
end

encode country_name, gen(country_id)
save "backsliding_episodes.dta", replace

//2. Cleaning V-Dem v15 (2025)
use "V-Dem-CY-Full+Others-v15.dta", clear

keep country_name country_id year v2x_libdem v2x_polyarchy v2x_regime e_boix_regime e_gdppc e_mipopula v2elffelr v2elffelrbin v2elsnlsff v2clrgunev

*Renaming for clarity
rename v2x_libdem      libdem
rename v2x_polyarchy   elecdem
rename e_mipopula      pop
rename v2elffelr       subnat_efree
rename v2elffelrbin    subnat_e

*Recoding for clarity
gen subnat_euneven = 3 - v2elsnlsff
gen subnat_civlib_uneven = 3 - v2clrgunev      

*Creating log_gdp / regimetype_binary
gen log_gdppc = log(e_gdppc)
gen log_pop = log(pop)
gen democracy_vdem = (v2x_regime >= 2) if !missing(v2x_regime)

save "vdem_subnational.dta", replace

//3. Merging datasets
merge 1:1 country_name year using "backsliding_episodes.dta", nogen
replace backsliding = 0 if missing(backsliding)
save "vdem_subnational_backsliding.dta", replace

//4. Running analysis
xtset country_id year

*Removing period not included in Haggard & Kaufman (2021)
keep if year >= 1990 & year <= 2017

* Defining onset of the backsliding episodes
by country_id (year): gen backsliding_onset = backsliding == 1 & (backsliding[_n-1] == 0 | _n == 1)

* Creating variation in elections free and fair
sort country_id year
by country_id: gen subnat_efree_t10 = subnat_efree[_n-10]
by country_id: gen subnat_efree_t0  = subnat_efree[_n]

gen d_subefree = subnat_efree_t0 - subnat_efree_t10

* Creating variation in civil liberties uneveness
by country_id: gen subnat_civlib_t10 = subnat_civlib_uneven[_n-10]
by country_id: gen subnat_civlib_t0  = subnat_civlib_uneven[_n]

gen d_subcivlib = subnat_civlib_t0 - subnat_civlib_t10

by country_id: gen L5_subnat_euneven = subnat_euneven[_n-5]

//Logit with clustered errors
	*Using BMR
preserve
keep if e_boix_regime == 1
logit backsliding_onset  subnat_euneven d_subefree d_subcivlib log_gdppc, vce(cluster country_id)
eststo boix
restore

	*Using RoW
preserve
keep if democracy_vdem == 1
logit backsliding_onset subnat_euneven d_subefree d_subcivlib log_gdppc, vce(cluster country_id)
eststo vdem
restore

estimates table boix vdem, stats(N r2_p)

//Firthlogit analysis

ssc install firthlogit
	*Using BMR
preserve
keep if e_boix_regime == 1
firthlogit backsliding_onset subnat_euneven d_subcivlib d_subefree log_gdppc
eststo boixfirth
restore

	*Using RoW	
preserve
keep if democracy_vdem == 1
firthlogit backsliding_onset subnat_euneven d_subcivlib d_subefree log_gdppc
eststo vdemfirth
restore

esttab using sub_backsliding.rtf, replace se label stats(chi2 df_m p r2_p ll N)


***************************OTHER SPECIFICATIONS NOT INCLUDED*******************************

//With interactions
* Regular logit with clustered errors
preserve
keep if democracy_vdem == 1
logit backsliding_onset c.subnat_euneven##c.subnat_efree d_subefree d_subcivlib subnat_civlib_uneven log_gdppc, vce(cluster country_id)
eststo vdem2
restore

*Firthlogit
preserve
keep if democracy_vdem == 1
firthlogit backsliding_onset c.subnat_euneven##c.subnat_efree d_subcivlib d_subefree subnat_civlib_uneven log_gdppc
eststo vdemfirth2
restore

//Controlling population + 5 years lag for subnational elections unevenness
* Regular logit with clustered errors
preserve
keep if democracy_vdem == 1
logit backsliding_onset L5_subnat_euneven d_subefree d_subcivlib subnat_civlib_uneven log_gdppc log_pop, vce(cluster country_id)
eststo vdem2
restore

*Firthlogit
preserve
keep if democracy_vdem == 1
firthlogit backsliding_onset L5_subnat_euneven d_subcivlib d_subefree subnat_civlib_uneven log_gdppc log_pop
eststo vdemfirth2
restore

//Rare event logit
	*Using BMR
relogit backsliding_onset L5.subnat_euneven d_subcivlib d_subefree log_gdppc ///
       if e_boix_regime==1, vce(cluster country_id) robust

	*Using RoW
relogit backsliding_onset L5.subnat_euneven d_subcivlib d_subefree log_gdppc ///
       if democracy_vdem ==1, vce(cluster country_id) robust

esttab using sub_backsliding_alternatives.rtf, replace se label stats(chi2 df_m p r2_p ll N)
