SHELL := /bin/sh
.DEFAULT_GOAL := all
.SUFFIXES:


-include stats.mk
-include float.mk
-include artifacts.mk


all : ms.pdf

ms.pdf : ms.tex preamble.tex
ms.pdf : $(wildcard *.bib) $(wildcard *.sty) $(wildcard *.cls)
ms.pdf : $(ALL_STATS) $(ALL_FIGS_AND_TABLES)
	@echo "--------------------"
	@echo "Rendering manuscript PDF"
	@echo "--------------------"
	@pdflatex ms
	@bibtex ms
	@pdflatex ms
	@pdflatex ms

$(STATS_DATA) : stats-data.R
	@echo "--------------------"
	@echo "Computing stats about the data that are"
	@echo "reported in the manuscript using stats-data.R"
	@echo "--------------------"
	@Rscript stats-data.R

Fig%.pdf : Fig%.tif tif-to-pdf.R
	@echo "--------------------"
	@echo "Converting $< to $@"
	@echo "--------------------"
	@Rscript tif-to-pdf.R $< 

Fig%.tif : Fig%.R
	@echo "--------------------"
	@echo "Rendering $@ with $<"
	@echo "--------------------"
	@Rscript $<

Fig5.tif Fig6.tif $(STATS_HEATMAP) : Fig4.R
	@echo "--------------------"
	@echo "Rendering Fig4.tif, Fig5.tif, and Fig6.tif"
	@echo "using Fig4.R because these get made together"
	@echo "--------------------"
	@Rscript Fig4.R

$(STATS_POLIO) polio-hist.png : Fig7.R
	@echo "--------------------"
	@echo "Rendering Fig7.tif and associated artifacts"
	@echo "using Fig7.R because these get made together"
	@echo "--------------------"
	@Rscript Fig7.R

$(STATS_WC) : Fig8.R
	@echo "--------------------"
	@echo "Rendering Fig8.tif and associated stats"
	@echo "using Fig8.R because these get made together"
	@echo "--------------------"
	@Rscript Fig8.R

Table1.tex $(STATS_TABLE) : Table1.R
	@echo "--------------------"
	@echo "Rendering Table1.tex and associated stats with $<"
	@echo "--------------------"
	@Rscript $<

## Figures for Supporting Information
$(FIGS_PORTAL) : phac-portal-comparisons.R canmod-cdi-normalized.rdata
	@echo '-------------------------------------------------------------'
	@echo 'Making phac portal comparisons'
	@echo '(supporting information)'
	@echo '-------------------------------------------------------------'
	@Rscript phac-portal-comparisons.R

## Figures for Supporting Information
$(FIGS_AGENCY) : agency-comparison-eg.R canmod-cdi-normalized.rdata
	@echo '-------------------------------------------------------------'
	@echo 'Making agency comparisons'
	@echo '(supporting information)'
	@echo '-------------------------------------------------------------'
	@Rscript agency-comparison-eg.R

## Figures for Supporting Information
$(FIGS_HIERARCHY) : disease-hierarchy-plots.R canmod-cdi-normalized.rdata
	@echo '-------------------------------------------------------------'
	@echo 'Making hierarchy plots'
	@echo '(supporting information)'
	@echo '-------------------------------------------------------------'
	@Rscript $< $@

wordcount.txt : ms.tex
	@texcount -sub=section ms.tex > wordcount.txt
	@echo "--------------------"
	@echo "Word count (including captions and headers):"
	@cat wordcount.txt
	@echo "--------------------"

clean :
	@make clean-latex
	@make clean-figs-tables-stats

clean-latex :
	@rm -f *.aux *.log *.bbl *.blg *.out *.toc *.lot *.lof *.fls *.fdb_latexmk

clean-figs-tables-stats :
	@rm -f $(FIGS) $(FIGS_AGENCY) $(FIGS_PORTAL) $(FIGS_HIERARCHY) $(TABLES)
	@rm -f $(ALL_STATS)

clean-pulled-data :
	@rm -f canmod*.rdata

fresh :
	@make clean
	@make clean-pulled-data
	@rm -f list_artifacts.txt
	@printf "%s\n" $(ARTIFACTS) | sort -u > list_artifacts.txt
	@rm -rf $(ARTIFACTS)

.PHONY : all clean clean-latex clean-figs-tables-stats clean-pulled-data fresh
