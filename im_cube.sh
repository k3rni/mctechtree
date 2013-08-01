#! /bin/bash

export IMG="block_0.png[16x16+16+48]"
export TOPIMG="block_0.png[16x16+16+48]"
export SIMG="block_0.png[16x16+16+48]"
export TOP="( $TOPIMG +repage -resize 64x76! -alpha set -background none -shear 0x30 -rotate -60 -gravity center )"
export LEFT="( $SIMG +repage -resize 64x64! -alpha set -background none -shear 0x30 )"
export RIGHT="( $SIMG +repage -resize 64x64! -alpha set -background none -shear 0x-30 )"
export ALPHA="-channel Alpha -evaluate Divide 3"

convert $LEFT $RIGHT +append \( $LEFT -repage +64-36 $APLHA\) \( $RIGHT -repage -0-36 $ALPHA \) \( $TOP -repage -0+6 $ALPHA \)  \( $TOP -repage -0-56 \) -background none -layers merge +repage -crop 127x138+0+0 -resize 32x32 copper.png
