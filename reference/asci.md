# `asci`

approximate spatial correlation implementation

## Usage

``` r
asci(a, b, a_x, a_y, b_index, scale_fact, err = 1e-8)
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

- b_index:

  spatial index for observation set \\B\\ (see
  [build_index](build_index.md))

- scale_fact:

  scale factor for negative exponential kernel

- err:

  error term in approximation, s.t. for all observation in sets \\A\\
  and \\B\\ only consider observation pairs \\a\\, \\b\\ such that:

  \\e^{\frac{-d(a, b)}{s}} \geq \epsilon\\ (or rephrased: \\d(a, b) \leq
  -ln(\epsilon) \* s\\)

  where:

  - \\d\\ is euclidian distance between observation \\a\\ and \\b\\

  - \\s\\ is the scale factor

  - \\\epsilon\\ is the error term

## Value

(approximate) spatial correlation metric \\c\\

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

b_idx <- build_index(b_x, b_y)

asci(a, b, a_x, a_y, b_idx, 1e-1)
#> [1] 0.03093763
```
