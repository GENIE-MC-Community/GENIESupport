#!/bin/bash

# Users need to edit this list by hand...
PDFLIST="GRV98lo.LHgrid GRV98nlo.LHgrid"

# what are the names of the code archives? we get ROOT
# from CERN's Git repos. log4cpp is "special" because
# we can't curl it (I think - maybe someone can).
PYTHIASRC=pythia8183.tgz          # only if we use Pythia8.
GSLSRC=gsl-1.16.tar.gz
ROOTTAG="v5-34-17"
LOG4CPPSRC=log4cpp-1.1.1.tar.gz       
LHAPDFSRC=lhapdf-5.9.1.tar.gz

ENVFILE="environment_setup.sh"
 
# command line arg options
MAKE=gmake           # This might need to `make` for some users.
MAKENICE=0           # make under nice?
HELPFLAG=0           # show the help block (if non-zero)
FORCEBUILD=0         # non-zero will archive existing packages and rebuild
PYTHIAVER=-1         # must eventually be either 6 or 8

# should we build these packages? - testing variables
BUILD_PYTHIA="yes"
BUILD_GSL="yes"
BUILD_ROOT="yes"
BUILD_LOG4CPP="yes"
BUILD_LHAPDF="yes"
GET_PDFS="yes"     # for lhapdf


#-----------------------------------------------------
# Begin work...

# how to use the script
help()
{
  mybr
  echo "Usage: ./build_support -<flag>"
  echo "                       -p  #  : Build Pythia 6 or 8 and link ROOT to it (required)."
  echo "                       -r tag : Which ROOT version (default = v5-34-17)."
  echo "                       -n     : Run configure, build, etc. under nice."
  echo "                       -m     : Use \"make\" instead of \"gmake\" to build."
  echo " "
  echo "  Examples:  "
  echo "    ./build_supprt -p 6"
  echo "    ./build_supprt -p 8 -r v5-34-18"
  mybr
  echo " "
}

# quiet pushd
mypush() 
{ 
  pushd $1 >& /dev/null 
  if [ $? -ne 0 ]; then
    echo "Error! Directory $1 does not exist."
    exit 0
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
  echo "----------------------------------------"
}

# save a copy of the install if it already exists
mymkarch() 
{
  if [ -d $1 ]; then
    if [ $FORCEBUILD -ne 0 ]; then
      echo "Tarring old directory..."
      mv $1 ${DAT}$1
      tar -cvzf ${DAT}${1}.tgz ${DAT}${1} >& /dev/null
      rm -rf ${DAT}${1}
      mv ${DAT}$1.tgz $ARCHIVE
    fi
  fi
}

getcode()
{
  if [ -f $ARCHIVE/$1 ]; then
    echo "Retrieving code from archive..."
    mv $ARCHIVE/$1 .
    tar -xvzf $1 >& /dev/null
    mv $1 $ARCHIVE
  else
    echo "Downloading code from the internet..."
    $WGET $2/$1 >& /dev/null
    tar -xvzf $1 >& /dev/null
    mv $1 $ARCHIVE
  fi
}
# bail on illegal versions of Pythia
badpythia()
{
  echo "Illegal version of Pythia! Only 6 or 8 are accepted."
  exit 0
}
#
allreadybuilt()
{
  echo "$1 top directory present. Remove or run with force (-f) to rebuild."
}

# build the packages...
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
  popd >& /dev/null

  # start the environment setup file. archive the old one first.
  if [ -f $ENVFILE ]; then
    mv $ENVFILE ${DAT}$ENVFILE
    mv ${DAT}$ENVFILE $ARCHIVE
  fi
  echo -e "\043\041/bin/bash" > $ENVFILE

  GIT=`which git`
  if [ "$GIT" == "" ]; then
    echo "We cannot check ROOT code out without Git."
    if [ ! -f $ARCHIVE/root.tgz ]; then
      echo "Please put a tarball of the ROOT code in the archive directory: "
      echo "   $ARCHIVE" 
      echo "named: root.tgz"
      exit 0
    fi
  fi
  WGET=`which wget`
  if [ "$WGET" == "" ]; then
    echo "This script is not clever enough to live without wget yet."
    echo "Please edit it and replace wget with whatever executable you"
    echo "have that is appropriate. You could track down the binaries"
    echo "and put them in the archive directory instead as a work-around."
  fi

  mybr
  if [ "$BUILD_PYTHIA" == "yes" ]; then
    if [ $PYTHIAVER -eq 8 ]; then
      echo "Will try to build Pythia8..."
    elif [ $PYTHIAVER -eq 6 ]; then
      echo "Will try to build Pythia6..."
    else
      badpythia
    fi
  fi
  if [ "$BUILD_GSL" == "yes" ]; then
    echo "Will try to build GSL..."
  fi
  if [ "$BUILD_ROOT" == "yes" ]; then
    echo "Will try to build ROOT..."
  fi
  if [ "$BUILD_LOG4CPP" == "yes" ]; then
    echo "Will try to build log4cpp..."
  fi
  if [ "$BUILD_LHAPDF" == "yes" ];  then
    echo "Will try to build LHAPDF..."
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
        $NICE ./configure --enable-debug --enable-shared >& log.config
        echo "Running make in $PWD..."
        $NICE $MAKE >& log.make
        mypop
        echo "Finished Pythia..."
      else
        allreadybuilt "Pythia"
      fi
    else 
      echo "Using pre-built Pythia8..."
    fi
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
    echo "export LD_LIBRARY_PATH=${PYTHIALIBDIR}:\$LD_LIBRARY_PATH" >> $ENVFILE
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
        mv ${ARCHIVE}/build_pythia6.sh .
        echo "Running the script in $PWD..."
        $NICE ./build_pythia6.sh >& log.pythia6
        mv build_pythia6.sh $ARCHIVE
        mypop
        echo "Finished Pythia..."
        mypop
      else
        allreadybuilt "Pythia"
      fi
    else 
      echo "Using pre-built Pythia6..."
    fi
    mypush $PYTHIADIR/v6_424/lib
    PYTHIALIBDIR=`pwd`
    mypop
    echo "Pythia6 lib dir is $PYTHIALIBDIR..."
    echo "export PYTHIA6=$PYTHIALIBDIR" >> $ENVFILE
    echo "export LD_LIBRARY_PATH=${PYTHIALIBDIR}:\$LD_LIBRARY_PATH" >> $ENVFILE
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
      $NICE ./configure --prefix=$GSLINST >& log.config
      echo "Running make in $PWD..."
      $NICE $MAKE >& log.make
      echo "Running make check in $PWD..."
      $NICE $MAKE check >& log.check
      echo "Running make install in $PWD..."
      $NICE $MAKE install >& log.install
      mypop
      echo "Finished GSL..."
      mypop
    else
      allreadybuilt "GSL"
    fi
  else
    echo "Using pre-built GSL..."
  fi
  mypush gsl/lib
  GSLLIB=`pwd`
  mypop
  mypush gsl/include
  GSLINC=`pwd`
  mypop
  echo "GSL lib dir is $GSLLIB..."
  echo "GSL inc dir is $GSLINC..."

  mybr
  if [ "$BUILD_ROOT" == "yes" ]; then
    mymkarch root
    if [ ! -d root ]; then
      echo "Building ROOT $ROOTTAG in $PWD..."
      if [ -f $ARCHIVE/root.tgz ]; then
        echo "Retrieving code from archive..."
        echo " We will not be adjusting the tag!"
        mv $ARCHIVE/root.tgz .
        tar -xvzf $1 >& /dev/null
        mv root.tgz $ARCHIVE
        mypush root
      else
        echo "Downloading code from the internet..."
        git clone http://root.cern.ch/git/root.git
        mypush root
        echo "Checking out tag $ROOTTAG..."
        git checkout -b ${ROOTTAG} ${ROOTTAG}
      fi
      echo "Configuring in $PWD..."
      PYTHIASTRING=""
      if [ $PYTHIAVER -eq 6 ]; then
        PYTHIASTRING="--enable-pythia6 --with-pythia6-libdir=$PYTHIALIBDIR"
      elif [ $PYTHIAVER -eq 8 ]; then
        PYTHIASTRING="--enable-pythia8 --with-pythia8-libdir=$PYTHIALIBDIR --with-pythia8-incdir=$PYTHIAINCDIR"
      else
        badpythia
      fi
      $NICE ./configure linuxx8664gcc --build=debug $PYTHIASTRING --enable-gsl-shared --enable-mathmore --with-gsl-incdir=$GSLINC --with-gsl-libdir=$GSLLIB >& log.config
      echo "Running make in $PWD..."
      nice $MAKE >& log.make
      echo "Finished ROOT..."
      mypop
    else
      allreadybuilt "ROOT"
    fi
  else
    echo "Using pre-built ROOT..."
  fi
  mypush root
  ROOTSYS=`pwd`
  echo "ROOTSYS is $ROOTSYS..."
  mypop
  echo "export ROOTSYS=$ROOTSYS" >> $ENVFILE
  echo "export PATH=${ROOTSYS}/bin:\$PATH" >> $ENVFILE
  echo "export LD_LIBRARY_PATH=${ROOTSYS}/lib:\$LD_LIBRARY_PATH" >> $ENVFILE

  LOG4CPPDIR="log4cpp"
  mybr
  if [ "$BUILD_LOG4CPP" == "yes" ]; then
    mymkarch $LOG4CPPDIR
    if [ ! -d $LOG4CPPDIR ]; then
      echo "Building log4cpp in $PWD..."
      if [ -f $ARCHIVE/$LOG4CPPSRC ]; then
        echo "Retrieving code from archive..."
        mv $ARCHIVE/$LOG4CPPSRC .
        tar -xvzf $LOG4CPPSRC >& /dev/null 
        mv $LOG4CPPSRC $ARCHIVE
        mypush $LOG4CPPDIR
      else
        echo "Using the log4cpp code present here..."
        tar -xvzf $LOG4CPPSRC >& /dev/null 
        echo "Archiving the log4cpp tarball. Look for it in $ARCHIVE..."
        mv $LOG4CPPSRC $ARCHIVE
        mypush $LOG4CPPDIR
      fi
      echo "Running autogen in $PWD..."
      $NICE ./autogen.sh >& log.autogen
      echo "Running configure in $PWD..."
      $NICE ./configure --prefix=`pwd` >& log.config
      echo "Running make in $PWD..."
      $NICE $MAKE >& log.make
      echo "Running make install in $PWD..."
      $NICE $MAKE install >& log.install
      echo "Finished log4cpp..."
      mypop
    else
      allreadybuilt "log4cpp"
    fi
  else
    echo "Using pre-built log4cpp..."
  fi
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

  LHAPDFDIR=`basename ${LHAPDFSRC} .tar.gz`
  LHAPDFROOT=lhapdf
  mybr
  if [ "$BUILD_LHAPDF" == "yes" ]; then
    mymkarch $LHAPDFROOT
    if [ ! -d $LHAPDFROOT ]; then
      echo "Making installation directories for LHAPDF..."
      mkdir $LHAPDFROOT
      mypush $LHAPDFROOT
      echo "Building ${LHAPDF} in $PWD..."
      LHAINST=`pwd`
      echo "LHAPDF install directory is $LHAINST..."
      getcode $LHAPDFSRC "http://www.hepforge.org/archive/lhapdf"
      mypush $LHAPDFDIR
      echo "Running configure in $PWD..."
      $NICE ./configure --prefix=$LHAINST >& log.config
      echo "Running make in $PWD..."
      $NICE $MAKE >& log.make
      echo "Running make install in $PWD..."
      $NICE $MAKE install >& log.install
      mypop
      mypop
      echo "Finished building LHAPDF..."
    else
      allreadybuilt "LHAPDF"
    fi
  else
    echo "Using pre-built LHAPDF..."
  fi
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
  if [ "$GET_PDFS" == "yes" ]; then
    echo "Getting PDFs..."
    mypush $LHAPDFROOT/bin
    for pdf in $PDFLIST
    do
      if [ ! -f $LHAPATH/$pdf ]; then
        echo "...Getting $pdf..."
        $NICE ./lhapdf-getdata $pdf --dest=$LHAPATH
      else
        echo "$pdf is already present..."
      fi
    done
    mypop
    echo "Finished getting PDFs..."
  else
    mypush $LHAPDFROOT/bin
    echo "PDF sets present: "
    ls *.*
    mypop
  fi

  mybr
  echo "Done!"
  mybr
}

while getopts "p:r:fmn" options; do
  case $options in
    p) PYTHIAVER=$OPTARG;;
    r) ROOTTAG=$OPTARG;;
    f) FORCEBUILD=1;;
    n) MAKENICE=1;;
    m) MAKE=make;;
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
echo "Selected Pythia Version is $PYTHIAVER..."
if [ $PYTHIAVER -ne 6 -a $PYTHIAVER -ne 8 ]; then
  badpythia
fi
echo "Selected ROOT tag is $ROOTTAG..."


dobuild
