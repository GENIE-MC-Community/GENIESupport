# READ ME FIRST!

It is a good idea to use a tagged version of GENIESupport. The latest
recommended tag is `R-2_9_0.0`. Use the following command to check
it out (and read below for more if you're really interested). After
cloning the repository, `cd` into the `GENIESupport` directory and
run:

    git checkout -b R-2_9_0.0-br R-2_9_0.0

Run `./build_support.sh -h` to get a help menu. If you run into trouble,
please consult the "Trouble-Shooting" section below. If you find a 
bug, please feel free to contact Gabe Perdue (`perdue` at Fermilab)
or open an issue on [GitHub](https://github.com/GENIEMC/GENIESupport).

## Basic Usage

This script will install the required third party packages to build GENIE 
from source. It has been thoroughly tested on Scientific Linux 5 only. Some
users have had success on Ubuntu, but read the trouble-shooting section
carefully.

Running the script with no arguments will produce the help menu:

    Usage: ./build_support.sh -<flag>
                       -h / --help     : print the help menu
                       -p / --pythia # : Pythia 6 or 8 and link ROOT to it (required).
                       -r / --root tag : Which ROOT version (default = v5-34-24).
                       -n / --nice     : Run configure, build, etc. under nice.
                       -c / --force    : Archive current build and start fresh.
                       -s / --https    : Use https for GitHub checkout (default is ssh)
                       -v / --verbose  : Print logging data to stdout during installation
     
      Examples:  
        ./build_support.sh                   # do nothing; print the help menu
        ./build_support.sh -h                # do nothing; print the help menu
        ./build_support.sh --help            # do nothing; print the help menu
        ./build_support.sh -p 6              # build Pythia 6, gmake, ssh checkout, ROOT v5-34-24
        ./build_support.sh -p 6 -v           # same with verbose logging
        ./build_support.sh -p 6 -v -n        # same building under "nice"
        ./build_support.sh --pythia 6
        ./build_support.sh -p 8 -r v5-34-18

## Tags and versioning

When first checking out this package, you will have the `HEAD` version of the
`master` branch. Get a specific tagged release by checking out the tag into a
branch like so:

    git checkout -b R-2_9_0.0-br R-2_9_0.0

This will checkout _tag_ `R-2_9_0.0` into _branch_ `R-2_9_0.0-br`. You want to
checkout into a branch so you are not in a "detached `HEAD`" state.

## Trouble-Shooting

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

Finally, the default checkout method for packages living in GitHub is
ssh (because it was easier for me to configure at Fermilab). If you run
into "permission denied" errors, try using the `https` checkout flag,
`-s` and see if that works.

## Contributors

* Gabriel Perdue,  [Fermilab](http://www.fnal.gov)
* Julia Yarba,     [Fermilab](http://www.fnal.gov)
* Ryan Hill,       [Queen Mary University of London](http://www.qmul.ac.uk)
* Martti Nirkko,   [University of Bern](http://www.unibe.ch/eng/)
