# enable/disable parallelism

enable or disable parallelism use across usci library (when enabled uses
[`rayon`](https://docs.rs/rayon/latest/rayon)).

## Usage

``` r
enable_par(enable = TRUE)
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
enable_par() # enables parallelization in package

enable_par(FALSE) # disables parallelization
```
