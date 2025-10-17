source("conflicts-policy.R")
library(iidda)
library(iidda.analysis)
library(dplyr)
library(ggplot2)
library(patchwork)
library(lubridate)
library(magick)

filename = "Fig8.tif"

geog_order = c(
  ## all
    "CA"
  ## east
  , "NL"
  , "PE"
  , "NS"
  , "NB"
  ## central
  , "QC"
  , "ON"
  ## west
  , "MB"
  , "SK"
  , "AB"
  , "BC"
  ## north
  , "YT"
  , "NU"
  , "NT"
)
period_year = function(period_start_date, period_end_date) {
  start_year = lubridate::year(period_start_date)
  end_year = lubridate::year(period_end_date)
  start_day = lubridate::yday(period_start_date)
  end_day = lubridate::yday(period_end_date)
  last_day = 365 + lubridate::leap_year(period_start_date)

  if (any(end_year - start_year > 1L)) {
    stop("At least some periods are too long to associated with a single year.")
  }

  more_days_in_start_year = (last_day - start_day) > end_day
  period_not_in_one_year = start_year != end_year
  take_start_year = period_not_in_one_year & more_days_in_start_year
  output = end_year
  output[take_start_year] = start_year[take_start_year]
  return(output)
}


# https://bmcpublichealth.biomedcentral.com/counter/pdf/10.1186/s12889-020-09854-4.pdf
#
vaccination_dates = c(
    `Whole cell\nvaccine (1943)` = 1943
  , `Adsorbed whole cell\nvaccine (1981 to 1985)` = 1985
  , `Acellular vaccine\n(1997 to 1998)` = 1998
  , `Adolescent booster\n(1999 to 2004)` = 2004
)

data_all = ("canmod-cdi-normalized.rdata"
  |> readRDS()
  |> filter(basal_disease == "whooping-cough")
  |> mutate(iso_3166_2 = sub("^CA-", "", iso_3166_2))
  |> mutate(
      cases_this_period = as.numeric(cases_this_period)
    , period_start_date = as.Date(period_start_date)
    , period_end_date = as.Date(period_end_date)
    , population = as.numeric(population)
    , year = period_year(period_start_date, period_end_date)
    , days_this_period = num_days(period_start_date, period_end_date)
  )
  |> filter(!(year < 1920 & iso_3166_2 == "SK")) ## remove isolated data point
)
data_basal = (data_all
  |> summarise(
        cases_this_period = sum(cases_this_period)
      , population = median(population)
      , n_sub_diseases = n() ## should always be 1 with whooping cough (no sub-diseases)
      , any_duplicated_diseases = anyDuplicated(disease)
      , .by = c(
            year, period_start_date, period_end_date
          , days_this_period, time_scale
          , iso_3166, iso_3166_2, basal_disease
      )
  )
  |> rename(disease = basal_disease)
  |> arrange(period_start_date)
)
prov_order = setdiff(geog_order, c("YT", "NU", "NT"))
prov_order = c("MB", "SK", "AB", "BC")
(data_basal
  |> mutate(iso_3166_2 = sub("^CA-", "", iso_3166_2))
  |> filter(iso_3166_2 %in% prov_order)
  |> filter(period_end_date < as.Date("2005-01-01"))
  |> filter(period_end_date > as.Date("1979-12-31"))
  |> mutate(iso_3166_2 = factor(iso_3166_2, levels = prov_order))
  |> ggplot()
  + geom_line(aes(period_end_date, cases_this_period/days_this_period/population, colour = iso_3166_2))
  + scale_y_continuous(transform = "sqrt")
  + scale_x_date(
        breaks = as.Date(c(
            "1900-01-01"
          , "1920-01-01"
          , "1940-01-01"
          , "1960-01-01"
          , "1980-01-01"
          , "2000-01-01"
          , "2020-01-01"
        ))
      , date_minor_breaks = "year"
    )
  + theme_bw()
)

data_year = (data_basal
  |> mutate(
       na_cases = is.na(cases_this_period)
     , na_days = is.na(days_this_period)
  )
  |> group_by(year, iso_3166_2)
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
)
if (interactive()) print(sum(data_year$disagree))
data_region = (data_year
  |> mutate(location = case_when(
      iso_3166_2 %in% c("NB", "NS", "PE", "NL") ~ "Atlantic"
    , iso_3166_2 %in% c("NU", "NT", "YT") ~ "Territories"
    , iso_3166_2 %in% c("AB", "SK", "MB") ~ "Prairies"
    , iso_3166_2 == "ON" ~ "Ontario"
    , iso_3166_2 == "QC" ~ "Quebec"
    , iso_3166_2 == "BC" ~ "British Columbia"
    , .default = iso_3166_2
  ))
  |> group_by(year, location)
  |> summarise(
      yearly_rate = sum(yearly_rate)
    , population = sum(population)
  )
  |> ungroup()
)
data_canada = (data_region
  |> group_by(year)
  |> summarise(
      yearly_rate = sum(yearly_rate)
    , population = sum(population)
  )
  |> ungroup()
  |> mutate(location = "Canada")
)
plot_data = (data_region
  |> bind_rows(data_canada)
  |> mutate(incidence_rate = 1e5 * yearly_rate / population)
)

## rough size of y-axis ticks on a sqrt scale for each region
sqrt_steps = c(
    Canada = 4L
  , Atlantic = 3L
  , Quebec = 5L
  , Ontario = 4L
  , Prairies = 4L
  , `British Columbia` = 6L
  , Territories = 7L
)
get_breaks = function(sqrt_step) {
  x = seq(from = 0L, by = sqrt_step, length = 4L)^2
  10 * ceiling(x / 10)
}
regions = names(sqrt_steps)
plot_location = function(region, data) {
  pd = filter(data, location == region)
  breaks = get_breaks(sqrt_steps[region])

  (pd
    |> ggplot()
    + annotate(geom = "rect", xmin = 1990, xmax = 2000, ymin = 0, ymax = Inf
      , fill = "red"
      , alpha = 0.2
    )
    + geom_line(aes(year, incidence_rate))
    + scale_y_continuous(
        name = "Annual incidence rate (per 100,000; square-root scale)"
      , trans = "sqrt"
      , expand = expansion(mult = c(0, 0.1))
      , breaks = breaks
      , minor_breaks = NULL
    )
    + scale_x_continuous(name = ""
      , breaks = seq(from = 1900, to = 2025, by = 20)
      , minor_breaks = seq(from = 1900, to = 2025, by = 5)
      , limits = c(1900, 2025)
      , expand = c(0, 0)
    )
    + annotate(
        geom = "label"
      , x = -Inf
      , y = Inf
      , label = region
      , hjust = "left"
      , vjust = "top"
      , size = 2.5
      , fill = "#E0E0E0"
    )
    + theme_bw()
    + theme(
        plot.margin = unit(c(0, 0, 0, 0), "lines")
      , axis.title.x = element_blank()
    )
  )
}
plots = lapply(regions, plot_location, plot_data) |> setNames(regions)

whooping_plot = wrap_plots(
    rev(plots)
  , design = paste(rev(LETTERS[seq_along(plots)]), collapse = "\n")
  , axes = "collect"
)
if (interactive()) plot(whooping_plot)

ggplot2::ggsave(
    file = filename
  , plot = whooping_plot
  , width = 6, height = 8, units = "in"
  , dpi = 600
)
(filename
  |> image_read()
  |> image_write(filename, compression = "LZW", flatten = TRUE)
)

# --------------------------
# whooping cough statistics
# used in the manuscript
# --------------------------

write_stat = function(focal, filename) {
  dd = filter(plot_data
    , location == focal
    , between(year, 1990, 1999)
  )$incidence_rate
  (dd
    |> max() |> round() |> as.character()
    |> writeLines(filename, sep = "%")
  )
}
write_stat("Ontario", "n_on_wc_max_90s")
write_stat("Territories", "n_territories_wc_max_90s")
