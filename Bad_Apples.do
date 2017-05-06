set more off
capture log close
log using "C:\Users\Sarcastic Sidra\Documents\NYU\4. Senior Year\Fall 2015\International Relations Senior Seminar\Data\Bad_Apples.log", text replace

clear
use "C:\Users\Sarcastic Sidra\Documents\NYU\4. Senior Year\Fall 2015\International Relations Senior Seminar\Data\Soccer_Replication\soccer_data.dta"

generate games_played = games_start + games_sub

generate total_cards = yellow_card + red_card

generate season = .
replace season = 2004 if year == "2004/05 Statistics"
replace season = 2005 if year == "2005/06 Statistics"
order season, after(league)
drop year

encode league, generate(league_factor)

generate region_indicator = .
replace region_indicator = 1 if africa == 1
replace region_indicator = 2 if asia == 1
replace region_indicator = 3 if east_europe == 1
replace region_indicator = 4 if lac == 1
replace region_indicator = 5 if oecd == 1

drop war_before
drop num_country
drop income
drop ln_income
drop weekly_wage
drop ln_wage

bysort team season league: egen teamavg_civwar = mean(civwar)
bysort team season league: egen teamavg_war_after = mean(war_after)
bysort team season league: egen teamavg_yellow_card = mean(yellow_card)
bysort team season league: egen teamavg_red_card = mean(red_card)
bysort team season league: egen teamavg_total_cards = mean(total_cards)
bysort team season league: egen teamavg_age = mean(age)
bysort team season league: egen teamavg_games_start = mean(games_start)
bysort team season league: egen teamavg_games_sub = mean(games_sub)
bysort team season league: egen teamavg_games_played = mean(games_played)
bysort team season league: egen teamavg_goals = mean(goals)
bysort team season league: egen teamavg_r_law = mean(r_law)
bysort team season league: egen teamavg_contract = mean(contract)
bysort team season league: egen teamavg_ln_contract = mean(ln_contract)

egen new_player_id = group(player_id season league games_start games_sub goals yellow_card red_card)
drop player_id
rename new_player_id player_id
order player_id

duplicates tag player_id, gen(dup)
duplicates drop
drop dup

save Bad_Apples_1.dta, replace
copy Bad_Apples_1.dta Bad_Apples_2.dta, replace

use Bad_Apples_1.dta, clear
renvars player_id - teamavg_ln_contract, postfix(_i)
rename team_i team
rename season_i season
rename league_i league
save, replace

use Bad_Apples_2.dta, clear
renvars player_id - teamavg_ln_contract, postfix(_j)
rename team_j team
rename season_j season
rename league_j league
save, replace

use Bad_Apples_1.dta, clear
joinby team season league using Bad_Apples_2.dta

drop if player_id_i == player_id_j

save Bad_Apples_Dyadic.dta

generate gmply_together = 1 - abs((games_played_i - games_played_j) / max(games_played_i, games_played_j))

spmon yellow_card_j, w(gmply_together) i(player_id_i) k(player_id_j) time(season) sename(se_gmply_yellow)

spmon red_card_j, w(gmply_together) i(player_id_i) k(player_id_j) time(season) sename(se_gmply_red)

spmon total_cards_j, w(gmply_together) i(player_id_i) k(player_id_j) time(season) sename(se_gmply_total_cards)

spmon civwar_j, w(gmply_together) i(player_id_i) k(player_id_j) time(season) sename(se_civwar)

drop player_id_j - teamavg_ln_contract_j
drop games_played_i
drop teamavg_games_played_i
drop gmply_together
drop _merge

duplicates drop

save Bad_Apples_Monadic.dta

outreg2 using Summary_Statistics.doc, replace sum(log)

* REGRESSIONS - MIGUEL ET AL. (2011) "Replication"

* Yellow Cards
nbreg yellow_card_i civwar_i age_i ln_contract_i games_start_i games_sub_i defender_i forward_i midfield_i goals_i africa_i asia_i east_europe_i lac_i italian_i champions_i french_i german_i spanish_i, robust cluster(nation_i)
outreg2 using Miguel_Replication.doc, replace ctitle(Yellow Cards) keep(civwar_i defender_i forward_i midfield_i games_start_i games_sub_i age_i ln_contract_i goals_i) addtext(League Fixed Effects, Yes, World Region Fixed Effects, Yes)

* Red Cards
nbreg red_card_i civwar_i age_i games_start_i games_sub_i defender_i forward_i midfield_i goals_i ln_contract_i africa_i asia_i east_europe_i lac_i italian_i champions_i french_i german_i spanish_i r_law_i, robust cluster(nation_i)
outreg2 using Miguel_Replication.doc, append ctitle(Red Cards) keep(civwar_i age_i games_start_i games_sub_i defender_i forward_i midfield_i goals_i ln_contract_i r_law_i) addtext(League Fixed Effects, Yes, World Region Fixed Effects, Yes)

* Total Cards
nbreg total_cards_i civwar_i r_law_i age_i games_start_i games_sub_i defender_i forward_i midfield_i goals_i ln_contract_i africa_i asia_i east_europe_i lac_i italian_i champions_i french_i german_i spanish_i, robust cluster(nation_i)
outreg2 using Miguel_Replication.doc, append ctitle(Total Cards) keep(civwar_i r_law_i age_i games_start_i games_sub_i defender_i forward_i midfield_i goals_i ln_contract_i) addtext(League Fixed Effects, Yes, World Region Fixed Effects, Yes)

estimates clear

* REGRESSIONS - AGGREGATE INFLUENCE

* Spatial Effect: Years of Civil War in Player j's Home Country, Weight = Games Played Together
* Yellow Cards - Individual Controls
nbreg yellow_card_i se_civwar civwar_i defender_i midfield_i forward_i games_start_i games_sub_i age_i goals_i ln_contract_i i. league_factor_i i. region_indicator_i, robust cluster(nation_i) 
outreg2 using SE_Civwar_Team_I.doc, replace ctitle(Yellow Cards, Individual Controls) keep(se_civwar civwar_i goalie_i defender_i midfield_i forward_i games_start_i games_sub_i age_i goals_i ln_contract_i) addtext(League Fixed Effects, Yes, World Region Fixed Effects, Yes)

* Yellow  Cards - Team Controls
nbreg yellow_card_i se_civwar civwar_i teamavg_games_start_i teamavg_games_sub_i teamavg_age_i teamavg_goals_i teamavg_ln_contract_i i. league_factor_i i. region_indicator_i, robust cluster(nation_i) 
outreg2 using SE_Civwar_Team_I.doc, append ctitle(Yellow Cards, Team Controls) keep(se_civwar civwar_i teamavg_games_start_i teamavg_games_sub_i teamavg_age_i teamavg_goals_i teamavg_ln_contract_i) addtext(League Fixed Effects, Yes, World Region Fixed Effects, Yes)

* Red Cards - Individual Controls
nbreg red_card_i se_civwar civwar_i defender_i midfield_i forward_i games_start_i games_sub_i age_i goals_i ln_contract_i r_law_i i. league_factor_i i. region_indicator_i, robust cluster(nation_i) 
outreg2 using SE_Civwar_Team_I.doc, append ctitle(Red Cards, Individual Controls) keep(se_civwar civwar_i defender_i midfield_i forward_i games_start_i games_sub_i age_i goals_i ln_contract_i r_law_i) addtext(League Fixed Effects, Yes, World Region Fixed Effects, Yes)

* Red Cards - Team Controls
nbreg red_card_i se_civwar civwar_i teamavg_games_start_i teamavg_games_sub_i teamavg_age_i teamavg_goals_i teamavg_ln_contract_i teamavg_r_law_i i. league_factor_i i. region_indicator_i, robust cluster(nation_i) 
outreg2 using SE_Civwar_Team_I.doc, append ctitle(Red Cards, Team Controls) keep(se_civwar civwar_i teamavg_games_start_i teamavg_games_sub_i teamavg_age_i teamavg_goals_i teamavg_ln_contract_i teamavg_r_law_i) addtext(League Fixed Effects, Yes, World Region Fixed Effects, Yes)

* Total Cards - Individual Controls
nbreg total_cards_i se_civwar civwar_i defender_i midfield_i forward_i games_start_i games_sub_i age_i goals_i ln_contract_i r_law_i i. league_factor_i i. region_indicator_i, robust cluster(nation_i) 
outreg2 using SE_Civwar_Team_I.doc, append ctitle(Total Cards, Individual Controls) keep(se_civwar civwar_i defender_i midfield_i forward_i games_start_i games_sub_i age_i goals_i ln_contract_i r_law_i) addtext(League Fixed Effects, Yes, World Region Fixed Effects, Yes)

* Total Cards - Team Controls
nbreg total_cards_i se_civwar civwar_i teamavg_games_start_i teamavg_games_sub_i teamavg_age_i teamavg_goals_i teamavg_ln_contract_i teamavg_r_law_i i. league_factor_i i. region_indicator_i, robust cluster(nation_i) 
outreg2 using SE_Civwar_Team_I.doc, append ctitle(Total Cards, Team Controls) keep(se_civwar civwar_i teamavg_games_start_i teamavg_games_sub_i teamavg_age_i teamavg_goals_i teamavg_ln_contract_i teamavg_r_law_i) addtext(League Fixed Effects, Yes, World Region Fixed Effects, Yes)

estimates clear

* Spatial Effect: Cards Received by Player j, Weight = Games Played Together - Individual Controls
*Yellow Cards – Individual Controls
nbreg yellow_card_i se_gmply_yellow civwar_i defender_i midfield_i forward_i games_start_i games_sub_i age_i goals_i ln_contract_i i. league_factor_i i. region_indicator_i, robust cluster(nation_i) 
outreg2 using SE_Cards_Team_I.doc, replace ctitle(Yellow Cards, Individual Controls) keep(se_gmply_yellow civwar_i goalie_i defender_i midfield_i forward_i games_start_i games_sub_i age_i goals_i ln_contract_i) addtext(League Fixed Effects, Yes, World Region Fixed Effects, Yes)

* Yellow Cards - Team Controls
nbreg yellow_card_i se_gmply_yellow civwar_i teamavg_games_start_i teamavg_games_sub_i teamavg_age_i teamavg_goals_i teamavg_ln_contract_i i. league_factor_i i. region_indicator_i, robust cluster(nation_i) 
outreg2 using SE_Cards_Team_I.doc, append ctitle(Yellow Cards, Team Controls) keep(se_gmply_yellow civwar_i teamavg_games_start_i teamavg_games_sub_i teamavg_age_i teamavg_goals_i teamavg_ln_contract_i) addtext(League Fixed Effects, Yes, World Region Fixed Effects, Yes)

* Red Cards - Individual Controls
nbreg red_card_i se_gmply_red civwar_i defender_i midfield_i forward_i games_start_i games_sub_i age_i goals_i ln_contract_i r_law_i i. league_factor_i i. region_indicator_i, robust cluster(nation_i) 
outreg2 using SE_Cards_Team_I.doc, append ctitle(Red Cards, Individual Controls) keep(se_gmply_red civwar_i defender_i midfield_i forward_i games_start_i games_sub_i age_i goals_i ln_contract_i r_law_i) addtext(League Fixed Effects, Yes, World Region Fixed Effects, Yes)

* Red Cards - Team Controls
nbreg red_card_i se_gmply_red civwar_i teamavg_games_start_i teamavg_games_sub_i teamavg_age_i teamavg_goals_i teamavg_ln_contract_i teamavg_r_law_i i. league_factor_i i. region_indicator_i, robust cluster(nation_i) 
outreg2 using SE_Cards_Team_I.doc, append ctitle(Red Cards, Team Controls) keep(se_gmply_red civwar_i teamavg_games_start_i teamavg_games_sub_i teamavg_age_i teamavg_goals_i teamavg_ln_contract_i teamavg_r_law_i) addtext(League Fixed Effects, Yes, World Region Fixed Effects, Yes)

* Total Cards - Individual Controls
nbreg total_cards_i se_gmply_total_cards civwar_i defender_i midfield_i forward_i games_start_i games_sub_i age_i goals_i ln_contract_i r_law_i i. league_factor_i i. region_indicator_i, robust cluster(nation_i) 
outreg2 using SE_Cards_Team_I.doc, append ctitle(Total Cards, Individual Controls) keep(se_gmply_total_cards civwar_i defender_i midfield_i forward_i games_start_i games_sub_i age_i goals_i ln_contract_i r_law_i) addtext(League Fixed Effects, Yes, World Region Fixed Effects, Yes)

* Total Cards - Team Controls
nbreg total_cards_i se_gmply_total_cards civwar_i teamavg_games_start_i teamavg_games_sub_i teamavg_age_i teamavg_goals_i teamavg_ln_contract_i teamavg_r_law_i i. league_factor_i i. region_indicator_i, robust cluster(nation_i) 
outreg2 using SE_Cards_Team_I.doc, append ctitle(Total Cards, Team Controls) keep(se_gmply_total_cards civwar_i teamavg_games_start_i teamavg_games_sub_i teamavg_age_i teamavg_goals_i teamavg_ln_contract_i teamavg_r_law_i) addtext(League Fixed Effects, Yes, World Region Fixed Effects, Yes)

estimates clear

* ROBUSTNESS CHECKS - AGGREGATE INFLUENCE

* Spatial Effect: Cards Received by Player j, Weight = Games Played Together - Individual Controls
* Yellow Cards - Individual Controls
zinb yellow_card_i se_gmply_yellow civwar_i defender_i midfield_i forward_i games_start_i games_sub_i age_i goals_i ln_contract_i i. league_factor_i i. region_indicator_i, inflate(yellow_card_i se_gmply_yellow civwar_i defender_i midfield_i forward_i games_start_i games_sub_i age_i goals_i ln_contract_i i. league_factor_i i. region_indicator_i) robust cluster(nation_i) 
outreg2 using Cards_Team_I_Robustness.doc, replace ctitle(Yellow Cards, Individual Controls) keep(se_gmply_yellow civwar_i defender_i midfield_i forward_i games_start_i games_sub_i age_i goals_i ln_contract_i) addtext(League Fixed Effects, Yes, World Region Fixed Effects, Yes)

* Yellow Cards - Team Controls
zinb yellow_card_i se_gmply_yellow civwar_i teamavg_games_start_i teamavg_games_sub_i teamavg_age_i teamavg_goals_i teamavg_ln_contract_i i. league_factor_i i. region_indicator_i, inflate(yellow_card_i se_gmply_yellow civwar_i teamavg_games_start_i teamavg_games_sub_i teamavg_age_i teamavg_goals_i teamavg_ln_contract_i i. league_factor_i i. region_indicator_i) robust cluster(nation_i) 
outreg2 using Cards_Team_I _Robustness.doc, append ctitle(Yellow Cards, Team Controls) keep(se_gmply_yellow civwar_i teamavg_games_start_i teamavg_games_sub_i teamavg_age_i teamavg_goals_i teamavg_ln_contract_i) addtext(League Fixed Effects, Yes, World Region Fixed Effects, Yes)

* Total Cards - Individual Controls
zinb total_cards_i se_gmply_total civwar_i defender_i midfield_i forward_i games_start_i games_sub_i age_i goals_i ln_contract_i r_law_i i. league_factor_i i. region_indicator_i, inflate(total_cards_i se_gmply_total civwar_i defender_i midfield_i forward_i games_start_i games_sub_i age_i goals_i ln_contract_i r_law_i i. league_factor_i i. region_indicator_i) robust cluster(nation_i) 
outreg2 using Cards_Team_I _Robustness.doc, append ctitle(Total Cards, Individual Controls) keep(se_gmply_total civwar_i defender_i midfield_i forward_i games_start_i games_sub_i age_i goals_i ln_contract_i r_law_i) addtext(League Fixed Effects, Yes, World Region Fixed Effects, Yes)

* Total Cards - Team Controls
zinb total_cards_i se_gmply_total civwar_i teamavg_games_start_i teamavg_games_sub_i teamavg_age_i teamavg_goals_i teamavg_ln_contract_i teamavg_r_law_i i. league_factor_i i. region_indicator_i, inflate(total_cards_i se_gmply_total_cards civwar_i teamavg_games_start_i teamavg_games_sub_i teamavg_age_i teamavg_goals_i teamavg_ln_contract_i teamavg_r_law_i i. league_factor_i i. region_indicator_i) robust cluster(nation_i) 
outreg2 using Cards_Team_I _Robustness.doc, append ctitle(Total Cards, Team Controls) keep(se_gmply_total_cards civwar_i teamavg_games_start_i teamavg_games_sub_i teamavg_age_i teamavg_goals_i teamavg_ln_contract_i teamavg_r_law_i) addtext(League Fixed Effects, Yes, World Region Fixed Effects, Yes)

estimates clear

use Bad_Apples_Dyadic.dta, clear

* REGRESSIONS - INDIVIDUAL INFLUENCE

* Years of Civil War in Player j's Home Country 
* Yellow Cards
nbreg yellow_card_i civwar_j civwar_i defender_i midfield_i forward_i games_start_i games_sub_i age_i goals_i ln_contract_i i. league_factor_i i. region_indicator_i, robust cluster(nation_i) 
outreg2 using Civwar_Player_j.doc, replace ctitle(Yellow Cards) keep(civwar_j civwar_i defender_i midfield_i forward_i games_start_i games_sub_i age_i goals_i ln_contract_i) addtext(League Fixed Effects, Yes, World Region Fixed Effects, Yes)

* Red Cards
nbreg red_card_i civwar_j civwar_i defender_i midfield_i forward_i games_start_i games_sub_i age_i goals_i ln_contract_i r_law_i i. league_factor_i i. region_indicator_i, robust cluster(nation_i) 
outreg2 using Civwar_Player_j.doc, append ctitle(Red Cards) keep(civwar_j civwar_i defender_i midfield_i forward_i games_start_i games_sub_i age_i goals_i ln_contract_i r_law_i i. league_factor_i) addtext(League Fixed Effects, Yes, World Region Fixed Effects, Yes)

* Total Cards
nbreg total_cards_i civwar_j civwar_i defender_i midfield_i forward_i games_start_i games_sub_i age_i goals_i ln_contract_i r_law_i i. league_factor_i i. region_indicator_i, robust cluster(nation_i) 
outreg2 using Civwar_Player_j.doc, append ctitle(Total Cards) keep(civwar_j civwar_i defender_i midfield_i forward_i games_start_i games_sub_i age_i goals_i ln_contract_i r_law_i) addtext(League Fixed Effects, Yes, World Region Fixed Effects, Yes) 

estimates clear  

* Cards Received by Player j 
* Yellow Cards
nbreg yellow_card_i yellow_card_j civwar_i defender_i midfield_i forward_i games_start_i games_sub_i age_i goals_i ln_contract_i i. league_factor_i i. region_indicator_i, robust cluster(nation_i) 
outreg2 using Cards_Player_j.doc, replace ctitle(Yellow Cards) keep(yellow_card_j civwar_i defender_i midfield_i forward_i games_start_i games_sub_i age_i goals_i ln_contract_i) addtext(League Fixed Effects, Yes, World Region Fixed Effects, Yes)

* Red Cards 
nbreg red_card_i red_card_j civwar_i defender_i midfield_i forward_i games_start_i games_sub_i age_i goals_i ln_contract_i r_law_i i. league_factor_i i. region_indicator_i, robust cluster(nation_i) 
outreg2 using Cards_Player_j.doc, append ctitle(Red Cards) keep(red_card_j civwar_i defender_i midfield_i forward_i games_start_i games_sub_i age_i goals_i ln_contract_i r_law_i) addtext(League Fixed Effects, Yes, World Region Fixed Effects, Yes)

* Total Cards 
nbreg total_cards_i total_cards_j civwar_i defender_i midfield_i forward_i games_start_i games_sub_i age_i goals_i ln_contract_i r_law_i i. league_factor_i i. region_indicator_i, robust cluster(nation_i) 
outreg2 using Cards_Player_j.doc, append ctitle(Total Cards) keep(total_cards_j civwar_i defender_i midfield_i forward_i games_start_i games_sub_i age_i goals_i ln_contract_i r_law_i) addtext(League Fixed Effects, Yes, World Region Fixed Effects, Yes)

estimates clear

use Bad_Apples_Monadic.dta, clear

* MARGINAL EFFECTS - AGGREGATE INFLUENCE

* Spatial Effect: Cards Received by Player j, Weight = Games Played Together - Individual Controls
* Yellow Cards - Individual Controls
nbreg yellow_card_i se_gmply_yellow civwar_i defender_i midfield_i forward_i games_start_i games_sub_i age_i goals_i ln_contract_i i. league_factor_i i. region_indicator_i, robust cluster(nation_i) 
margins, at(se_gmply_yellow=(0 1.209986 2.558272 7.840179)) vsquish
marginsplot, yline(0)
/*
1.209986 = Lionel Messi, Barcelona (UEFA 2005-06)
2.558272 = Zamora Raul Medina, Atletico Madrid (Spain 2004-05)
7.840179 = Cesar, Malaga (Spain 2005-06)
*/

* Red Cards - Individual Controls
nbreg red_card_i se_gmply_red civwar_i defender_i midfield_i forward_i games_start_i games_sub_i age_i goals_i ln_contract_i r_law_i i. league_factor_i i. region_indicator_i, robust cluster(nation_i) 
margins, at(se_gmply_red=(0 .1320298 1.034383)) vsquish
marginsplot, yline(0)
/*
.1320298 = Christian Alvarez & Tono, Racing Santander (Spain 2004-05)
1.034383 = Cesar, Malaga (Spain 2005-06)
*/

* Total Cards - Individual Controls
nbreg total_cards_i se_gmply_total_cards civwar_i defender_i midfield_i forward_i games_start_i games_sub_i age_i goals_i ln_contract_i r_law_i i. league_factor_i i. region_indicator_i, robust cluster(nation_i) 
margins, at(se_gmply_total=(0 1.209986 2.703115 8.874562)) vsquish  
marginsplot, yline(0)
/*
1.209986 = Lionel Messi, Barcelona (UEFA 2005-06)
2.703115 = Pernambucano Juninho, Lyon (France 2004-05)
8.874562 = Cesar, Malaga (Spain 2005-06)
*/

* INCIDENCE RATE RATIOS - AGGREGATE INFLUENCE

* Spatial Effect: Cards Received by Player j, Weight = Games Played Together - Individual Controls
*Yellow Cards – Individual Controls
nbreg yellow_card_i se_gmply_yellow civwar_i defender_i midfield_i forward_i games_start_i games_sub_i age_i goals_i ln_contract_i i. league_factor_i i. region_indicator_i, robust cluster(nation_i) irr
outreg using SE_Cards_Team_I_IRR.doc, irr replace ctitle(Yellow Cards, Individual Controls)
 
* Yellow Cards - Team Controls
nbreg yellow_card_i se_gmply_yellow civwar_i teamavg_games_start_i teamavg_games_sub_i teamavg_age_i teamavg_goals_i teamavg_ln_contract_i i. league_factor_i i. region_indicator_i, robust cluster(nation_i) irr
outreg using SE_Cards_Team_I_IRR.doc, irr append ctitle(Yellow Cards, Team Controls) 

* Red Cards - Individual Controls
nbreg red_card_i se_gmply_red civwar_i defender_i midfield_i forward_i games_start_i games_sub_i age_i goals_i ln_contract_i r_law_i i. league_factor_i i. region_indicator_i, robust cluster(nation_i) irr
outreg using SE_Cards_Team_I_IRR.doc, irr append ctitle(Red Cards, Individual Controls)
 
* Red Cards - Team Controls
nbreg red_card_i se_gmply_red civwar_i teamavg_games_start_i teamavg_games_sub_i teamavg_age_i teamavg_goals_i teamavg_ln_contract_i teamavg_r_law_i i. league_factor_i i. region_indicator_i, robust cluster(nation_i) irr
outreg using SE_Cards_Team_I_IRR.doc, irr append ctitle(Red Cards, Team Controls) 

* Total Cards - Individual Controls
nbreg total_cards_i se_gmply_total_cards civwar_i defender_i midfield_i forward_i games_start_i games_sub_i age_i goals_i ln_contract_i r_law_i i. league_factor_i i. region_indicator_i, robust cluster(nation_i) irr
outreg using SE_Cards_Team_I_IRR.doc, irr append ctitle(Total Cards, Individual Controls) 

* Total Cards - Team Controls
nbreg total_cards_i se_gmply_total_cards civwar_i teamavg_games_start_i teamavg_games_sub_i teamavg_age_i teamavg_goals_i teamavg_ln_contract_i teamavg_r_law_i i. league_factor_i i. region_indicator_i, robust cluster(nation_i) irr
outreg using SE_Cards_Team_I_IRR.doc, irr append ctitle(Total Cards, Team Controls)

* CHARTS
twoway (scatter yellow_card se_gmply_yellow) (lfit yellow_card se_gmply_yellow), title(The Effect of Interaction with Player j on the Number of Yellow Cards Received By Player i) xtitle(Spatial Effect, Weight = Position Distance) ytitle(Yellow Cards)
twoway (scatter red_card se_gmply_red) (lfit red_card se_gmply_red), title(The Effect of Interaction with Player j on the Number of Red Cards Received By Player i) xtitle(Spatial Effect, Weight = Position Distance) ytitle(Red Cards)

log close
