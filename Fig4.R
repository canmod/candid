source("conflicts-policy.R")
library(dplyr)
library(iidda.analysis)
library(iidda)
library(lubridate)
library(ggplot2)
library(patchwork)
library(cowplot)
library(Cairo)
library(magick)

## This script actually makes Figures 4-6, because they are related
## and and harmonized so that they all have the same width of each
## of the plotting elements. You can think of them as the same
## figure that spans multiple pages.

n_pages = 3    ## number of figures in this series
first_page = 4 ## number labelling the first figure in this series

canmod_cdi_normalized = readRDS("canmod-cdi-normalized.rdata")


normalized_for_extent_plot = (canmod_cdi_normalized
  # |> mutate(time_scale = ifelse(time_scale == "2wk", "wk", time_scale))
  # |> mutate(time_scale = ifelse(time_scale == "3qr", "qr", time_scale))
  |> filter(time_scale != "3qr")
  |> mutate(time_scale = case_when(
        time_scale == "wk" ~ "weekly"
      , time_scale == "2wk" ~ "2-weekly"
      , time_scale == "mo" ~ "monthly"
      , time_scale == "qr" ~ "quarterly"
      , time_scale == "3qr" ~ "3-quarterly"
  ))

  |> iidda_defaults(
        count_variable = "cases_this_period"
      , norm_variable = "population"
      , period_start_variable = "period_start_date"
      , period_end_variable = "period_end_date"
      , period_mid_time_variable = "period_mid_time"
      , period_mid_date_variable = "period_mid_date"
      , period_days_variable = "num_days"
      , among_panel_variable = "basal_disease"
      , within_panel_variable = "iso_3166_2"
      , colour_variable = "time_scale"
  )
)

n_all_diseases = length(unique(normalized_for_extent_plot$basal_disease))
diseases_per_page = ceiling(n_all_diseases / n_pages)
remainder = (diseases_per_page * n_pages) - n_all_diseases


plots = iidda_availability(normalized_for_extent_plot
  , pages = seq_len(n_pages)
  , page_size = diseases_per_page
  , legend_colour_breaks = c("weekly", "monthly", "quarterly")
  , scale_colour = c(
        weekly    = "#007FFF"
      , `2-weekly` = "limegreen"
      , monthly   = "#FF7F00"
      , quarterly = "#DC143C"
      , `3-quarterly` = "white"
    )
  , colour_order = c("weekly", "2-weekly", "monthly", "quarterly", "3-quarterly")
  , title_colour = "Time Scale:"
  , title_totals = "Total\nCases"
  , within_panel_order = c(
        ## east
          "CA-NL"
        , "CA-PE"
        , "CA-NS"
        , "CA-NB"
        ## central
        , "CA-QC"
        , "CA-ON"
        ## west
        , "CA-MB"
        , "CA-SK"
        , "CA-AB"
        , "CA-BC"
        ## north
        , "CA-YT"
        , "CA-NT"
        , "CA-NU"
      ) |> rev()
  , x_title = "Year"
  , x_breaks = seq(
        as.POSIXct("1910-01-01")
      , as.POSIXct("2010-01-01")
      , by = "20 years"
    )
  , x_minor_breaks = seq(
        as.POSIXct("1910-01-01")
      , as.POSIXct("2010-01-01")
      , by = "5 years"
    )
  , x_date_labels = "%Y"
  , text_size = 9
  , left_margin = 100
  , legend_margin = 15
  , subplot_widths = c(5, 1)
)

save_plots = function(plots, first_page) {
  ratio = 8.75 / 7.5
  width = 7.5
  for (page in seq_len(n_pages)) {
    filename = sprintf("Fig%s.tif", page + first_page - 1L)
    tiff(filename
      , width = width
      , height = width * ratio
      , units = "in"
      , res = 600 ## plos requires 300-600
    )
    plot(plots[[page]])
    dev.off()
    (filename
      |> image_read()
      |> image_write(filename, compression = "LZW", flatten = TRUE)
    )
  }
}

harmonized_plots = harmonize_plots(plots)
save_plots(harmonized_plots, first_page = first_page)

for (i in seq_len(n_pages)) {
  nn = diseases_per_page
  if (i == n_pages) nn = nn - remainder
  writeLines(as.character(nn), sprintf("n-diseases-page-%s", i))
}
