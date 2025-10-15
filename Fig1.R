source("conflicts-policy.R")
library(magick)

scan = ("cdi_ca_1965-01-09-scan.png"
  |> magick::image_read(density = 600)
  |> image_scale("1898x1169")
)
excel = magick::image_read("cdi_ca_1965-01-09-digitization.png", density = 600)
fig = magick::image_append(c(scan, excel), stack = TRUE)

if (interactive()) {
  magick::image_info(excel)
  magick::image_info(scan)
  magick::image_info(fig)
}

magick::image_write(fig
  , "Fig1.tif"
  , flatten = TRUE
  , compression = "LZW"
  , format = "tiff"
  , density = 600
)
