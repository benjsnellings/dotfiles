#!/bin/bash

ping -c 1 192.168.1.61 > /dev/null 2>/dev/null;
retcode=$(echo $?);
if [ $retcode = 0 ]
then
    echo " online";
else
    echo " offline";
fi
