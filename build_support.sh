#!/bin/sh

# TODO - let the user pass flags to control what is built?

ENVFILE="environment_setup.sh"

PYTHIA8="no"   # no means use Pythia6

# should we build these packages?
BUILD_HEPMC="yes"
BUILD_PYTHIA="yes"
BUILD_GSL="yes"
BUILD_ROOT="yes"
BUILD_LOG4CPP="yes"
BUILD_LHAPDF="yes"
GET_PDFS="yes"     # for lhapdf
PDFLIST="GRV98lo.LHgrid GRV98nlo.LHgrid"

# what are the names of the code archives? we get ROOT
# from CERN's Git repos. log4cpp is "special" because
# we can't curl it (I think - maybe someone can).
HEPMCSRC=HepMC-2.06.08.tar.gz
PYTHIASRC=pythia8183.tgz          # only if we use Pythia8.
GSLSRC=gsl-1.16.tar.gz
ROOTTAG="v5-34-08"
LOG4CPPSRC=log4cpp-1.1.1.tar.gz       
LHAPDFSRC=lhapdf-5.9.1.tar.gz

# make under nice?
MAKENICE="no"

#-----------------------------------------------------
# Begin work...

# quiet pushd
mypush() 
{ 
  pushd $1 >& /dev/null 
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
    echo "Tarring old directory..."
    mv $1 ${DAT}$1
    tar -cvzf ${DAT}${1}.tgz ${DAT}${1} >& /dev/null
    rm -rf ${DAT}${1}
    mv ${DAT}$1 $ARCHIVE
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
    echo -e "\043\041/bin/sh" > $ENVFILE
  fi

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
  if [ "$BUILD_HEPMC" == "yes" ]; then
    echo "Will build HepMC..."
  fi
  if [ "$BUILD_PYTHIA" == "yes" ]; then
    if [ "$PYTHIA8" == "yes" ]; then
      echo "Will build Pythia8..."
    else
      echo "Will build Pythia6..."
    fi
  fi
  if [ "$BUILD_GSL" == "yes" ]; then
    echo "Will build GSL..."
  fi
  if [ "$BUILD_ROOT" == "yes" ]; then
    echo "Will build ROOT..."
  fi
  if [ "$BUILD_LOG4CPP" == "yes" ]; then
    echo "Will build log4cpp..."
  fi
  if [ "$BUILD_LHAPDF" == "yes" ];  then
    echo "Will build LHAPDF..."
  fi

  if [ "$MAKENICE" == "yes" ]; then
    NICE=nice
  else 
    NICE=""
  fi

  # TODO - near future, take out HepMC. S. Mrenna says it is not required.
  HEPMCDIR=`basename ${HEPMCSRC} .tar.gz`
  HEPMCROOT=hepmc
  mybr
  if [ "$BUILD_HEPMC" == "yes" ]; then
    echo "Building ${HEPMCDIR} in $PWD..."
    mymkarch $HEPMCROOT
    echo "Making installation directories for HepMC..."
    mkdir ${HEPMCROOT}
    mkdir ${HEPMCROOT}/build
    mkdir ${HEPMCROOT}/install
    mypush ${HEPMCROOT}
    mypush install
    HEPMCINST=`pwd`
    echo "Target install directory is ${HEPMCINST}..."
    mypop
    echo "Getting source in $PWD..."
    getcode $HEPMCSRC "http://lcgapp.cern.ch/project/simu/HepMC/download"
    echo "Pushing to $HEPMCDIR..."
    mypush ${HEPMCDIR} 
    echo "Running autoreconf in $PWD..."
    autoreconf -f -i
    mypop
    mypush build
    echo "Running configure in $PWD..."
    $NICE ../${HEPMCDIR}/configure --prefix=$HEPMCINST --with-momentum=GEV --with-length=CM >& log.config
    echo "Running make in $PWD..."
    $NICE make >& log.make
    echo "Running make install in $PWD..."
    $NICE make install >& log.install
    mypop
    echo "Finished HepMC..."
  else
    echo "Using pre-built HepMC..."
  fi
  mypush $HEPMCROOT/install/lib 
  HEPMCLIB=`pwd`
  echo "HepMC lib is $HEPMCLIB..."
  mypop

  if [ "$PYTHIA8" == "yes" ]; then
    PYTHIADIR=`basename ${PYTHIASRC} .tgz`
    mybr
    if [ "$BUILD_PYTHIA" == "yes" ]; then
      echo "Building ${PYTHIADIR} in $PWD..."
      mymkarch $PYTHIADIR
      echo "Getting source in $PWD..."
      getcode $PYTHIASRC "http://home.thep.lu.se/~torbjorn/pythia8"
      mypush $PYTHIADIR
      echo "Running configure in $PWD..."
      $NICE ./configure --enable-debug --enable-shared >& log.config
      echo "Running make in $PWD..."
      $NICE gmake >& log.make
      mypop
      echo "Finished Pythia..."
    else 
      echo "Using pre-built Pythia8..."
    fi
    mypush $PYTHIADIR/lib
    PYTHIALIBDIR=`pwd`
    echo "Pythia8 lib dir is $PYTHIALIBDIR..."
    echo "export PYTHIA8=$PYTHIALIBDIR" >> $ENVFILE
    mypop
  else
    PYTHIADIR=pythia6
    mybr
    if [ "$BUILD_PYTHIA" == "yes" ]; then
      echo "Building ${PYTHIADIR} in $PWD..."
      mymkarch $PYTHIADIR
      mkdir $PYTHIADIR
      pushd $PYTHIADIR
      echo "Getting script in $PWD..."
      mv ${ARCHIVE}/build_pythia6.sh .
      echo "Running the script in $PWD..."
      $NICE ./build_pythia6.sh
      mv build_pythia6.sh $ARCHIVE
      mypop
      echo "Finished Pythia..."
      mypop
    else 
      echo "Using pre-built Pythia6..."
    fi
    mypush $PYTHIADIR/v6_424/lib
    PYTHIALIBDIR=`pwd`
    echo "Pythia6 lib dir is $PYTHIALIBDIR..."
    echo "export PYTHIA6=$PYTHIALIBDIR" >> $ENVFILE
    mypop
  fi

  mybr
  GSLDIR=`basename ${GSLSRC} .tar.gz`
  if [ "$BUILD_GSL" == "yes" ]; then
    mymkarch gsl
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
    $NICE make >& log.make
    echo "Running make check in $PWD..."
    $NICE make check >& log.check
    echo "Running make install in $PWD..."
    $NICE make install >& log.install
    mypop
    echo "Finished GSL..."
    mypop
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
    $NICE ./configure linuxx8664gcc --build=debug --enable-pythia8 \
    --with-pythia8-libdir=$PYTHIALIBDIR --enable-gsl-shared \
    --enable-mathmore --with-gsl-incdir=$GSLINC --with-gsl-libdir=$GSLLIB >& log.config
    echo "Running make in $PWD..."
    nice make >& log.make
    echo "Finished ROOT..."
    ROOTSYS=`pwd`
    mypop
  else
    echo "Using pre-built ROOT..."
  fi
  echo "export ROOTSYS=$ROOTSYS" >> $ENVFILE

  LOG4CPPDIR="log4cpp"
  mybr
  if [ "$BUILD_LOG4CPP" == "yes" ]; then
    mymkarch $LOG4CPPDIR
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
    $NICE ./autogen.sh >& log.config
    echo "Running make in $PWD..."
    $NICE gmake >& log.make
    echo "Running make install in $PWD..."
    $NICE gmake install >& log.install
    echo "Finished log4cpp..."
    mypop
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

  LHAPDFDIR=`basename ${LHAPDFSRC} .tar.gz`
  LHAPDFROOT=lhapdf
  mybr
  if [ "$BUILD_LHAPDF" == "yes" ]; then
    mymkarch $LHAPDFROOT
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
    $NICE gmake >& log.make
    echo "Running make install in $PWD..."
    $NICE gmake install >& log.install
    mypop
    echo "Finished building LHAPDF..."
  else
    echo "Using pre-built LHAPDF..."
  fi
  mypush $LHAPDFROOT/lib
  LHAPDF_LIB=`pwd`
  mypop
  mypush $LHAPDFROOT/include
  LHAPDF_INC=`pwd`
  mypop
  echo "LHAPDF lib is $LHAPDF_LIB..."
  echo "LHAPDF inc is $LHAPDF_INC..."
  echo "export LHAPATH=$LHAPDFROOT" >> $ENVFILE
  echo "export LHAPDF_INC=$LHAPDF_INC" >> $ENVFILE
  echo "export LHAPDF_LIB=$LHAPDF_LIB" >> $ENVFILE
  if [ "$GET_PDFS" == "yes" ]; then
    echo "Getting PDFs..."
    mypush $LHAPDFROOT/bin
    for pdf in $PDFLIST
    do
      echo "...Getting $pdf..."
      $NICE ./lhapdf-getdata $pdf --dest=$LHAPDFROOT
    done
    mypop
    echo "Finished getting PDFs..."
  fi

  mybr
  echo "Done!"
  mybr
}

dobuild
