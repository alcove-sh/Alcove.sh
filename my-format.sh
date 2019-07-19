#!/bin/sh

# To format each line ends without ';'
sed -Ei 's/(.*[^;]);$/\1/g' alcove.sh
exit $?

