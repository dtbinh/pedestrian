CF aussi la description dans le fichier .nlogo

1. La premiere chose à faire est de choisir entre "bmp" et "ledru" au niveau du bouton "env"
 - ledru permetra de générer un simili carefour tracé "à la main"
 - bmp permet de choisir un plan à utiliser.

2. Si bmp est selectionné : 
Il faut entrer le nom du plan dans la case "Name". Ce nom doit correspondre à un fichier présent dans data/input/maps/ ayant le même nom (exemple : si test est entrés dans "Name", alors test.bmp doit être exister dans data/input/maps). Le fichier équivalent .tm doit aussi être présent dans data/input/timing/ (cf data/input/timing/README)

3. Une fois les étapes précendantes finies, appuyer sur "Setup". L'image du plan (ou le plan fait main) devrait se charger, les variables définies, etc.
Si l'image ne se charge pas alors revoir les étapes 1 et 2

4. Pour lancer la simulation, appuyer sur "GO".
Si la simulation ne démarre pas, vérfier que avort est bien sur "off" (si avort est sur "on" cela veut dire que l'on veut "arrêter" la simulation. Ça peut sembler contre-intuitif, mais il y a une logique).

5.La simulation durera tant que le nombre de "ticks" n'aura pas atteint "duration". Pour arrêter la simulation avabt il suffit de mettre le bouton "avort" sur "on".

6.Les résultats sont écrits dans un fichier texte dans data/output/modelOutputFiles/

7. Pour analyser les fichiers de sortie, des scripts sont disponibles dans script/
