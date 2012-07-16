#!/bin/bash
#this script cut the list line of file in modelOutputFiles

for i in data/output/modelOutputFiles/*.csv ; do
	j=${i}_new;
	head -n $((`wc -l "$i" | awk '{print $1}'`-1)) "$i" > "$j";
	mv "$j" "$i";
done
