withr::with_envvar(
  c(RUSTFLAGS = "-C target-cpu=native"),
  pkgload::load_all(compile = TRUE, debug = FALSE)
)

a_n <- 1024
b_n <- 2048

a <- rnbinom(a_n, mu = runif(1, 0, 32), size = runif(1, 1 / 32, 32))
a_x <- rnorm(a_n, runif(8, -4, 4), runif(8, 0, 2))
a_y <- rnorm(a_n, runif(8, -4, 4), runif(8, 0, 2))

b <- rnbinom(b_n, mu = runif(1, 0, 32), size = runif(1, 1 / 32, 32))
b_x <- rnorm(b_n, runif(8, -4, 4), runif(8, 0, 2))
b_y <- rnorm(b_n, runif(8, -4, 4), runif(8, 0, 2))

b_idx <- build_index(b_x, b_y)
idx_build <- bench::mark(build_index(b_x, b_y))

bench_seq <- bench::press(
  sf = c(1e-2, 1e-1, 1),
  bench::mark(
    usci(a, b, a_x, a_y, b_x, b_y, sf),
    asci(a, b, a_x, a_y, b_idx, sf),
    check = function(ref, approx) abs(ref - approx) <= abs(ref) * 1e-4
  )
)

enable_par()

bench_par <- bench::press(
  sf = c(1e-2, 1e-1, 1),
  bench::mark(
    usci(a, b, a_x, a_y, b_x, b_y, sf),
    asci(a, b, a_x, a_y, b_idx, sf),
    check = function(ref, approx) abs(ref - approx) <= abs(ref) * 1e-4
  )
)
