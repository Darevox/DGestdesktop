#!/bin/bash

# Set up environment variables
BASEDIR="$(pwd)"    # Root of your source directory
PROJECT="dim"       # Your project name
PACKAGE="$PROJECT"
BUGADDR="akram@riseup.net"  # Email for bug reports
WDIR="$BASEDIR"

echo "Preparing extraction files"

# Create temporary directory
mkdir -p "$BASEDIR/po"

echo "Extracting messages"
XGETTEXT="xgettext --from-code=UTF-8 -C -kde -ci18n -ki18n:1 -ki18nc:1c,2 -ki18np:1,2 \
          -ki18ncp:1c,2,3 -ktr2i18n:1 -kI18N_NOOP:1 -kI18N_NOOP2:1c,2 -kN_:1 \
          -kaliasLocale -kki18n:1 -kki18nc:1c,2 -kki18np:1,2 -kki18ncp:1c,2,3"

export XGETTEXT
export podir="$BASEDIR/po"

# Call the Messages.sh script
sh ./Messages.sh

echo "Merging translations"
cd "$BASEDIR"
catalogs=$(find . -name '*.po')
for cat in $catalogs; do
  echo "$cat"
  msgmerge --no-fuzzy-matching  -o "$cat.new" "$cat" "po/$PROJECT.pot"
  mv "$cat.new" "$cat"
done

