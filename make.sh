#!/bin/bash

TARGET_VOLUME="$1"

if [[ -z "$TARGET_VOLUME" ]]; then
    TARGET_VOLUME=2
fi

bash vol$TARGET_VOLUME/build.sh
ntex blog/CL_vol$TARGET_VOLUME.tex --nosync $2
