#!/bin/sh
# Student: Joe Castrejon
# Course: Linux System Programming and Introduction to Buildroot

filesdir=$1
searchstr=$2

# Check if parameters are present.
if [ -z "$filesdir" ] || [ -z "$searchstr" ]; then
	printf "ERROR: One or more parameters are missing.\n"
	exit 1
fi 


# Check if parameter 'filesdir' is not on filesystem
if [ ! -d "$filesdir" ]; then
	printf "ERROR: Parameter 'filesdir' is not a directory on system.\n"
	exit 1
fi

# Get total number of files under a directory and all sub-directories.
x=$(find $filesdir -type f | wc -l)

# Get matching lines containing 'searchstr' using grep.
y=$(grep -r $searchstr $filesdir | wc -l)

# Print result
printf "The number of files are $x and the number of matching lines are $y.\n"
exit 0
