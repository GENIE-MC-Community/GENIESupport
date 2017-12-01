#!/bin/bash

# how to use the script
help()
{
    mybr
    cat <<EOF
Usage: ./build_support -<flag>
                   -h / --help     : print the help menu
                   -p / --pythia # : Pythia 6 or 8 and link ROOT to it (required).
                   -r / --root tag : Which ROOT version (default = v5-34-24).
                   -n / --nice     : Run configure, build, etc. under nice.
                   -c / --force    : Archive current build and start fresh.
                   -s / --https    : Use https for GitHub checkout (default is ssh)
                   -v / --verbose  : Print logging data to stdout during installation
                   -d / --debug    : Build with debugging symbols (in Pythia8 and ROOT)
                   --no-roomu      : build without RooMUHistos
 
  Examples:  
    ./build_support                   # do nothing; print the help menu
    ./build_support -h                # do nothing; print the help menu
    ./build_support --help            # do nothing; print the help menu
    ./build_support -p 6              # build Pythia 6, gmake, ssh checkout, ROOT v5-34-24
    ./build_support -p 6 -v           # same with verbose logging
    ./build_support -p 6 -v -n        # same building under \"nice\"
    ./build_support --pythia 6
    ./build_support -p 8 -r v5-34-18
EOF
    mybr
    echo " "
}

# Users need to edit this list by hand...
PDFLIST="GRV98lo.LHgrid GRV98nlo.LHgrid"

# what are the names of the code archives? we get ROOT
# from CERN's Git repos. log4cpp is "special" because
# we can't curl it (I think - maybe someone can).
PYTHIASRC=pythia8183.tgz          # only if we use Pythia8.
GSLSRC=gsl-2.3.tar.gz
ROOTTAG="v5-34-36"
LOG4CPPSRC=log4cpp-1.1.1.tar.gz       
LHAPDFSRC=lhapdf-5.9.1.tar.gz
LHAPDFMAJOR=`echo $LHAPDFSRC | cut -c8-8` # expecting 'lhapdf-M.', etc.
CMAKEDIR=cmake-3.6.1
CMAKESRC=${CMAKEDIR}.tar.gz
NEWCMAKE_MAJOR=`echo $CMAKEDIR | cut -c7-7`  # expecting cmake-j.n.p
NEWCMAKE_MINOR=`echo $CMAKEDIR | cut -c9-9`  # expecting cmake-j.n.p
CMAKE_URL="https://cmake.org/files/v${NEWCMAKE_MAJOR}.${NEWCMAKE_MINOR}/"

ENVFILE="environment_setup.sh"

# command line arg options
MAKE=make                # This might need to `gmake`?
MAKENICE=0               # make under nice?
HELPFLAG=0               # show the help block (if non-zero)
FORCEBUILD=0             # non-zero will archive existing packages and rebuild
PYTHIAVER=-1             # must eventually be either 6 or 8
HTTPSCHECKOUT=0          # use https checkout if non-zero (otherwise ssh)
VERBOSE=0                # send logging data to stdout also
USE_CMAKE_FOR_ROOT="yes" # use CMake to build ROOT
DEBUG="no"

# should we build these packages? 
BUILD_PYTHIA="yes"
BUILD_GSL="yes"
BUILD_ROOT="yes"
BUILD_LOG4CPP="yes"
BUILD_LHAPDF="yes"
GET_PDFS="yes"     # for lhapdf
BUILD_ROOMU="yes"

ADD_PYTHIA_ENV=$BUILD_PYTHIA
ADD_GSL_ENV=$BUILD_GSL
ADD_ROOT_ENV=$BUILD_ROOT
ADD_LOG4CPP_ENV=$BUILD_LOG4CPP
ADD_LHAPDF_ENV=$BUILD_LHAPDF

#-----------------------------------------------------
# Begin work...

BUILDSTARTTIME=`date +%Y-%m-%d-%H-%M-%S`
echo "  Starting the build at $BUILDSTARTTIME"

# quiet pushd
mypush() 
{ 
    pushd $1 >& /dev/null 
    if [ $? -ne 0 ]; then
        echo "Error! Directory $1 does not exist."
        exit 1
    fi
}

# quiet popd
mypop() 
{ 
    popd >& /dev/null 
}

# uniformly printed "subject" breaks
mybr()
{
    echo "------------------------------------------------------------------------------"
}

# save a copy of the install if it already exists
mymkarch() 
{
    if [ -d $1 ]; then
        if [ $FORCEBUILD -ne 0 ]; then
            echo "Tarring old directory..."
            mv -v $1 ${DAT}$1
            tar -cvzf ${DAT}${1}.tgz ${DAT}${1} >& /dev/null
            rm -rf ${DAT}${1}
            mv -v ${DAT}$1.tgz $ARCHIVE
        fi
    fi
}

getcode()
{
    OUTDEST="/dev/null"
    if [[ $VERBOSE = 1 ]]; then
        OUTDEST="$1_get.log"
    fi
    if [ -f $ARCHIVE/$1 ]; then
        echo "Retrieving code from archive..."
        mv -v $ARCHIVE/$1 .
        tar -xvzf $1 >& $OUTDEST
        mv -v $1 $ARCHIVE
    else
        echo "Downloading code from the internet..."
        # TODO - remove `--no-check-certificate` when we stop building on SLF5
        if [ $# -eq 2 ]; then
            $WGET --no-check-certificate $2/$1 >& $OUTDEST
        elif [ $# -eq 3 ]; then
            $WGET --no-check-certificate $2/$1/$3  >& $OUTDEST 
        fi
        tar -xvzf $1 >& /dev/null
        mv -v $1 $ARCHIVE
    fi
}

# bail on illegal versions of Pythia
badpythia()
{
    echo "Illegal version of Pythia! Only 6 or 8 are accepted."
    exit 1
}

# echo if the arg was already built
allreadybuilt()
{
    echo "$1 top directory present. Remove or run with force (-c) to rebuild."
}

# build/configure a package
exec_package_comm()
{
    echo "Build command is: $1, and log file is: $2"
    if [[ $VERBOSE = 1 ]]; then
        $NICE $1 | tee $2
    else
        $NICE $1 >& $2
    fi
    check_status $? $1
}

check_status()
{
    if [[ $1 == 0 ]]; then
        echo " $2: Success!"
    else
        echo " $2: Failure!"
        exit $1
    fi
}

# build ALL the packages...
dobuild()
{

    DAT=`date -u +%s`
    mybr
    echo "Building GENIE support libraries in $PWD. Linux time is $DAT..."
    mybr

    # get the archive directory path.
    mypush archive
    ARCHIVE=`pwd`
    echo "Saving source tarballs to $ARCHIVE"
    mypop

    # start the environment setup file. archive the old one first.
    if [ -f $ENVFILE ]; then
        mv -v $ENVFILE ${DAT}$ENVFILE
        mv -v ${DAT}$ENVFILE $ARCHIVE
    fi
    echo -e "\043\041/bin/bash" > $ENVFILE

    GIT=`which git`
    if [ "$GIT" == "" ]; then
        echo "We cannot check ROOT code out without Git."
        if [ ! -f $ARCHIVE/root.tgz ]; then
            echo "Please put a tarball of the ROOT code in the archive directory: "
            echo "   $ARCHIVE" 
            echo "named: root.tgz"
            exit 1
        fi
    fi
    WGET=`which wget`
    if [ "$WGET" == "" ]; then
        echo "This script is not clever enough to live without wget yet."
        echo "Please edit it and replace wget with whatever executable you"
        echo "have that is appropriate. You could track down the binaries"
        echo "and put them in the archive directory instead as a work-around."
    fi

    if [ "$USE_CMAKE_FOR_ROOT" == "yes" ]; then
        # based on requirements in ROOT's CMakeLists
        # TODO: parse that file to get requirements
        CMAKE_OK="no"  
        CMAKE=`which cmake`
        if [ "$CMAKE" != "" ]; then
            CMAKE_MAJOR=`cmake --version | perl -ne '@l=split(" ",$_);@m=split("\\.",@l[2]);print @m[0];'`
            CMAKE_MINOR=`cmake --version | perl -ne '@l=split(" ",$_);@m=split("\\.",@l[2]);@n=split("-",@m[1]);print @n[0];'`
            if [[ $CMAKE_MAJOR -ge 3 ]]; then
                CMAKE_OK="yes"
            elif [[ $CMAKE_MAJOR -ge 2 && $CMAKE_MINOR -ge 9 ]]; then
                CMAKE_OK="yes"
            fi
        fi
        if [[ "$CMAKE_OK" == "no" ]]; then
            echo "Building CMake from scratch."
            if [ -d $CMAKEDIR ]; then
                # rm -rf $CMAKEDIR
                echo "Assuming CMake is already built locally..."
            else
                getcode $CMAKESRC $CMAKE_URL
                mypush $CMAKEDIR
                exec_package_comm "./bootstrap" "log_${BUILDSTARTTIME}.bstrap"
                exec_package_comm "$MAKE" "log_${BUILDSTARTTIME}.make"
                mypop
            fi
            mypush $CMAKEDIR/bin
            CMAKEBINDIR=`pwd`
            PATH=${CMAKEBINDIR}:$PATH
            mypop
            echo "export CMAKEBINDIR=`pwd`" >> $ENVFILE
            echo "export PATH=${CMAKEBINDIR}:\$PATH" >> $ENVFILE
            echo "Finished installing CMake..."
        fi
    fi

    mybr
    if [ "$BUILD_PYTHIA" == "yes" ]; then
        if [ $PYTHIAVER -eq 8 ]; then
            echo "Will try to build Pythia8 using $PYTHIASRC..."
        elif [ $PYTHIAVER -eq 6 ]; then
            echo "Will try to build Pythia6..."
        else
            badpythia
        fi
    fi
    if [ "$BUILD_GSL" == "yes" ]; then
        echo "Will try to build GSL using $GSLSRC..."
    fi
    if [ "$BUILD_ROOT" == "yes" ]; then
        echo "Will try to build ROOT using version $ROOTTAG..."
    fi
    if [ "$BUILD_LOG4CPP" == "yes" ]; then
        echo "Will try to build log4cpp using $LOG4CPPSRC..."
    fi
    if [ "$BUILD_LHAPDF" == "yes" ];  then
        echo "Will try to build LHAPDF using $LHAPDFSRC..."
    fi
    if [ "$BUILD_ROOMU" == "yes" ];  then
        echo "Will try to build RooMUHistos using GitHub HEAD..."
    fi

    if [ $MAKENICE -ne 0 ]; then
        NICE=nice
    else 
        NICE=""
    fi

    if [ $PYTHIAVER -eq 8 ]; then
        PYTHIADIR=`basename ${PYTHIASRC} .tgz`
        mybr
        if [ "$BUILD_PYTHIA" == "yes" ]; then
            echo "Building ${PYTHIADIR} in $PWD..."
            mymkarch $PYTHIADIR
            if [ ! -d $PYTHIADIR ]; then
                echo "Getting source in $PWD..."
                getcode $PYTHIASRC "http://home.thep.lu.se/~torbjorn/pythia8"
                mypush $PYTHIADIR
                echo "Running configure in $PWD..."
                DEBUGFLAG=""
                if [ "$DEBUG" == "yes" ]; then
                    DEBUGFLAG="--enable-debug"
                fi
                exec_package_comm "./configure $DEBUGFLAG --enable-shared" "log_${BUILDSTARTTIME}.config"
                echo "Running make in $PWD..."
                exec_package_comm "$MAKE" "log_${BUILDSTARTTIME}.make"
                mypop
                echo "Finished Pythia..."
            else
                allreadybuilt "Pythia"
            fi
        else 
            echo "Using pre-built Pythia8..."
        fi
        if [ "$ADD_PYTHIA_ENV" == "yes" ]; then
            mypush $PYTHIADIR/lib
            PYTHIALIBDIR=`pwd`
            mypop
            mypush $PYTHIADIR/include
            PYTHIAINCDIR=`pwd`
            mypop
            mypush $PYTHIADIR/xmldoc
            PYTHIA8DATA=`pwd`
            mypop
            echo "Pythia8 lib dir is $PYTHIALIBDIR..."
            echo "export PYTHIA8=$PYTHIALIBDIR" >> $ENVFILE
            echo "export PYTHIA8DATA=$PYTHIA8DATA" >> $ENVFILE
            echo "export PYTHIA8_INC=$PYTHIAINCDIR" >> $ENVFILE
            echo "export LD_LIBRARY_PATH=${PYTHIALIBDIR}:\$LD_LIBRARY_PATH" >> $ENVFILE
        fi
    elif [ $PYTHIAVER -eq 6 ]; then
        PYTHIADIR=pythia6
        mybr
        if [ "$BUILD_PYTHIA" == "yes" ]; then
            echo "Building ${PYTHIADIR} in $PWD..."
            mymkarch $PYTHIADIR
            if [ ! -d $PYTHIADIR ]; then
                mkdir $PYTHIADIR
                pushd $PYTHIADIR
                echo "Getting script in $PWD..."
                cp -v ${ARCHIVE}/build_pythia6.sh .
                COPYSTATUS=$?
                if [[ ! -e build_pythia6.sh ]]; then
                    echo "ERROR! Could not copy the build_pythia6.sh script to this area!"
                    echo "  cp status = $COPYSTATUS"
                    ls $ARCHIVE
                    exit 1
                fi 
                echo "Running the script in $PWD..."
                exec_package_comm "./build_pythia6.sh" "log_${BUILDSTARTTIME}.pythia6"        
                rm build_pythia6.sh 
                mypop
                echo "Finished Pythia..."
                mypop
            else
                allreadybuilt "Pythia"
            fi
        else 
            echo "Using pre-built Pythia6..."
        fi
        if [ "$ADD_PYTHIA_ENV" == "yes" ]; then
            mypush $PYTHIADIR/v6_424/lib
            PYTHIALIBDIR=`pwd`
            mypop
            echo "Pythia6 lib dir is $PYTHIALIBDIR..."
            echo "export PYTHIA6=$PYTHIALIBDIR" >> $ENVFILE
            echo "export LD_LIBRARY_PATH=${PYTHIALIBDIR}:\$LD_LIBRARY_PATH" >> $ENVFILE
        fi
    else 
        badpythia
    fi

    mybr
    GSLDIR=`basename ${GSLSRC} .tar.gz`
    if [ "$BUILD_GSL" == "yes" ]; then
        mymkarch gsl
        if [ ! -d gsl ]; then
            mkdir gsl
            mypush gsl
            echo "Building $GSLDIR in $PWD..."
            echo "Getting source in $PWD..."
            getcode $GSLSRC "http://ftpmirror.gnu.org/gsl"
            GSLINST=`pwd`
            mypush $GSLDIR
            echo "Running configure in $PWD..."
            exec_package_comm "./configure --prefix=$GSLINST" "log_${BUILDSTARTTIME}.config"
            echo "Running make in $PWD..."
            exec_package_comm "$MAKE" "log_${BUILDSTARTTIME}.make"
            echo "Running make check in $PWD..."
            exec_package_comm "$MAKE check" "log_${BUILDSTARTTIME}.check"
            echo "Running make install in $PWD..."
            exec_package_comm "$MAKE install" "log_${BUILDSTARTTIME}.install"
            mypop
            echo "Finished GSL..."
            mypop
        else
            allreadybuilt "GSL"
        fi
    else
        echo "Using pre-built GSL..."
    fi
    if [ "$ADD_GSL_ENV" == "yes" ]; then
        mypush gsl
        GSL_INSTALL_DIR=`pwd`
        mypop
        mypush gsl/lib
        GSLLIB=`pwd`
        mypop
        mypush gsl/include
        GSLINC=`pwd`
        mypop
        echo "GSL lib dir is $GSLLIB..."
        echo "GSL inc dir is $GSLINC..."
        echo "export GSLLIB=$GSLLIB" >> $ENVFILE
        echo "export GSLINC=$GSLINC" >> $ENVFILE
        echo "export LD_LIBRARY_PATH=${GSLLIB}:\$LD_LIBRARY_PATH" >> $ENVFILE
    fi

    mybr
    if [ "$BUILD_ROOT" == "yes" ]; then
        mymkarch root
        if [ ! -d root ]; then
            echo "Building ROOT $ROOTTAG in $PWD..."
            if [ -f $ARCHIVE/root.tgz ]; then
                echo "Retrieving code from archive..."
                echo " We will not be adjusting the tag!"
                mv -v $ARCHIVE/root.tgz .
                tar -xvzf $1 >& /dev/null
                mv -v root.tgz $ARCHIVE
                mypush root
            else
                echo "Downloading code from the internet..."
                git clone http://root.cern.ch/git/root.git
                mypush root
                echo "Checking out tag $ROOTTAG..."
                git checkout -b ${ROOTTAG} ${ROOTTAG}
            fi
            echo "Configuring in $PWD..."
            if [ "$USE_CMAKE_FOR_ROOT" == "yes" ]; then
                mkdir ../build_root
                mypush ../build_root/
                ROOT_BUILD_TYPE="Release"
                if [ "$DEBUG" == "yes" ]; then
                    ROOT_BUILD_TYPE="Debug"
                fi
                cmake -DCMAKE_BUILD_TYPE=$ROOT_BUILD_TYPE \
                    -Dcxx11=OFF -Dgdml=ON -Dminuit2=ON -Dgsl_shared=ON \
                    -DPYTHIA6_LIBRARY=$PYTHIALIBDIR/libPythia6.so \
                    -DGSL_DIR=$GSS_INSTALL_DIR \
                    -DGSL_CONFIG_EXECUTABLE=$GSL_INSTALL_DIR/bin/gsl-config \
                    ../root > log_${BUILDSTARTTIME}.config
                cmake --build . > log_${BUILDSTARTTIME}.make
                mypop
            else
                PYTHIASTRING=""
                if [ $PYTHIAVER -eq 6 ]; then
                    PYTHIASTRING="--enable-pythia6 --with-pythia6-libdir=$PYTHIALIBDIR"
                elif [ $PYTHIAVER -eq 8 ]; then
                    PYTHIASTRING="--enable-pythia8 --with-pythia8-libdir=$PYTHIALIBDIR --with-pythia8-incdir=$PYTHIAINCDIR"
                else
                    badpythia
                fi
                DEBUGFLAG=""
                if [ "$DEBUG" == "yes" ]; then
                    DEBUGFLAG="--build=debug"
                fi
                exec_package_comm "$NICE ./configure linuxx8664gcc $DEBUGFLAG $PYTHIASTRING --enable-gdml --enable-gsl-shared --enable-mathmore --enable-minuit2 --with-gsl-incdir=$GSLINC --with-gsl-libdir=$GSLLIB" "log_${BUILDSTARTTIME}.config"
                echo "Running make in $PWD..."
                # nice $MAKE >& log_${BUILDSTARTTIME}.make
                exec_package_comm "$MAKE" "log_${BUILDSTARTTIME}.make"
            fi   # endif USE_CMAKE_FOR_ROOT 
            echo "Finished ROOT..."
            mypop  # after Git checkout
        else
            allreadybuilt "ROOT"
        fi
    else
        echo "Using pre-built ROOT..."
    fi
    if [ "$ADD_ROOT_ENV" == "yes" ]; then
        if [ -d build_root ]; then
            mypush build_root
            ROOTSYS=`pwd`
            echo "ROOTSYS is $ROOTSYS..."
            mypop
        elif [ -d root ]; then
            mypush root
            ROOTSYS=`pwd`
            echo "ROOTSYS is $ROOTSYS..."
            mypop
        else
            echo "Error! Can't figure out how to set ROOTSYS!"
            exit 1
        fi
        echo "export ROOTSYS=$ROOTSYS" >> $ENVFILE
        echo "export PATH=${ROOTSYS}/bin:\$PATH" >> $ENVFILE
        echo "export LD_LIBRARY_PATH=${ROOTSYS}/lib:\$LD_LIBRARY_PATH" >> $ENVFILE
    fi

    LOG4CPPDIR="log4cpp"
    mybr
    if [ "$BUILD_LOG4CPP" == "yes" ]; then
        mymkarch $LOG4CPPDIR
        if [ ! -d $LOG4CPPDIR ]; then
            echo "Building log4cpp in $PWD..."
            if [ -f $ARCHIVE/$LOG4CPPSRC ]; then
                echo "Retrieving code from archive..."
                mv -v $ARCHIVE/$LOG4CPPSRC .
                tar -xvzf $LOG4CPPSRC >& /dev/null 
                mv -v $LOG4CPPSRC $ARCHIVE
                mypush $LOG4CPPDIR
            else
                echo "Using the log4cpp code present here..."
                tar -xvzf $LOG4CPPSRC >& /dev/null 
                echo "Archiving the log4cpp tarball. Look for it in $ARCHIVE..."
                mv -v $LOG4CPPSRC $ARCHIVE
                mypush $LOG4CPPDIR
            fi
            echo "Running autogen in $PWD..."
            exec_package_comm "$NICE ./autogen.sh" "log_${BUILDSTARTTIME}.autogen"
            echo "Running configure in $PWD..."
            exec_package_comm "$NICE ./configure --prefix=`pwd`" "log_${BUILDSTARTTIME}.config"
            echo "Running make in $PWD..."
            exec_package_comm "$NICE $MAKE" "log_${BUILDSTARTTIME}.make"
            echo "Running make install in $PWD..."
            echo "  ...for some reason, make install usually succeeds, but throws an"
            echo "  error anyway, so we won't check for success here (yet)."
            $NICE $MAKE install >& log_${BUILDSTARTTIME}.install
            echo "Finished log4cpp..."
            mypop
        else
            allreadybuilt "log4cpp"
        fi
    else
        echo "Using pre-built log4cpp..."
    fi
    if [ "$ADD_LOG4CPP_ENV" == "yes" ]; then
        mypush $LOG4CPPDIR/include
        LOG4CPP_INC=`pwd`
        mypop
        mypush $LOG4CPPDIR/lib
        LOG4CPP_LIB=`pwd`
        mypop
        echo "log4cpp lib dir is $LOG4CPP_LIB..."
        echo "log4cpp inc dir is $LOG4CPP_INC..."
        echo "export LOG4CPP_INC=$LOG4CPP_INC" >> $ENVFILE
        echo "export LOG4CPP_LIB=$LOG4CPP_LIB" >> $ENVFILE
        echo "export LD_LIBRARY_PATH=${LOG4CPP_LIB}:\$LD_LIBRARY_PATH" >> $ENVFILE
    fi

    LHAPDFDIR=`basename ${LHAPDFSRC} .tar.gz`
    LHAPDFROOT=lhapdf
    mybr
    if [ "$BUILD_LHAPDF" == "yes" ]; then
        mymkarch $LHAPDFROOT
        if [ ! -d $LHAPDFROOT ]; then
            echo "Making installation directories for LHAPDF..."
            mkdir $LHAPDFROOT
            mypush $LHAPDFROOT
            echo "Building LHAPDF in $PWD..."
            LHAINST=`pwd`
            echo "LHAPDF install directory is $LHAINST..."
            getcode $LHAPDFSRC "http://www.hepforge.org/archive/lhapdf"
            mypush $LHAPDFDIR
            echo "Running configure in $PWD..."
            exec_package_comm "$NICE ./configure --prefix=$LHAINST --disable-old-ccwrap --disable-pyext" "log_${BUILDSTARTTIME}.config"
            echo "Running make in $PWD..."
            exec_package_comm "$NICE $MAKE" "log_${BUILDSTARTTIME}.make"
            echo "Running make install in $PWD..."
            exec_package_comm "$NICE $MAKE install" "log_${BUILDSTARTTIME}.install"
            mypop
            mypop
            echo "Finished building LHAPDF..."
        else
            allreadybuilt "LHAPDF"
        fi
    else
        echo "Using pre-built LHAPDF..."
    fi
    if [ "$ADD_LHAPDF_ENV" == "yes" ]; then
        mypush $LHAPDFROOT
        LHAPATH=`pwd`
        mypop
        mypush $LHAPDFROOT/lib
        LHAPDF_LIB=`pwd`
        mypop
        mypush $LHAPDFROOT/include
        LHAPDF_INC=`pwd`
        mypop
        echo "LHAPDF lib is $LHAPDF_LIB..."
        echo "LHAPDF inc is $LHAPDF_INC..."
        echo "export LHAPATH=$LHAPATH" >> $ENVFILE
        echo "export LHAPDF_INC=$LHAPDF_INC" >> $ENVFILE
        echo "export LHAPDF_LIB=$LHAPDF_LIB" >> $ENVFILE
        echo "export LD_LIBRARY_PATH=${LHAPDF_LIB}:\$LD_LIBRARY_PATH" >> $ENVFILE
    fi
    if [ "$GET_PDFS" == "yes" ]; then
        echo "Getting PDFs..."
        mypush $LHAPDFROOT/bin
        for pdf in $PDFLIST
        do
            if [ ! -f $LHAPATH/$pdf ]; then
                echo "...Getting $pdf..."
                $NICE ./lhapdf-getdata $pdf --dest=$LHAPATH
                check_status $?
            else
                echo "$pdf is already present..."
            fi
        done
        mypop
        if [ $LHAPDFMAJOR -eq 5 ]; then
            echo "Installing the patched GRV98lo file from the archive."
            cp -b archive/GRV98lo_pdflib.LHgrid $LHAPATH/GRV98lo_patched.LHgrid
        else
            echo "ERROR! Unsupported LHAPDF!"
            exit 1
        fi
        echo "Finished getting PDFs..."
    else
        mypush $LHAPATH
        echo "PDF sets present: "
        ls *.*
        mypop
    fi

    mybr
    if [ "$BUILD_ROOMU" == "yes" ]; then
        ROOMUPKG=RooMUHistos
        mymkarch $ROOMUPKG
        if [ ! -d $ROOMUPKG ]; then
            echo "Building RooMUHistos in $ROOMUPKG..." 
            git clone ${GITCHECKOUT}ManyUniverseAna/${ROOMUPKG}.git
            mypush $ROOMUPKG
            ROOMU_SYS=`pwd`
            echo " ROOMU_SYS is $ROOMU_SYS..."
            export ROOMU_SYS=$ROOMU_SYS
            export PATH=$ROOMU_SYS/bin:$PATH
            # to build RooMUHistos, ROOT env.var. need to be explicitly set 
            export ROOTSYS=$ROOTSYS
            export LD_LIBRARY_PATH=${ROOTSYS}/lib:$LD_LIBRARY_PATH
            mypush PlotUtils
            echo "Building PlotUtils in $PWD..."
            # $NICE $MAKE >& log_${BUILDSTARTTIME}.make
            exec_package_comm "$NICE $MAKE" "log_${BUILDSTARTTIME}.make"
            mypop
            mypush macros
            echo "Building macros in $PWD..."
            # $NICE $MAKE >& log_${BUILDSTARTTIME}.make
            exec_package_comm "$NICE $MAKE" "log_${BUILDSTARTTIME}.make"
            mypop
            mypop
        else
            echo "Using pre-built RooMUHistos..."
            mypush $ROOMUPKG
            ROOMU_SYS=`pwd`
            mypop
        fi
        echo "export ROOMU_SYS=$ROOMU_SYS" >> $ENVFILE
        echo "export LD_LIBRARY_PATH=$ROOMU_SYS/lib:\$LD_LIBRARY_PATH" >> $ENVFILE
        echo "export PATH=\$ROOMU_SYS/bin:\$PATH" >> $ENVFILE
    fi

    mybr
    echo "Done!"
    mybr
    exit 0
}

#
# Parse the command line flags.
#
while [[ $# > 0 ]]
do
    key="$1"
    shift

    case $key in
        -h|--help)
            HELPFLAG=1
            ;;
        -p|--pythia)
            PYTHIAVER="$1"
            shift
            ;;
        -n|--nice)
            MAKENICE=1
            ;;
        -r|--root)
            ROOTTAG="$1"
            shift
            ;;
        -s|--https)
            HTTPSCHECKOUT=1
            ;;
        -v|--verbose)
            VERBOSE=1
            ;;
        -c|--force)
            FORCEBUILD=1
            ;;
        -d|--debug)
            DEBUG="yes"
            ;;
        --no-roomu)
            BUILD_ROOMU="no"
            ;;
        --no-cmake)
            USE_CMAKE_FOR_ROOT="no"
            ;;
        *)    # Unknown option

            ;;
    esac
done


if [ $PYTHIAVER -eq -1 ]; then
    HELPFLAG=1
fi
if [ $HELPFLAG -ne 0 ]; then
    help
    exit 0
fi
mybr
echo " "
echo "Welcome to the GENIE 3rd party support code build script."
echo " "
echo " OS Information: "
if [[ `which lsb_release` != "" ]]; then
    lsb_release -a
elif [[ -e "/etc/lsb-release" ]]; then
    cat /etc/lsb-release
elif [[ -e "/etc/issue.net" ]]; then
    cat /etc/issue.net
else
    echo " Missing information on Linux distribution..."
fi
uname -a
mybr
echo "Selected Pythia Version is $PYTHIAVER..."
if [ $PYTHIAVER -ne 6 -a $PYTHIAVER -ne 8 ]; then
    badpythia
fi
echo "Selected ROOT tag is $ROOTTAG..."

GITCHECKOUT="http://github.com/"
if [ $HTTPSCHECKOUT -ne 0 ]; then
    GITCHECKOUT="https://github.com/"
else
    GITCHECKOUT="git@github.com:"
fi

# Build the code
dobuild
