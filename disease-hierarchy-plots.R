args <- commandArgs(trailingOnly = TRUE)
if (length(args) > 0L) args = lapply(args, \(x) sub("_1\\.png$", "", basename(x)))
print(args)

source("conflicts-policy.R")
library(ggraph)
library(tidygraph)
library(iidda)
library(iidda.analysis)
library(lubridate)

data = readRDS("canmod-cdi-normalized.rdata")
disease_lookup = readRDS("canmod-disease-lookup.rdata")

prune_lookup = function(lookup, basal_diseases_to_prune) {
  hierarchy = (disease_lookup
    |> select(disease, nesting_disease)
    |> distinct()
  )
  new_basal_diseases = unique(hierarchy$disease[hierarchy$nesting_disease %in% basal_diseases_to_prune])
  children_of_the_new = (hierarchy
    |> filter(nesting_disease %in% new_basal_diseases)
  )
  parents_of_the_new = (hierarchy
    |> filter(disease %in% new_basal_diseases)
    |> mutate(nesting_disease = "")
  )
  the_old = (hierarchy
    |> filter(!nesting_disease %in% new_basal_diseases)
    |> filter(!disease %in% new_basal_diseases)
  )
  hierarchy = rbind(children_of_the_new, parents_of_the_new, the_old)
  add_basal_disease(hierarchy, hierarchy)
}

unaccounted_hierarchy = (data
  |> filter(grepl("_unaccounted$", disease))
  |> distinct(disease, nesting_disease, basal_disease)
)
hierarchy = (disease_lookup
  |> prune_lookup("venereal-diseases")
  |> rbind(unaccounted_hierarchy)
)

th <- theme_set(theme_graph())
theme_update(plot.margin = unit(c(0.2, 1, 0, 1), "in"))
theme_update(legend.position = "bottom")
th <- theme_get()
print(ggplot() + th)

## make one plot
## @param scheme Integer describing a particular disease hierarchy that was
## observed in a particular time and place.
## @param obs_dat Data with scheme information.
## @param hierarchy Lightly processed disease lookup table.
## @param focal Name of the focal basal disease.
viz = function(scheme, obs_dat, hierarchy, focal) {
  i = obs_dat$scheme == scheme
  obs_diseases = unique(obs_dat$disease[i])
  date_sum = unique(obs_dat$dates[i])
  place_sum = unique(obs_dat$places[i])
  nodes = (hierarchy
    |> filter(basal_disease %in% focal)
    |> mutate(observed = disease %in% obs_diseases)
  )
  all_nodes = (
       nodes[, c("disease", "nesting_disease", "basal_disease"), drop = FALSE]
    |> unlist()
    |> unique()
  )
  edges = (nodes
    |> filter(nesting_disease != "")
    |> mutate(to = match(disease, all_nodes))
    |> mutate(from = match(nesting_disease, all_nodes))
  )

  plt = (nodes
    |> tbl_graph(edges, node_key = "disease")
    |> ggraph(layout = "tree")
    + geom_edge_diagonal(
        aes(
            x = -y
          , y = x
          , xend = -yend
          , yend = xend
        )
      , flipped = TRUE)
    + geom_node_label(
        aes(
            x = -y
          , y = x
          , colour = observed
          , label = shorten_nested_names(disease, nesting_disease)
          , hjust = 0.5
        )
      , lineheight = 0.7
    )
    + th
    + ggtitle(date_sum, place_sum)
    + coord_cartesian(clip = "off")
  )
  return(plt)
}

## custom abbreviation function that handles the 'ex' convention for
## conditions that are excluded from a particular disease.
abbr = function(sep = "ex-", fmt ="ex-%s", pat = "[-_]") {
  function(x,  ...) {
    x_splt = strsplit(x, sep)
    y = vapply(x_splt, getElement, character(1L), 1L)
    z = (x_splt
      |> lapply(\(n) n[-1L])
      |> lapply(gsub, pattern = pat, replacement = "")
      |> lapply(abbreviate, ...)
      |> vapply(paste, character(1L), collapse = "-")
    )
    z[z != ""] = sprintf(fmt, z[z != ""])
    sprintf("%s%s", y, z)
  }
}

## Shorten names of diseases that are intermediate in the hierarchy by
## removing parts of the name that are implied by their position in the
## hierarchy.  For example syphilis-primary need only be called primary,
## because the network graph makes it clear that it is a form of syphilis.
shorten_nested_names = function(names, nested) {
  x = names
  z = nested
  for (i in seq_along(x)) {
    if (!is_empty(z[i])) {
      x[i] =  sub(sprintf("^%s", z[i]), "", x[i])
      x[i] = gsub(sprintf("-%s", z[i]), "", x[i])
      x[i] = sub("^[_-]", "", x[i])
    }
    zz = nested[names == nested[i]] ## parent of parent
    if (isFALSE(is_empty(zz))) {
      x[i] =  sub(sprintf("^%s", zz), "", x[i])
      x[i] = gsub(sprintf("-%s", zz), "", x[i])
      x[i] = sub("^[_-]", "", x[i])
    }
  }
  abbr()(x, 4, method = "both.sides")
}

## create a unique label for a 'scheme' -- see above
make_scheme = function(disease, nesting_disease) {
  paste(sprintf("%s<-->%s", disease, nesting_disease), collapse = ":")
}

## plot all schemes for a particular focal disease, and save them in a file.
all_viz = function(data, hierarchy, focal) {
  if (!any(focal %in% data$basal_disease)) {
    stop("not any focal disease in the observed list of basal diseases")
  }
  obs_dat = (data
    |> filter(basal_disease %in% focal)
    |> select(period_start_date, period_end_date, iso_3166_2, disease, nesting_disease)
    |> distinct()
    |> group_by(period_start_date, period_end_date, iso_3166_2)
    |> arrange(disease, nesting_disease)
    |> mutate(scheme = make_scheme(disease, nesting_disease))
    |> ungroup()
    |> mutate(scheme = as.numeric(as.factor(scheme)))
    |> group_by(scheme, disease, nesting_disease)
    |> summarise(
        places = summarise_strings(sub("CA-", "", iso_3166_2))
      , dates = summarise_periods_vec(period_start_date, period_end_date)
    )
    |> ungroup()
    |> add_basal_disease(hierarchy)
  )
  schemes = 1:max(obs_dat$scheme)
  ht = 8.5
  if (focal == "hepatitis-A-B") ht = 3
  if (!dir.exists("disease-hierarchies")) dir.create("disease-hierarchies")
  for (s in schemes) {
    plt = viz(s, obs_dat, hierarchy, focal)
    fnm = sprintf("disease-hierarchies/%s_%s.png", focal, s)
    ggsave(fnm, plt, width = 8.5, height = ht)
  }
  return(plt)
}

if (interactive()) { ## make all diseases if interactive

  ## what basal diseases have the biggest hierarchies?
  disease_clusters = (hierarchy
    |> group_by(basal_disease)
    |> summarise(n_nodes = n())
    |> ungroup()
    |> arrange(desc(n_nodes))
    |> filter(n_nodes > 1)
  )

  ## save plots
  for (d in disease_clusters$basal_disease) {
    print(d)
    all_viz(data, hierarchy, d)
  }

} else {
  for (d in unlist(args)) {
    print(d)
    all_viz(data, hierarchy, d)
  }
}
