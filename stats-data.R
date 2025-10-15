# ----------------------------------------------
# compute and save statistics that are used in
# the manuscript to describe the data
# ----------------------------------------------

source("conflicts-policy.R")
library(iidda.api)
library(dplyr)
library(iidda)
library(iidda.analysis)
options(iidda_api_msgs = FALSE)

read_frame = function(id) {
  filename = sprintf("%s.rdata", id)
  message("Reading ", filename)
  data = readRDS(filename)
  objectname = gsub("-", "_", id)
  e = parent.frame()
  assign(objectname, data, envir = e)
  invisible(NULL)
}

for (id in candid_data_ids()) read_frame(id)
for (id in candid_lookup_ids()) read_frame(id)


percent = \(x) 100 * x/sum(x)
max_perc = \(x) x |> table() |> percent() |> sort(decreasing = TRUE) |> getElement(1L)

prob_yr_loc = distinct(canmod_time_scale_cross_check, year, iso_3166_2, historical_disease, historical_disease_family, historical_disease_subclass)
all_yr_loc = (canmod_cdi_harmonized
  |> mutate(year = lubridate::year(period_end_date))
  |> distinct(year, iso_3166_2, historical_disease, historical_disease_family, historical_disease_subclass)
)
prob_per_dis = (canmod_location_cross_check
  |> distinct(period_start_date, period_end_date, historical_disease, historical_disease_family, historical_disease_subclass)
)
all_per_dis = (canmod_cdi_harmonized
  |> distinct(period_start_date, period_end_date, historical_disease, historical_disease_family, historical_disease_subclass)
)
prob_per_loc = (canmod_disease_cross_check
  |> distinct(period_start_date, period_end_date, iso_3166_2)
)
all_per_loc = (canmod_cdi_harmonized
  |> distinct(period_start_date, period_end_date, iso_3166_2)
)
if (interactive()) {
  x = distinct(
      canmod_time_scale_cross_check
    , iso_3166_2
    , historical_disease_subclass
    , historical_disease_family
    , historical_disease
  )
  semi_join(canmod_cdi_normalized, x) |> nrow()
  bind_rows(
      semi_join(canmod_cdi_normalized, prob_per_dis)
    , semi_join(canmod_cdi_normalized, prob_per_loc)
    , semi_join(canmod_cdi_normalized, prob_yr_loc)
  ) |> distinct() |> nrow()
}


remove_empty = function(x) x[!is_empty(x)]
print("computing stats")
stats = within(list(), {
  normalized_sample_sizes_per_time_scale <- table(canmod_cdi_normalized$time_scale)
  normalized_sample_size_wk <- normalized_sample_sizes_per_time_scale[["wk"]]
  normalized_sample_size_mo <- normalized_sample_sizes_per_time_scale[["mo"]]
  normalized_sample_size_qr <- normalized_sample_sizes_per_time_scale[["qr"]]
  normalized_sample_size_2wk <- normalized_sample_sizes_per_time_scale[["2wk"]]
  normalized_sample_size_3qr <- normalized_sample_sizes_per_time_scale[["3qr"]]
  normalized_sample_sizes <- table(canmod_cdi_normalized$record_origin)
  normalized_sample_size <- sum(normalized_sample_sizes)
  # normalized_historical_sample_size <- normalized_sample_sizes["historical"] |> unname()
  # normalized_derived_sample_size <- normalized_sample_sizes[grepl("^derived-", names(normalized_sample_sizes))] |> unname() |> sum()
  unharmonized_sample_size <- nrow(canmod_cdi_unharmonized)
  harmonized_sample_size <- nrow(canmod_cdi_harmonized)
  normalized_basal_diseases <- sort(unique(canmod_cdi_normalized$basal_disease))
  harmonized_basal_diseases <- sort(unique(canmod_cdi_harmonized$basal_disease))
  normalized_sub_diseases <- sort(unique(canmod_cdi_normalized$disease))
  historical_diseases <-  remove_empty(unique(c(canmod_cdi_unharmonized$historical_disease, canmod_cdi_unharmonized$historical_disease_family, canmod_cdi_unharmonized$historical_disease_subclass)))
  n_historical_diseases <- dplyr::select(canmod_cdi_unharmonized, icd_7, icd_9, icd_7_subclass, icd_9_subclass, historical_disease, historical_disease_family, historical_disease_subclass) |> distinct() |> nrow() # length(historical_diseases)
  n_basal_diseases <- length(normalized_basal_diseases)
  n_diseases <- length(unique(canmod_cdi_normalized$disease))
  n_disease_cross_check <- nrow(canmod_disease_cross_check)
  n_time_scale_cross_check <- nrow(canmod_time_scale_cross_check)
  n_location_cross_check <- nrow(canmod_location_cross_check)
  perc_yr_loc_no_err <- round(100 * (1 - nrow(prob_yr_loc) / nrow(all_yr_loc)), 1)
  perc_pd_dis_no_err <- round(100 * (1 - nrow(prob_per_dis) / nrow(all_per_dis)), 1)
  perc_pd_loc_no_err <- round(100 * (1 - nrow(prob_per_loc) / nrow(all_per_loc)), 1)
  perc_dis_cc_err_handwritten <- canmod_disease_cross_check$iidda_source_id |> max_perc() |> round(1L)
  perc_loc_cc_err_handwritten <- canmod_location_cross_check$iidda_source_id |> max_perc() |> round(1L)
  perc_ts_cc_err_handwritten <- canmod_time_scale_cross_check$iidda_source_id |> max_perc() |> round(1L)
})
print(stats)
single_number_stats = Filter(\(x) length(x) == 1L, stats)

write_stat = function(x) {
  filename = x
  if (!dir.exists(dirname(filename))) dir.create(dirname(filename), recursive = TRUE)
  stat = formatC(
      as.integer(stats[[x]])
    , big.mark = ","
    , format = "f"
    , digits = 0
  )
  print(sprintf("%s: %s : %s", x, stat, filename))
  print(stat)
  writeLines(stat, filename, sep = "%")
  readLines(filename)
}
trash = lapply(names(single_number_stats), write_stat)
diseases = stats$normalized_basal_diseases
