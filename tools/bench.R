withr::with_envvar(
  c(RUSTFLAGS = "-C target-cpu=native"),
  pkgload::load_all(compile = TRUE, debug = FALSE)
)

bhf <- function(n, sf, seed, iters) {
  bench::press(
    n = n,
    sf = sf,
    seed = seed,

    local({
      set.seed(seed * n)

      a_n <- n
      b_n <- n

      a <- rnbinom(a_n, mu = runif(1, 0, 32), size = runif(1, 1 / 32, 32))
      a_x <- rnorm(a_n, runif(8, -4, 4), runif(8, 0, 2))
      a_y <- rnorm(a_n, runif(8, -4, 4), runif(8, 0, 2))

      b <- rnbinom(b_n, mu = runif(1, 0, 32), size = runif(1, 1 / 32, 32))
      b_x <- rnorm(b_n, runif(8, -4, 4), runif(8, 0, 2))
      b_y <- rnorm(b_n, runif(8, -4, 4), runif(8, 0, 2))

      b_idx <- build_index(b_x, b_y)

      bench::mark(
        usci_ref(a, b, a_x, a_y, b_x, b_y, sf),
        usci(a, b, a_x, a_y, b_x, b_y, sf),
        asci(a, b, a_x, a_y, b_idx, sf),
        check = function(ref, approx) abs(ref - approx) <= abs(ref) * 1e-4,
        iterations = iters
      )
    })
  )
}

bench_seq <- bhf((1:8) * 1000, c(1e-2, 1e-1, 1), 1:4, 8)

set_par(TRUE)

bench_par <- bhf((1:8) * 1000, c(1e-2, 1e-1, 1), 1:4, 8)
