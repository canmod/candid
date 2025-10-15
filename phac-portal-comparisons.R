source("conflicts-policy.R")
library(dplyr)
library(iidda)
library(iidda.analysis)
library(lubridate)
library(ggplot2)
library(patchwork)

group_contiguous_years <- function(df, year_col, group_cols) {

  # Split the data frame by the grouping factors
  groups <- split(df, df[group_cols])

  iter_func = function(group) {
    # Sort the group by the year column
    group <- group[order(group[[year_col]]), ]

    # Create a new column for contiguous group identifiers
    group$contiguous_group <- 1

    # Loop through the group and identify contiguous sequences of years
    if (nrow(group) > 1L) {
      for (i in 2:nrow(group)) {
        # If the difference between the current year and the previous year is greater than 1, increment the group number
        if (group[[year_col]][i] - group[[year_col]][i - 1] > 1) {
          group$contiguous_group[i:nrow(group)] <- group$contiguous_group[i - 1] + 1
        } else {
          group$contiguous_group[i] <- group$contiguous_group[i - 1]
        }
      }
    }

    return(group)
  }

  # Iterate over each group
  grouped_data <- lapply(groups, iter_func)

  # Combine all groups back into a single data frame
  df <- do.call(rbind, grouped_data)

  return(df)
}

period_year = function(period_start_date, period_end_date, days_this_period) {
  mids = mid_times(
      period_start_date
    , period_end_date
    , days_this_period
  )
  year(mids)
}



#disease_convert = read_data_frame("reference-data/phac-to-canmod-disease.csv")
#reporting_schedule = read_data_frame("reference-data/phac-reporting-schedule.csv")


reporting_schedule = readRDS("phac-reporting-schedule.rdata")
disease_convert = readRDS("phac-to-canmod-disease-lookup.rdata")
canmod = ("canmod-cdi-normalized.rdata"
  |> readRDS()
  |> mutate(
      cases_this_period = as.numeric(cases_this_period)
    , population = as.numeric(population)
    , days_this_period = as.numeric(days_this_period)
  )
)

specific_prov_schedule = (reporting_schedule
  |> filter(iso_3166_2 != "CA")
)
all_prov_schedule = (reporting_schedule
  |> filter(iso_3166_2 == "CA")
  |> select(-iso_3166_2)
  |> expand_grid(iso_3166_2 = unique(specific_prov_schedule$iso_3166_2))
)
reporting_schedule = bind_rows(specific_prov_schedule, all_prov_schedule)

pop = ("canmod-pop-normalized.rdata"
  |> readRDS()
  |> mutate(year = lubridate::year(date))
  |> group_by(year, iso_3166_2)
  |> summarise(population = median(as.numeric(population)))
  |> ungroup()
)

phac_prov_population = (reporting_schedule
  |> mutate(year = as.numeric(year))

  %>% inner_join(pop, join_by(year, iso_3166_2))
  ## sum population over provinces for each year and disease
  %>% group_by(historical_disease, year)
  %>% summarise(population = sum(as.numeric(population)))
  %>% ungroup()
  |> left_join(disease_convert, join_by(historical_disease))
)
phac = ("phac-cdi-portal.rdata"
  |> readRDS()
  |> mutate(
      year = as.numeric(year)
    , cases_this_period = as.numeric(cases_this_period)
  )
  |> left_join(phac_prov_population, join_by(year, disease))
  |> filter(!is.na(population))
)


canmod_disease = (canmod
  |> filter(disease %in% unique(phac$disease))
)
canmod_nesting = (canmod
  |> filter(nesting_disease %in% unique(phac$disease))
  |> setdiff(canmod_disease)
  |> mutate(year = period_year(period_start_date, period_end_date, days_this_period))
  |> mutate(
      cases_this_period = as.numeric(cases_this_period)
    , population = as.numeric(population)
    , days_this_period = as.numeric(days_this_period)
  )
  |> summarise(
        cases_this_period = sum(cases_this_period)
      , population = median(population)
      , n_sub_diseases = n()
      , any_duplicated_diseases = anyDuplicated(disease)
      , .by = c(
            year, period_start_date, period_end_date
          , days_this_period, time_scale
          , iso_3166, iso_3166_2, nesting_disease
      )
  )
  |> rename(disease = nesting_disease)
  |> arrange(period_start_date)
)


canmod_overlap = (canmod_disease
  |> select(-nesting_disease)
  |> bind_rows(canmod_nesting)
  |> semi_join(disease_convert, by = join_by(disease == disease))
  |> mutate(year = period_year(period_start_date, period_end_date, days_this_period))
)

canmod_year = (canmod_overlap
  |> mutate(
       na_cases = is.na(cases_this_period)
     , na_days = is.na(days_this_period)
  )
  |> group_by(year, iso_3166_2, disease)
  |> summarise(
       cases_this_period = sum(cases_this_period[!na_cases])
     , days_this_period = sum(days_this_period[!na_days])
     , population = median(population)
     , disagree = sum(na_cases != na_days)
  )
  |> ungroup()
  |> mutate(
      daily_rate = cases_this_period / days_this_period
    , yearly_rate = 365 * daily_rate
  )
  ## arbitrary
  |> filter(days_this_period > 100)
)


canmod_canada = (canmod_year
  |> group_by(year, disease)
  |> summarise(
      yearly_rate = sum(yearly_rate)
    , population = sum(population)
  )
  |> ungroup()
  |> rename(cases_this_period = yearly_rate)
)

compare = (bind_rows(
      `This paper` = canmod_canada
    , `PHAC portal` = filter(phac, disease %in% unique(canmod_canada$disease))
    , .id = "source_description"
  )
  |> mutate(cases_this_period = round(cases_this_period))
  |> select(year, disease, cases_this_period, population, source_description)
)

plot_data = (compare
  |> arrange(year)
  |> mutate(rate = 1e5 * cases_this_period / population)
  |> group_contiguous_years("year", c("source_description", "disease"))
  |> arrange(year)
  |> rename(source = source_description)
)
all_diseases = sort(unique(plot_data$disease))

plots = list()
for (d in all_diseases) {
  dp = (plot_data
    |> filter(disease == d)
    |> ggplot()
    + geom_line(aes(year, rate, colour = source, linewidth = source, alpha = source, group = sprintf("%s-%s", contiguous_group, source)))
    + ggtitle(d)
    + scale_color_manual(
        values = c("PHAC portal" = "grey", "This paper" = "red")
    )
    + scale_linewidth_manual(
       values = c("PHAC portal" = 1.5, "This paper" = 0.5)
    )
    + scale_alpha_manual(
        values = c("PHAC portal" = 0.7, "This paper" = 1)
    )
    + scale_y_continuous(
        name = "Yearly incidence rate\n(per 100,000)"
      , trans = "sqrt", expand = c(0, 0)
    )
    + theme_bw()
  )
  pp = (plot_data
    |> filter(disease == d)
    |> ggplot()
    + geom_line(aes(year, population, colour = source, linewidth = source, alpha = source))
    + scale_linewidth_manual(
       values = c(`PHAC portal` = 1.5, `This paper` = 0.5)
    )
    + scale_color_manual(
        values = c(`PHAC portal` = "grey", `This paper` = "red")
    )
    + scale_alpha_manual(
        values = c(`PHAC portal` = 0.7, `This paper` = 1)
    )
    + scale_y_continuous(name = "Population\nreporting"
      , trans = "sqrt", expand = c(0, 0)
    )
    + theme_bw()
  )
  plots[[d]] = dp / pp + plot_layout(axes = "collect", guides = "collect")
  if (!dir.exists("phac-portal-comparisons")) dir.create("phac-portal-comparisons")
  ggplot2::ggsave(
      file = sprintf("phac-portal-comparisons/%s.png", d)
    , plot = plots[[d]]
    , width = 4, height = 4, units = "in"
  )
}
