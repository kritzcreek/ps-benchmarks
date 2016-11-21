#!/usr/bin/env stack
-- stack --install-ghc runghc --package turtle

{-# LANGUAGE OverloadedStrings #-}

import Turtle

import Control.Monad
import qualified Data.Text as T

data HeapCapture = HC | HY

data BenchTarget = BenchTarget
  { name :: Turtle.FilePath
  , globs :: [Text]
  , heapProfiles :: [HeapCapture]
  }

benchRun :: BenchTarget -> IO ()
benchRun bt = do
  echo ("Benchmarking: " <> T.pack (show (name bt)))
  cd (name bt)

  rmBowerComponents
  rmOutput
  bowerInstall

  proc "psc" (map quote (globs bt) <> ["+RTS", "-p", "-RTS"]) mempty

  return ()

quote s = "\"" <> s <> "\""

rmBowerComponents =
  whenM (testdir "bower_components") (rmtree "bower_components")

rmOutput =
  whenM (testdir "output") (rmtree "output")

bowerInstall =
  shell "bower install" mempty

pscid :: BenchTarget
pscid = BenchTarget
  { name = "pscid"
  , globs = ["src/**/*.purs", "bower_components/purescript-*/src/**/*.purs"]
  , heapProfiles = []
  }

whenM x f = do
  a <- x
  when a f

main = do
  echo "Benchmark some shit yo."
  benchRun pscid


-- Command to build psc with profiling:
-- stack build --executable-profiling --library-profiling --ghc-options="-fprof-auto -rtsopts"

-- convert -density 600 results-master/pscid-hc.ps image.jpg

-- ### PSCID
-- pushd pscid
-- rm -r bower_components output
-- bower install
-- psc "src/**/*.purs" "bower_components/purescript-*/src/**/*.purs" +RTS -p
-- rm -r output
-- mv psc.prof ../results/pscid.prof
--
-- psc "src/**/*.purs" "bower_components/purescript-*/src/**/*.purs" +RTS -p -hc
-- rm -r output
-- hp2ps -c psc.hp
-- mv psc.ps ../results/pscid-hc.ps
--
-- psc "src/**/*.purs" "bower_components/purescript-*/src/**/*.purs" +RTS -p -hy
-- rm -r output
-- hp2ps -c psc.hp
-- mv psc.ps ../results/pscid-hy.ps
-- popd
