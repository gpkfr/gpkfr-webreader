#!/bin/sh
# Install le webreader

BASE_DIR=/var/www

[[ $# -eq 1 ]] || exit 1

WEBREADER=$1
DOCROOT=${BASE_DIR}/${WEBREADER}

#Main
cd $DOCROOT
npm install
bower install
gulp build

> ${DOCROOT}/${WEBREADER}.lock
exit 0
