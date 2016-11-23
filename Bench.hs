{-# LANGUAGE OverloadedStrings #-}

module Main where

import Turtle

import Control.Monad
import Control.Applicative
import qualified Data.Text as T

data HeapCapture = HC | HY

hcToString :: HeapCapture -> Text
hcToString hc = case hc of
  HC -> "-hc"
  HY -> "-hy"

data BenchTarget = BenchTarget
  { name :: Turtle.FilePath
  , globs :: [Text]
  , heapProfiles :: [HeapCapture]
  }

benchRun :: Bool -> BenchTarget -> IO ()
benchRun noDeps bt = do
  echo ("Benchmarking: " <> T.pack (show (name bt)))
  cd (name bt)

  rmOutput
  unless noDeps (rmBowerComponents <* bowerInstall)

  -- psc (globs bt) Nothing
  psc (globs bt) (Just HC)
  hp2ps "psc.hp"
  convert "psc.ps" "image.jpg"

  return ()

psc globs' hc = do
  proc "psc" (globs' <> ["+RTS", "-p", maybe "" hcToString hc , "-RTS"]) empty
  rmOutput

rmBowerComponents =
  whenM (testdir "bower_components") (rmtree "bower_components")

rmOutput =
  whenM (testdir "output") (rmtree "output")

bowerInstall =
  shell "bower install" empty

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
  echo "Benchmarking..."
  opts <- options "Options for benchmarking" parser
  benchRun opts pscid

hp2ps i =
  proc "stack" (["exec", "--", "hp2ps", "-c", i]) empty

convert i o =
  proc "convert" (["-density", "600", i, o]) empty

parser :: Parser Bool
parser = switch "no-deps" 'd' "Whether to not reinstall bower dependencies"

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
