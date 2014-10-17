# Basic Usage

This script will install the required third party packages to build GENIE 
from source. It has been thoroughly tested on Scientific Linux 5 only. Some
users have had success on Ubuntu, but read the trouble-shooting section
carefully.

Running the script with no arguments will produce the help menu:

    Usage: ./build_support -<flag>
                           -p  #  : Build Pythia 6 or 8 and link ROOT to it (required).
                           -r tag : Which ROOT version (default = v5-34-08).
                           -n     : Run configure, build, etc. under nice.
                           -m     : Build using "make" instead of "gmake".
                           -f     : Archive build directories and start fresh.
                           -s     : Use https to check out from GitHub (default is ssh)
     
      Examples:  
        ./build_supprt -p 6
        ./build_supprt -p 8 -r v5-34-12

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
