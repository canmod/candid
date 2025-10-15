source("conflicts-policy.R")
library(dplyr)
library(tidyr)
library(iidda)
library(xtable)


keys = c(
    "cdi_mort_on_1903-1947_mn"
  , "cdi_sask_1910_1927_mn"
  , "cdi_qc_1895-1925_1927-31_mn_munic"
  , "cdi_ca_1924-55_wk_prov_dbs_statcan"
  , "cdi_mort_on_1939-1989_wk_moh"
  , "cdi_ca_1956-63_1973-74_wk_prov"
  , "cdi_ca_1956-63_1973-74_wk_prov"
  , "cdi_ca_1964-67_wk_prov"
  , "cdi_ca_1968-72_wk_prov"
  , "cdi_ca_1968-72_wk_prov"
  , "cdi_ca_1956-63_1973-74_wk_prov"
  , "cdi_ca_1975-78_wk_prov"
  , "cdi_ca_1979-89_4wk_prov"
  , "cdi_ca_1990-2001_quart_prov"
  , "cdi_on_1990-2021_wk"
  , "cdi_ca_1990-2001_quart_prov"
  , "cdi_man_2004-13_mn_age_sex"
  , "cdi_ab_2004-19_wk_age"
  , "cdi_ca_2001-2006_qr_prov_ccdr"
) |> unique()
join_years = function(x) {
  x = iidda::summarise_integers(x)
  x[x == "1895-1925, 1927-1931"] = "1915-1925"  ## HACK for incomplete quebec digitization
  x
}


sources_table = ("https://raw.githubusercontent.com/canmod/iidda/main/metadata/sources/%s.json"
  |> sprintf(keys)
  |> iidda::json_files_to_data()
  |> mutate(location = ifelse(location == "Canada", "All", location))
  |> mutate(
    organization = ifelse(
        organization == "Dominion Bureau of Statistics"
      , "Statistics Canada"
      , organization
    )
  )
  |> separate_rows(years, sep = ",")
)
sources_table = (sources_table
  |> dplyr::select(years, location, frequency, organization, formats)
  |> group_by(location, frequency, organization, formats)
  |> summarise(years = join_years(years))
  |> ungroup()
  |> relocate(years)
  |> mutate(formats = ifelse(startsWith(formats, "Hardcopy"), sub("Hardcopy", "Hard copy", formats), formats))
  |> rename(Years = years, Provinces = location, Frequency = frequency, Organization = organization, `Received As` = formats)
  |> arrange(Years)
  |> as.data.frame()
)
(sources_table
  |> xtable()
  |> print(
      include.rownames = FALSE
    , only.contents = TRUE
  )
  |> writeLines("Table1.tex")
)
writeLines(as.character(nrow(sources_table)), "n_sources")
