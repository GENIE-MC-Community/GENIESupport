# Tags

## Checking out a tag

When first checking out this package, you will have the `HEAD` version of the
`master` branch. Get a specific tagged release by checking out the tag into a
branch like so:

    git checkout -b R-2_8_6.2-br R-2_8_6.2

This will checkout _tag_ `R-2_8_6.2` into _branch_ `R-2_8_6.2-br`. You want to
checkout into a branch so you are not in a "detached `HEAD`" state.


## Current tags

* `R-2_8_6.1`: Compliant with GENIE 2.8.6; builds 
[RooMUHistos](https://github.com/ManyUniverseAna/RooMUHistos) using the `HEAD`
of `master` correctly.
* `R-2_8_6.2`: Add a verbose flag to also print log info to stdout; check for 
exit codes when building packages and exit if they fail.
