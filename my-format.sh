#!/bin/sh

# To format shebang style
sed -Ei 's/^#! +([^ ;]+)/#!\1/g' alcove.sh

# To format each line ends without ';'
sed -Ei 's/([^;]+);$/\1/g' alcove.sh

# To format '$X' -> '${X}'
sed -Ei 's/\$([0-9A-Za-z@#!?%_-]|[A-Za-z_][0-9A-Za-z_]+)/\${\1}/g' alcove.sh
exit $?

