source("data-raw/setup.R")
source("data-raw/kuwanauchi_repo.R")

# kuwanauchi_datalist -----------------------------------------------------

kuwanauchi_datalist <- read_csv(str_glue("{url_amx_project}/kuwanauchi/main/kuwanauchi_datalist.csv"),
                                col_types = cols(.default = "c")) |>
  mutate(pref_name = prefecture_code |>
           str_extract("(?<=^moj-\\d{2}).+"),
         id = file_name |>
           str_extract("^\\d{5}-\\d+"),
         city_code = file_name |>
           str_extract("^\\d{5}"),
         pref_code = city_code |>
           str_extract("^\\d{2}") |>
           as.integer(),
         city_name = municipality |>
           str_extract("^[^（]+"),
         file_name = str_glue("{path_ext_remove(file_name)}-search-list.csv"),
         .keep = "unused") |>
  left_join(kuwanauchi_repo,
            by = join_by(pref_name, pref_code)) |>
  relocate(id, pref_code, city_code, pref_name, city_name, repo, file_name)

kuwanauchi_datalist_pref <- kuwanauchi_datalist |>
  distinct(pref_code, pref_name, repo)
