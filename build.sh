#!/bin/sh

# Author: urain39 <urain39[AT]qq[DOT]com>

set -e

sed -e '/^[ \t]*$/d' \
	-e '/^[ \t]*#.*$/d' \
	-e 's/^[ \t]*//' \
	-Ee 's/^#! +([^ ;]+)/#!\1/' \
	-Ee 's/^([^;]+);[ \t]*$/\1/' \
	-Ee 's/\$([A-Za-z_][0-9A-Za-z_]+|[0-9A-Za-z@#!?%_-])/\${\1}/g' \
		./alcove.sh > dist/alcove


