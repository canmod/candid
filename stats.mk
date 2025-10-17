## stats created in stats-data.R
STATS_DATA := unharmonized_sample_size
STATS_DATA += harmonized_sample_size
STATS_DATA += normalized_sample_size
STATS_DATA += normalized_sample_size_2wk
STATS_DATA += normalized_sample_size_3qr
STATS_DATA += normalized_sample_size_mo
STATS_DATA += normalized_sample_size_qr
STATS_DATA += normalized_sample_size_wk
STATS_DATA += n_basal_diseases
STATS_DATA += n_disease_cross_check
STATS_DATA += n_diseases
STATS_DATA += n_historical_diseases
STATS_DATA += n_location_cross_check
STATS_DATA += n_time_scale_cross_check
STATS_DATA += perc_dis_cc_err_handwritten
STATS_DATA += perc_loc_cc_err_handwritten
STATS_DATA += perc_pd_dis_no_err
STATS_DATA += perc_pd_loc_no_err
STATS_DATA += perc_ts_cc_err_handwritten
STATS_DATA += perc_yr_loc_no_err

## stats created in Fig4.R
STATS_HEATMAP := n-diseases-page-1
STATS_HEATMAP += n-diseases-page-2
STATS_HEATMAP += n-diseases-page-3

## stats created in Fig7.R
STATS_POLIO := polio-max-week-peak
STATS_POLIO += polio-max-year
STATS_POLIO += polio-max-year-peak
STATS_POLIO += polio-min-week-peak
STATS_POLIO += polio-min-year
STATS_POLIO += polio-min-year-peak

## stats created in Fig8.R
STATS_WC := n_territories_wc_max_90s
STATS_WC += n_on_wc_max_90s

## stats created in Table1.R
STATS_TABLE := n_sources

ALL_STATS := $(STATS_DATA) $(STATS_POLIO) $(STATS_WC) $(STATS_HEATMAP) $(STATS_TABLE)
