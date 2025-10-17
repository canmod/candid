source("conflicts-policy.R")
library(magick)
library(ggplot2)
library(grid)
library(patchwork)

filename = "Fig2.tif"  ## file produced by this script

image_good = magick::image_read(
    "cdi_ery_gon_on_1939_easy_to_read.png"
  , density = 600
)
image_bad = magick::image_read(
    "cdi_poliounspec_ca_1955_difficult_to_read.png"
  , density = 600
)

grob_good = grid::rasterGrob(image_good, hjust = 0.6, vjust = 0.5)
grob_bad = grid::rasterGrob(image_bad, hjust = 0.6, vjust = 0.5)

p = ggplot()
p_good = p + annotation_custom(grob_good)
p_bad = p + annotation_custom(grob_bad)

plot = (
    plot_spacer()
  + p_good
  + labs(caption = "(A) Easy to read")
  + theme_void()
  + theme(plot.caption = element_text(hjust = 0, size = 12))
  + patchwork::plot_spacer()
  + p_bad
  + labs(caption = "(B) Difficult to read")
  + theme_void()
  + theme(plot.caption = element_text(hjust = 0, size = 12))
  + patchwork::plot_spacer()
  + patchwork::plot_layout(ncol = 5, widths = c(-0.04, 1, -0.1, 1.25, -0.2))
)
ggsave(filename
  , plot
  , device = "tiff"
  , dpi = 600
  , width = 6
  , height = 6
  , units = "in"
)
(filename
  |> magick::image_read()
  |> magick::image_write(filename, compression = "LZW", flatten = TRUE)
)
