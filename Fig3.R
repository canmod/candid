source("conflicts-policy.R")
library(sf)
library(ggplot2)
library(dplyr)
library(stringr)
library(readr)
library(rnaturalearth)
library(rnaturalearthdata)
library(patchwork)
library(magick)

filename = "Fig3.tif"  ## file produced by this script
fig_width = 5.2  ## recommended by PLoS
fig_height = fig_width/2.6  ## trial and error

# Metadata on the Provinces
#
# Columns:
#   * postal : Provincial abbreviation
#   * lx : Longitude in degrees
#   * ly : Latitude in degrees
#   * use_leader : Should the province be pointed at from outside?
#   * region : https://www150.statcan.gc.ca/n1/en/pub/12-571-x/12-571-x2021001-eng.pdf?st=ihui0H05
prov_locations <- read_csv("prov-locations.csv")

region_palette = region_palette_wrap = setNames(
  c(
        "#8da0cb" ## Atlantic
      , "#66c2a5" ## Quebec
      , "#fc8d62" ## Ontario
      , "#ffd92f" ## Prairies
      , "#a6d854" ## British Columbia
      , "#e78ac3" ## Territories
  )
  , unique(prov_locations$region)
)
names(region_palette_wrap) = str_wrap(names(region_palette), 1)

# Use Lambert projection as recommended by
# https://www12.statcan.gc.ca/census-recensement/2021/ref/dict/az/Definition-eng.cfm?ID=geo031
label_coords <- (prov_locations
  |> st_as_sf(coords = c("lx", "ly"), crs = 4326) # map projection: https://epsg.io/?q=4326
  |> st_transform(crs = 3347) # map projection: https://epsg.io/?q=3347
  |> st_coordinates()
)
label_data = (prov_locations
  |> mutate(
      lx = label_coords[,"X"]
    , ly = label_coords[,"Y"]
  )
)

# Point both to the island of Newfoundland
# and to Labrador.
nl_coords <- (tibble(
      lx = rep(label_data$lx[label_data$postal == "NL"], 2)
    , ly = rep(label_data$ly[label_data$postal == "NL"], 2)
    , cx = c(-55.8, -62.5)
    , cy = c(48.5, 53.5)
  )
  |> st_as_sf(coords = c("cx", "cy"), crs = 4326) # map projection: https://epsg.io/?q=4326
  |> st_transform(crs = 3347) # map projection: https://epsg.io/?q=3347
)
nl_coords$cx = st_coordinates(nl_coords)[,1]
nl_coords$cy = st_coordinates(nl_coords)[,2]
nl_targets = mutate(nl_coords
  , lx = rep(label_data$lx[label_data$postal == "NL"], 2)
  , ly = rep(label_data$ly[label_data$postal == "NL"], 2)
)

## apply the Lambert projection and join the locations of
## the province labels on the map
map_data <- (
     ne_states(country = "canada", returnclass = "sf")
  |> st_transform(crs = 3347) # map projection: https://epsg.io/?q=3347
  |> mutate(centroid = st_centroid(geometry))
  |> mutate(
      cx = st_coordinates(centroid)[, 1]
    , cy = st_coordinates(centroid)[, 2]
  )
  |> select(-region)
  |> left_join(label_data, by = "postal")
)

## plot object contain only the map (without the legend)
map_plot <- (map_data
  |> mutate(region = str_wrap(region, width = 1))
  |> mutate(region = factor(region, levels = names(region_palette_wrap)))
  |> ggplot()
  + geom_sf(aes(fill = region), color = "black", linewidth = 0.1)
  + geom_segment(
      data = filter(map_data, use_leader & postal != "NL")
    , aes(x = lx, y = ly, xend = cx, yend = cy) # point from label to centroid
    , color = "gray30", linewidth = 0.2
  )
  + geom_segment(
      data = nl_targets
    , aes(x = lx, y = ly, xend = cx, yend = cy)
    , color = "gray30", linewidth = 0.2
  )
  + geom_label(
      aes(x = lx, y = ly, label = postal)
    , size = 2.5, label.size = 0.25, label.padding = unit(0.2, "lines")
    , fontface = "bold"
  )
  + scale_fill_manual(values = region_palette_wrap)
  + theme_minimal()
  + theme(
      axis.title = element_blank()
    , axis.text = element_blank()
    , axis.ticks = element_blank()
    , panel.grid = element_blank()
    , plot.margin = margin(0, 0, 0, 0)
  )
  + guides(fill = guide_legend(title = "Region"))
)

## object for translating iso-3166-2 codes into full
## province and territory names
translate = (map_data
  |> data.frame()
  |> select(postal, name)
  |> with(setNames(name, postal))
)

## plot object containing only the legend
text_plot = (prov_locations
  |> mutate(label = sprintf("%s: %s", postal, translate[postal]))
  |> mutate(x = 0, y = rev(seq_along(prov_locations$postal)))
  |> ggplot()
  + geom_text(
      aes(x + 0.1, y, label = label)
    , hjust = 0
    , size = 2.8
    , family = "Helvetica"
  )
  + geom_tile(
      aes(
          x = x + 0.05
        , y = y
        , height = 1
        , width = 0.05
        , fill = region
      )
    , linewidth = 0.1
    , colour = "black"
  )
  + scale_colour_identity()
  + scale_fill_manual(values = region_palette)
  + coord_cartesian(xlim = c(0, 1), expand = FALSE, clip = "off")
  + guides(fill = "none")
  + theme_void()
  + theme(
      plot.margin = margin(0, 0, 0, 0)
    , axis.title = element_blank()
    , axis.title.x = element_blank()
    , axis.title.y = element_blank()
    , axis.text = element_blank()
    , axis.ticks = element_blank()
    , panel.grid = element_blank()
  )
)


full_plot = (
    map_plot
  + text_plot
  + plot_layout(
      widths = c(2, 1.8)
    , heights = 1
  )
)

ggsave(filename
  , full_plot
  , device = "tif"
  , height = fig_height
  , width = fig_width
  , units = "in"
  , dpi = 600
)
(filename
  |> image_read()
  |> image_write(filename
    , compression = "LZW"
    , flatten = TRUE
  )
)
