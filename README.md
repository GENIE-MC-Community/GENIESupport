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

