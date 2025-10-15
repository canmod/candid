library(iidda.api)
options(iidda_api_msgs = FALSE)
options(iidda_api_all_char = TRUE)
options(iidda_api_pull_msg = TRUE)


save_frame = function(id, fn) {
  id |> fn() |> saveRDS(file = sprintf("%s.rdata", id))
  invisible(NULL)
}
data_ids = iidda.api::candid_data_ids()
# [1] "canmod-cdi-unharmonized"
# [2] "canmod-cdi-harmonized"
# [3] "canmod-cdi-normalized"
# [4] "canmod-pop-normalized"
# [5] "phac-cdi-portal"
# [6] "phac-reporting-schedule"
# [7] "canmod-disease-cross-check"
# [8] "canmod-location-cross-check"
# [9] "canmod-time-scale-cross-check"

lookup_ids = iidda.api::candid_lookup_ids()
# [1] "phac-to-canmod-disease-lookup"
# [2] "canmod-disease-lookup"

trash = lapply(data_ids, save_frame, candid_data)
trash = lapply(lookup_ids, save_frame, candid_lookup)
