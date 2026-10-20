# `usci`

untitled spatial correlation implementation

## Usage

``` r
usci(a, b, a_x, a_y, b_x, b_y, scale_fact)
```

## Arguments

- a:

  vector of values for observation set \\A\\

- b:

  vector of values for observation set \\B\\

- a_x:

  x-axis coordinates for observation set \\A\\

- a_y:

  y-axis coordinates for observation set \\A\\

- b_x:

  x-axis coordinates for observation set \\B\\

- b_y:

  y-axis coordinates for observation set \\B\\

- scale_fact:

  scale factor for negative exponential kernel

## Value

spatial correlation metric \\c\\

## Examples

``` r
set.seed(8)

a_n <- 128
b_n <- 256

a <- rpois(a_n, runif(1, 0, 32))
a_x <- rnorm(a_n)
a_y <- rnorm(a_n)

b <- rpois(b_n, runif(1, 0, 32))
b_x <- rnorm(b_n)
b_y <- rnorm(b_n)

usci(a, b, a_x, a_y, b_x, b_y, 1e-1)
#> [1] 0.03093763
```
