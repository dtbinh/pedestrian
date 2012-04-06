#!/bin/bash
#A script to automatically convert and crop images


if [ -z "$1" ]
then
	echo -e "usage :./convertToBmp.sh filename WIDTHxHEIGHT\nwhere: \n\t WIDTH is the width of the netlogo area \n\t HEIGHT the height of the netlogo area"
	exit 1;
fi
fname=`basename "$1"`
fname=${fname%.*}

finalsize=$2

echo "pdf to eps"
#convert first to eps
pdftops -eps "$1" "$fname"


#convert to bmp while croping and resing the image
echo "eps to bmp"
convert -density 300 "$fname" "$fname.bmp"
#get original size"
width=`identify -format "%[fx:w]" "$fname.bmp"`
height=`identify -format "%[fx:h]" "$fname.bmp"`
echo "$fname : $width x $height"

#set new size as a half of original sizes
newwidth=$(($width/2))
newheight=$(($height/2))

convert "$fname.bmp" -crop ${newwidth}x${newheight}+$(($width/4))+$(($height/4)) -resize $finalsize! "$fname.bmp"
echo "resized to $newwidth x $newheight and crop to "$finalsize
echo "clean"
rm "$fname"
echo "done"

