usci_dbl_impl <- function(fn, a, b, ...) {
  da <- a - mean(a)
  db <- b - mean(b)

  out <- fn(da, db, ...)
  c <- out[[1]]
  w_sum <- out[[2]]

  da_norm <- sqrt(sum(da^2))
  db_norm <- sqrt(sum(db^2))

  if ((w_sum == 0) && (c == 0)) {
    0
  } else {
    (sqrt(length(a)) * sqrt(length(b)) * c) / (da_norm * db_norm * w_sum)
  }
}

usci_ref <- function(...) {
  usci_dbl_impl(
    fn = function(a, b, a_x, a_y, b_x, b_y, sf) {
      stopifnot((length(a) == length(a_x)) && (length(a) == length(a_y)))
      stopifnot((length(b) == length(b_x)) && (length(b) == length(b_y)))

      pdist <- sqrt((outer(a_x, b_x, "-")^2) + (outer(a_y, b_y, "-")^2))
      w <- exp(-pdist / sf)
      c(sum(w * outer(a, b, "*")), sum(w))
    },
    ...
  )
}

.eop <- eop_seq
.eopi <- eopi_seq
.build_index <- build_index_seq
.par_enable <- FALSE

usci_par_enabled <- function() .par_enable

#' build spatial index
#'
#' build a spatial index (specifically an R*-tree, using [`rstar`](https://docs.rs/rstar/latest/rstar)).
#'
#' this is useful for efficient approximation of a spatial correlation metric by only including proximal neighbours, see [asci].
#'
#' @param x x-axis coordinates
#' @param y y-axis coordinates
#' @export
#' @returns spatial index (used by [asci], should otherwise be treated as an opaque pointer)
build_index <- function(x, y) {
  stopifnot(length(x) == length(y)) # x and y must have the same length

  .build_index(x, y)
}

#' `usci`
#'
#' untitled spatial correlation implementation
#'
#' @usage usci(a, b, a_x, a_y, b_x, b_y, scale_fact)
#'
#' @param a vector of values for observation set \eqn{A}
#' @param b vector of values for observation set \eqn{B}
#' @param a_x x-axis coordinates for observation set \eqn{A}
#' @param a_y y-axis coordinates for observation set \eqn{A}
#' @param b_x x-axis coordinates for observation set \eqn{B}
#' @param b_y y-axis coordinates for observation set \eqn{B}
#' @param scale_fact scale factor for negative exponential kernel
#' @returns spatial correlation metric \eqn{c}
#' @export
#' @examples
#' set.seed(8)
#'
#' a_n <- 128
#' b_n <- 256
#'
#' a <- rpois(a_n, runif(1, 0, 32))
#' a_x <- rnorm(a_n)
#' a_y <- rnorm(a_n)
#'
#' b <- rpois(b_n, runif(1, 0, 32))
#' b_x <- rnorm(b_n)
#' b_y <- rnorm(b_n)
#'
#' usci(a, b, a_x, a_y, b_x, b_y, 1e-1)
usci <- function(...) usci_dbl_impl(fn = .eop, ...)

#' `asci`
#'
#' approximate spatial correlation implementation
#'
#' @usage asci(a, b, a_x, a_y, b_index, scale_fact, err = 1e-8)
#'
#' @param a vector of values for observation set \eqn{A}
#' @param b vector of values for observation set \eqn{B}
#' @param a_x x-axis coordinates for observation set \eqn{A}
#' @param a_y y-axis coordinates for observation set \eqn{A}
#' @param b_index spatial index for observation set \eqn{B} (see [build_index])
#' @param scale_fact scale factor for negative exponential kernel
#' @param err error term in approximation, s.t.
#'  for all observation in sets \eqn{A} and \eqn{B}
#'  only consider observation pairs \eqn{a}, \eqn{b} such that:
#'
#'  \eqn{e^{\frac{-d(a, b)}{s}} \geq \epsilon} (or rephrased: \eqn{d(a, b) \leq -ln(\epsilon) * s})
#'
#'  where:
#'    - \eqn{d} is euclidian distance between observation \eqn{a} and \eqn{b}
#'    - \eqn{s} is the scale factor
#'    - \eqn{\epsilon} is the error term
#' @returns (approximate) spatial correlation metric \eqn{c}
#' @export
#' @examples
#' set.seed(8)
#'
#' a_n <- 128
#' b_n <- 256
#'
#' a <- rpois(a_n, runif(1, 0, 32))
#' a_x <- rnorm(a_n)
#' a_y <- rnorm(a_n)
#'
#' b <- rpois(b_n, runif(1, 0, 32))
#' b_x <- rnorm(b_n)
#' b_y <- rnorm(b_n)
#'
#' b_idx <- build_index(b_x, b_y)
#'
#' asci(a, b, a_x, a_y, b_idx, 1e-1)
asci <- function(...) usci_dbl_impl(fn = .eopi, ...)

#' enable/disable parallelism
#'
#' enable or disable parallelism use across usci library (when enabled uses [`rayon`](https://docs.rs/rayon/latest/rayon)).
#'
#' note:
#'  to set the exact number of threads used when parallelism is enabled the
#'  [`RAYON_NUM_THREADS`](https://github.com/rayon-rs/rayon/blob/main/FAQ.md#how-many-threads-will-rayon-spawn)
#'  environment variable needs to be set ***prior*** to loading the usci library
#'
#' @param enable boolean flag to indicate if parallelism should be enabled
#' @returns NULL
#' @export
#' @examples
#' enable_par() # enables parallelization in package
#'
#' enable_par(FALSE) # disables parallelization
enable_par <- function(enable = TRUE) {
  if (enable) {
    utils::assignInMyNamespace(".eop", eop_par) # nolint: object_usage_linter
    utils::assignInMyNamespace(".eopi", eopi_par) # nolint: object_usage_linter
    utils::assignInMyNamespace(".par_enable", TRUE) # nolint: object_usage_linter
  } else {
    utils::assignInMyNamespace(".eop", eop_seq) # nolint: object_usage_linter
    utils::assignInMyNamespace(".eopi", eopi_seq) # nolint: object_usage_linter
    utils::assignInMyNamespace(".par_enable", FALSE) # nolint: object_usage_linter
  }
}
