pkgs_to_install = ("*.R"
  |> file.path()
  |> Sys.glob()
  |> lapply(readLines)
  |> lapply(grep, pattern = "library\\([a-zA-Z][a-zA-Z0-9._]*\\)", value = TRUE)
  |> unlist()
  |> unique()
  |> sub(pattern = "^library", replacement = "")
  |> gsub(pattern = "[()]", replacement = "")
  |> trimws()
)

message("Installing the following packages:")
message(" ", paste0(pkgs_to_install, collapse = "\n "))

universe = c("iidda", "iidda.api", "iidda.analysis")
cran = setdiff(pkgs_to_install, universe)

install.packages(cran
  , repos = list(CRAN = "https://cran.r-project.org")
)
install.packages(universe
  , repos = c(
      "https://canmod.r-universe.dev"
    , "https://cran.r-project.org"
  )
)
