source("data-raw/setup.R")

# kuwanauchi_search_list --------------------------------------------------

kuwanauchi_datalist <- read_rds("data-raw/kuwanauchi_datalist.rds")

dir_kuwanauchi_search_list <- "data-raw/kuwanauchi_search_list"
dir_create("data-raw/kuwanauchi_search_list")
kuwanauchi_datalist |>
  mutate(file_name = str_glue("{url_amx_project}/{repository}/main/xml/{file_name}")) |>
  pull(file_name) |>
  walk(\(file_name) {
    destfile <- path(dir_kuwanauchi_search_list, path_file(file_name))

    if (!file_exists(destfile)) {
      safely(curl::curl_download)(file_name,
                                  destfile = destfile)
    }
  },
  .progress = TRUE)
