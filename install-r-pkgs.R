pkgs_to_install = source("pkgs-loaded-with-library.R")$value

pkgs_to_install <- c(pkgs_to_install
  , if ("scales" %in% pkgs_to_install) "dichromat"
)

message("Installing the following packages:")
message(" ", paste0(pkgs_to_install, collapse = "\n "))

universe = c("iidda", "iidda.api", "iidda.analysis")
cran = setdiff(pkgs_to_install, universe)

install.packages(cran)
install.packages(universe
  , repos = c(
      "https://canmod.r-universe.dev"
    , "https://cran.r-project.org"
  )
)
