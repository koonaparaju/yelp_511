#' <Add Title>
#'
#' <Add Description>
#'
#' @import htmlwidgets
#'
#' @export
C3BarChart <- function(value, keyx = 'Rating', width = NULL, height = NULL) {

  # forward options using x
  x = list(
    value = value,
    keyx = keyx
    )
  #x <- value

  # create widget
  htmlwidgets::createWidget(
    name = 'C3BarChart',
    x,
    width = width,
    height = height,
    package = 'C3'
  )
}

#' Shiny bindings for C3BarChart
#'
#' Output and render functions for using C3BarChart within Shiny
#' applications and interactive Rmd documents.
#'
#' @param outputId output variable to read from
#' @param width,height Must be a valid CSS unit (like \code{'100\%'},
#'   \code{'400px'}, \code{'auto'}) or a number, which will be coerced to a
#'   string and have \code{'px'} appended.
#' @param expr An expression that generates a C3BarChart
#' @param env The environment in which to evaluate \code{expr}.
#' @param quoted Is \code{expr} a quoted expression (with \code{quote()})? This
#'   is useful if you want to save an expression in a variable.
#'
#' @name C3BarChart-shiny
#'
#' @export
C3BarChartOutput <- function(outputId, width = '100%', height = '400px'){
  htmlwidgets::shinyWidgetOutput(outputId, 'C3BarChart', width, height, package = 'C3')
}

#' @rdname C3BarChart-shiny
#' @export
renderC3BarChart <- function(expr, env = parent.frame(), quoted = FALSE) {
  if (!quoted) { expr <- substitute(expr) } # force quoted
  htmlwidgets::shinyRenderWidget(expr, C3BarChartOutput, env, quoted = TRUE)
}
