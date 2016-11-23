{-# LANGUAGE OverloadedStrings #-}

module Main where

import Turtle

import Control.Monad
import Control.Applicative
import Data.Maybe (isJust)
import qualified Data.Text as T

{-

Command to build psc with profiling:
stack build --executable-profiling --library-profiling --ghc-options="-fprof-auto -rtsopts" && stack install

-}

-- ==============================================================
-------------------------- Tweak here ---------------------------
-- ==============================================================

pscid :: BenchTarget
pscid = BenchTarget
  { name = "pscid"
  , globs = ["src/**/*.purs", "bower_components/purescript-*/src/**/*.purs"]
  , heapProfile = Just HC
  }

halogen :: BenchTarget
halogen = BenchTarget
  { name = "purescript-halogen"
  , globs = ["src/**/*.purs", "bower_components/purescript-*/src/**/*.purs"]
  , heapProfile = Just HC
  }

slamdata :: BenchTarget
slamdata = BenchTarget
  { name = "slamdata"
  , globs = ["src/**/*.purs", "bower_components/purescript-*/src/**/*.purs"]
  -- heap capture is turned off for slamdata, because it takes forever...
  , heapProfile = Nothing
  }

main = do
  echo "Benchmarking..."
  opts <- options "Options for benchmarking" parser
  benchRun opts pscid
  benchRun opts halogen
  benchRun opts slamdata

-- ==============================================================

data HeapCapture = HC | HY

hcToString :: HeapCapture -> Text
hcToString hc = case hc of
  HC -> "-hc"
  HY -> "-hy"

data BenchTarget = BenchTarget
  { name :: Turtle.FilePath
  , globs :: [Text]
  , heapProfile :: Maybe HeapCapture
  }

benchRun :: Bool -> BenchTarget -> IO ()
benchRun noDeps bt = do
  echo ("Benchmarking: " <> T.pack (show (name bt)))
  pwd' <- pwd
  cd (name bt)

  rmOutput
  unless noDeps (rmBowerComponents <* bowerInstall)

  psc (globs bt) (heapProfile bt)
  when (isJust (heapProfile bt)) $ do
    hp2ps "psc.hp"
    convert "psc.ps" "image.jpg"
    pure ()

  cd pwd'
  pure ()

psc globs' hc = do
  proc "psc" (globs' <> ["+RTS", "-p"] <> maybe [] (pure . hcToString) hc <> ["-RTS"]) empty
  rmOutput

rmBowerComponents =
  whenM (testdir "bower_components") (rmtree "bower_components")

rmOutput =
  whenM (testdir "output") (rmtree "output")

bowerInstall =
  shell "bower install" empty

whenM x f = do
  a <- x
  when a f

hp2ps i =
  proc "stack" (["exec", "--", "hp2ps", "-c", i]) empty

convert i o =
  proc "convert" (["-density", "600", i, o]) empty

parser :: Parser Bool
parser = switch "no-deps" 'd' "Whether to not reinstall bower dependencies"

