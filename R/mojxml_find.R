#' Find MOJ XML via 'kuwanauchi'
#'
#' @param city_code A city code in Japan.
#' @param lang_col_names Language of column names, English (`"en"`; default) or
#' Japanese (`"ja"`).
#'
#' @return A `mojxml_find` object, which is a data frame.
#'
#' @export
mojxml_find <- function(city_code,
                        lang_col_names = c("en", "ja")) {
  lang_col_names <- arg_match(lang_col_names, c("en", "ja"))

  out <- kuwanauchi_datalist |>
    dplyr::filter(.data$city_code %in% .env$city_code)
  out <- purrr::map2_dfr(out$repo, out$file_name,
                         \(repo, file_name) {
                           out <- readr::read_csv(str_glue("{url_amx_project}/{repo}/main/xml/{file_name}"),
                                                  locale = readr::locale(encoding = "shift-jis"),
                                                  col_types = readr::cols(.default = "c",
                                                                          !!term_ja$datetime_output := readr::col_datetime("%Y%m%d%H%M"))) |>
                             dplyr::select(term_ja$chiban_name, term_ja$chiban_code,
                                           term_ja$chiban_name_undecided, term_ja$chiban_code_undecided,
                                           term_ja$datetime_output, term_ja$zipfile_name)
                           if (lang_col_names == "en") {
                             out <- out |>
                               dplyr::rename(chiban_name = !!term_ja$chiban_name,
                                             chiban_code = !!term_ja$chiban_code,
                                             chiban_name_undecided = !!term_ja$chiban_name_undecided,
                                             chiban_code_undecided = !!term_ja$chiban_code_undecided,
                                             datetime_output = !!term_ja$datetime_output)
                           }
                           out |>
                             dplyr::rename(zipfile_name = !!term_ja$zipfile_name)
                         })
  stickyr::new_sticky_tibble(out,
                             cols = "zipfile_name",
                             col_show = NULL,
                             class = "mojxml_find")
}

#' @export
tbl_sum.mojxml_find <- function(x) {
  NextMethod() |>
    set_names("MOJ XML")
}
