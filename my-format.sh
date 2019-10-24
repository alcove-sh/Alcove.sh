#!/bin/sh

find . -type f -name '*.sh' | xargs -i -- sed -i \
	-Ee 's/^#! +([^ ;]+)/#!\1/' \
	-Ee 's/^([^;]+);[ \t]*$/\1/' \
	-Ee 's/\$([A-Za-z_][0-9A-Za-z_]+|[0-9A-Za-z@#!?%_-])/\${\1}/g' \
		"{}"

