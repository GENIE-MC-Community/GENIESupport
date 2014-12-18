# Basic Usage

This script will install the required third party packages to build GENIE 
from source. It has been thoroughly tested on Scientific Linux 5 only. Some
users have had success on Ubuntu, but read the trouble-shooting section
carefully.

Running the script with no arguments will produce the help menu:

    Usage: ./build_support -<flag>
                       -h / --help     : print the help menu
                       -p / --pythia # : Pythia 6 or 8 and link ROOT to it (required).
                       -r / --root tag : Which ROOT version (default = v5-34-24).
                       -n / --nice     : Run configure, build, etc. under nice.
                       -m / --make     : Use "make" instead of "gmake" to build.
                       -f / --force    : Archive current build and start fresh.
                       -s / --https    : Use https for GitHub checkout (default is ssh)
                       -v / --verbose  : Print logging data to stdout during installation
     
      Examples:  
        ./build_support                   # do nothing; print the help menu
        ./build_support -h                # do nothing; print the help menu
        ./build_support --help            # do nothing; print the help menu
        ./build_support -p 6              # build Pythia 6, gmake, ssh checkout, ROOT v5-34-24
        ./build_support -p 6 -v           # same with verbose logging
        ./build_support -p 6 -v -n        # same building under "nice"
        ./build_support --pythia 6
        ./build_support -p 8 -r v5-34-18

## Tags and versioning

When first checking out this package, you will have the `HEAD` version of the
`master` branch. Get a specific tagged release by checking out the tag into a
branch like so:

    git checkout -b R-2_8_6.3-br R-2_8_6.3

This will checkout _tag_ `R-2_8_6.3` into _branch_ `R-2_8_6.3-br`. You want to
checkout into a branch so you are not in a "detached `HEAD`" state.

# Trouble-Shooting

This is a bash script, so some errors will likely occur under different
shells. If you get errors, make sure `/bin/bash` exists and is not a 
link to a different executable.

If there is a strong desire for a c-shell or some other version of this 
script, we welcome a translation!

If you are having trouble installing some items (especially log4cpp) it 
is possible you are missing the autoconf tools. In that case, you can 
install them with a package manager:

* `sudo apt-get install autoconf` (Ubuntu)
* `yum install autoconf` (RedHat/SLF)
* Download source from [GNU](http://ftp.gnu.org/gnu/autoconf/) and build.
* etc.

It is possible that there is a problem with `make` vs. `gmake` on your 
system. If you find cryptic error messages associated with libtool and 
autoconf while attempting to build log4cpp, you may chose to try make
in place of gmake.

Finally, the default checkout method for packages living in GitHub is
ssh (because it was easier for me to configure at Fermilab). If you run
into "permission denied" errors, try using the `https` checkout flag,
`-s` and see if that works.

# To-Do

Build support is included for LHAPDF 6, but installation flags are not
exposed yet. We need to settle on a new PDF set first.

## Contributors

* Gabriel Perdue,  [Fermilab](http://www.fnal.gov)
* Julia Yarba,     [Fermilab](http://www.fnal.gov)

