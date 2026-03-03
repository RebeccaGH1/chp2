# chp2

## 1merge_gov_data.ipynb
Merge the tables from Ministry of Cities from 2017 and 2025
Outputs are
    1) all_final_clear : all intervention in 2017 (Urb or San) and 2025, from Min City
   
## 1merged_API_conv.ipynb
Merge all the API files from interventions in different municipalities

## 1code_analysis_tablesCAIXA
Merge all files from Min City (2017, 2025) with CAIXA file. Initial analysis of investments types, time series.
Outputs are 
    1) all_merge_Tab2026 => all interventions in Min City 2017 or 2025 and CAIXA table
    2) all_merge_Tab2026_missing => interventions which are in Min City 2017 or 2025 but not in CAIXA table
        - they could still be in table 2017
    3) fig of investments $, by mont/year/state (3outputs)
  
## 2initial_data.R
Look at ministry of city data and see their distribution

## 2initial_data_CAIXA26.R
Using data details from 2025, filtered by the lsit of interventions givin by the Ministry of Cities, this code try to do some general statistics about the interventions. 