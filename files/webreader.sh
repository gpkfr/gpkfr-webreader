#!/bin/sh
# Install le webreader


[ $# -eq 2 ] || exit 1

BASE_DIR=$1
WEBREADER=$2

DOCROOT=${BASE_DIR}/${WEBREADER}


[ ! -r ${DOCROOT}/${WEBREADER}.lock ] || exit 0

export PATH=/usr/local/node/node-default/bin:$PATH
export CI=true

#Main
cd $DOCROOT
npm install
bower install
gulp build

> ${DOCROOT}/${WEBREADER}.lock
exit 0
