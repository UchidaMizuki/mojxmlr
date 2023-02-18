url_amx_project <- "https://raw.githubusercontent.com/amx-project"

coord_system_to_crs <- function(coord_system) {
  if (coord_system == term_ja$coord_system_arbitrary) {
    return(sf::NA_crs_)
  } else {
    coord_system <- coord_system |>
      str_extract(str_glue("(?<={term_ja$coord_system_public[[1L]]})\\d+(?={term_ja$coord_system_public[[2L]]})")) |>
      as.integer()

    return(sf::st_crs(2442 + coord_system))
  }
}
