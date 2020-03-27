#!/bin/bash
#
# Dribble lines from iinput to output
# $1 per second, forever. If argument isn't provided, default to
# 1 per second.
#
HERE=`dirname $0`

if [ -z "$1" ]
then
    n=1
else
    n=$1
fi

    while read line; do
        echo $line 
        sleep 1
    done 

