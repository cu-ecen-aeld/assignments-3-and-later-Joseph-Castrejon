#!/bin/sh
# Student: Joe Castrejon
# Course: Linux System Programming and Introduction to Buildroot

writefile=$1
writestr=$2

# Check if parameters are present.
if [ -z "$writefile" ] || [ -z "$writestr" ]; then
	printf "ERROR: One or more parameters are missing.\n"
	exit 1
fi 

# Get path
file_dir=$(dirname $writefile)

mkdir -p $file_dir

# Create new file
touch $writefile

if [ ! -e $writefile ]; then
	printf "ERROR: Could not create file '$writefile'.\n"
	exit 1
fi

# Overwrite contents with string.
echo $writestr >> $writefile
exit 0
