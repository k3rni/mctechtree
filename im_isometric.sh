#! /bin/bash

export IMG="block_0.png[16x16+0+16]"
export TOPIMG="block_0.png[16x16+80+112]"
export SIMG="block_0.png[16x16+64+112]"
export TOP="( $TOPIMG +repage -resize 64x76! -alpha set -background none -shear 0x30 -rotate -60 -gravity center  )"
export LEFT="( $SIMG +repage -resize 64x64! -alpha set -background none -shear 0x30  )"
export RIGHT="( $SIMG +repage -resize 64x64! -alpha set -background none -shear 0x-30  )"

convert $LEFT $RIGHT +append \( $TOP -repage -2-56 \) -background none -layers merge +repage copper.png
