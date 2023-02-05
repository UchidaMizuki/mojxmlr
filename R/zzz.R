.onLoad <- function(...) {
  read_mojxml_crs <<- memoise::memoise(read_mojxml_crs)
  read_mojxml_attr <<- memoise::memoise(read_mojxml_attr)
  read_mojxml_geometry_point <<- memoise::memoise(read_mojxml_geometry_point)
  read_mojxml_geometry_line <<- memoise::memoise(read_mojxml_geometry_line)
  read_mojxml_geometry_polygon <<- memoise::memoise(read_mojxml_geometry_polygon)
}
