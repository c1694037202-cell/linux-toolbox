#!/bin/bash
echo "starting program at $(date)" #Date will be substituted
echo "running program $0 with $# arguments with pid $$"
for file in "$@"; do
	grep foobar "$file" > /dev/null 2> /dev/null
	#When pattern is not found, grep has exit status
	#We redirect STDOUT and STDERR to a null register are about them
	if [[ "$?" -ne 0 ]]; then
		echo "File $file does not have any foobar, adding one"
		echo "$foobar" >> "file"
	fi
done

