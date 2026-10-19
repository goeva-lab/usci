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
  tfh <- function(e) {
    if (e) {
      expect_true(usci_par_enabled())
      expect_true(identical(environment(usci)[[".eop"]], eop_par))
      expect_true(identical(environment(asci)[[".eopi"]], eopi_par))
    } else {
      expect_false(usci_par_enabled())
      expect_true(identical(environment(usci)[[".eop"]], eop_seq))
      expect_true(identical(environment(asci)[[".eopi"]], eopi_seq))
    }
  }

  test_that("enable_par works", {
    par_stat <- usci_par_enabled()

    tfh(par_stat)
    enable_par(!par_stat)
    tfh(!par_stat)
    enable_par(par_stat)
    tfh(par_stat)
  })
})
