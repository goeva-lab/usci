local({
  for (seed in c(2, 4, 8, 16, 32)) {
    set.seed(seed)

    a_n <- sample(128:256, 1)
    b_n <- sample(256:512, 1)

    a <- rnbinom(a_n, mu = runif(1, 0, 32), size = runif(1, 1 / 32, 32))
    a_x <- rnorm(a_n, runif(8, -4, 4), runif(8, 0, 2))
    a_y <- rnorm(a_n, runif(8, -4, 4), runif(8, 0, 2))

    b <- rnbinom(b_n, mu = runif(1, 0, 32), size = runif(1, 1 / 32, 32))
    b_x <- rnorm(b_n, runif(8, -4, 4), runif(8, 0, 2))
    b_y <- rnorm(b_n, runif(8, -4, 4), runif(8, 0, 2))

    for (scale_fact in c(1e-2, 1e-1, 1)) {
      fts <- function(x) sprintf("%s (seed=%s, scale_fact=%g)", x, seed, scale_fact)

      test_that(
        fts("usci and reference match"),
        expect_equal(
          usci(a, b, a_x, a_y, b_x, b_y, scale_fact),
          usci_ref(a, b, a_x, a_y, b_x, b_y, scale_fact)
        )
      )

      test_that(
        fts("usci output is invariant to input order"),
        expect_equal(
          usci(b, a, b_x, b_y, a_x, a_y, scale_fact),
          usci(a, b, a_x, a_y, b_x, b_y, scale_fact)
        )
      )

      test_that(
        fts("eop_seq & eop_par implementations match"),
        expect_equal(
          (function(...) usci_dbl_impl(eop_par, ...))(b, a, b_x, b_y, a_x, a_y, scale_fact),
          (function(...) usci_dbl_impl(eop_seq, ...))(a, b, a_x, a_y, b_x, b_y, scale_fact)
        )
      )

      b_idx <- build_index(b_x, b_y)
      test_that(
        fts("asci & usci approximately match"),
        expect_equal(
          asci(a, b, a_x, a_y, b_idx, scale_fact),
          usci(a, b, a_x, a_y, b_x, b_y, scale_fact),
          tolerance = 1e-4
        )
      )
      a_idx <- build_index(a_x, a_y)
      test_that(
        fts("asci output is invariant to input order"),
        expect_equal(
          asci(b, a, b_x, b_y, a_idx, scale_fact),
          asci(a, b, a_x, a_y, b_idx, scale_fact)
        )
      )

      test_that(
        fts("eopi_seq & eopi_par implementations match"),
        expect_equal(
          (function(...) usci_dbl_impl(eopi_par, ...))(a, b, a_x, a_y, b_idx, scale_fact),
          (function(...) usci_dbl_impl(eopi_seq, ...))(a, b, a_x, a_y, b_idx, scale_fact)
        )
      )
    }
  }
})

local({
  thf <- function(fn) {
    expect_error(
      fn(c(2), c(4, 8), c(16, 32), c(64, 128), c(256, 512), c(1024, 2048), 4096),
      "a, a_x, and a_y must have the same length",
      fixed = TRUE
    )
    expect_error(
      fn(c(1, 2), c(4, 8), c(32), c(64, 128), c(256, 512), c(1024, 2048), 4096),
      "a, a_x, and a_y must have the same length",
      fixed = TRUE
    )
    expect_error(
      fn(c(1, 2), c(4, 8), c(16, 32), c(128), c(256, 512), c(1024, 2048), 4096),
      "a, a_x, and a_y must have the same length",
      fixed = TRUE
    )
    expect_error(
      fn(c(1, 2), c(8), c(16, 32), c(64, 128), c(256, 512), c(1024, 2048), 4096),
      "b, b_x, and b_y must have the same length",
      fixed = TRUE
    )
    expect_error(
      fn(c(1, 2), c(4, 8), c(16, 32), c(64, 128), c(512), c(1024, 2048), 4096),
      "b, b_x, and b_y must have the same length",
      fixed = TRUE
    )
    expect_error(
      fn(c(1, 2), c(4, 8), c(16, 32), c(64, 128), c(256, 512), c(2048), 4096),
      "b, b_x, and b_y must have the same length",
      fixed = TRUE
    )
  }
  test_that("eop_seq validates inputs properly", thf(eop_seq))
  test_that("eop_par validates inputs properly", thf(eop_par))
})

test_that("build_index validates inputs properly", {
  expect_error(build_index(c(1, 2), c(4)), "length(x) == length(y) is not TRUE", fixed = TRUE)
  expect_error(build_index(c(2), c(4, 8)), "length(x) == length(y) is not TRUE", fixed = TRUE)
})

local({
  thf <- function(fn) {
    expect_error(
      fn(c(2), c(4, 8), c(16, 32), c(64, 128), build_index(c(256, 512), c(1024, 2048)), 4096),
      "a, a_x, and a_y must have the same length",
      fixed = TRUE
    )
    expect_error(
      fn(c(1, 2), c(4, 8), c(32), c(64, 128), build_index(c(256, 512), c(1024, 2048)), 4096),
      "a, a_x, and a_y must have the same length",
      fixed = TRUE
    )
    expect_error(
      fn(c(1, 2), c(4, 8), c(16, 32), c(128), build_index(c(256, 512), c(1024, 2048)), 4096),
      "a, a_x, and a_y must have the same length",
      fixed = TRUE
    )
    expect_error(
      fn(c(1, 2), c(8), c(16, 32), c(64, 128), build_index(c(256, 512), c(1024, 2048)), 4096),
      "b and b_index must have the length",
      fixed = TRUE
    )
    expect_error(
      fn(c(1, 2), c(4, 8), c(16, 32), c(64, 128), build_index(c(256), c(1024)), 4096),
      "b and b_index must have the length",
      fixed = TRUE
    )
  }
  test_that("eopi_seq validates inputs properly", thf(eopi_seq))
  test_that("eopi_par validates inputs properly", thf(eopi_par))
})

test_that("set_par works", {
  thf <- function(e) {
    if (e) {
      expect_true(get_par())
      expect_true(identical(environment(usci)[[".eop"]], eop_par))
      expect_true(identical(environment(asci)[[".eopi"]], eopi_par))
    } else {
      expect_false(get_par())
      expect_true(identical(environment(usci)[[".eop"]], eop_seq))
      expect_true(identical(environment(asci)[[".eopi"]], eopi_seq))
    }
  }

  par_conf <- get_par()

  thf(par_conf)
  set_par(!par_conf)
  thf(!par_conf)
  set_par(par_conf)
  thf(par_conf)
})
