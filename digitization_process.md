# Digitization Process <!-- omit in toc -->

- [General Guidelines](#general-guidelines)
- [Template Guildelines](#template-guildelines)
  - [Template: Provincial incidence 1924 to 1955](#template-provincial-incidence-1924-to-1955)
  - [Template: Provincial incidence 1924 to 1955 with age and sex breakdowns](#template-provincial-incidence-1924-to-1955-with-age-and-sex-breakdowns)
  - [Templates: Provincial incidence 1956 to 2001 -- general guidelines for following five templates](#templates-provincial-incidence-1956-to-2001----general-guidelines-for-following-five-templates)
      - [Template: Provincial incidence 1956 to 1959 week 3](#template-provincial-incidence-1956-to-1959-week-3)
      - [Template: Provincial incidence 1959 week 4 to 1968](#template-provincial-incidence-1959-week-4-to-1968)
      - [Template: Provincial incidence 1969 to 1972](#template-provincial-incidence-1969-to-1972)
      - [Template: Provincial incidence 1975 to 1978](#template-provincial-incidence-1975-to-1978)
      - [Template: Provincial incidence 1979 to 2001](#template-provincial-incidence-1979-to-2001)
  - [Template: Provincial populations 1871 to 1921](#template-provincial-populations-1871-to-1921)
  - [Template: Provincial populations 1921-1971](#template-provincial-populations-1921-1971)

This document outlines the recommended digitization methods for the CANDID project.

The core principle is that digitized Excel files should mirror the structure and appearance of the original documents closely enough to allow easy comparison, while still allowing practical flexibility when an exact match is not feasible. Consistency with the source is emphasized, but work should continue even when small differences remain.

## General Guidelines

- All data should be entered exactly the same as it is seen in the original document if possible
- The layout of each spreadsheet should be exactly the same or very similar to the original
- All rows and columns in the Excel file should be in the same order as in the original file
- The format of every cell should be set to `text` _before_ entering the data
- Dates should be in exactly the same format as the original source
- Alternating grey/white lines should be consistently used for readability, even if they are not in the source document
- Metadata underneath the main table should have the following format
  - Separated from the main table by one blank row
  - Metadata 'keys' should be in column `B` and values in column `C`
  - Required keys are "Created by:", "Date:"
  - Another required key is "Entered from:", which contains the name of the PDF file that the data is being entered from
  - Encouraged keys are "Time taken:"
  - Any sheet-wide comments should be associated with a "Comments:" key
  - Any other keys can be added
  - See [this Excel file](https://github.com/canmod/iidda/blob/main/pipelines/cdi_ca_1924-55_wk_prov_dbs_statcan/digitizations/cdi_cp_ca_1924-55_wk_prov.xlsx) in sheet 1924, columns B and C, in rows 61-63 for an example of what 'metadata underneath the main table' means
- If the value of a cell is uncertain but you can make an informed guess, use the following procedure:
  - Set text colour to red
  - Add an 'Excel Comment' to the cell with one word:  "Unclear"
  - No other formatting should be used that deviates from the overall format style
- In cells containing numbers, please use the following values to indicate different types of missing or unclear numbers:
  - Non-missing numeric case numbers (non-negative integers).
  - Strings explaining why case numbers are missing
    (typically taken as-is from the source, but before 1924 we sometimes made an educated guess about the reason particular records were missing):
    - The phrase `Not available`, for unknown reasons.
    - The phrase `Not reported`, for unknown reasons.
    - The phrase `Not reportable`, presumably indicating that the jurisdiction was not required to report these numbers.
    - The word `Missing`, typically indicating missing pages in the middle of a multi-page table.
    - The word `Unclear`, meaning that the value is missing because it is not legible.
    - The word `Unclear`, with a special string format:
      > `{guess_1}-{guess_2}-...-{guess_n} (unclear)`
      (e.g., `36-23-59 (unclear)`), meaning that the value is missing because the number is difficult to read but we have one or more guesses. Please place your best guess first, followed by the second best guess, etc.
    - Phrases of the format `Wrong but clear total in this cell is {value}` means that this cell should contain a marginal total (e.g., annual total), and that the value is clearly written but is not the correct total
- When several source documents have the same or similar formatting, the formatting of the corresponding digitized Excel documents should also be similar to each other and consistent with the source
- If you are unsure how to enter data, discuss the issue with the group so this document can be clarified or expanded

## Template Guildelines

- Use an existing Excel template as a starting point where possible -- see this [example template](https://github.com/canmod/iidda/blob/main/pipelines/cdi_ca_1924-55_wk_prov_dbs_statcan/templates/DBS_StatCan_1924-1955_Template.xlsx) 
- If a template is not available for your data source, consider creating one and sharing for reuse
- The following sections are guidelines for particular templates to be used in addition to the [General Guidelines](#general-guidelines).

### Template: Provincial incidence 1924 to 1955

- Follow [template](https://github.com/canmod/iidda/blob/main/pipelines/cdi_ca_1924-55_wk_prov_dbs_statcan/templates/DBS_StatCan_1924-1955_Template.xlsx)
- Year always goes in last column containing data, in the second row
- Keep the filenames consistent with Samara's name changes. The format is `cdi_disease_ca_year-year_wk_prov`. Example for diphtheria: `cdi_dipth_ca_1924-55_wk_prov`
- [nfld](https://github.com/canmod/iidda/blob/main/pipelines/cdi_ca_1924-55_wk_prov_dbs_statcan/templates/DBS_StatCan_1924-1955_Template_withNewfoundland.xlsx) should be formatted like [all other provinces](https://github.com/canmod/iidda/blob/main/pipelines/cdi_ca_1924-55_wk_prov_dbs_statcan/templates/DBS_StatCan_1924-1955_Template.xlsx)
- Names of sheets should be the year in YYYY format

### Template: Provincial incidence 1924 to 1955 with age and sex breakdowns

- Follow guidelines above for `DBS_StatCan_1924-1955_Template.xlsx`, and additional guidelines in this list, but use this [template](pipelines/cdi_ca_1924-55_wk_prov_dbs_statcan/templates/DBS_StatCan_template_agesex.xlsx)
- Names of sheets should be in {year} {age group} format (with age groups using the formats that occur in the original document)
  - e.g. 1942 15-19 years
  - e.g. 1942 under 1 year
- When 'age not stated' and 'sex not stated' footnotes are used:
  - Place the footnote definitions in column A immediately below the table, before the metadata
  - Write the footnotes exactly as they appear
  - You do not need to use superscripts or subscripts when referring to the footnotes in the data tables
  - There should be zero space between the footnote symbol and the associated datum
  - There should be at least some space between a footnote symbol and a datum that is not associated with the footnote
  - If two data points are given in a single cell separated by a plus symbol, please put one space on either side of the plus
  - If a number is written on the line between two cells, include it in the female column along with other data that already exist there
  - Please include the row and column totals of the 'age/sex not stated' data -- name the associated row/column 'age-not-stated totals' / 'sex-not-stated totals' if the original source does not include a name (otherwise use the name in the original source)

### Templates: Provincial incidence 1956 to 2001 -- general guidelines for following five templates

- Update template as format changes from year to year or week to week to match the original as closely as possible
- Include a new row in Excel for each line in the header and `merge across` all header rows for the width of the table
- Keep all information exactly as seen in the original document including sub- and superscripts
- Keep all types of missing data the same as is seen in the original document (i.e. '-', '.', '..') along with the corresponding legend below the table
- Include "ENTERED BY: 'name' on 'date'" and "ENTERED FROM:" at the bottom of each Excel sheet after all data
- Reference notes below for more details on different templates

##### Template: Provincial incidence 1956 to 1959 week 3

- Follow [template](https://github.com/canmod/iidda/blob/main/pipelines/cdi_ca_1956-63_1973-74_wk_prov/templates/cdi_ca_1956-1959_wk_prov_Template.xlsx). May be subject to change depending on additional information following the main table
- Legend directly below table
- Directly following legend: "The Situation in the United States"
- All other info or notes on the data sheet are in the lines after "The Situation in the United States"
- Include "ENTERED BY: 'name' on 'date'" at the bottom of each Excel sheet after all info

##### Template: Provincial incidence 1959 week 4 to 1968

- Follow [template](https://github.com/canmod/iidda/blob/main/pipelines/cdi_ca_1956-63_1973-74_wk_prov/templates/cdi_ca_1959-1968_wk_prov_Template.xlsx)
- Include only tables found in Template
- Include an Excel sheet with a list of tables not found in the Template along with corresponding page numbers
- Template may change minimally from year to year or week to week so follow original pdf as closely as possible
- Note: all tables (including those not found in Template) were included in cdi_ca_1964_wk_prov.xlsx as a reference
- Legend directly below table
- Directly following legend: "Rare Diseases" and "The Situation in the United States"
- For 1959 and 1964 all other info or notes on the data sheet are in the lines after "The Situation in the United States"
- Include "ENTERED BY: 'name' on 'date'" at the bottom of each Excel sheet after all info

##### Template: Provincial incidence 1969 to 1972

- Follow [template](https://github.com/canmod/iidda/blob/main/pipelines/cdi_ca_1968-72_wk_prov/templates/cdi_ca_1969-1972_wk_prov_Template.xlsx)
- Template may change minimally from year to year or week to week so follow original pdf as closely as possible
- Legend directly below table
- Directly following legend: "Rare Diseases" and "The Situation in the United States"
- Include "ENTERED BY: 'name' on 'date'" and "ENTERED FROM: .pdf" at the bottom of each Excel sheet after all info

##### Template: Provincial incidence 1975 to 1978

- Follow [template](https://github.com/canmod/iidda/blob/main/pipelines/cdi_ca_1975-78_wk_prov/templates/cdi_ca_1975-1978_wk_prov_Template.xlsx). Template may change minimally from year to year or week to week so follow original pdf as closely as possible.
- Legend directly below table
- Directly following legend: "Rare Diseases"
- Include "ENTERED BY: 'name' on 'date'" and "ENTERED FROM: .pdf" at the bottom of each Excel sheet after all info

##### Template: Provincial incidence 1979 to 2001

- Template missing
- Follow the original document as closely as possible as there are changes from sheet to sheet


### Template: Provincial populations 1871 to 1921 

- Template missing
- For age categories that are merged for some columns but not others (e.g. bottom of page 6, PEI)
  - merge the cells so that they cover multiple age categories
  - Text colour is yellow
  - 'Excel Comment' added to the cell with the phrase:  "Sum over more than one category"
  - No other formatting should be used that deviates from the overall format style

### Template: Provincial populations 1921-1971

- Follow [template](https://github.com/canmod/iidda/blob/main/pipelines/pop_ca_1921-71_an_age_prov_sex/templates/pop_ca_1921-1971_annual_prov_age_sex_Template.xlsx)
