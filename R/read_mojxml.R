#' Read MOJ XML
#'
#' @param file A file name of MOJ XML.
#' @param type The data type to be read, `"fude_polygon"` (default),
#' `"fude_polygon"`, `"fude_line"`, `"admin_line"`, or `"map_info"`.
#' @param lang_col_names Language of column names, English (`"en"`; default) or
#' Japanese (`"ja"`).
#' @param add_columns Whether to add MOJ XML attributes to columns? By default,
#' `TRUE`. If `FALSE`, they are added to `attributes`.
#'
#' @return A sf object, except when `type == "map_info"`. If
#' `type == "map_info"`, a tibble object.
#'
#' @export
read_mojxml <- function(file,
                        type = c("fude_polygon", "fude_point", "fude_line", "admin_line", "map_info"),
                        lang_col_names = c("en", "ja"),
                        add_columns = TRUE) {
  type <- arg_match(type, c("fude_polygon", "fude_point", "fude_line", "admin_line", "map_info"))
  lang_col_names <- arg_match(lang_col_names, c("en", "ja"))

  xml <- read_xml(file)
  attr <- read_mojxml_attr(xml,
                           lang_col_names = lang_col_names)

  if (type == "fude_polygon") {
    out <- read_mojxml_fude_polygon(xml,
                                    lang_col_names = lang_col_names)
  } else if (type == "fude_point") {
    out <- read_mojxml_fude_point(xml)
  } else if (type == "fude_line") {
    out <- read_mojxml_fude_line(xml)
  } else if (type == "admin_line") {
    out <- read_mojxml_admin_line(xml)
  } else if (type == "map_info") {
    out <- read_mojxml_map_info(xml,
                                lang_col_names = lang_col_names)
  }

  if (add_columns) {
    dplyr::bind_cols(out, !!!attr)
  } else {
    exec(structure, out,
         !!!attr)
  }
}

read_mojxml_attr <- function(xml, lang_col_names) {
  attr <- c("version", term_ja$map_name, term_ja$city_code, term_ja$city_name, term_ja$datum_type)
  name_attr <- switch(
    lang_col_names,
    en = c("version", "map_name", "city_code", "city_name", "datum_type"),
    ja = attr
  )
  attr |>
    set_names(name_attr) |>
    purrr::map(\(name) {
      xml |>
        xml_find_first(str_glue("./d1:{name}")) |>
        xml_text()
    })
}

read_mojxml_fude_polygon <- function(xml, lang_col_names) {
  # CRS
  crs <- read_mojxml_crs(xml)

  # Geometry
  point <- read_mojxml_geometry_point(xml,
                                      crs = crs)
  line <- read_mojxml_geometry_line(xml,
                                    point = point)
  polygon <- read_mojxml_geometry_polygon(xml,
                                          line = line)

  # Fude Polygon
  xml_fude_polygon <- xml |>
    xml_find_all(str_glue("./d1:{term_ja$thematic_attr}/d1:{term_ja$fude_polygon}"))

  fude_polygon <- c(term_ja$oaza_code, term_ja$chome_code, term_ja$koaza_code, term_ja$spare_code,
                    term_ja$oaza_name, term_ja$chome_name, term_ja$chiban, term_ja$coord_type)
  name_fude_polygon <- switch(
    lang_col_names,
    en = c("oaza_code", "chome_code", "koaza_code", "spare_code",
           "oaza_name", "chome_name", "chiban", "coord_type"),
    ja = fude_polygon
  )
  fude_polygon <- fude_polygon |>
    set_names(name_fude_polygon) |>
    purrr::map(\(name) {
      xml_fude_polygon |>
        xml_find_first(str_glue("./d1:{name}")) |>
        xml_text()
    })
  tibble::tibble(id = xml_fude_polygon |>
                   xml_attr("id"),
                 id_polygon = xml_fude_polygon |>
                   xml_find_first(str_glue("./d1:{term_ja$shape}")) |>
                   xml_attr("idref"),
                 !!!fude_polygon) |>
    dplyr::left_join(polygon,
                     by = dplyr::join_by("id_polygon" == "id")) |>
    sf::st_as_sf(sf_column_name = "geometry") |>
    dplyr::select(!"id_polygon")
}

read_mojxml_fude_point <- function(xml) {
  # CRS
  crs <- read_mojxml_crs(xml)

  # Geometry
  point <- read_mojxml_geometry_point(xml,
                                      crs = crs)

  # Fude Point
  xml_fude_point <- xml |>
    xml_find_all(str_glue("./d1:{term_ja$thematic_attr}/d1:{term_ja$fude_point}"))
  tibble::tibble(name = xml_fude_point |>
                   xml_find_first(str_glue("./d1:{term_ja$tenban_name}")) |>
                   xml_text(),
                 id = xml_fude_point |>
                   xml_find_first(str_glue("./d1:{term_ja$shape}")) |>
                   xml_attr("idref")) |>
    dplyr::left_join(point,
                     by = "id") |>
    dplyr::select(!"id") |>
    sf::st_as_sf(sf_column_name = "geometry")
}

read_mojxml_fude_line <- function(xml) {
  # CRS
  crs <- read_mojxml_crs(xml)

  # Geometry
  point <- read_mojxml_geometry_point(xml,
                                      crs = crs)
  line <- read_mojxml_geometry_line(xml,
                                    point = point)

  # Fude Line
  xml_fude_line <- xml |>
    xml_find_all(str_glue("./d1:{term_ja$thematic_attr}/d1:{term_ja$fude_line}"))
  tibble::tibble(id = xml_fude_line |>
                   xml_find_first(str_glue("./d1:{term_ja$shape}")) |>
                   xml_attr("idref")) |>
    dplyr::left_join(line,
                     by = "id") |>
    dplyr::select(!"id") |>
    sf::st_as_sf(sf_column_name = "geometry")
}

read_mojxml_admin_line <- function(xml) {
  # CRS
  crs <- read_mojxml_crs(xml)

  # Geometry
  point <- read_mojxml_geometry_point(xml,
                                      crs = crs)
  line <- read_mojxml_geometry_line(xml,
                                    point = point)

  # Admin Line
  xml_admin_boundary <- xml |>
    xml_find_all(str_glue("./d1:{term_ja$thematic_attr}/d1:{term_ja$admin_line}"))
  tibble::tibble(name = xml_admin_boundary |>
                   xml_find_first(str_glue("./d1:{term_ja$line_type}")) |>
                   xml_text(),
                 id = xml_admin_boundary |>
                   xml_find_first(str_glue("./d1:{term_ja$shape}")) |>
                   xml_attr("idref")) |>
    dplyr::left_join(line,
                     by = "id") |>
    dplyr::select(!"id") |>
    sf::st_as_sf(sf_column_name = "geometry")
}

read_mojxml_map_info <- function(xml, lang_col_names) {
  xml_map_info <- xml |>
    xml_find_all(str_glue("./d1:{term_ja$map_info}"))

  polygon_map_info <- xml_map_info |>
    purrr::map(\(xml) {
      xml |>
        xml_find_all(str_glue("./d1:{term_ja$fude_ref}")) |>
        xml_attr("idref")
    })

  XY_map_info <- c(term_ja$bottom_left, term_ja$top_left, term_ja$bottom_right, term_ja$top_right)
  name_XY_map_info <- switch(
    lang_col_names,
    en = c("bottom_left", "top_left", "bottom_right", "top_right"),
    ja = XY_map_info
  )
  XY_map_info <- XY_map_info |>
    set_names(name_XY_map_info) |>
    purrr::imap(\(name, col_name) {
      XY_map_info <- xml_map_info |>
        xml_find_first(str_glue("./d1:{name}"))
      tibble::tibble(X = XY_map_info |>
                       xml_find_first("./zmn:X") |>
                       xml_text() |>
                       as.double(),
                     Y = XY_map_info |>
                       xml_find_first("./zmn:Y") |>
                       xml_text() |>
                       as.double()) |>
        dplyr::rename_with(\(x) str_c(x, col_name,
                                      sep = "_"))
    }) |>
    unname()

  date_map_info <- c(term_ja$year, term_ja$month, term_ja$day)
  name_date_map_info <- switch(
    lang_col_names,
    en = c("year", "month", "day"),
    ja = date_map_info
  )
  date_map_info <- date_map_info |>
    set_names(name_date_map_info) |>
    purrr::map(\(name) {
      xml_map_info |>
        xml_find_first(str_glue("./d1:{term_ja$date_mapped}/d1:{name}")) |>
        xml_text()
    })

  map_info <- c(term_ja$map_id, term_ja$scale_denominator, term_ja$direction_unknown, term_ja$map_type, term_ja$map_class, term_ja$map_material)
  name_map_info <- switch(
    lang_col_names,
    en = c("map_id", "scale_denominator", "direction_unknown", "map_type", "map_class", "map_material"),
    ja = map_info
  )
  map_info <- map_info |>
    set_names(name_map_info) |>
    purrr::map(\(name) {
      xml_map_info |>
        xml_find_first(str_glue("./d1:{name}")) |>
        xml_text()
    })

  tibble::tibble(fude_polygon_id = polygon_map_info,
                 !!!XY_map_info,
                 !!!date_map_info,
                 !!!map_info)
}

read_mojxml_crs <- function(xml) {
  crs <- xml |>
    xml_find_first(str_glue("./d1:{term_ja$coord_system}")) |>
    xml_text()

  if (crs == term_ja$coord_system_arbitrary) {
    return(sf::NA_crs_)
  } else {
    crs <- crs |>
      str_extract(str_glue("(?<={term_ja$coord_system_public[[1L]]})\\d+(?={term_ja$coord_system_public[[2L]]})")) |>
      as.integer()

    return(sf::st_crs(2442 + crs))
  }
}

read_mojxml_geometry_point <- function(xml, crs) {
  xml_point <- xml |>
    xml_find_all(str_glue("./d1:{term_ja$spatial_attr}/zmn:GM_Point"))
  id_point <- xml_attr(xml_point, "id")

  xml_point_position <- xml_point |>
    xml_find_first("./zmn:GM_Point.position/zmn:DirectPosition")
  tibble::tibble(id = id_point,
                 X = xml_point_position |>
                   xml_find_first("./zmn:X") |>
                   xml_text() |>
                   as.double(),
                 Y = xml_point_position |>
                   xml_find_first("./zmn:Y") |>
                   xml_text() |>
                   as.double()) |>
    sf::st_as_sf(coords = c("X", "Y"),
                 crs = crs)
}

read_mojxml_geometry_line <- function(xml, point) {
  xml_line <- xml |>
    xml_find_all(str_glue("./d1:{term_ja$spatial_attr}/zmn:GM_Curve"))
  id_line <- xml_line |>
    xml_attr("id")

  xml_line <- xml_line |>
    xml_find_first("./zmn:GM_Curve.segment/zmn:GM_LineString/zmn:GM_LineString.controlPoint")
  by_line <- vec_rep_each(seq_along(xml_line),
                          times = xml_length(xml_line))

  xml_line <- xml_line |>
    xml_find_all("./zmn:GM_PointArray.column")

  line_direct <- cbind(X = xml_line |>
                         xml_find_first("./zmn:GM_Position.direct/zmn:X") |>
                         xml_text() |>
                         as.double(),
                       Y = xml_line |>
                         xml_find_first("./zmn:GM_Position.direct/zmn:Y") |>
                         xml_text() |>
                         as.double())
  line_indirect <- vec_slice(sf::st_coordinates(point),
                             i = vec_match(xml_line  |>
                                             xml_find_first("./zmn:GM_Position.indirect/zmn:GM_PointRef.point") |>
                                             xml_attr("idref"),
                                           point$id))

  tibble::tibble(id = id_line,
                 geometry = ifelse(!is.na(line_direct), line_direct, line_indirect) |>
                   vec_split(by_line) |>
                   purrr::chuck("val") |>
                   purrr::modify(sf::st_linestring)) |>
    sf::st_as_sf(crs = sf::st_crs(point),
                 sf_column_name = "geometry")
}

read_mojxml_geometry_polygon <- function(xml, line) {
  xml_polygon <- xml |>
    xml_find_all(str_glue("./d1:{term_ja$spatial_attr}/zmn:GM_Surface"))
  id_polygon <- xml_polygon |>
    xml_attr("id")

  xml_polygon <- xml_polygon |>
    xml_find_first("zmn:GM_Surface.patch/zmn:GM_Polygon/zmn:GM_Polygon.boundary/zmn:GM_SurfaceBoundary")

  # exterior
  xml_polygon_exterior <- xml_polygon |>
    xml_find_first("./zmn:GM_SurfaceBoundary.exterior/zmn:GM_Ring")

  loc_polygon_exterior <- !is.na(xml_polygon_exterior)
  xml_polygon_exterior <- xml_polygon_exterior[loc_polygon_exterior]

  by_polygon_exterior <- vec_rep_each(seq_along(xml_polygon_exterior),
                                      times = xml_length(xml_polygon_exterior))
  polygon_exterior <- xml_polygon_exterior |>
    xml_find_all("./zmn:GM_CompositeCurve.generator") |>
    xml_attr("idref") |>
    vec_split(by = by_polygon_exterior) |>
    purrr::chuck("val") |>
    purrr::modify(\(name) {
      polygon <- vec_slice(line,
                           i = vec_match(name, line$id)) |>
        sf::st_coordinates()
      sf::st_polygon(list(polygon[, c("X", "Y")]))
    })

  # interior
  xml_polygon_interior <- xml_polygon |>
    xml_find_first("./zmn:GM_SurfaceBoundary.interior/zmn:GM_Ring")

  loc_polygon_interior <- !is.na(xml_polygon_interior)
  xml_polygon_interior <- xml_polygon_interior[loc_polygon_interior]

  by_polygon_interior <- vec_rep_each(seq_along(xml_polygon_interior),
                                      times = xml_length(xml_polygon_interior))
  polygon_interior <- xml_polygon_interior |>
    xml_find_all("./zmn:GM_CompositeCurve.generator") |>
    xml_attr("idref") |>
    vec_split(by = by_polygon_interior) |>
    purrr::chuck("val") |>
    purrr::modify(\(name) {
      polygon <- vec_slice(line,
                           i = vec_match(name, line$id)) |>
        sf::st_coordinates()
      sf::st_polygon(list(polygon[, c("X", "Y")]))
    })

  polygon <- data_frame(line_exterior = list(NULL),
                        line_interior = list(NULL),
                        .size = length(xml_polygon))
  vec_slice(polygon$line_exterior, loc_polygon_exterior) <- polygon_exterior
  vec_slice(polygon$line_interior, loc_polygon_interior) <- polygon_interior
  tibble::tibble(id = id_polygon,
                 geometry = purrr::modify2(polygon$line_exterior, polygon$line_interior,
                                           \(line_exterior, line_interior) {
                                             c(line_exterior, line_interior)
                                           })) |>
    sf::st_as_sf(crs = sf::st_crs(line),
                 sf_column_name = "geometry")
}
