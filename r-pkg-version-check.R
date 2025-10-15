source("conflicts-policy.R")
dependencies = source("r-package-recommendations.R")$value
options(warn = 1L) ## show all warnings

iidda_pkgs = c("iidda", "iidda.analysis", "iidda.api")

wrap = function(...) {
  (c(...)
    |> paste(collapse = " ")
    |> strwrap(prefix = "\n", initial = "")
  )
}
ver_equal = vapply(
    names(dependencies)
  , \(dep) packageVersion(dep) == as.package_version(dependencies[[dep]])
  , logical(1L)
)

iidda_note_needed <- FALSE
if (any(!ver_equal)) {
  deps <- dependencies[!ver_equal]

  for (dep in names(deps)) {
    rec <- as.package_version(deps[[dep]])
    inst <- tryCatch(packageVersion(dep), error = function(e) NA)

    if (is.na(inst)) {
      if (!iidda_note_needed) message("WARNING")
      warning(sprintf(
        "package %s is not installed (recommended %s).",
        dep, rec
      ), call. = FALSE)
      if (dep %in% iidda_pkgs) {
        message(sprintf("installing latest version of %s", dep))
        install.packages(dep, repos = c(
            "https://canmod.r-universe.dev"
          , "https://cran.r-project.org"
        ))
      }
      iidda_note_needed = TRUE
      next
    }

    if (rec != inst) {
      if (!iidda_note_needed) message("WARNING")
      cmp <- if (rec > inst) "older than recommended" else "newer than recommended"
      warning(sprintf(
        "package %s (installed %s) is %s (recommended %s).",
        dep, inst, cmp, rec
      ), call. = FALSE)
      if (dep %in% iidda_pkgs) {
        message(sprintf("installing latest version of %s", dep))
        install.packages(dep, repos = c(
            "https://canmod.r-universe.dev"
          , "https://cran.r-project.org"
        ))
      }
      iidda_note_needed = TRUE
    }
  }

  if (iidda_note_needed) {
    msg = wrap(
        "\nIf you are going to install any package that begins"
      , "with the word iidda, "
      , "please follow the installation instructions here: "
      , "https://canmod.github.io/iidda-tools"
    )

    message("\n", msg)
  }
}
if (!iidda_note_needed) message("OK", appendLF = FALSE)
