#' Download MOJ XML
#'
#' @param x File names of MOJ XML or a data frame created with `mojxml_find()`.
#' @param exdir A directory name to download data. If it does not exist, it will
#' be created.
#' @param progress Whether to show a progress bar. Passed to [purrr::walk()].
#' @param ... Unused, for extensibility.
#'
#' @return The names of downloaded files invisibly.
#'
#' @export
mojxml_download <- function(x, exdir,
                            progress = TRUE, ...) {
  UseMethod("mojxml_download")
}

#' @export
mojxml_download.character <- function(x, exdir,
                                      progress = TRUE, ...) {
  x <- path_ext_remove(x)
  x |>
    purrr::walk(\(x) {
      pref_code <- x |>
        str_extract("^\\d{2}") |>
        as.integer()
      repo <- vec_slice(kuwanauchi_datalist_pref$repo,
                        i = vec_match(pref_code, kuwanauchi_datalist_pref$pref_code))

      url <- str_glue("{url_amx_project}/{repo}/main/xml/{x}.zip")
      destfile <- file_temp(ext = "zip")
      download.file(url,
                    destfile = destfile,
                    quiet = TRUE,
                    mode = "wb", ...)
      unzip(destfile,
            exdir = exdir)
    },
    .progress = progress)

  out <- path(exdir, x,
              ext = "xml")
  invisible(out)
}

#' @export
mojxml_download.mojxml_find <- function(x, exdir,
                                        progress = TRUE, ...) {
  vec_unique(x$zipfile_name) |>
    mojxml_download(exdir = exdir,
                    progress = progress)
}
