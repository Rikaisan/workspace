#!/bin/sh
sed -i \
         -e 's/rgb(0%,0%,0%)/#383c4a/g' \
         -e 's/rgb(100%,100%,100%)/#d3dae3/g' \
    -e 's/rgb(50%,0%,0%)/#2f343f/g' \
     -e 's/rgb(0%,50%,0%)/#5294e2/g' \
 -e 's/rgb(0%,50.196078%,0%)/#5294e2/g' \
     -e 's/rgb(50%,0%,50%)/#404552/g' \
 -e 's/rgb(50.196078%,0%,50.196078%)/#404552/g' \
     -e 's/rgb(0%,0%,50%)/#d3dae3/g' \
	"$@"
