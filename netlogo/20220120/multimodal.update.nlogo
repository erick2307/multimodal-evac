__includes [ "env.nls" "grid.nls" "routes.nls" "sfm.nls"]

globals [
  ;color variables
  frame-color
  road-color
  sw-color
  bldg-color
  grid-color

  ;other variables
  scale
  total-width
  peds-pen-flag
  shape-flag
  p-collision
  p-out-sw
  slow-peds

  ;choose case
  c-left
  c-right
  c-down
  c-up
  p-route
]




breed [ cars car ]
breed [ peds ped ]

peds-own [ p-size p-origin p-destination p-path p-remain p-goal p-veloc-max p-in-time p-out-time p-color
  ;for output variables
  p-num-of-cars p-num-of-peds p-num-of-crossings p-time-at-intersection
]
cars-own [ c-size c-goal c-veloc c-veloc-max c-in-time c-out-time ncs
  ;for output variables
  c-num-of-cars c-num-of-peds c-time-at-intersection
]

to setup
  clear-all
  reset-ticks
  random-seed 5

  set frame-color white; black
  set road-color gray ;white
  set sw-color 8 ;gray
  set bldg-color 89
  set grid-color 3

  ask patches [ set pcolor road-color ]
  set scale 0.5 ;(m/patch)
  set total-width max-pxcor * scale ;m
  set grid-flag false
  set peds-pen-flag false
  set shape-flag true
  create-road
  create-sidewalk
  create-border
  set-points
  set c-left true
  set c-right true
  set c-up true
  set c-down true
  choose-case
  ;if number-of-cars != 0 [ insert-cars ]
  ;if number-of-pedestrians != 0 [ insert-peds ]
  set slow-peds []
;  make-slow-peds-list
  let file "log-world.csv" ;user-new-file
  export-world file
;  find-slow-peds
end

;###########################################################################################################

to go
  ask cars [ c-move ]
  ask peds [ p-move-2 ]
;  choose-case
  if ticks mod (p-interval * fps) = 0 and count peds < max-peds [ insert-peds ]
  if number-of-cars > 0 and ticks mod (10 * fps) = 0 and count cars < max-cars [ insert-cars ]
  tick
  if ticks = 4332000 [ stop ]
end

;###########################################################################################################
to choose-case
  if case = "2directions-parallel"
  [set c-left true
   set c-right true
   set c-up false
   set c-down false
   set p-route 1]

  if case = "2directions-perpendicular"
  [set c-left true
   set c-right false
   set c-up true
   set c-down false
   set p-route 2]

  if case = "3directions"
  [set c-left true
   set c-right false
   set c-up true
   set c-down true
   set p-route 3]

  if case = "4directions"
  [set c-left true
   set c-right true
   set c-up true
   set c-down true
   set p-route 4]

  if case = "4directions-free"
  [set c-left true
   set c-right true
   set c-up true
   set c-down true
   set p-route 5]
end

to insert-cars
  if c-left
  [create-cars 1 [
    ifelse not shape-flag [ set shape "car top" ] [set shape "dot" ]
    set size rd car-size
    set color black
    set xcor min-pxcor + swidth / scale
    set ycor rd ((2 * total-width + height) / 4 )
    set c-goal patch max-pxcor ycor
    set c-veloc-max random-normal 13.8 0.5 / fps
    set c-veloc c-veloc-max
    set heading 90
    set c-size size
    set c-in-time ticks
    set c-out-time 0
    set c-num-of-cars count other cars
    set c-num-of-peds count other peds
    set c-time-at-intersection 0
  ]]

  if c-right
  [create-cars 1 [
    ifelse not shape-flag [ set shape "car top" ] [set shape "dot" ]
    set size rd car-size
    set color black
    set xcor max-pxcor - swidth / scale
    set ycor rd ((2 * total-width - height) / 4 )
    set c-goal patch min-pxcor ycor
    set c-veloc-max random-normal 13.8 0.5 / fps ;m/s
    set c-veloc c-veloc-max
    set heading 270
    set c-size size
    set c-in-time ticks
    set c-out-time 0
    set c-num-of-cars count other cars
    set c-num-of-peds count peds
    set c-time-at-intersection 0
  ]]

  if c-up
  [create-cars 1 [
    ifelse not shape-flag [ set shape "car top" ] [set shape "dot" ]
    set size rd car-size
    set color white
    set xcor rd ((2 * total-width + width) / 4 )
    set ycor max-pycor - swidth / scale
    set c-goal patch xcor min-pycor
    set c-veloc-max random-normal 13.8 0.5 / fps ;m/s
    set c-veloc c-veloc-max
    set heading 180
    set c-size size
    set c-in-time ticks
    set c-out-time 0
    set c-num-of-cars count other cars
    set c-num-of-peds count peds
    set c-time-at-intersection 0
  ]]

  if c-down
  [create-cars 1 [
    ifelse not shape-flag [ set shape "car top" ] [set shape "dot" ]
    set size rd car-size
    set color white
    set xcor rd ((2 * total-width - width) / 4 )
    set ycor min-pycor + swidth / scale
    set c-goal patch xcor max-pycor
    set c-veloc-max random-normal 13.8 0.5 / fps ;m/s
    set c-veloc c-veloc-max
    set heading 0
    set c-size size
    set c-in-time ticks
    set c-out-time 0
    set c-num-of-cars count other cars
    set c-num-of-peds count peds
    set c-time-at-intersection 0
  ]]
end

to insert-peds
  create-peds p-num [
    set shape "dot"
    set size rd ped-size
    set p-size size
    move-to get-one-origin-point
    set p-path select-trajectory patch-here
    set p-remain but-first p-path
    set p-origin first p-path
    set p-destination last p-path
    set p-goal item 1 p-path
    set p-veloc-max rd (calc-veloc-max / fps) ; rd ((random-normal 1.5 0.5) / fps)
    set p-velocx p-veloc-max
    set p-velocy p-veloc-max
    set p-in-time ticks
    set p-out-time 0
    if peds-pen-flag [ pd ]
    ;draw-path self
    ;set heading 90
    set p-num-of-cars count cars
    set p-num-of-peds count other peds
    set p-num-of-crossings length p-path - 3
    ifelse p-num-of-crossings = 0 [set p-color red][ifelse p-num-of-crossings = 1[set p-color blue][set p-color green]]
    set color p-color
    set p-time-at-intersection 0
  ]
end

;###########################################################################################################

to c-move
  if count other cars > 0 [c-sense]
  if count peds > 0 [ c-decide ]
;  if ncs > 0 [set c-veloc 0]
  c-update
  verify-arrival-cars
end

to c-sense ;sense of cars and adjust velocity
  let nc count other cars in-cone (car-look-ahead-cars / scale ) alfaVV
  set ncs count other cars in-cone (car-stop-ahead-cars / scale ) alfaVVS
  let dc ceiling distance min-one-of other cars [ distance myself ] / scale
  ifelse nc >= 1 and dc > 0
    [ set c-veloc c-veloc * (random-float ( dc / nc  ) ) ]
  [ set c-veloc c-veloc-max ]
end


to c-decide ;sense of pedestrians
  let np count other peds in-cone (car-look-ahead-peds / scale) alfaVP ;10
  let dp ceiling distance min-one-of peds [ distance myself ] / scale
  ;adjust velocity
  ifelse np >= 1 and dp > 0
  [ set c-veloc min list c-veloc-max ( c-veloc-max / (car-look-ahead-peds - car-stop-ahead-peds) * ( dp - car-stop-ahead-peds) ) ]
  [ set c-veloc c-veloc-max ]

  ;old version
  ;if np >= 1 and dp > 0 [ set c-veloc c-veloc * (random-float ( 1 / ( np * dp ) ) ) ]
end

to c-update
  fd rd c-veloc
end

;###########################################################################################################

to p-move-2
  calc-desired-direction
  calc-driving-force
  calc-obstacle-force
;  if any? other peds
;    [ calc-territorial-forces ]
  move-peds
  verify-arrival-peds
;  ifelse in-intersection
;  [check-p-collision][set color p-color]
;  check-p-at-sw
end

;to make-slow-peds-list
;  file-open "log_slow_peds.csv"
;  let pid 0
;  if file-exists? "log_slow_peds.csv"
;  [ifelse file-at-end?
;    [file-close-all]
;    [repeat 30 [set pid file-read-line
;      set slow-peds lput pid slow-peds]]]
;  show slow-peds
;  watch ped (read-from-string pid)
;end



;to p-move ;in Gorrini et al, 2018 terms
 ; face p-goal
 ; p-sense ;approach
 ; p-decide ;appraise
 ; p-update ;cross
 ; if patch-here = p-goal and patch-here != p-destination [ set p-goal first p-remain set p-remain but-first p-remain ]
 ; if patch-here = p-destination [ die ]
;end

; to p-sense
 ; let np count other peds in-cone (ped-look-ahead-peds / scale ) alfaPP ;60
 ; let dp ceiling distance min-one-of peds [ distance myself ] / scale
  ;adjust velocity based on pedestrians
 ; ifelse np >= 1 and dp > 0 [ set p-veloc p-veloc * (random-float ( dp /  np  ) ) ] [ set p-veloc p-veloc-max ]
 ; ifelse np >= 1 and dp > 0 [ set p-veloc p-veloc-max * ( 1 - exp(-1.913 * (1 / np - 1 / 5.4 ) ) )] [ set p-veloc p-veloc-max ]
; end

; to p-decide
 ; let nc count cars in-cone (ped-look-ahead-cars / scale) alfaPV ; 60
 ; let dc ceiling distance min-one-of cars [ distance myself ] / scale
;  ;adjust velocity
 ; if nc >= 1 and dc > ped-stop-ahead-cars [ set p-veloc 1.5 * p-veloc-max ]
 ; if nc >= 1 and dc < ped-stop-ahead-cars [ set p-veloc min list p-veloc-max ( p-veloc-max / (ped-look-ahead-cars - ped-stop-ahead-cars) * ( dc - ped-stop-ahead-cars) )  ]
;
;  ;old version
;  ;if nc >= 1 and dc > 0 [ set p-veloc p-veloc * (random-float ( 1 / ( nc * dc ) ) ) ]
; end

;to p-update
;  fd rd p-veloc
;end
@#$#@#$#@
GRAPHICS-WINDOW
214
10
1222
1019
-1
-1
10.0
1
10
1
1
1
0
0
0
1
0
99
0
99
1
1
1
fps
30.0

BUTTON
37
114
207
147
NIL
setup
NIL
1
T
OBSERVER
NIL
NIL
NIL
NIL
1

SLIDER
36
12
208
45
width
width
2
25
7.0
1
1
m
HORIZONTAL

SLIDER
36
45
208
78
height
height
2
25
7.0
1
1
m
HORIZONTAL

SLIDER
36
78
208
111
swidth
swidth
1
5
2.5
0.5
1
m
HORIZONTAL

SLIDER
37
148
209
181
number-of-cars
number-of-cars
0
10000
10000.0
1
1
NIL
HORIZONTAL

SLIDER
37
182
210
215
number-of-pedestrians
number-of-pedestrians
1
10000
10000.0
1
1
NIL
HORIZONTAL

BUTTON
35
249
140
282
NIL
go
T
1
T
OBSERVER
NIL
NIL
NIL
NIL
1

BUTTON
209
1019
321
1052
Grid ON/OFF
grid-on-off
NIL
1
T
OBSERVER
NIL
NIL
NIL
NIL
1

INPUTBOX
8
284
58
344
fps
120.0
1
0
Number

SLIDER
9
346
207
379
car-look-ahead-cars
car-look-ahead-cars
1
100
70.0
1
1
m
HORIZONTAL

SLIDER
10
380
212
413
car-look-ahead-peds
car-look-ahead-peds
0
100
69.0
1
1
m
HORIZONTAL

SLIDER
9
414
212
447
car-stop-ahead-peds
car-stop-ahead-peds
0.5
5
4.5
0.5
1
m
HORIZONTAL

SLIDER
8
485
180
518
alfaVV
alfaVV
10
180
120.0
10
1
deg
HORIZONTAL

SLIDER
2
555
174
588
alfaVP
alfaVP
10
180
120.0
10
1
deg
HORIZONTAL

SLIDER
2
590
207
623
ped-look-ahead-peds
ped-look-ahead-peds
0
100
100.0
1
1
m
HORIZONTAL

SLIDER
2
625
204
658
ped-look-ahead-cars
ped-look-ahead-cars
0
100
100.0
1
1
m
HORIZONTAL

SLIDER
2
660
205
693
ped-stop-ahead-cars
ped-stop-ahead-cars
1
20
20.0
1
1
m
HORIZONTAL

SLIDER
2
695
174
728
alfaPV
alfaPV
10
180
180.0
10
1
deg
HORIZONTAL

SLIDER
2
729
174
762
alfaPP
alfaPP
10
180
180.0
10
1
deg
HORIZONTAL

INPUTBOX
61
284
130
344
max-cars
10000.0
1
0
Number

INPUTBOX
133
285
206
345
max-peds
10000.0
1
0
Number

BUTTON
323
1020
454
1053
POINTS ON/OFF
ifelse points-flag\n[ask odps [ set pcolor sw-color ] set points-flag false ]\n[ask odps [ set pcolor red ] set points-flag true ]
NIL
1
T
OBSERVER
NIL
NIL
NIL
NIL
1

BUTTON
458
1020
585
1053
TRACE ON/OFF
ifelse peds-pen-flag\n[clear-drawing ask peds [ pu ] set peds-pen-flag false ]\n[ask peds [ pd ] set peds-pen-flag true ]
NIL
1
T
OBSERVER
NIL
NIL
NIL
NIL
1

SLIDER
2
775
174
808
v0
v0
0
10
0.0
0.1
1
NIL
HORIZONTAL

SLIDER
2
809
174
842
sigma
sigma
0.1
10
0.1
0.1
1
NIL
HORIZONTAL

SLIDER
2
843
174
876
u0
u0
0
20
0.5
.1
1
NIL
HORIZONTAL

SLIDER
2
878
174
911
r0
r0
0.1
10
0.3
.1
1
NIL
HORIZONTAL

SLIDER
2
1055
174
1088
tau
tau
1
30
1.0
1
1
NIL
HORIZONTAL

MONITOR
722
1021
807
1066
Pedestrians
count peds
17
1
11

MONITOR
810
1022
867
1067
STD
standard-deviation [ magnitude p-velocx p-velocy ] of peds
3
1
11

BUTTON
143
249
206
282
NIL
go
NIL
1
T
OBSERVER
NIL
NIL
NIL
NIL
1

PLOT
1014
1027
1214
1177
Pedestrians
NIL
NIL
0.0
10.0
0.0
10.0
true
false
"" ""
PENS
"IN" 1.0 0 -13345367 true "" "plot count peds with [p-remain != []]"
"pen-1" 1.0 0 -2674135 true "" "plot count peds with [p-remain = []]"

SWITCH
6
215
109
248
log?
log?
0
1
-1000

BUTTON
588
1021
720
1054
SHAPES ON/OFF
ifelse shape-flag\n[ask cars [ set shape \"car top\" set shape-flag false ] ]\n[ask cars [ set shape \"dot\" set shape-flag true ] ]
NIL
1
T
OBSERVER
NIL
NIL
NIL
NIL
1

INPUTBOX
868
1021
935
1081
car-size
3.6
1
0
Number

BUTTON
111
215
208
248
erase-files
if file-exists? \"log.csv\"\n[ file-delete \"log.csv\" ]\nif file-exists? \"log-world.csv\"\n[ file-delete \"log-world.csv\" ]
NIL
1
T
OBSERVER
NIL
NIL
NIL
NIL
1

INPUTBOX
939
1021
1009
1081
ped-size
1.2
1
0
Number

SLIDER
9
450
198
483
car-stop-ahead-cars
car-stop-ahead-cars
0
10
2.0
1
1
m
HORIZONTAL

SLIDER
8
520
180
553
alfaVVS
alfaVVS
0
180
30.0
10
1
deg
HORIZONTAL

SLIDER
2
913
174
946
u1
u1
0
20
7.0
0.1
1
NIL
HORIZONTAL

SLIDER
2
948
174
981
r1
r1
0.1
10
0.5
0.1
1
NIL
HORIZONTAL

INPUTBOX
16
1130
171
1190
Arb
100.0
1
0
Number

INPUTBOX
176
1130
331
1190
Brab
1.35
1
0
Number

SLIDER
2
982
174
1015
u2
u2
0
20
1.1
0.1
1
NIL
HORIZONTAL

SLIDER
1
1018
173
1051
r2
r2
0.1
10
0.2
0.1
1
NIL
HORIZONTAL

CHOOSER
204
1067
402
1112
case
case
"2directions-parallel" "2directions-perpendicular" "3directions" "4directions" "4directions-free"
2

SLIDER
613
1093
786
1126
p-interval
p-interval
0
100
15.0
5
1
NIL
HORIZONTAL

SLIDER
430
1092
603
1125
p-num
p-num
0
100
20.0
5
1
NIL
HORIZONTAL

@#$#@#$#@
## WHAT IS IT?

(a general understanding of what the model is trying to show or explain)

## HOW IT WORKS

(what rules the agents use to create the overall behavior of the model)

## HOW TO USE IT

(how to use the model, including a description of each of the items in the Interface tab)

## THINGS TO NOTICE

(suggested things for the user to notice while running the model)

## THINGS TO TRY

(suggested things for the user to try to do (move sliders, switches, etc.) with the model)

## EXTENDING THE MODEL

(suggested things to add or change in the Code tab to make the model more complicated, detailed, accurate, etc.)

## NETLOGO FEATURES

(interesting or unusual features of NetLogo that the model uses, particularly in the Code tab; or where workarounds were needed for missing features)

## RELATED MODELS

(models in the NetLogo Models Library and elsewhere which are of related interest)

## CREDITS AND REFERENCES

(a reference to the model's URL on the web if it has one, as well as any other necessary credits, citations, and links)
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

car top
true
0
Polygon -7500403 true true 151 8 119 10 98 25 86 48 82 225 90 270 105 289 150 294 195 291 210 270 219 225 214 47 201 24 181 11
Polygon -16777216 true false 210 195 195 210 195 135 210 105
Polygon -16777216 true false 105 255 120 270 180 270 195 255 195 225 105 225
Polygon -16777216 true false 90 195 105 210 105 135 90 105
Polygon -1 true false 205 29 180 30 181 11
Line -7500403 false 210 165 195 165
Line -7500403 false 90 165 105 165
Polygon -16777216 true false 121 135 180 134 204 97 182 89 153 85 120 89 98 97
Line -16777216 false 210 90 195 30
Line -16777216 false 90 90 105 30
Polygon -1 true false 95 29 120 30 119 11

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
15
Circle -1 true true 203 65 88
Circle -1 true true 70 65 162
Circle -1 true true 150 105 120
Polygon -7500403 true false 218 120 240 165 255 165 278 120
Circle -7500403 true false 214 72 67
Rectangle -1 true true 164 223 179 298
Polygon -1 true true 45 285 30 285 30 240 15 195 45 210
Circle -1 true true 3 83 150
Rectangle -1 true true 65 221 80 296
Polygon -1 true true 195 285 210 285 210 240 240 210 195 210
Polygon -7500403 true false 276 85 285 105 302 99 294 83
Polygon -7500403 true false 219 85 210 105 193 99 201 83

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

wolf
false
0
Polygon -16777216 true false 253 133 245 131 245 133
Polygon -7500403 true true 2 194 13 197 30 191 38 193 38 205 20 226 20 257 27 265 38 266 40 260 31 253 31 230 60 206 68 198 75 209 66 228 65 243 82 261 84 268 100 267 103 261 77 239 79 231 100 207 98 196 119 201 143 202 160 195 166 210 172 213 173 238 167 251 160 248 154 265 169 264 178 247 186 240 198 260 200 271 217 271 219 262 207 258 195 230 192 198 210 184 227 164 242 144 259 145 284 151 277 141 293 140 299 134 297 127 273 119 270 105
Polygon -7500403 true true -1 195 14 180 36 166 40 153 53 140 82 131 134 133 159 126 188 115 227 108 236 102 238 98 268 86 269 92 281 87 269 103 269 113

x
false
0
Polygon -7500403 true true 270 75 225 30 30 225 75 270
Polygon -7500403 true true 30 75 75 30 270 225 225 270
@#$#@#$#@
NetLogo 6.2.1
@#$#@#$#@
@#$#@#$#@
@#$#@#$#@
<experiments>
  <experiment name="collision&amp;out of sw" repetitions="1" runMetricsEveryStep="true">
    <setup>setup</setup>
    <go>go</go>
    <exitCondition>ticks &gt; 10000</exitCondition>
    <metric>p-collision</metric>
    <metric>p-out-sw</metric>
    <enumeratedValueSet variable="car-look-ahead-peds">
      <value value="69"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="sigma">
      <value value="0.1"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="car-look-ahead-cars">
      <value value="70"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="alfaVVS">
      <value value="30"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="u0">
      <value value="0.5"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="width">
      <value value="7"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="u1">
      <value value="7"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="v0">
      <value value="0"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="alfaVV">
      <value value="120"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="car-size">
      <value value="3.6"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="log?">
      <value value="false"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="car-stop-ahead-peds">
      <value value="4.5"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="alfaVP">
      <value value="120"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="car-stop-ahead-cars">
      <value value="5"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="alfaPV">
      <value value="180"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="fps">
      <value value="120"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="height">
      <value value="7"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="alfaPP">
      <value value="180"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="ped-look-ahead-peds">
      <value value="100"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="ped-look-ahead-cars">
      <value value="100"/>
    </enumeratedValueSet>
    <steppedValueSet variable="r0" first="0.1" step="0.1" last="0.5"/>
    <enumeratedValueSet variable="swidth">
      <value value="2.5"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="max-peds">
      <value value="10000"/>
    </enumeratedValueSet>
    <steppedValueSet variable="r1" first="0.1" step="0.1" last="0.5"/>
    <enumeratedValueSet variable="max-cars">
      <value value="10000"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="number-of-pedestrians">
      <value value="10000"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="tau">
      <value value="1"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="ped-stop-ahead-cars">
      <value value="20"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="number-of-cars">
      <value value="10000"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="ped-size">
      <value value="1.2"/>
    </enumeratedValueSet>
  </experiment>
  <experiment name="experiment" repetitions="1" runMetricsEveryStep="true">
    <setup>setup</setup>
    <go>go</go>
    <exitCondition>ticks &gt; 10000</exitCondition>
    <metric>p-collision</metric>
    <metric>p-out-sw</metric>
    <enumeratedValueSet variable="car-look-ahead-peds">
      <value value="69"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="car-look-ahead-cars">
      <value value="70"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="sigma">
      <value value="0.1"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="Arb">
      <value value="100"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="alfaVVS">
      <value value="30"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="u0">
      <value value="0.5"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="width">
      <value value="7"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="u1">
      <value value="7"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="v0">
      <value value="0"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="u2">
      <value value="0.8"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="alfaVV">
      <value value="120"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="car-size">
      <value value="3.6"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="log?">
      <value value="false"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="car-stop-ahead-peds">
      <value value="4.5"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="alfaVP">
      <value value="120"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="car-stop-ahead-cars">
      <value value="5"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="alfaPV">
      <value value="180"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="fps">
      <value value="120"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="height">
      <value value="7"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="alfaPP">
      <value value="180"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="ped-look-ahead-peds">
      <value value="100"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="ped-look-ahead-cars">
      <value value="100"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="Brab">
      <value value="1.35"/>
    </enumeratedValueSet>
    <steppedValueSet variable="r0" first="0.1" step="0.1" last="0.5"/>
    <enumeratedValueSet variable="swidth">
      <value value="2.5"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="max-peds">
      <value value="10000"/>
    </enumeratedValueSet>
    <steppedValueSet variable="r1" first="0.1" step="0.1" last="0.5"/>
    <enumeratedValueSet variable="max-cars">
      <value value="10000"/>
    </enumeratedValueSet>
    <steppedValueSet variable="r2" first="0.1" step="0.1" last="0.5"/>
    <enumeratedValueSet variable="number-of-pedestrians">
      <value value="10000"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="tau">
      <value value="1"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="ped-stop-ahead-cars">
      <value value="20"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="number-of-cars">
      <value value="10000"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="ped-size">
      <value value="1.2"/>
    </enumeratedValueSet>
  </experiment>
</experiments>
@#$#@#$#@
@#$#@#$#@
default
0.0
-0.2 0 0.0 1.0
0.0 1 1.0 0.0
0.2 0 0.0 1.0
link direction
true
0
Line -7500403 true 150 150 90 180
Line -7500403 true 150 150 210 180
@#$#@#$#@
0
@#$#@#$#@
