#! /bin/bash

export TOPIMG="block_0.png[8x16+0+16]"
export TOPIMG_TOP="block_0.png[8x16+8+16]"
export SIMG="block_0.png[16x8+0+16]"
export SIMG_TOP="block_0.png[16x8+0+24]"
export SIMG_TOP_RIGHT="block_0.png[8x8+8+16]"

export TOP="( $TOPIMG +repage -resize 32x76! -alpha set -background none -shear 0x30 -rotate -60 -gravity center )"
export TOP_TOP="( $TOPIMG_TOP +repage -resize 32x76! -alpha set -background none -shear 0x30 -rotate -60 -gravity center )"
export LEFT="( $SIMG +repage -resize 64x32! -alpha set -background none -shear 0x30 )"
export LEFT_TOP="( $SIMG_TOP +repage -resize 64x32! -alpha set -background none -shear 0x30 )"
export RIGHT="( $SIMG +repage -resize 64x32! -alpha set -background none -shear 0x-30 )"
export RIGHT_TOP="( $SIMG_TOP_RIGHT +repage -resize 32x32! -alpha set -background none -shear 0x-30 )"

convert $LEFT $RIGHT +append \( $LEFT_TOP -repage +32-50 \) \( $TOP -repage -1-28 \) \( $RIGHT_TOP -repage +96-32 \) \( $TOP_TOP -repage +31-78 \) -background none -layers merge +repage copper.png
