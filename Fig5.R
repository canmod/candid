source("conflicts-policy.R")
library(iidda)
library(dplyr)
library(ggplot2)
library(lubridate)
library(patchwork)
library(magick)

filename = "Fig5.tif"

# put the typical peak week (~week 34) in the middle of the year
polio_week <- function(week_of_year) {
  # Center week 34 (typical polio peak) around week 26 (mid-year)
  shift <- 34 - 26

  # Adjust week number and use modulo to wrap around
  new_week <- ((week_of_year - shift - 1) %% 52) + 1

  return(new_week)
}
polio_year <- function(week_of_year, year) {
  # Calculate the new week to determine if year needs adjustment
  new_week <- polio_week(week_of_year)

  # Adjust the year if new week falls into the previous year
  new_year <- ifelse(week_of_year <= (34 - 26), year - 1, year)

  return(new_year)
}

polio_month = function(month) {
  shift = 8 - 6
  new_month = ((month - shift - 1) %% 12) + 1
  return(new_month)
}
polio_monthyear = function(month, year) {
  new_month = polio_month(month)
  new_year = ifelse(month <= (8 - 6), year - 1, year)
  return(new_year)
}

plot_location = function(location, data, canada_peaks, trans = "sqrt", response = "rate") {
  special_labels = c(
      "Injected,\ninactivated\nvaccine"
    , "Oral,\nattenuated\nvaccine"
  )
  special_dates  = c(as.Date("1955-01-01"), as.Date("1962-01-01"))
  vax_colour = "#6495ED"
  if (is.na(location)) {
    location = "CA"
    pd = filter(data, iso_3166_2 == "")
  } else {
    pd = filter(data, iso_3166_2 == location)
  }

  pop = mean(unique(pd$population), na.rm = TRUE)


  if (trans == "identity") {
    if (location %in% c("CA", "BC", "NS", "QC")) {
      breaks = c(0, 2, 4)
    } else if (location %in% c("AB", "ON", "NB", "PE", "NL")) {
      breaks = c(0, 4, 8)
    } else if (location %in% c("SK", "MB")) {
      breaks = c(0, 8, 16)
    }
    trans_text = ""
  } else if ((trans == "sqrt") | (trans == "log1p") | (trans == "log") | (trans == "pseudo_log")) {
    if (location %in% c("CA", "BC", "NS", "QC")) {
      breaks = c(0, 1, 4)
    } else if (location %in% c("AB", "ON", "NB", "PE", "NL")) {
      breaks = c(0, 2, 8)
    } else if (location %in% c("SK", "MB")) {
      breaks = c(0, 4, 16)
    }
    trans_text = "; square-root scale"
  } else if (trans == "pseudo_log") {
    if (location %in% c("CA")) {
      breaks = c(0.01, 0.2, 4)
    } else if (location %in% c("BC", "NS")) {
      breaks = c(0.2, 1, 5)
    } else if (location %in% c("QC")) {
      breaks = c(0.05, 0.5, 5)
    } else if (location %in% c("NB", "NL")) {
      breaks = c(0.4, 2, 10)
    } else if (location %in% c("AB")) {
      breaks = c(0.1, 1, 10)
    } else if (location %in% c("PE")) {
      breaks = c(1, 3, 9)
    } else if (location %in% c("ON")) {
      breaks = c(0.1, 1, 10)
    } else if (location %in% c("SK", "MB")) {
      breaks = c(0.2, 2, 20)
    }
    trans_text = "; log scale"
  } else {
    stop("Unknown transformation")
  }
  if (response == "rate") {
    gl = geom_line(aes(period_end_date, weekly_rate))
    nm = sprintf("Weekly incidence rate (per 100,000%s)", trans_text)
  } else if (response == "abs") {
    gl = geom_line(aes(period_end_date, cases_this_period))
    nm = sprintf("Weekly number of new reported cases (%s)", substr(trans_text, 3, nchar(trans_text)))
    breaks = round(breaks * pop / 1e5)
    digits = nchar(breaks)
    fact = 10^(digits - 1)
    breaks = ceiling(breaks / fact) * fact
    breaks[2] = mean(breaks[c(1, 3)])
  } else {
    stop("Unknown response variable")
  }
  (pd
    |> ggplot()
    + geom_vline(xintercept = special_dates, colour = vax_colour, linetype = "dashed")
    + gl
    + scale_y_continuous(
        name = nm
      , transform = trans
      , expand = expansion(mult = c(0, 0.2))
      , breaks = breaks
    )
    + scale_x_date(name = ""
        , expand = c(0, 0)
        , breaks = as.Date("1935-01-01") + lubridate::years(5 * (0:20))
        , limits = range(data$period_end_date)
        , labels = lubridate::year
        , sec.axis = sec_axis(~.
          , breaks = special_dates
          , labels = special_labels
        )
    )
    + geom_vline(aes(xintercept = peak)
      , data = canada_peaks
      , alpha = 0.1
      , colour = "red"
    )
    + annotate(
        geom = "label"
      , x = as.Date(-Inf)
      , y = Inf
      , label = location
      , hjust = "left"
      , vjust = "top"
      , size = 2.5
      , fill = "#E0E0E0"
    )
    + theme_bw()
    + theme(
        panel.grid.major.x = element_blank()
      , panel.grid.minor.x = element_blank()
      , axis.ticks.x.top = element_line(colour = vax_colour)
      , axis.text.x.top = element_text(colour = vax_colour)
      , panel.grid.minor.y = element_blank()
      , plot.margin = unit(c(0, 0, 0, 0), "lines")
      , axis.title.x = element_blank()
    )
  )
}

geog_order = c(
  ## east
    "NL"
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
)


data = ("canmod-cdi-normalized.rdata"
  |> readRDS()
  |> filter(
      basal_disease == "poliomyelitis"
    , time_scale == "wk"
    , period_end_date > "1933-01-01"
  )
  |> mutate(iso_3166_2 = sub(pattern = "CA-", replacement = "", iso_3166_2))
  |> filter(iso_3166_2 %in% geog_order)
  |> mutate(iso_3166_2 = factor(iso_3166_2, levels = geog_order))
  |> mutate(
      cases_this_period = as.numeric(cases_this_period)
    , period_start_date = as.Date(period_start_date)
    , period_end_date = as.Date(period_end_date)
    , population = as.numeric(population)
  )

  ## aggregate disease sub-classes during some periods
  |> group_by(period_start_date, period_end_date, iso_3166_2)
  |> summarise(
      cases_this_period = sum(cases_this_period, na.rm = TRUE)
    , population = median(population)
  )
  |> ungroup()
)

canada = (data
  |> group_by(period_start_date, period_end_date)
  |> summarise(
      cases_this_period = sum(cases_this_period, na.rm = TRUE)
    , population = sum(population, na.rm = TRUE)
  )
  |> ungroup()
  |> mutate(iso_3166 = "CA", iso_3166_2 = "")
)



plot_data = bind_rows(canada, data)


# Reproducing Fig5 --------------------

min_date = min(plot_data$period_end_date)
max_date = max(plot_data$period_end_date)
total_weeks = as.integer(difftime(max_date, min_date, units = "weeks"))
all_dates = min_date + lubridate::weeks(0:total_weeks)
grid = expand.grid(period_end_date = all_dates, iso_3166_2 = c("", geog_order))

## used to stop lines connecting over gaps in the data
gaps = (grid
  |> anti_join(plot_data)
  |> mutate(weekly_rate = NA_real_)
)
data_with_response = (plot_data
  |> mutate(
      weekly_rate = 1e5 * cases_this_period / population
  )
  |> filter(!is.na(weekly_rate))
  |> bind_rows(gaps)
)


canadian_province_coords <- data.frame(
  iso_3166_2 = c(
    "AB", "BC", "MB", "NB", "NL", "NS",
    "NT", "NU", "ON", "PE", "QC", "SK", "YT"
  ),
  latitude = c(
    53.9333, 53.7267, 49.8951, 46.5653, 53.1355, 44.6820,
    64.8255, 70.2998, 51.2538, 46.5107, 52.9399, 52.9399, 64.2823
  ),
  longitude = c(
    -116.5765, -127.6476, -97.1384, -66.4619, -57.6604, -63.7443,
    -124.8457, -89.5926, -85.3232, -63.4168, -73.5491, -106.4509, -135.0000
  )
)




canada_peaks = (data_with_response
  |> filter(iso_3166_2 == "")
  |> mutate(year = lubridate::epiyear(period_end_date))
  |> mutate(week = lubridate::epiweek(period_end_date))
  |> mutate(polioyear = polio_year(week, year))
  |> group_by(polioyear)
  |> summarise(
      peak = period_end_date[which.max(weekly_rate)]
    , cases = sum(cases_this_period)
  )
  |> ungroup()
  |> mutate(peak_week = lubridate::epiweek(peak))
  |> filter(cases > 20)
  |> filter(polioyear != min(polioyear))
  |> mutate(peak_polioweek = polio_week(peak_week))
)

canada_peaks$peak_week |> min() |> as.character() |> writeLines("polio-min-week-peak", sep = "%")
canada_peaks$peak_week |> max() |> as.character() |> writeLines("polio-max-week-peak", sep = "%")
canada_peaks$polioyear |> min() |> as.character() |> writeLines("polio-min-year-peak", sep = "%")
canada_peaks$polioyear |> max() |> as.character() |> writeLines("polio-max-year-peak", sep = "%")
data_with_response$period_start_date |> min(na.rm = TRUE) |> epiyear() |> as.character() |> writeLines("polio-min-year", sep = "%")
data_with_response$period_end_date   |> max(na.rm = TRUE) |> epiyear() |> as.character() |> writeLines("polio-max-year", sep = "%")

plot_location_hist = function(location, data) {
  if (is.na(location)) {
    location = "CA"
    pd = filter(data, iso_3166_2 == "")
  } else {
    pd = filter(data, iso_3166_2 == location)
  }
  if (location %in% c("CA")) {
    breaks = c(0, 8, 16)
  } else if (location %in% c("ON")) {
    breaks = c(0, 7, 14)
  } else if (location %in% "QC") {
    breaks = c(0, 6, 12)
  } else if (location %in% c("MB", "AB")) {
    breaks = c(0, 5, 10)
  } else if (location %in% c("SK")) {
    breaks = c(0, 4, 8)
  } else if (location %in% c("BC", "NB")) {
    breaks = c(0, 3, 6)
  } else if (location %in% c("NS")) {
    breaks = c(0, 2, 4)
  } else if (location %in% c("PE")) {
    breaks = 0:3
  } else if (location %in% c("NL")) {
    breaks = 0:2
  }
  (pd
    |> ggplot()
    + geom_col(aes(polio_month(peak_month), count), width = 0.95, just = 0)
    + scale_x_continuous(
        name = "Peak Week in the Polio Year (binned by month)"
      , expand = c(0, 0)
      , limits = c(1, 13)
      , minor_breaks = 1:12
      , breaks = 1:12
      , labels = month.abb[(((1:12) + 1) %% 12) + 1]
    )
    + scale_y_continuous(
        name = "Number of Polio Years"
      , expand = c(0, 0)
      , breaks = breaks
      , minor_breaks = NULL
    )
    + annotate(
        geom = "label"
      , x = -Inf
      , y = Inf
      , label = location
      , hjust = "left"
      , vjust = "top"
      , size = 2.5
      , fill = "#E0E0E0"
    )
    + theme_bw()
  )
}

trans = "sqrt"
norm = "rate"
ca_plot = plot_location(NA, data_with_response, canada_peaks, trans, norm)
prov_plot = (geog_order
  |> lapply(plot_location, data_with_response, canada_peaks, trans, norm)
  |> setNames(geog_order)
  |> append(list(CA = ca_plot), after = 0L)
)
polio_plot = wrap_plots(
    rev(prov_plot)
  , design = paste(rev(LETTERS[seq_along(prov_plot)]), collapse = "\n")
  , axes = "collect"
)
ggplot2::ggsave(
    file = filename
  , plot = polio_plot
  , width = 6, height = 6, units = "in"
  , dpi = 600
)
(filename
  |> image_read()
  |> image_write(filename, compression = "LZW", flatten = TRUE)
)



# ------------------------
# Supporting Information
# ------------------------

data_for_plotting = (data_with_response
  |> mutate(year = lubridate::epiyear(period_end_date))
  |> mutate(week = lubridate::epiweek(period_end_date))
  |> mutate(month = lubridate::month(period_end_date))
  |> mutate(polioyear = polio_year(week, year))
  |> filter(!is.na(cases_this_period))
  |> mutate(data_week = cases_this_period > 0)
  |> filter(data_week)
  |> group_by(iso_3166_2, polioyear)
  |> summarise(
      data_weeks = n()
    , cases = sum(cases_this_period)
    , peak = period_end_date[which.max(weekly_rate)]
  )
  |> ungroup()
  |> mutate(peak_week = lubridate::epiweek(peak))
  |> mutate(peak_polioweek = polio_week(peak_week))
  |> filter(polioyear != min(polioyear))
  |> mutate(peak_month = month(peak))
  |> filter(data_weeks > 5)
  |> filter(cases > 20)
  |> group_by(iso_3166_2, peak_month)
  |> summarise(count = n())
  |> ungroup()
)
ca_plt = plot_location_hist(NA, data_for_plotting)
plts = (geog_order
  |> lapply(plot_location_hist, data_for_plotting)
  |> setNames(geog_order)
  |> append(list(CA = ca_plt), after = 0L)
)

polio_hist_supp_mat = wrap_plots(
    rev(plts)
  , design = paste(rev(LETTERS[seq_along(plts)]), collapse = "\n")
  , axes = "collect"
)
ggplot2::ggsave(
    file = "polio-hist.png"
  , plot = polio_hist_supp_mat
  , width = 6, height = 6, units = "in"
)
