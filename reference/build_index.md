# build spatial index

build a spatial index (specifically an R\*-tree, using
[`rstar`](https://docs.rs/rstar/latest/rstar)).

## Usage

``` r
build_index(x, y)
```

## Arguments

- x:

  x-axis coordinates

- y:

  y-axis coordinates

## Value

spatial index (used by [asci](asci.md), should otherwise be treated as
an opaque pointer)

## Details

this is useful for efficient approximation of a spatial correlation
metric by only including proximal neighbours, see [asci](asci.md).
