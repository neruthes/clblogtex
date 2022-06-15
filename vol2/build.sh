#!/bin/bash

#
# Notes:
#   - PWD should be repository root
#

ls vol2/articles/*.tex | sed 's|^|\\input\{|' | sed 's|$|}|' > vol2/list.tex
