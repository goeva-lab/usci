# configure parallelism

enable or disable parallelism use across usci library (when enabled uses
[`rayon`](https://docs.rs/rayon/latest/rayon)).

## Usage

``` r
set_par(enable = TRUE)

get_par()
```

## Arguments

- enable:

  boolean flag to indicate if parallelism should be enabled

## Details

note: to set the exact number of threads used when parallelism is
enabled the
[`RAYON_NUM_THREADS`](https://github.com/rayon-rs/rayon/blob/main/FAQ.md#how-many-threads-will-rayon-spawn)
environment variable needs to be set ***prior*** to loading the usci
library

## Examples

``` r
curr_par_stat <- get_par()
curr_par_stat # view current parallelization configuration
#> [1] FALSE

set_par(!curr_par_stat) # change parallelization in package
get_par()
#> [1] TRUE

set_par(curr_par_stat)
get_par()
#> [1] FALSE
```
