#! /usr/bin/env bash
# SPDX-FileCopyrightText: 2020 Tobias Fella <fella@posteo.de>
# SPDX-License-Identifier: CC0-1.0
$XGETTEXT `find . -not -path "./build/*" \( -name "*.cpp" -o -name "*.qml" -o -name "*.js" \)` -o $podir/dim.pot
