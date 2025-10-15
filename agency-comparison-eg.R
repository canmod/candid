source("conflicts-policy.R")
library(dplyr)
library(lubridate)
library(ggplot2)
library(scales)
library(patchwork)
library(iidda)

basal_diseases_to_prune = "venereal-diseases"
lookup = ("canmod-disease-lookup.rdata"
  |> readRDS()
  |> filter(!nesting_disease %in% basal_diseases_to_prune)
  |> filter(!disease %in% basal_diseases_to_prune)
  |> mutate(nesting_disease = ifelse(
        nesting_disease %in% basal_diseases_to_prune
      , ""
      , nesting_disease
  ))
  |> distinct(disease, nesting_disease)
)
data = ("canmod-cdi-harmonized.rdata"
  |> readRDS()
  |> mutate(source_location_scale = ifelse(
        grepl("^cdi[_a-zA-Z]*_ca", digitization_id)
      , "national"
      , "sub-national"
  ))
  |> filter(!disease %in% basal_diseases_to_prune)
  |> mutate(nesting_disease = ifelse(
        nesting_disease %in% basal_diseases_to_prune
      , ""
      , nesting_disease
  ))
  |> mutate(cases_this_period = as.numeric(cases_this_period))
  |> mutate(period_start_date = as.Date(period_start_date))
  |> mutate(period_end_date = as.Date(period_end_date))
  |> add_basal_disease(lookup)
)


save_plot = function(data, min_yr, max_yr, focal) {
  case_aes = aes(period_end_date, cases_this_period)
  data_filtered = (data
    |> filter(
      , between(year(period_end_date), min_yr, max_yr)
      , iso_3166_2 == "CA-ON"
      , basal_disease == focal
      , time_scale == "wk"
    )
    |> group_by(period_end_date, source_location_scale)
    |> summarise(cases_this_period = sum(cases_this_period))
    |> ungroup()
  )

  nat = filter(data_filtered, source_location_scale == "national")
  sub_nat = filter(data_filtered, source_location_scale == "sub-national")

  pad_nat = pad_weeks(nat) |> select(-period_start_date)
  pad_sub_nat = pad_weeks(sub_nat) |> select(-period_start_date)
  islands_nat = time_series_islands(pad_nat, "cases_this_period", "period_end_date")
  islands_sub_nat = time_series_islands(pad_sub_nat, "cases_this_period", "period_end_date")
  diff_data = (pad_nat
    |> inner_join(
        pad_sub_nat
      , by = "period_end_date"
      , suffix = c("_nat", "_sub_nat")
    )
    |> mutate(period_end_date = as.Date(period_end_date))
    |> mutate(diff = cases_this_period_nat - cases_this_period_sub_nat)
  )

  signed_sqrt_trans <- trans_new(
    name = "signed_sqrt",
    transform = function(x) sign(x) * sqrt(abs(x)),
    inverse = function(x) sign(x) * (x^2)
  )
  x_rng = range(data_filtered$period_end_date, na.rm = TRUE)
  y_rng = range(data_filtered$cases_this_period, na.rm = TRUE)
  max_sqrt = floor(sqrt(y_rng))[2]
  diff_rng = range(diff_data$diff, na.rm = TRUE)
  max_pos_sqrt_diff = floor(sqrt(diff_rng[2]))
  max_neg_sqrt_diff = floor(sqrt(-diff_rng[1]))
  (max_yr - min_yr)
  x_ax = scale_x_date(""
    , limits = x_rng
    , breaks = seq(
        as.Date(sprintf("%s-01-01", min_yr    ))
      , as.Date(sprintf("%s-01-01", max_yr + 1))
      , by = sprintf("%s years", as.integer(ceiling((max_yr - min_yr) / 10)))
    )
    , date_minor_breaks = "year"
    , date_labels = "%Y"
    , expand = c(0, 0)
  )
  th = theme_set(theme_bw())
  th = theme_update(
    plot.margin = unit(c(0.2, 0.5, 0.2, 0.5), "cm"),  # Adjust top, right, bottom, left margins
    plot.title = element_text(margin = margin(t = 5, b = 5)), # Reduce title margin
    axis.title.x = element_text(margin = margin(t = 5)),      # Reduce x-axis title margin
    axis.title.y = element_text(margin = margin(r = 5))       # Reduce y-axis title margin
  )
  plt_nat = (ggplot(pad_nat, case_aes)
    + geom_line(colour = "red")
    + x_ax
    + scale_y_continuous(
        "Reported Cases"
      , trans = "sqrt"
      , limits = y_rng
      , breaks = seq(0, max_sqrt, by = floor(max_sqrt/4))^2
      , expand = c(0.01, 0)
    )
    + ggtitle("As reported by Statistics Canada (StatCan)")
    + th
  )
  plt_sub_nat = (ggplot(pad_sub_nat, case_aes)
    + geom_line(colour = "red")
    + x_ax
    + scale_y_continuous(
        "Reported Cases"
      , trans = "sqrt"
      , limits = y_rng
      , breaks = seq(0, max_sqrt, by = floor(max_sqrt/4))^2
      , expand = c(0, 0)
    )
    + ggtitle("As reported by Ontario Ministry of Health (MoH)")
    + th
  )
  step_size = floor((max_neg_sqrt_diff + max_pos_sqrt_diff) / 4)
  db = c(
      -rev(seq(from = 0 , to = max_neg_sqrt_diff, by = step_size))^2
    , seq(from = step_size, to = max_pos_sqrt_diff, by = step_size)^2
  )
  plt_diff = (diff_data
    |> ggplot()
    + geom_line(aes(period_end_date, diff), colour = "red")
    + x_ax
    + scale_y_continuous(
        "Difference"
      , expand = c(0, 0)
      , trans = signed_sqrt_trans
      , breaks = db
    )
    + ggtitle("Difference in Reports (StatCan - MoH)")
    + th
  )
  plt_ann = plot_annotation(
      sprintf("Weekly Cases of %s in Ontario (%s-%s)", focal, min_yr, max_yr)
    , theme = theme(plot.title = element_text(size = 20))
  )
  plt = plt_nat / plt_sub_nat / plt_diff + plt_ann
  if (interactive()) print(plt)
  if (!dir.exists("agency-comparisons")) dir.create("agency-comparisons")
  ggsave(
      sprintf("agency-comparisons/%s-ontario.png", focal)
    , plt
    , height = 6
    , width = 7.5
  )
  return(plt)
}
save_plot(data, 1968, 1978, "salmonellosis")
save_plot(data, 1940, 1960, "poliomyelitis")
save_plot(data, 1965, 1979, "hepatitis-A-B")
save_plot(data, 1940, 1980, "syphilis")
save_plot(data, 1940, 1977, "whooping-cough")
