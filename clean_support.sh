#!/bin/bash

DO_CLEAN="no"
CLEAN_ARCHIVE="no"
HELPFLAG="no"

while getopts "efh" options; do
  case $options in
    e) DO_CLEAN="yes";;
    f) CLEAN_ARCHIVE="yes";;
    h) HELPFLAG="yes";;
  esac
done

if [ "$DO_CLEAN" == "no" ]; then
  HELPFLAG="yes"
fi

if [ "$HELPFLAG" == "yes" ]; then
  echo "./clean_support.sh       -e   # do the clean - this flag MUST be supplied to remove ANYTHING"
  echo "                         -f   # clean the user files in the archive directory as well"
  echo "                         -h   # show help and exit"
  echo " "
  echo " Examples:   "
  echo "  ./clean_support.sh -e      # clean the install"
  echo "  ./clean_support.sh -e -f   # clean the install and the archive"
  echo "  ./clean_support.sh -f      # NO CLEAN. print help and exit!"
  echo "  ./clean_support.sh -e -h   # NO CLEAN. print help and exit!"
  exit 0
fi


if [ "$CLEAN_ARCHIVE" == "yes" ]; then
  echo "Cleaning archived env setup files..."
  rm -f  archive/*environment_setup*
  echo "Cleaning archived GSL tar balls..."
  rm -rf archive/*gsl*tar.gz
  echo "Cleaning archived HepMC tar balls..."
  rm -rf archive/*HepMC*tar.gz
  # DO NOT remove the log4cpp source bundle we need to install.
  echo "Cleaning archived log4cpp tar balls..." 
  rm -rf archive/1*log4cpp.tgz
  echo "Cleaning archived LHAPDF tar balls..."
  rm -rf archive/*lhapdf*tar.gz
  rm -rf archive/*LHAPDF*tar.gz
  echo "Cleaning archived boost tar balls..."
  rm -rf archive/*boost*.tar.gz
  echo "Cleaning archived Pythia8 tar balls..."
  rm -rf archive/*pythia8*.tgz
# NOTE: RooMUHistos is not archived (yet); nothing to remove
fi

echo "Cleaning env setup file..."
rm -f  environment_setup.sh
echo "Cleaning GSL..."
rm -rf gsl
echo "Cleaning HepMC..."
rm -rf hepmc
echo "Cleaning boost..."
rm -rf boost
echo "Cleaning LHAPDF..."
rm -rf lhapdf
echo "Cleaning ROOT..."
rm -rf root
echo "Cleaning log4cpp..."
rm -rf log4cpp
echo "Cleaning Pythia6..."
rm -rf pythia6
echo "Cleaning Pythia8..."
rm -rf pythia8*
echo "Cleaning RooMUHistos..."
rm -rf RooMUHistos*
