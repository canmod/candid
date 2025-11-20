library(iidda)
tex = readLines("ms.tex")
pat = "\\\\input\\{[a-z0-9_-]+\\}"
focal_lines = grep(pat, tex)
input_names = lapply(tex[focal_lines]
  , iidda::extract_all_between_paren
  , "\\\\input\\{"
  , "\\}"
  , "[a-z0-9_-]+"
) |> unlist() |> unique()
input_values = (input_names
  |> lapply(readLines, warn = FALSE)
  |> setNames(input_names)
)

for (nm in input_names) {
  tex = gsub(
      sprintf("\\\\input\\{%s\\}(\\\\)?(,)?", nm)
    , sub("%$", "", input_values[[nm]])
    , tex
  )
}

tex = gsub("(\\\\protect)([0-9]+)", "\\2 ", tex)
tex = gsub("(\\\\includegraphics)", "%\\1", tex)
tex = gsub("\\\\usepackage\\{pdfpages\\}", "", tex)
tex = gsub("(\\\\includepdf)", "%\\1", tex)
tex = gsub("\\\\newpage$", "", tex)

writeLines(tex, "ms_flat.tex")
