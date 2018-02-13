#!/bin/bash

SELF=`dirname ${BASH_SOURCE}`
. ${SELF}/../common.sh

CURRENT_OUTPUTS[0]="${SELF}/output.gd"
EXPECTED_OUTPUTS[0]="${SELF}/expected.gd"

TESTCMD="\
    ${GDTOOLS} \
        SUBTRACT \
        -o ${SELF}/output.gd \
        ${SELF}/input_1.gd \
        ${SELF}/input_2.gd \
    "

do_test $1 ${SELF}
