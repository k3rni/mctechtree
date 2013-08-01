#! /bin/bash

export TOPIMG="block_0.png[16x16+96+0]"
export SIMG="block_0.png[16x8+80+0]"
export TOP="( $TOPIMG +repage -resize 64x76! -alpha set -background none -shear 0x30 -rotate -60 -gravity center )"
export LEFT="( $SIMG +repage -resize 64x32! -alpha set -background none -shear 0x30 )"
export RIGHT="( $SIMG +repage -resize 64x32! -alpha set -background none -shear 0x-30 )"

convert $LEFT $RIGHT +append \( $TOP -repage -0-56 \) -background none -layers merge +repage -crop 126x110+0+11 -resize 32x32 copper.png
