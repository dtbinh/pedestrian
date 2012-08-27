#!/bin/bash
#Un petit script pour updater l'archive publique telechargeable sur le git

cd ../../
rm pedestrian/pedestrian-last.tgz;
tar czvf pedestrian-last.tgz --exclude-from pedestrian/.archexclude pedestrian/;
mv pedestrian-last.tgz pedestrian;
cd pedestrian/script

