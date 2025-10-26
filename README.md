# Canadian Notifiable Disease Incidence Dataset (CANDID)

This repository contains all code used to produce the CANDID manuscript and associated figures, tables, and statistics.

The following steps from a unix-like command line should reproduce the manuscript.

```
Rscript install-iidda-r-pkgs.R
./configure
make
```

The first step, `Rscript install-iidda-r-pkgs.R`, is not necessary if you already have up-to-date installations of `iidda`, `iidda.analysis`, and `iidda.api`. [These are packages](https://canmod.github.io/iidda-tools/) that we developed, which are not on [CRAN](https://cran.r-project.org/).

The `configure` command does the following.

1. Check that R is installed and has version 4.0 or greater
2. Check that required R packages are installed (see [install-r-pkgs.R](install-r-pkgs.R) for some tips)
3. Warns if R package versions are different from those listed in [r-package-recommendations.R](r-package-recommendations.R)
4. Check that `pdflatex` and `bibtex` are installed
5. Check that required LaTeX packages are available
6. Pull the CANDID datasets and store them as `rdata` files

The `make` command creates a PDF of the manuscript and all statistics, images, and tables that either appear in the PDF, will appear in the published article, or on this repository. The figure files, `Fig1.tif` to `Fig8.tif`, are those that appear in the main text of the manuscript.

A pre-rendered version of the manuscript is [output/ms.pdf](output/ms.pdf).
