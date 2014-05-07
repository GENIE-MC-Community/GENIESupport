#Basic Usage

This script will install the required third party packages to build GENIE 
from source. It has been lightly test on Scientific Linux 5 only.

Running the script with no arguments will produce the help menu:

    Usage: ./build_support -<flag>
                           -p  #  : Build Pythia 6 or 8 and link ROOT to it (required).
                           -r tag : Which ROOT version (default = v5-34-08).
                           -n     : Run configure, build, etc. under nice.
     
      Examples:  
        ./build_supprt -p 6
        ./build_supprt -p 8 -r v5-34-12

#Trouble-Shooting

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
