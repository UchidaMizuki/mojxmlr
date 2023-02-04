source("data-raw/setup.R")

# kuwanauchi_datalist -----------------------------------------------------

kuwanauchi_datalist <- read_csv(str_glue("{url_amx_project}/kuwanauchi/main/kuwanauchi_datalist.csv"),
                                col_types = cols(.default = "c")) |>
  mutate(prefecture_name = prefecture_code |>
           str_extract("(?<=^moj-\\d{2}).+"),
         repository = prefecture_code |>
           str_replace("^moj-", "kuwanauchi"),
         municipality = municipality |>
           str_extract("^[^（]+"),
         file_name = str_glue("{path_ext_remove(file_name)}-search-list") |>
           path_ext_set("csv"),
         .keep = "unused")

write_rds(kuwanauchi_datalist, "data-raw/kuwanauchi_datalist.rds")
