# Benchmarking scripts for PS

## Requirements

- `psc` compiled with profiling like so:

  ```sh
  stack build --executable-profiling --library-profiling --ghc-options="-fprof-auto -rtsopts" 
  stack build --copy-bins
  ```

- `imagemagick` for converting the heap capture images to jpg (in particular the
  `convert` utility)

## Running

After cloning the submodules:

```sh
stack build && stack exec -- ps-bench
```

On subsequent runs add the `-d` flag to not reinstall the dependencies with
bower all the time.

The benchmarking results can be found inside the respective project directories
as `psc.prof` and (if a heap capture was chosen) `image.jpg`.

## Tweaking the bench script

Inside `Bench.hs`, either modify the existing `BenchTarget`s or add new ones.
Remember to also add or comment out `benchRun`s inside `main` as needed.

