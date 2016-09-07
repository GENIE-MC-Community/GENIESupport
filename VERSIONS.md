# Tags

## Checking out a tag

When first checking out this package, you will have the `HEAD` version of the
`master` branch. Get a specific tagged release by checking out the tag into a
branch like so:

    git checkout -b R-2_11_0.0-br R-2_11_0.0

This will checkout _tag_ `R-2_11_0.0` into _branch_ `R-2_11_0.0-br`. You want
to checkout into a branch so you are not in a "detached `HEAD`" state.


## Current tags

* `R-2_11_0.0`: Change ROOT build system to use CMake by default. We
currently assume ROOT requires CMake 2.9 or greater and if it is not
available in the PATH, we additionally check out and build CMake from
scratch.
* `R-2_10_10.0`: Enable minuit2 when building ROOT. Also turn off debug
builds by default - users should now add a `-d/--debug` flag to build
with debugging symbols (impacts Pythia8 (not used yet) and ROOT).
* `R-2_10_6.0`: Use GitHub now to store Pythia6 files.
* `R-2_10_2.0`: Optional disabling of RooMUHistos and fix for LHAPDF 5.9 on
gcc 5.
* `R-2_9_0.1`: Bugfix patch to `R-2_9_0.0` that correctly sets the `$GSLINC`
environment variable.
* `R-2_9_0.0`: Minor changes to `R-2_8_6.3`. Intended for use with GENIE 2.9.0.
* `R-2_8_6.3-no-LHAPDF6`: Minor changes to `R-2_8_6.3`; No longer supporting
building LHAPDF6 and Boost.
* `R-2_8_6.3-last-LHAPDF6`: Minor changes to `R-2_8_6.3` (new command argument
parsing, documentation); Last tag to support building LHAPDF6 and Boost.
* `R-2_8_6.3`: Add a test script to check a few different build permutations 
and flags.
* `R-2_8_6.2`: Add a verbose flag to also print log info to stdout; check for 
exit codes when building packages and exit if they fail.
* `R-2_8_6.1`: Compliant with GENIE 2.8.6; builds 
[RooMUHistos](https://github.com/ManyUniverseAna/RooMUHistos) using the `HEAD`
of `master` correctly.
