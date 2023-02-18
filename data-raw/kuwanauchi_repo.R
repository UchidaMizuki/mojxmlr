source("data-raw/setup.R")

# kuwanauchi_repo ---------------------------------------------------------

kuwanauchi_repo <- gh::gh("/users/amx-project/repos") |>
  map_chr(\(repo) repo$name) |>
  keep(\(repo) str_starts(repo, "kuwanauchi\\d{2}"))

kuwanauchi_repo <- tibble(repo = kuwanauchi_repo) |>
  mutate(pref_code = repo |>
           str_extract("(?<=kuwanauchi)\\d{2}") |>
           as.integer(),
         pref_name = repo |>
           str_extract("(?<=kuwanauchi\\d{2}).+")) |>
  relocate(pref_code, pref_name)
