#!/bin/bash

TESTBUILDSLOG="log_test_builds.txt"
TESTARCHIVELOG="log_test_archive_list.txt"

# warn the user - this is not for general use
warn_the_user()
{
    echo ""
    cat <<EOF
                                WARNING! 

Do not run these tests unless you know what you are doing! All they will do
is build a lot of code and then tear it back down.

EOF
    echo "Press ctrl-c to stop. Otherwise starting the (long) set of tests in..."
    for i in {10..1}
    do
        echo "$i"
        sleep 1
    done
}

init_logs()
{
    DAT=`date -u +%s`
    echo "Initializing logs at $DAT"
    echo "Date is $DAT" >& $TESTARCHIVELOG
    echo "Date is $DAT" >& $TESTBUILDSLOG
}

teardown()
{
    echo "START TEARDOWN------------------------------------------------------" \
        | tee -a $TESTARCHIVELOG
    echo " Before teardown; Archive contents:" | tee -a $TESTARCHIVELOG
    ls archive >> $TESTARCHIVELOG
    ./clean_support.sh -e -f | tee -a $TESTARCHIVELOG
    echo " After  teardown; Archive contents:" | tee -a $TESTARCHIVELOG
    echo "FINISH TEARDOWN-----------------------------------------------------" \
        | tee -a $TESTARCHIVELOG
}

test()
{
    PYTHIAV=$1
    ROOTV=$2
    HTTPFLAG=""
    if [[ $# > 2 ]]; then
        HTTPFLAG=$3
    fi
    echo "START TEST----------------------------------------------------------" \
        | tee -a $TESTBUILDSLOG
    echo "Build command is: ./build_support.sh -p $PYTHIAV -r $ROOTV $HTTPFLAG" \
        | tee -a $TESTBUILDSLOG
    ./build_support.sh -p $PYTHIAV -r $ROOTV $HTTPFLAG \
        | tee -a $TESTBUILDSLOG
    if [[ $? != 1 ]]; then
        echo " "
        echo " "
        echo " "
        echo "The build failed! There was an ERROR = $?!"
        teardown
        echo " "
        echo "Exiting after error!"
        exit 1
    fi
    echo "FINISH TEST---------------------------------------------------------" \
        | tee -a $TESTBUILDSLOG
}

warn_the_user
init_logs

test 6 v5-34-24 -s
teardown

test 8 v5-34-24 -s
teardown

echo " "
echo " "
DAT=`date -u +%s`
echo "Done at $DAT"
