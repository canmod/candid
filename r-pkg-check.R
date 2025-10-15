source("conflicts-policy.R")
dependencies = source("r-package-recommendations.R")$value

iidda_pkgs = c("iidda", "iidda.api", "iidda.analysis")
universe = dependencies |> names() |> intersect(iidda_pkgs)
default = dependencies |> names() |> setdiff(iidda_pkgs)

handle_error = function(pkgs, msg) {
  wrap = function(...) {
    (c(...)
      |> paste(collapse = " ")
      |> strwrap(prefix = "\n", initial = "")
    )
  }

  if (any(pkgs)) {
    pkgs = pkgs |> which() |> names()
    err = c(
          "\n\n\n"
        , wrap(
            "The following packages are required to make the manuscript "
          , "but they (or their dependencies) are not available:"
        )
        , sprintf("\n   %s", pkgs)
        , "\n\nThe simplest fix to this problem is to install these packages ", msg, "\n\n\n"
    )
    return(err)
  }
  NULL
}

pkg_default = vapply(default, Negate(requireNamespace), logical(1L), quietly = TRUE)
err_default = handle_error(pkg_default
  , "using code in install-r-pkgs.R or using your standard package installation approach."
)


pkg_universe = vapply(universe, Negate(requireNamespace), logical(1L), quietly = TRUE)
err_universe = handle_error(pkg_universe
  , "using code in install-r-pkgs.R or using instructions here:\n   https://canmod.github.io/iidda-tools/"
)

err = if (is.null(err_default) | is.null(err_universe)) {
  c(err_default, err_universe)
} else {
  c(err_default, "-------------------------", err_universe)
}

if (!is.null(err)) stop(err)
