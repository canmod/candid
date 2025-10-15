source("conflicts-policy.R")
pkg_versions = function(dir, file) {
  library_calls = (dir
    |> file.path("*.R")
    |> Sys.glob()
    |> lapply(readLines)
    |> lapply(grep, pattern = "library\\([a-zA-Z][a-zA-Z0-9._]*\\)", value = TRUE)
    |> unlist()
    |> unique()
  )

  for (line in library_calls) eval(parse(text = line))

  info = sessionInfo()
  pkgs = c(names(info$loadedOnly), names(info$otherPkgs))
  vers = (pkgs
    |> lapply(packageVersion)
    |> lapply(as.character)
    |> setNames(pkgs)
    |> unlist()
  )

  dput(vers, file = file)
  return(vers)
}

pkg_versions(".", "r-package-recommendations.R")
