#!/usr/bin/env bash

grep.() {
	grep --exclude-dir={.git,node_modules,build,.config,.cache} --exclude="*.{o,so,a,pyc}" "$@"
	return $?
}

export -f grep.

# grep -r --include="*$suffix" "$pattern" . | grep -o "$pattern" | sort -u

