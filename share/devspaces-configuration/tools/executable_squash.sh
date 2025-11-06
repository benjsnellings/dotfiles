#!/bin/sh
#

#get number of commits to squash
#squashCount=$1

#get the commit message
#shift
#commitMsg=$@
#commitMsgNum=`expr $squashCount`
commitMsg=`git log -n 1 --first-parent HEAD --pretty=format:'%s%n%n%b'`
#regular expression to verify that squash number is an integer
regex='^[0-9]+$'

echo "---------------------------------"
echo "Will squash into the last commit"
echo "Commit message will be '$commitMsg'"

echo "...validating input"
#if ! [[ $squashCount =~ $regex ]]
#then
#    echo "Squash count must be an integer."
if [ -z "$commitMsg" ]
then
    echo "Invalid commit message.  Make sure string is not empty"
else
    echo "...input looks good"
    echo "...adding all diffs"
    git add -A
    echo "...commiting the changes"
    git commit -m "Commit by Ben's squash script"
    echo "...proceeding to squash"
    #git reset --soft HEAD~$squashCount
    git reset --soft HEAD~2
    git commit -m "$commitMsg"
    echo "...done"
fi

echo
exit 0
