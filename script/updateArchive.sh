#!/bin/bash
#Un petit script pour updater l'archive publique telechargeable sur le git

cd ../../
rm pedestrian/pedestrian*.tgz;
tar czvf pedestrian`date +%Y-%m-%d`.tgz --exclude-from pedestrian/.archexclude pedestrian/;
mv pedestrian*.tgz pedestrian;
cd pedestrian/script

