;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;;;;;;;AUCRE Simulation de traversé de pietons
;;;;;;;
;;;;;;;Première implémentation Mars 2011, Simon Carrignon simon.carrignon@gmail.com
;;;;;;;

globals
[
  
  h ;List of heights of building block
  w ;List of widths of building block
  t ;List of width of trottoirs
  
    ;;;;;;;;;;;;;;;;;;;;;;;;
    ;;;;;;;;ICI EN PROFITER POUR DECRIRE LE PLACEMENT
    ;;;;;;;;ET LES NUMEROTATIONS
    ;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
    ;;;;;;;;
    ;;;;;;;;
  
  
  bx1        ;;coordonées des block d'immeubles
  bx2        ;; ---
  by1        ;; ---
  by2        ;; ---
  
  zx1        ;; coordonnées des zebra pietons
  zx2        ;; ---
  zy1        ;; ---
  zy2        ;; ---goal
  
  izx1        ;; cordinates of illegals zebra 
  izx2        ;; ---
  izy1        ;; ---
  izy2        ;; ---
  
  tx1        ;; coordonnées des trotoires
  tx2        ;; ---
  ty1        ;; ---
  ty2        ;; ---
  
             ;; patch agentsets
  trottoirs    ;; patchset containing the patches that are trottoirs
  roads         ;; patchset containing the patches that are roads
  buildings     ;; patchset containing the patches that are building's blocks
  inout        ;;  patchset sur lesquels de nouveaux piétons peuvent apparaître
  numio        ;;number of input ouput zone available
  zebra        ;;patchset containing zebras
  izebra      ;;patchset containing illegal zebras
  lights
  ;;;;;;;;;;;;;;;;;;;;;;;;;; general colors
  iocolors     ;;tableau contenant eles couleurs des différentes entrées/sorties possibles
  bcolor       ;; block color
  tcolor       ;; trotttoire color
  zcolor       ;; zebra color
  rcolor       ;; road color
  Lcolors
  z-size       ;;epaisseur d'un passage piéton
  echelle      ;;echelle du plan a 
  SOUTH1       ;; identifiant de la première partie passage pietons au SUD 
  SOUTH2       ;; identifiant de la seconde partie passage pietons au SUD 
  EAST         ;; identifiant du passage pietons à l'EST
  WEST         ;; identifiant du passage pietons à l'OUEST
  NORTH        ;; identifiant du passage pietons au NORD
  
  
               ;  bmpFilename  ;;file name of the background image
]

turtles-own
[
  speed     ;; the speed of the turtle
  up-car?   ;; true if the turtle moves downwards and false if it moves to the right
  wait-time ;; the amount of time since the last time a turtle has moved
  goal      ;; id of the exit where the agent want to go
  quick
  cross?    ;; tell whether or not the agent is crossing a zebra/izebra
  lifetime  ;;
]


patches-own
[
  intersection?   ;; true if the patch is at the intersection of two roads
  green-light-up? ;; true if the green light is above the intersection.  otherwise, false.
                  ;; false for a non-intersection patches.
  my-row          ;; the row of the intersection counting from the upper left corner of the
                  ;; world.  -1 for non-intersection patches.
  my-column       ;; the column of the intersection counting from the upper left corner of the
                  ;; world.  -1 for non-intersection patches.
  my-phase        ;; the phase for the intersection.  -1 for non-intersection patches.
  auto?           ;; whether or not this40 intersection will switch automatically.
                  ;; false for non-intersection patches.
  
  io-id           ;; inout identification number
  zebra-id        ;; if a patch is a zebra it's its idea
  zid             ;; if a patch is a illegal zebra it's the z-idea associated (it allow the agents to know the state of lights on this zebra)
  pl-state        ;; state of pedestrian light around the zebra zone
  cl-state        ;; state of car light around the zebra zone
  
  light-id        ;; id of a light
  car-light?      ;;if it's a car light or not
  state           ;;state of a light
  proba
]


breed[
  cars car
  
]
;;;;
;; initiailise certaines variables statiques comme les couleurs 
;; certaines mesures statiques et fait appelle aux procedures pour calculer les coordonnés en fonction de ces
;; mesures
to initialize
  set bcolor [157 110 72] ;brown
  set Lcolors [red orange green]
  set iocolors [blue green red yellow]
  set zcolor [255 255 255] ;white
  set rcolor [0 0 0] ;black
  set tcolor [141 141 141];grey
  set lights patch-set nobody
  
  
  set SOUTH1 0
  set SOUTH2 4
  
  set EAST 1
  
  set WEST 3
  
  set NORTH 2
  
  ask patches [set proba -1]
  
end


;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;; Cette fonction initialise les mesures necessaires 
;; au calcul des coordonnées des différent éléments du carrefour spécifiquemment pour 
;; le croisemment ledru rollin/Faubourg SA.
;; c'est ici que sont déclarées les largeurs des trottoirs, des routes, etc.. En fonction de mesures faites TRES
;; approximativemment à partir du plan gracieusement imprimé par le service de l'urbanisme du XIe arrondissement de Paris
;;
;; 
to initializeLedru
  set w [12 16 18 0 18 ]  
  set h [14 15 12 17]
  set bx1 [0 0 0 0] 
  set by1 [0 0 0 0] 
  set bx2 [0 0 0 0] 
  set by2 [0 0 0 0] 
  
  set zx1 [0 0 0 0] 
  set zy1 [0 0 0 0] 
  set zx2 [0 0 0 0] 
  set zy2 [0 0 0 0] 
  
  set izx1 [0 0 0 0] 
  set izy1 [0 0 0 0] 
  set izx2 [0 0 0 0] 
  set izy2 [0 0 0 0] 
  
  set tx1 [0 0 0 0] 
  set ty1 [0 0 0 0] 
  set tx2 [0 0 0 0] 
  set ty2 [0 0 0 0] 
  
  set t [6 2 3 3 3 3 4 6]
  
  set echelle 5  ;;echelle approximative pour passer des mesures en cm sur le papier au m de la réalité. 1 patch = 1m
  set z-size 0.8 * echelle
  
  set t [.9 1.1 .9 .9 1 1 1 .9 ] ;;largeur appro des 8 troittoires
  let a 0
  foreach t [ ;;mise à l'echelle des troittoires
    set t (replace-item a t (? * 5)) 
    set a (a + 1) 
  ]
  
  
  set w ( replace-item 3 w  ( (max-pxcor) - ((1 / 2) * 2.5 * echelle) - ( item 6 t ))) ;;calcul de la largeur des block à dessiner
  set w ( replace-item 2 w  ( (max-pxcor) - ((1 / 2) * 2.5 * echelle) - (  item 5 t )))
  set h ( replace-item 3 h  ( (max-pycor) - ((1 / 2) * 2.4 * echelle) - (  item 7 t )))
  set h ( replace-item 2 h  ( (max-pycor) - ((1 / 2) * 2.4 * echelle) - ( item 4 t )))
  
  
  set w ( replace-item 0 w  ( (max-pxcor) - ((1 / 2) * 3.4 * echelle) - (item 1 t) ))
  set h ( replace-item 0 h  ( (max-pycor) - ((1 / 2) * 2.4 * echelle) - ( item 0 t)))
  
  set h ( replace-item 1 h  ( (max-pycor) - ((1 / 2) * 2.4 * echelle) - ( item 3 t)))
  set w ( replace-item 1 w  ( (max-pxcor) - ((1 / 2) * 3.4 * echelle) - ( item 2 t)))
  
end

extensions[ bitmap ]

to initializeBmp
;  if(bmpFilename = "") [ set bmpFilename "../data/intput/maps/t1.bmp"]
  let bmpFilename (word "../data/input/maps/" Name ".bmp")
  let bg bitmap:import bmpFilename
  ; set world-width bitmap:width bg 
  ; set world-height bitmap:height bg 
  ; set bg bitmap:scaled bg 81 81
  bitmap:copy-to-pcolors bg FALSE
end

;; Make the patches have appropriate colors, set up the roads and intersections agentsets,
;; and initialize the traffic lights to one setting
to setup-patches
  
  ask patches [
    set zebra-id -1
    set zid -1
    set light-id -1
  ] 
  
  setup-zebra
  let allb [[] [] [] []] 
  
  let allt [[] [] [] []]
  foreach [0 1 2 3][
    
    set allb ( replace-item ? allb ( getRect ( item ? bx1 ) (item ? by1) (item ? bx2) (item ? by2)) ) ;get block rectangle
    set allt ( replace-item ? allt ( getRect ( item ? tx1 ) (item ? ty1) (item ? tx2) (item ? ty2)) )
    ask item ? allt [ set pcolor tcolor set proba 100 ] ;draw trottoirs
    ask item ? allb [ set pcolor bcolor set proba -1 ] ;draw block rectangle
    
  ]
  
  
  
  
  
  set trottoirs patches with [ pcolor = tcolor]
  
  set buildings patches with [ pcolor = bcolor]
  
  setup-inout
  
  setup-lightLedru
  
end
to setup-patchesBmp
  ask patches [
    set zebra-id -1
    set zid -1
    set light-id -1
  ] 
  
  set trottoirs patches with [ pcolor = tcolor ]
  
  set buildings patches with [ pcolor = bcolor] ask buildings [let pzcor 10]

  ask trottoirs [ set proba 100 let pzcor 2] ;draw trottoirs
  setup-zebraBmp
  setup-inoutBmp
  setup-lightBmp
end  


to setup-lightBmp
  set lights patches with [ (item 0 pcolor) = 255 and ( (item 1 pcolor) = 0 or (item 1 pcolor) = 1 ) ] 

  ask lights with [ (item 1 pcolor) = 0 ] [set light-id item 2 pcolor]
  ask lights with [ (item 1 pcolor) = 1 ] [set light-id item 2 pcolor set car-light? true set state 0 changeCol]
end


to setup-zebraBmp
    set zebra patches with [  (item 0 pcolor) = 255 and (item 1 pcolor) = 255 ]
;  ask zebra [ set proba probzeb]
  ask zebra [set zebra-id 255 - item 2 pcolor set proba probzeb ] 
  
  set izebra patches with [ (item 0 pcolor) = 0 and (item 1 pcolor) = 0 ] 
  ask izebra [set zid item 2 pcolor set proba probizeb ] 
 
end

;;;;;;;;
;;setup zebra 
;;Defini est dessine les zones de passage piétons en fonction des coordonnées 
;;calculées ou définies précedemment 
to setup-zebra
  let allp [[][][][]]
  let allip [[][][][]]
  
  foreach [ 0 1 2 3][
    set allp replace-item ? allp (getRect (item ? zx1) (item ? zy1) (item ? zx2) (item ? zy2))
    set allip replace-item ? allip (getRect (item ? izx1) (item ? izy1) (item ? izx2) (item ? izy2))
    ask item ? allp [
      set pcolor zcolor  ;blanchi les passages
      set zebra-id ?     ;assigne au patche du passage un id
      ifelse(? mod 2 = 0)[set pl-state 0][set pl-state 2]] ;just epour initialiser les feux qui seront associer à ce passage : ne sert à rien
    
    ask item ? allip [
      if(zebra-id = -1)[
        ;  set pcolor green ;
        set zid ?     ;assigne au patche du passage illegal l'id du zebra associer
      ]   
    ]      
  ]
  
  set zebra patches with [ zebra-id > -1]
  
  set izebra patches with [ zid > -1]
  ;;for ledru rollin : we split the south zebra in two
  ask zebra with [zebra-id = 0 and (pxcor > 0)][set zebra-id SOUTH2 set pl-state 1]
  ask izebra with [zid = 0 and (pxcor > 0)][set zid SOUTH2]
  
  ask zebra [ set proba probzeb]
  
  ask izebra [set proba probizeb]
  
end
;;;;;;;;;;;;;;;;;;;;;;


;;;;;;;;;;;;;;;;;;
;;Calcul/définition des coordonées des principaux élements du décors
;; soit : les buildings, les trottoirs et les passages piétons
;; tous les autres élements (feux, sortie..) seront ensuite positionné relativement à ces
;; coordonnées
to setup-coor 
  
  buildings-coor
  trottoirs-coor
  
  zebra-coor
end
;;;;;;;;;;;;;;;;;;;





;;;;;;;;
;Calcul les coordonnées des blocks de buildings en fonction
;;de la hauteur et de largeur de ces derniers
to buildings-coor
  ;;Set cordinate of the left bottom corner of building blocks
  
  set bx1 replace-item 0 bx1 min-pxcor 
  set by1 replace-item 0 by1 min-pycor 
  
  set bx1 replace-item 1 bx1 ( max-pxcor - item 1 w)
  set by1 replace-item 1 by1 min-pycor 
  
  set bx1 replace-item 2 bx1 (max-pxcor - item 2 w)
  set by1 replace-item 2 by1 (max-pycor - item 2 h)
  
  set bx1 replace-item 3 bx1 min-pxcor 
  set by1 replace-item 3 by1 (max-pycor  - item 3 h)
  
  foreach [0 1 2 3] [
    
    ;;Set cordinate of the right up corner of building blocks
    set bx2 replace-item ? bx2 ( item ? bx1 + item ? w) 
    set by2 replace-item ? by2 (item ? by1  + item ? h) 
    
    
  ]
end

;Initialise les trottoirs en fonction des cordonnées des blocks
;et du vecteur t dans lequel sont stockés toutes les longeurs des trottoirs
;;les trottoirs sont enfaites definis comme des carré de la taille des blocks qu'ils bordent
;;plus la taille du trottoirs en question (dependamment de la position du trottoir sa taille
;; sera ajoutée a la largeur ou à la hauteur du block)
to trottoirs-coor
  
  
  ;;;set cordinate of pavement
  set tx1 replace-item 0 tx1 item 0 bx1
  set ty1 replace-item 0 ty1 item 0 by1
  
  set tx2 replace-item 0 tx2 (item 0 bx2 + item 0 t)
  set ty2 replace-item 0 ty2 (item 0 by2 + item 1 t)
  ;  
  
  set tx1 replace-item 1 tx1 ((item 1 bx1) - (item 2 t))
  set ty1 replace-item 1 ty1 (item 1 by1)
  
  set tx2 replace-item 1 tx2 (item 1 bx2) 
  set ty2 replace-item 1 ty2 ((item 1 by2) + (item 3 t))
  
  
  set tx1 replace-item 2 tx1 ((item 2 bx1) - (item 4 t))
  set ty1 replace-item 2 ty1 ((item 2 by1) - (item 5 t))
  
  set tx2 replace-item 2 tx2 (item 2 bx2)
  set ty2 replace-item 2 ty2 (item 2 by2)
  
  
  
  set tx1 replace-item 3 tx1 (item 3 bx1)
  set ty1 replace-item 3 ty1 ((item 3 by1) - (item 7 t))
  
  set tx2 replace-item 3 tx2 ((item 3 bx2) + (item 6 t))
  set ty2 replace-item 3 ty2 (item 3 by2)
  
  
  
end

;;;;;;;;;;;;;;;
;; Ajuste les coordonné des passages piétons en fonctions 
;; des coordonnées des trottoirs et de distance ici mises manuellement (peut être stocké dans un vecteur pour être bien)
;; c'est ici sa distance par rapport à l'angle du block qui est positionné manuellement et qui pourrait être
;; stocké de façon globale pour en simplifier la modification.
to zebra-coor
  
  
  ;;;set cordinate of zebra
  set zx1 replace-item 0 zx1 item 0 tx2
  set zy1 replace-item 0 zy1 ((item 0 ty2) - (0.5 * echelle) - z-size)
  
  set zx2 replace-item 0 zx2 item 1 tx1
  set zy2 replace-item 0 zy2 ((item 0 ty2) - (0.5 * echelle))
  ;  
  
  set zx1 replace-item 1 zx1 ((item 1 tx1) + (2.6 * echelle))
  set zy1 replace-item 1 zy1 ((item 1 ty2) + 1)
  
  set zx2 replace-item 1 zx2 ((item 1 tx1) +(2.6 * echelle)  + z-size)
  set zy2 replace-item 1 zy2 ((item 2 ty1) - 1 )
  
  
  set zx1 replace-item 2 zx1 ((item 3 tx2))
  set zy1 replace-item 2 zy1 ((item 3 ty1) + (1 * echelle) )
  
  
  set zx2 replace-item 2 zx2 ((item 2 tx1))
  set zy2 replace-item 2 zy2 ((item 3 ty1) + (1 * echelle)  + z-size)
  
  set zx1 replace-item 3 zx1 ((item 0 tx2) - (2.5 * echelle) - z-size )
  set zy1 replace-item 3 zy1 ((item 0 ty2) + 1 )
  
  set zx2 replace-item 3 zx2 ((item 0 tx2) - (2.5 * echelle))
  set zy2 replace-item 3 zy2 ((item 3 ty1) - 1)
  
  
  
  ;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
  ;;;;;;;; Set illegal zebra- 
  ;; !!LES AGRANDIR AU REBORD DES PLUS GRANDS TROTTOIRES QUI LeS BORDENT
  
  
  set izx1 replace-item 0 izx1 (item 0 zx1)
  set izy1 replace-item 0 izy1 ((item 0 zy1) - 10)
  
  set izx2 replace-item 0 izx2 (item 1 tx1)
  set izy2 replace-item 0 izy2 ((item 0 ty2) )
  ;  
  
  set izx1 replace-item 1 izx1 ((item 1 tx1))
  set izy1 replace-item 1 izy1 ((item 1 ty2) + 1)
  
  set izx2 replace-item 1 izx2 ((item 1 zx2) + 4)
  set izy2 replace-item 1 izy2 ((item 2 ty1) - 1 )
  
  
  set izx1 replace-item 2 izx1 ((item 3 tx2))
  set izy1 replace-item 2 izy1 ((item 3 ty1))
  
  set izx2 replace-item 2 izx2 ((item 2 zx2))
  set izy2 replace-item 2 izy2 ((item 2 zy2) + 5)
  
  set izx1 replace-item 3 izx1 ((item 3 zx1) - 10 )
  set izy1 replace-item 3 izy1 ((item 0 ty2) + 1 )
  
  set izx2 replace-item 3 izx2 ((item 0 tx2))
  set izy2 replace-item 3 izy2 ((item 3 ty1) - 1)
  
end

;;;
;Rajoute des feux pietons au debut et à la fin de chaque passage.
;Procédure "automatique" a ne pas utiliser pour un plan donné (par ex pour Ledru)
to setup-light
  
  foreach [0 1 2 3][
    ifelse(? mod 2 = 0)[
      
      ;;create the left light of a horizontal zebra
      let currentLight patch ((min [pxcor] of getZebra ?) - 1 ) (max [pycor] of getZebra ? )  
      ask currentLight [set zebra-id ? changeCol]
      set lights (patch-set lights currentLight)
      
      ;;create the right light of a horizontal zebra
      set currentLight patch ((max [pxcor] of getZebra ?) + 1 ) (min [pycor] of getZebra ? ) 
      ask currentLight [set zebra-id ? changeCol]
      set lights (patch-set lights currentLight)
      
    ]
    [
      
      ;;create the bottom light of a vertical zebra
      let currentLight patch ((min [pxcor] of getZebra ?) ) ( (min [pycor] of getZebra ?) - 1)
      ask currentLight [set zebra-id ? changeCol]
      set lights (patch-set lights currentLight)
      
      ;;create the top light of a vertical zebra
      set currentLight patch ((max [pxcor] of getZebra ?) ) ( (max [pycor] of getZebra ?) + 1 ) 
      ask currentLight [set zebra-id ? changeCol]
      set lights (patch-set lights currentLight)
      
    ]    
  ]
  
end




;;;;;;;;;;;;;;;;
;Procédure qui positionne tout les feux du carrefour Ledru Rollin - Faubourg Saint antoine
to setup-lightLedru
  
  
  
  ;SOUTH----
  ;;create the first west light of the south zebra
  
  let z-id SOUTH1
  add-light  ((item z-id zx1 ) - 1 ) (item z-id zy2) 6 z-id false
  ;;create the second west light of the south zebra
  add-light  (((item z-id zx2 ) + (item z-id zx1) - 1 ) / 2) ((item z-id zy1 ) - 1)  6 z-id false 
  
  
  
  ;;create the east light of the second part of the south zebra
  add-light  (((item z-id zx2)  + (item z-id zx1)+ 1 ) / 2) ((item z-id zy1) - 1) 8 SOUTH2 false
  ;;-add a car light
  add-light  (((item z-id zx2)  + (item z-id zx1) ) / 2) ((item z-id zy1) - 2) 7 SOUTH2 true
  
  ;;create the east light of the second part of the south zebra
  add-light (item z-id zx2 ) (item z-id zy1 - 1 ) 8 z-id  false
  ;;-add a car light 
  add-light (item z-id zx2 ) (item z-id zy1 - 2 ) 7 z-id  true
  ;;-------
  
  
  
  ;EAST----
  set z-id EAST
  ;south light
  add-light ((max [pxcor] of getZebra z-id) ) ( (min [pycor] of getZebra z-id) ) 1 z-id false
  
  ;;north light
  add-light ((max [pxcor] of getZebra z-id) ) ( (max [pycor] of getZebra z-id) + 1 ) 1 z-id  false
  ;;--ad a car light  
  add-light (((max [pxcor] of getZebra z-id)) + 1 ) ((max [pycor] of getZebra z-id) + 1)  0 z-id  true
  ;;-------
  
  ;NORTH---------
  set z-id NORTH
  ;west light----
  add-light ((min [pxcor] of getZebra z-id) - 1 ) (max [pycor] of getZebra z-id ) 5 z-id false 
  
  ;;-add a car light     
  add-light ((min [pxcor] of getZebra z-id) ) (max [pycor] of getZebra z-id + 1) 4 z-id true
  ;east light
  add-light ((max [pxcor] of getZebra z-id) + 1 ) (max [pycor] of getZebra z-id ) 5 z-id false
  ;;-------
  
  ;WEST----
  set z-id WEST
  ;;create the bottom light of a vertical zebra
  add-light ((min [pxcor] of getZebra z-id) ) ( (min [pycor] of getZebra z-id) - 1) 3 z-id false
  add-light ((min [pxcor] of getZebra z-id) - 1) ( (min [pycor] of getZebra z-id) - 1) 2 z-id true
  
  ;;create the top light of a vertical zebra
  add-light ((max [pxcor] of getZebra z-id) ) ( (max [pycor] of getZebra z-id) + 1 ) 3 z-id false 
  ;;-------
  
end


;;
;Function which add a light at the patch of cordinate (x,y) with an idea l-idea and associated with the zebra z-idea. 
;I it's a light to regulate cars car-l? is true.
to add-light [x y l-id z-id car-l?]
  let currentLight patch x y 
  ask currentLight [
    set zebra-id z-id 
    set light-id l-id 
    set car-light? car-l?
    set state 0
    changeCol
  ]
  set lights (patch-set lights currentLight)
end

;;change the color of a light depanding on its state
to changeCol
  set pcolor item (state) Lcolors 
end

;to-report getState [l-id]
;  report min [pl-state] of zebra with [zebra-id = z]
;end

;;;;
; getZebra return a patch set of all patches drawing the zebra z
to-report getZebra [z]
  report zebra with [zebra-id = z]
end

;;;;;
;Setup inout define patches where people can appears and disappears
to setup-inout
  
  ;;set inout define by the start of 
  set inout patches with [
    pcolor = tcolor and (pxcor = max-pxcor - 1 or pxcor = min-pxcor + 1 or pycor = max-pycor - 1 or pycor = min-pycor + 1)
  ]
  ask inout [
    
    if pycor = min-pycor + 1 and (pxcor <= (item 0 tx2) ) [setio 0 ]
    if pycor = min-pycor + 1 and (pxcor >= (item 1 tx1) ) [setio 1 ]
    
    if pxcor = max-pxcor - 1 and (pycor <= item 1 ty2 ) [setio 2 ]    
    if pxcor = max-pxcor - 1 and (pycor >= item 2 ty1 ) [setio 3 ]
    
    if pycor = max-pycor - 1 and (pxcor >= item 2 tx1 ) [setio 4 ]
    if pycor = max-pycor - 1 and (pxcor <= item 3 tx2 ) [setio 5 ]
    
    if pxcor = min-pxcor + 1 and (pycor >= item 3 ty1 ) [setio 6 ]
    if pxcor = min-pxcor + 1 and (pycor <= item 0 ty2 ) [setio 7 ]
    
    
  ]
  
  set-metro
  set numio max [io-id] of patches
  
end

to setup-inoutBmp
;  set inout patches with [
;    pcolor = tcolor and (pxcor = max-pxcor - 1 or pxcor = min-pxcor + 1 or pycor = max-pycor - 1 or pycor = min-pycor + 1)
;  ]
;  ask inout [
;    
;    if pycor = min-pycor + 1  [setio 0 ]
;    
;    if pxcor = max-pxcor - 1 [setio 1 ]    
;    
;    if pycor = max-pycor - 1 [setio 2 ]
;    
;    if pxcor = min-pxcor + 1[setio 3 ]
;    
;  ]
  set inout patches with [
    item 0 pcolor = 0 and
    item 0 pcolor = 255 
  ]
  ask inout [
    setio item 3 pcolor
  ]
  set numio max [io-id] of inout
end

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;;
;; ajout des stations de metro.
;;  Il est à noter que 2 escaliers ont le même identifiant (ie les agents aparaissent et disparaissent à un des deux)
;; Il serait peut être judicieux de faire une fonction similaire à addLight pour faire ça
to set-metro
  let metOutSize 2
  let currentMetro ( getRect((item SOUTH1 zx1) - metOutsize) (item SOUTH1 zy1 - 1) (item SOUTH1 zx1) (item SOUTH1 zy1 ) )
  ask currentMetro [ setio 8  ]
  set inout (patch-set inout currentMetro)
  
  set currentMetro ( getRect((item 0 zx1) - metOutsize) (item 0 zy1 - 1 - 6) (item 0 zx1) (item 0 zy1 - 6) )
  ask currentMetro [ setio 8  ]
  set inout (patch-set inout currentMetro)
  
  set currentMetro ( getRect((item EAST zx1 ) ) (item EAST zy1 - 1 - metOutSize) (item EAST zx1 + 1 ) (item EAST zy1 - 1 ) )
  ask currentMetro [ setio 9  ]
  set inout (patch-set inout currentMetro)
  
  
  set currentMetro ( getRect((item EAST zx1 + 6) ) (item EAST zy1 - 1 - metOutSize) (item EAST zx1 + 1 + 6) (item EAST zy1 - 1 ) )
  ask currentMetro [ setio 9  ]
  set inout (patch-set inout currentMetro)
  
  
  set currentMetro ( getRect((item NORTH zx2  ) )(item NORTH zy2 + 4 ) (item NORTH zx2  + metOutSize + 1) (item NORTH zy2 + 4) )
  ask currentMetro [ setio 10  ]
  set inout (patch-set inout currentMetro)
  
  set currentMetro ( getRect((item NORTH zx2 ) ) (item NORTH zy2 + 2 + 6) (item NORTH zx2   + metOutSize + 1 ) (item NORTH zy2 + 2 + 6  ) )
  ask currentMetro [ setio 10  ]
  set inout (patch-set inout currentMetro)
  
  
end
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;


;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;;
;;
;;setup the current patch as the inout (can be an entry or an exit at the same time) number "n" with an associated color
to setio [n]
  set io-id n
  if(iocolored)[ set pcolor n * 10 + 6]
end
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;


;;;;;;;;;;;;;;;;;;;;;;;;;;
;; setup the agent 
;; and assign him/it with a random entry and a random goal
;;
to setup-agent
  
  move-to one-of inout
  set goal random numio
  set quick random 0
  set speed 1;set heading towardsxy [pxcor] of g [pycor] of g    ;; On oriente la direction de l'agent vers ce but
  set cross? FALSE;
  set size 4
  face get-goal
end
;;;;;;;;;;;;;;;;;;;;;;;;;;

;;;;;;;;;;;;;;;;;;;;;;;;;;
;; setup the cars 
;; and assign him/it with a random entry 
;;
to setup-cars
  
  ;move-to one-of inout-road
  set goal random numio
  set quick random 0
  set speed 1;set heading towardsxy [pxcor] of g [pycor] of g    ;; On oriente la direction de l'agent vers ce but
  set cross? FALSE;
  face get-goal
end
;;;;;;;;;;;;;;;;;;;;;;;;;;

;;;;;;;;;;;;;;;;;;;;;;;;;;
;; 
;; return a patch which is the goal of the agent
to-report get-goal
  let a goal 
  let g one-of (inout with [io-id = a])
  report g
end
;;;;;;;;;;;;;;;;;;;;;;;;;;


;;;;;;;;;;;;;;;;;;;;;;;;;;
;; First Setup of the environnement
to setup
  clear-all
  initialize
  
  if(env = "ledru")[   
    initializeLedru
    setup-coor
    setup-patches
;    set bmpFilename "ledru"
  ]
  if(env = "bmp")[ initializeBmp setup-patchesBmp]
  
  crt 20 [
    setup-agent
  ]
end

;;;;;;;;;;;;;;;;;;;;;;;;;;

;;;;;;;;;;;;;;;;;;;;;;;;;;
;;return the patch set 
to-report getRect[x1 y1 x2 y2]
  
  report (patches with [pxcor >= x1 and pycor >= y1 and pxcor <= x2 and pycor <= y2])
end
;;;;;;;;;;;;;;;;;;;;;;;;;;


;;peut etre clarifier avec :
;;switchOn [l-id time]
;;switchOr [l-id time]
;;switchOff [l-id time]
to switchOn [l-id time]
  if ( ((ticks mod 70) = time) and light-id = l-id )[set state 2] 
end
to switchOff [l-id time]
  if ( ((ticks mod 70) = time) and light-id = l-id )[set state 0] 
end

to switchOr [l-id time]
  if ( ((ticks mod 70) = time) and light-id = l-id )[set state 1] 
end


;;;
;; fonction d'allumage et eteignage des feux du croisement : peut ETRE SIMPLIFIé
to update-light
  
  switchOn 0 67
  switchOff 0 33
  switchOr 0 30
  
  switchOn 1 38
  switchOff 1 54
  
  switchOn 2 67
  switchOff 2 33
  switchOr 2 30
  
  
  switchOn 3 38
  switchOff 3 55
  
  switchOn 4 36
  switchOff 4 66
  switchOr 4 63
  
  switchOn 5 69
  switchOff 5 23
  
  switchOn 6 69
  switchOff 6 30
  
  switchOn 7 36
  switchOff 7 66
  switchOr 7 63
  
  switchOn 8 66
  switchOff 8 27
  
  
  ;  if (ticks mod (switch-t - orange-t) = 0)[ ask zebra with [pl-state = 2] [ set pl-state 1]]
  ;  if (ticks mod switch-t = 0)[ask zebra with [pl-state = 0] [ set pl-state 2] ask zebra with [pl-state = 1] [ set pl-state 0] ]
  changeCol
end
;;;
;; fonction d'allumage et eteignage des feux en utilisant un fichier dans lequel tout est stocké
to update-lightWithFile
  let timeFilname  (word "../data/input/timing/" Name ".tm") 
  file-open timeFilname
  while [not file-at-end? ] [
  let id file-read
  let On file-read
  let Off file-read
  let Ora file-read

  switchOn id On
  switchOr id Ora
  switchOff id Off
  
  changeCol
  ]
  file-close
end

;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;   MAIN PROCEDURE
;
;
to go
  output-init
  repeat duration[
    if avort [stop]
    tick ;la simulation avance d'un pas
    ask lights [update-lightWithFile] ;mets à jours les feux
    ask turtles [
      agent-behavior
      ifelse(Person)[ set shape "person"][set shape "arrow"] 
      set lifetime (lifetime + 1)
    ]
    if (ticks mod pSpeed = 0) [crt pNb [ setup-agent ]] ;procedure de réaparition des agents
    
    do-plot
    
    ask zebra [ set proba probzeb]
    
    ; ask izebra [set proba probizeb]
    print-output
  ]
  file-close
  stop
  
end 
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;


;;;;;;;;;
;How the agent reacts?
to agent-behavior
  if(lifetime > 100)[ set goal random numio set lifetime 0]
  if ( ( member? patch-at 0 0  inout ) and ([io-id] of patch-at 0 0 = goal))[die report 1]
  
  
  if(not cross?)[ face get-goal ]
  
  let look patch-ahead 1    
  ifelse( look != nobody )[ ;;case when pedestrian reachs a limit of the world
    if( [proba] of look >= 100 )[ set cross? FALSE]    
    
    if(not cross?)[ ;;si le pieton n'est pas déja entrain de traverser
      let p [proba] of look
      let z 0
      let al 0
      
      if( izebra != 0)[  if(member? look izebra)[ set al lights with [zebra-id = ([zid] of look) and car-light? = false]set cross? TRUE ]]
      
      if(member? look zebra)[ set al lights with [zebra-id = ([zebra-id] of look) and car-light? = false]set cross? TRUE]
      
      if(al != 0)[ if(any? al)[if(one-of[state] of al = 2 )[set p (p * 100)]]]
      
      let r (random 100 + 1) 
      
      if(r > p)[ 
        avoidIllegalPatch 
        set cross? FALSE ;;unable to cross a ezbra/izebra
      ]
      
    ]
    ;  
    
  ][avoidIllegalPatch]
  fd speed 
  
end


to avoidIllegalPatch[]
  
  while[patch-ahead 1 = nobody][set heading (heading - 2) ]
  
  
  let r  patch-right-and-ahead 90 3 
  let l  patch-left-and-ahead 90 3
  
  
  while[[proba] of patch-ahead 1 != 100][ 
    ;;;Check left and right paches to know wich side choose
    ifelse(r = nobody )[ set heading (heading - 2)][
      ifelse(l = nobody )[ set heading (heading + 2)][
        ifelse([proba] of r <= [proba] of l) [ set heading (heading - 2) ][set heading (heading + 2)]
        ;       show heading 
        while[patch-ahead 1 = nobody][set heading (heading - 2) ]
        
      ]
    ]
    ;   ;show [proba] of patch-ahead 1
    
  ]
  
end

;;;;
;cross? return true if the agent is crossing a zebra or a izebra
;to-report cross?[]
;  
;  report  member? (patch-at 0 0) zebra or member? (patch-at 0 0) izebra
;  
;end


;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;; Count, plot, watch global system state  ;;;;;;;;;;;;;;;;;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;


;;;;;
;Plot different variables
to do-plot
  set-current-plot "Num pietons"
  plot count turtles
  set-current-plot "Illegal"
  set-current-plot-pen "legal"
  plot num-legal   
  set-current-plot-pen "illegal"
  plot crossers - num-legal   
  ;    show num-legal
end 


;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;; Var count                                     ;;;;;;;;;;;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;;;
;return the number of agent crossing a zebra with green lights
to-report num-legal
  let n-ind 0
  ask turtles[  
    let z [zebra-id] of (patch-at 0 0)                          ;;zebra id of the patch under me
    if( (member? (patch-at 0 0) zebra) and                 ;;the patch under me is a zebra 
      (one-of [state] of (lights with [zebra-id = z and not car-light? ]) = 2)) [ 
    set n-ind n-ind + 1 ;;the associated light is green (and not an car light)
      ]
  ]
  report n-ind
end

to-report greenNotZebra
  let n-ind 0
  ask turtles[  
    let z [zid] of (patch-at 0 0)                          ;;zebra id of the patch under me
    if( (member? (patch-at 0 0) izebra) and                 ;;the patch under me is a izebra 
      (one-of [state] of (lights with [zebra-id = z and not car-light? ]) = 2)) [ 
    set n-ind n-ind + 1 ;;the associated light is green (and not an car light)
      ]
  ]
  report n-ind
end

to-report zebraNotGreen
  let n-ind 0
  ask turtles[  
    let z [zebra-id] of (patch-at 0 0)                          ;;zebra id of the patch under me
    if( (member? (patch-at 0 0) zebra) and                 ;;the patch under me is a zebra 
      (one-of [state] of (lights with [zebra-id = z and not car-light? ]) != 2)) [ 
    set n-ind n-ind + 1 ;;the associated light is green (and not an car light)
      ]
  ]
  report n-ind
end

to-report doNotCare
  let n-ind 0
  ask turtles[  
    let z [zid] of (patch-at 0 0)                          ;;zebra id of the patch under me
    if( (member? (patch-at 0 0) izebra) and                 ;;the patch under me is a izebra 
      (one-of [state] of (lights with [zebra-id = z and not car-light? ]) != 2)) [ 
    set n-ind n-ind + 1 ;;the associated light is green (and not an car light)
      ]
  ]
  report n-ind
end

to-report crosserNotReferenced
  let n-ind 0
  ask turtles[  
    let z [zid] of (patch-at 0 0)                          
    if( not (member? (patch-at 0 0) zebra or member? (patch-at 0 0) izebra or member? (patch-at 0 0) trottoirs ) )[
      set n-ind n-ind + 1 ;;the associated light is green (and not an car light)
    ]
  ]
  report n-ind
end
  
  
to-report total
  report count turtles
end
  
to-report onsidewalk
  report count turtles with [ (member? (patch-at 0 0) trottoirs) ]
end
  
to-report crossers
  report count turtles with [cross?] 
  
end
  ;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
  
  
  ;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
  ;; Output Printing                               ;;;;;;;;;;;
  ;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
to output-init
  file-open (word "../data/" date-and-time "PedestrianOutput.csv") ;
  file-print "time,imgId,pzebra,pizeb,A,B,C,D,E,notOnSidewalk,total" ;
  file-close
end
  
  
to print-output
  file-open (word "../data/" date-and-time "PedestrianOutput.csv") ;
  file-print (word ticks "," Name "," probzeb "," probizeb "," num-legal "," greenNotZebra "," zebraNotGreen "," doNotCare "," crosserNotReferenced "," (total - onsidewalk) "," total)
  file-close
end
  
  ;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
  ;; Trigo tools : some useful trigonometric tools ;;;;;;;;;;;
  ;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
  
  
  ;; getAngle gives the smallest angle to turn a (the current agent) in order 
  ;; to avoid an obstacle between a (the agent) and g (the goal)
  ;; a shloud be an agent and g a patch
to getAngle [xa ya xg yg]
  let dist 0
  set dist sqrt( (xg - xa) ^ 2 + (xg - xa) ^ 2)
  print dist
end
  ;;norm(a,b) return the length of the segment ab
  ;to-report norm [a,b]
  ;  report 
  ;end
  
  
@#$#@#$#@
GRAPHICS-WINDOW
347
10
958
567
200
175
1.5
1
10
1
1
1
0
0
0
1
-200
200
-175
175
1
1
1
ticks

BUTTON
21
13
84
46
Go
go
T
1
T
OBSERVER
NIL
NIL
NIL
NIL

BUTTON
228
16
302
49
Setup
setup
NIL
1
T
OBSERVER
NIL
NIL
NIL
NIL

SWITCH
20
205
144
238
iocolored
iocolored
1
1
-1000

SLIDER
6
321
103
354
pSpeed
pSpeed
0
100
20
1
1
NIL
HORIZONTAL

SLIDER
117
321
212
354
pNb
pNb
0
100
4
1
1
NIL
HORIZONTAL

TEXTBOX
7
295
227
319
Caractéristiques d'apparition des nouveaux pietons :
9
0.0
1

PLOT
175
444
335
564
Num pietons
NIL
NIL
0.0
10.0
0.0
10.0
true
false
PENS
"default" 1.0 0 -16777216 true

SLIDER
7
382
99
415
probizeb
probizeb
0
100
0
1
1
NIL
HORIZONTAL

SLIDER
111
382
203
415
probzeb
probzeb
0
100
1
1
1
NIL
HORIZONTAL

PLOT
3
444
163
564
Illegal
Time
Amount illegal p
0.0
10.0
0.0
10.0
true
false
PENS
"illegal" 1.0 0 -2674135 true
"legal" 1.0 0 -10899396 true

SWITCH
170
204
262
237
Person
Person
1
1
-1000

TEXTBOX
169
186
319
204
Shape us!
9
0.0
1

CHOOSER
228
54
320
99
env
env
"ledru" "bmp"
1

SLIDER
22
58
149
91
duration
duration
0
50000
15500
100
1
NIL
HORIZONTAL

SWITCH
87
12
177
45
avort
avort
1
1
-1000

INPUTBOX
46
112
133
172
Name
SALR
1
0
String

@#$#@#$#@
WHAT IS IT?
-----------
This program will be used to test different models trying to explain how pedestrians act when they reach a crossway with where over pedestrian can appaers from metro exit, bus station and 


HOW IT WORKS
------------
The main idea is to simulate behavior which respect law and other which are able to more or less transgress laws and rules.

An agent is able to see zebra pathways and at that precise moment he can know the state of each light around the zebra (lights which regulate pedestrian but also lights which regulate cars).

At the time I write the agents move followings those rules :

	he looks in front of himself to know what is the type of the patch ahead
	 
	he puts is heading to face his go which is randomly chosen when the agents is created


HOW TO USE IT
-------------
The user can choose the probability need to cross a red zebra or a izebra (area on the road but near to the zebra). 
The user can also choose the path of a bmp image in order to use it as background for pedestrian.

THINGS TO NOTICE
----------------
This section could give some ideas of things for the user to notice while running the model.


THINGS TO TRY
-------------
This section could give some ideas of things for the user to try to do (move sliders, switches, etc.) with the model.


EXTENDING THE MODEL
-------------------
This section could give some ideas of things to add or change in the procedures tab to make the model more complicated, detailed, accurate, etc.


NETLOGO FEATURES
----------------
This section could point out any especially interesting or unusual features of NetLogo that the model makes use of, particularly in the Procedures tab.  It might also point out places where workarounds were needed because of missing features.


RELATED MODELS
--------------
This section could give the names of models in the NetLogo Models Library or elsewhere which are of related interest.


CREDITS AND REFERENCES
----------------------
This section could contain a reference to the model's URL on the web if it has one, as well as any other necessary credits or references.
@#$#@#$#@
default
true
0
Polygon -7500403 true true 150 5 40 250 150 205 260 250

airplane
true
0
Polygon -7500403 true true 150 0 135 15 120 60 120 105 15 165 15 195 120 180 135 240 105 270 120 285 150 270 180 285 210 270 165 240 180 180 285 195 285 165 180 105 180 60 165 15

arrow
true
0
Polygon -7500403 true true 150 0 0 150 105 150 105 293 195 293 195 150 300 150

box
false
0
Polygon -7500403 true true 150 285 285 225 285 75 150 135
Polygon -7500403 true true 150 135 15 75 150 15 285 75
Polygon -7500403 true true 15 75 15 225 150 285 150 135
Line -16777216 false 150 285 150 135
Line -16777216 false 150 135 15 75
Line -16777216 false 150 135 285 75

bug
true
0
Circle -7500403 true true 96 182 108
Circle -7500403 true true 110 127 80
Circle -7500403 true true 110 75 80
Line -7500403 true 150 100 80 30
Line -7500403 true 150 100 220 30

butterfly
true
0
Polygon -7500403 true true 150 165 209 199 225 225 225 255 195 270 165 255 150 240
Polygon -7500403 true true 150 165 89 198 75 225 75 255 105 270 135 255 150 240
Polygon -7500403 true true 139 148 100 105 55 90 25 90 10 105 10 135 25 180 40 195 85 194 139 163
Polygon -7500403 true true 162 150 200 105 245 90 275 90 290 105 290 135 275 180 260 195 215 195 162 165
Polygon -16777216 true false 150 255 135 225 120 150 135 120 150 105 165 120 180 150 165 225
Circle -16777216 true false 135 90 30
Line -16777216 false 150 105 195 60
Line -16777216 false 150 105 105 60

car
false
0
Polygon -7500403 true true 300 180 279 164 261 144 240 135 226 132 213 106 203 84 185 63 159 50 135 50 75 60 0 150 0 165 0 225 300 225 300 180
Circle -16777216 true false 180 180 90
Circle -16777216 true false 30 180 90
Polygon -16777216 true false 162 80 132 78 134 135 209 135 194 105 189 96 180 89
Circle -7500403 true true 47 195 58
Circle -7500403 true true 195 195 58

circle
false
0
Circle -7500403 true true 0 0 300

circle 2
false
0
Circle -7500403 true true 0 0 300
Circle -16777216 true false 30 30 240

cow
false
0
Polygon -7500403 true true 200 193 197 249 179 249 177 196 166 187 140 189 93 191 78 179 72 211 49 209 48 181 37 149 25 120 25 89 45 72 103 84 179 75 198 76 252 64 272 81 293 103 285 121 255 121 242 118 224 167
Polygon -7500403 true true 73 210 86 251 62 249 48 208
Polygon -7500403 true true 25 114 16 195 9 204 23 213 25 200 39 123

cylinder
false
0
Circle -7500403 true true 0 0 300

dot
false
0
Circle -7500403 true true 90 90 120

face happy
false
0
Circle -7500403 true true 8 8 285
Circle -16777216 true false 60 75 60
Circle -16777216 true false 180 75 60
Polygon -16777216 true false 150 255 90 239 62 213 47 191 67 179 90 203 109 218 150 225 192 218 210 203 227 181 251 194 236 217 212 240

face neutral
false
0
Circle -7500403 true true 8 7 285
Circle -16777216 true false 60 75 60
Circle -16777216 true false 180 75 60
Rectangle -16777216 true false 60 195 240 225

face sad
false
0
Circle -7500403 true true 8 8 285
Circle -16777216 true false 60 75 60
Circle -16777216 true false 180 75 60
Polygon -16777216 true false 150 168 90 184 62 210 47 232 67 244 90 220 109 205 150 198 192 205 210 220 227 242 251 229 236 206 212 183

fish
false
0
Polygon -1 true false 44 131 21 87 15 86 0 120 15 150 0 180 13 214 20 212 45 166
Polygon -1 true false 135 195 119 235 95 218 76 210 46 204 60 165
Polygon -1 true false 75 45 83 77 71 103 86 114 166 78 135 60
Polygon -7500403 true true 30 136 151 77 226 81 280 119 292 146 292 160 287 170 270 195 195 210 151 212 30 166
Circle -16777216 true false 215 106 30

flag
false
0
Rectangle -7500403 true true 60 15 75 300
Polygon -7500403 true true 90 150 270 90 90 30
Line -7500403 true 75 135 90 135
Line -7500403 true 75 45 90 45

flower
false
0
Polygon -10899396 true false 135 120 165 165 180 210 180 240 150 300 165 300 195 240 195 195 165 135
Circle -7500403 true true 85 132 38
Circle -7500403 true true 130 147 38
Circle -7500403 true true 192 85 38
Circle -7500403 true true 85 40 38
Circle -7500403 true true 177 40 38
Circle -7500403 true true 177 132 38
Circle -7500403 true true 70 85 38
Circle -7500403 true true 130 25 38
Circle -7500403 true true 96 51 108
Circle -16777216 true false 113 68 74
Polygon -10899396 true false 189 233 219 188 249 173 279 188 234 218
Polygon -10899396 true false 180 255 150 210 105 210 75 240 135 240

house
false
0
Rectangle -7500403 true true 45 120 255 285
Rectangle -16777216 true false 120 210 180 285
Polygon -7500403 true true 15 120 150 15 285 120
Line -16777216 false 30 120 270 120

leaf
false
0
Polygon -7500403 true true 150 210 135 195 120 210 60 210 30 195 60 180 60 165 15 135 30 120 15 105 40 104 45 90 60 90 90 105 105 120 120 120 105 60 120 60 135 30 150 15 165 30 180 60 195 60 180 120 195 120 210 105 240 90 255 90 263 104 285 105 270 120 285 135 240 165 240 180 270 195 240 210 180 210 165 195
Polygon -7500403 true true 135 195 135 240 120 255 105 255 105 285 135 285 165 240 165 195

line
true
0
Line -7500403 true 150 0 150 300

line half
true
0
Line -7500403 true 150 0 150 150

pentagon
false
0
Polygon -7500403 true true 150 15 15 120 60 285 240 285 285 120

person
false
0
Circle -7500403 true true 110 5 80
Polygon -7500403 true true 105 90 120 195 90 285 105 300 135 300 150 225 165 300 195 300 210 285 180 195 195 90
Rectangle -7500403 true true 127 79 172 94
Polygon -7500403 true true 195 90 240 150 225 180 165 105
Polygon -7500403 true true 105 90 60 150 75 180 135 105

plant
false
0
Rectangle -7500403 true true 135 90 165 300
Polygon -7500403 true true 135 255 90 210 45 195 75 255 135 285
Polygon -7500403 true true 165 255 210 210 255 195 225 255 165 285
Polygon -7500403 true true 135 180 90 135 45 120 75 180 135 210
Polygon -7500403 true true 165 180 165 210 225 180 255 120 210 135
Polygon -7500403 true true 135 105 90 60 45 45 75 105 135 135
Polygon -7500403 true true 165 105 165 135 225 105 255 45 210 60
Polygon -7500403 true true 135 90 120 45 150 15 180 45 165 90

sheep
false
0
Rectangle -7500403 true true 151 225 180 285
Rectangle -7500403 true true 47 225 75 285
Rectangle -7500403 true true 15 75 210 225
Circle -7500403 true true 135 75 150
Circle -16777216 true false 165 76 116

square
false
0
Rectangle -7500403 true true 30 30 270 270

square 2
false
0
Rectangle -7500403 true true 30 30 270 270
Rectangle -16777216 true false 60 60 240 240

star
false
0
Polygon -7500403 true true 151 1 185 108 298 108 207 175 242 282 151 216 59 282 94 175 3 108 116 108

target
false
0
Circle -7500403 true true 0 0 300
Circle -16777216 true false 30 30 240
Circle -7500403 true true 60 60 180
Circle -16777216 true false 90 90 120
Circle -7500403 true true 120 120 60

tree
false
0
Circle -7500403 true true 118 3 94
Rectangle -6459832 true false 120 195 180 300
Circle -7500403 true true 65 21 108
Circle -7500403 true true 116 41 127
Circle -7500403 true true 45 90 120
Circle -7500403 true true 104 74 152

triangle
false
0
Polygon -7500403 true true 150 30 15 255 285 255

triangle 2
false
0
Polygon -7500403 true true 150 30 15 255 285 255
Polygon -16777216 true false 151 99 225 223 75 224

truck
false
0
Rectangle -7500403 true true 4 45 195 187
Polygon -7500403 true true 296 193 296 150 259 134 244 104 208 104 207 194
Rectangle -1 true false 195 60 195 105
Polygon -16777216 true false 238 112 252 141 219 141 218 112
Circle -16777216 true false 234 174 42
Rectangle -7500403 true true 181 185 214 194
Circle -16777216 true false 144 174 42
Circle -16777216 true false 24 174 42
Circle -7500403 false true 24 174 42
Circle -7500403 false true 144 174 42
Circle -7500403 false true 234 174 42

turtle
true
0
Polygon -10899396 true false 215 204 240 233 246 254 228 266 215 252 193 210
Polygon -10899396 true false 195 90 225 75 245 75 260 89 269 108 261 124 240 105 225 105 210 105
Polygon -10899396 true false 105 90 75 75 55 75 40 89 31 108 39 124 60 105 75 105 90 105
Polygon -10899396 true false 132 85 134 64 107 51 108 17 150 2 192 18 192 52 169 65 172 87
Polygon -10899396 true false 85 204 60 233 54 254 72 266 85 252 107 210
Polygon -7500403 true true 119 75 179 75 209 101 224 135 220 225 175 261 128 261 81 224 74 135 88 99

wheel
false
0
Circle -7500403 true true 3 3 294
Circle -16777216 true false 30 30 240
Line -7500403 true 150 285 150 15
Line -7500403 true 15 150 285 150
Circle -7500403 true true 120 120 60
Line -7500403 true 216 40 79 269
Line -7500403 true 40 84 269 221
Line -7500403 true 40 216 269 79
Line -7500403 true 84 40 221 269

x
false
0
Polygon -7500403 true true 270 75 225 30 30 225 75 270
Polygon -7500403 true true 30 75 75 30 270 225 225 270

@#$#@#$#@
NetLogo 4.1.3
@#$#@#$#@
@#$#@#$#@
@#$#@#$#@
@#$#@#$#@
@#$#@#$#@
default
0.0
-0.2 0 1.0 0.0
0.0 1 1.0 0.0
0.2 0 1.0 0.0
link direction
true
0
Line -7500403 true 150 150 90 180
Line -7500403 true 150 150 210 180

@#$#@#$#@
0
@#$#@#$#@
