source("data-raw/term_ja.R")
source("data-raw/kuwanauchi_datalist.R")

# internal ----------------------------------------------------------------

usethis::use_data(term_ja,
                  kuwanauchi_datalist,
                  kuwanauchi_datalist_pref,
                  internal = TRUE,
                  overwrite = TRUE)
