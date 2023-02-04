#' @export
read_mojxml <- function(file) {
  xml <- read_xml(file)

  version <- xml |>
    xml_find_first("./d1:version") |>
    xml_text()
  map_name <- xml |>
    xml_find_first("./d1:地図名") |>
    xml_text()
  city_code <- xml |>
    xml_find_first("./d1:市区町村コード") |>
    xml_text()
  city_name <- xml |>
    xml_find_first("./d1:市区町村名") |>
    xml_text()
  crs <- read_mojxml_crs(xml)
  datum_type <- xml |>
    xml_find_first("./d1:測地系判別") |>
    xml_text()

  list(version = version,
       map_name = map_name,
       city_code = city_code,
       city_name = city_name,
       crs = crs,
       datum_type = datum_type)
}

read_mojxml_crs <- function(xml) {
  crs <- xml |>
    xml_find_first("./d1:座標系") |>
    xml_text()

  if (crs == "任意座標系") {
    return(sf::NA_crs_)
  } else {
    crs <- crs |>
      stringr::str_extract("(?<=公共座標)\\d+(?=系)") |>
      as.integer()

    return(sf::st_crs(2442 + crs))
  }
}

read_mojxml_geometry <- function(xml, crs) {
  point <- read_mojxml_geometry_point(xml,
                                      crs = crs)
  curve <- read_mojxml_geometry_curve(xml,
                                      point = point)
  surface <- read_mojxml_geometry_surface(xml,
                                          curve = curve)
  list(point = point,
       curve = curve,
       surface = surface)
}

read_mojxml_geometry_point <- function(xml, crs) {
  xml_point <- xml |>
    xml_find_all("./d1:空間属性/zmn:GM_Point")
  id_point <- xml_attr(xml_point, "id")

  xml_point_position <- xml_point |>
    xml_find_first("./zmn:GM_Point.position/zmn:DirectPosition")
  data_frame(id = id_point,
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

read_mojxml_geometry_curve <- function(xml, point) {
  xml_curve <- xml |>
    xml_find_all("./d1:空間属性/zmn:GM_Curve")
  id_curve <- xml_curve |>
    xml_attr("id")

  xml_curve <- xml_curve |>
    xml_find_first("./zmn:GM_Curve.segment/zmn:GM_LineString/zmn:GM_LineString.controlPoint")
  by_curve <- vec_rep_each(seq_along(xml_curve),
                           times = xml_length(xml_curve))

  xml_curve <- xml_curve |>
    xml_find_all("./zmn:GM_PointArray.column")

  curve_direct <- cbind(X = xml_curve |>
                          xml_find_first("./zmn:GM_Position.direct/zmn:X") |>
                          xml_text() |>
                          as.double(),
                        Y = xml_curve |>
                          xml_find_first("./zmn:GM_Position.direct/zmn:Y") |>
                          xml_text() |>
                          as.double())
  curve_indirect <- vec_slice(sf::st_coordinates(point),
                              i = vec_match(xml_curve  |>
                                              xml_find_first("./zmn:GM_Position.indirect/zmn:GM_PointRef.point") |>
                                              xml_attr("idref"),
                                            point$id))

  data_frame(id = id_curve,
             geometry = ifelse(!is.na(curve_direct), curve_direct, curve_indirect) |>
               vec_split(by_curve) |>
               purrr::chuck("val") |>
               purrr::modify(sf::st_linestring)) |>
    sf::st_as_sf(crs = sf::st_crs(point),
                 sf_column_name = "geometry")
}

read_mojxml_geometry_surface <- function(xml, curve) {
  xml_surface <- xml |>
    xml_find_all("./d1:空間属性/zmn:GM_Surface")
  id_surface <- xml_surface |>
    xml_attr("id")

  xml_surface <- xml_surface |>
    xml_find_first("zmn:GM_Surface.patch/zmn:GM_Polygon/zmn:GM_Polygon.boundary/zmn:GM_SurfaceBoundary")

  # exterior
  xml_surface_exterior <- xml_surface |>
    xml_find_first("./zmn:GM_SurfaceBoundary.exterior/zmn:GM_Ring")

  loc_surface_exterior <- !is.na(xml_surface_exterior)
  xml_surface_exterior <- xml_surface_exterior[loc_surface_exterior]

  by_surface_exterior <- vec_rep_each(seq_along(xml_surface_exterior),
                                      times = xml_length(xml_surface_exterior))
  surface_exterior <- xml_surface_exterior |>
    xml_find_all("./zmn:GM_CompositeCurve.generator") |>
    xml_attr("idref") |>
    vec_split(by = by_surface_exterior) |>
    purrr::chuck("val") |>
    purrr::modify(\(name) {
      surface <- vec_slice(curve,
                           i = vec_match(name, curve$id)) |>
        sf::st_coordinates()
      sf::st_polygon(list(surface[, c("X", "Y")]))
    })

  # interior
  xml_surface_interior <- xml_surface |>
    xml_find_first("./zmn:GM_SurfaceBoundary.interior/zmn:GM_Ring")

  loc_surface_interior <- !is.na(xml_surface_interior)
  xml_surface_interior <- xml_surface_interior[loc_surface_interior]

  by_surface_interior <- vec_rep_each(seq_along(xml_surface_interior),
                                      times = xml_length(xml_surface_interior))
  surface_interior <- xml_surface_interior |>
    xml_find_all("./zmn:GM_CompositeCurve.generator") |>
    xml_attr("idref") |>
    vec_split(by = by_surface_interior) |>
    purrr::chuck("val") |>
    purrr::modify(\(name) {
      surface <- vec_slice(curve,
                           i = vec_match(name, curve$id)) |>
        sf::st_coordinates()
      sf::st_polygon(list(surface[, c("X", "Y")]))
    })

  surface <- data_frame(curve_exterior = list(NULL),
                        curve_interior = list(NULL),
                        .size = length(xml_surface))
  vec_slice(surface$curve_exterior, loc_surface_exterior) <- surface_exterior
  vec_slice(surface$curve_interior, loc_surface_interior) <- surface_interior
  data_frame(id = id_surface,
             geometry = purrr::modify2(surface$curve_exterior, surface$curve_interior,
                                       \(curve_exterior, curve_interior) {
                                         c(curve_exterior, curve_interior)
                                       })) |>
    sf::st_as_sf(crs = sf::st_crs(curve),
                 sf_column_name = "geometry")
}
