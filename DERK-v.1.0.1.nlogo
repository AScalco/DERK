;;;;;;;;;;;;;;;;
;; BREEDS     ;;
;;;;;;;;;;;;;;;;

breed [people person]   ;; Turtles are specified as a breed as later retailers will also be included
;breed [stores store]   ;; TBC

;;;;;;;;;;;;;;;;
;; VARIABLES  ;;
;;;;;;;;;;;;;;;;

globals [
temp0 temp1 temp2       ;; Use to debug code through local of turtle-specific variables
  world.recipes         ;; All recipes avaiable in the virtual world
  world.beef            ;; Daily units of beef consumed
]

people-own [
  memory.recipes        ;; List of recipes known by an agent
  house.food.storage    ;; List of ingredients (foods) available to an agent
  planned.meal          ;; Recipe selected by an agent to be consumed
  shopping.list         ;; Ingredients that needs to be bought to consume planned.meal
]

;;;;;;;;;;;;;;;;
;; SETUP      ;;
;;;;;;;;;;;;;;;;

to setup
  ca

  ;; Insert here the list of recipes that will be available to be known by people.
  ;; This list also defines the ingredients that will be considered in agents' house food storage.
  set world.recipes (list ["beef" "potatoes" "beans"] ["fish" "chips"] ["fish" "beans"] ["beef" "chips"] ["fish" "salad"] ["tomatoes" "salad"])

  ;; Create people and initialise people's variables
  create-people Number.of.People [
    ;; Number of recipes known by an agent
    set memory.recipes n-of (1 + (floor random-normal 3 0.25)) world.recipes ;; Normal distribution of meal prepartion knowledge (i.e. recipes)
    set house.food.storage []
    build-house.food.storage   ;; Initialise available ingredients
    set shopping.list []
  ]


  reset-ticks
end

;; For each recipe imported in the virtual world, this piece of code create for each agent a "virtual kitchen" with all the ingredients and their current availability
to build-house.food.storage
  ; First extract the single ingredients from the imported recipes and create a food storage list for each agents
  foreach world.recipes
  [
    let x ?
    foreach x
    [
      if member? ? house.food.storage = FALSE
      [
        set house.food.storage lput (?) house.food.storage ; This contains a list of food names (e.g. [beef salad ...])
      ]
    ]
  ]

  ;; Rewrite house food storage as a list of lists to store availability of each food
  let i 0
  while [i <= ((length house.food.storage) - 1)]
  [
    ;; Rewrite the current ingredient as a list and add next to the name the initial value available (e.g. [beef salad ...] >> [[beef 4] [salad 0] ...]
    let newitem (list (item i house.food.storage) (0))
    set house.food.storage (replace-item i house.food.storage newitem)
    set i i + 1
  ]
end


;;;;;;;;;;;;;;;;
;; GO         ;;
;;;;;;;;;;;;;;;;

to go

  new-tick-reset

  ask people
  [
    set planned.meal item 0 (n-of 1 memory.recipes) ; The use of "item 0" make "planned.meal" a list, rather than returning a list of list (because memory.recipes is a list of lists)
    ifelse check-ingredients-availability (planned.meal)
    [
      consume-meal (planned.meal)
    ]
    [
      food-shopping  ;; Shop for the food required by the recipe
      set shopping.list []  ;; Reset shopping list immediately after the ingredients have been bought and made available for the recipe
      consume-meal (planned.meal)
    ]
  ]

 tick

end

to-report check-ingredients-availability [mymeal] ;; Note that you're in a turtle context
;; Check the availability of only one ingredient of mymeal
  let all.ingredients.available? TRUE ;; Start assuming there are all the necessary ingredients
  let i 0
  while [i <= ((length mymeal) - 1)]  ;; (NB there's probably a more elegant way than using while for a list that check another list, but that'll do for now)
  [
    ;; For each ingredient of planned meal, report the current availability by looking at the house food storage (which is a list of lists, like [[Food.X Value.for.X] [Food.Y Value.for.Y] ...]
    let drawer filter [(item i mymeal) = (item 0 ?)] house.food.storage ; "Filter" returns "drawer" something like [[Food.X Value.for.X]] (note the double brackets)
    set drawer (item 0 drawer) ;; We need to ask "item 0" to remove the first set of brackets from the previous variable, so that we end with [Food.X Value.for.X]
    ;; Build the shopping list for the future
    if ((item 1 drawer) = 0)
    [
      build-shopping-list (item 0 drawer)
      set all.ingredients.available? FALSE ;; If at least one ingredients is missing the function will report that something is missing
    ]
    set i i + 1
  ]
  report all.ingredients.available?
end

to build-shopping-list [food.to.restock]
  ;; If the availability ("item 1") of a food ("item 0") is equal to zero, list that food in the shopping list
  ; Check if the item is already in the shopping list, first
  if member? (food.to.restock) shopping.list = FALSE
  [
    ; Add the item to the shopping list
    set shopping.list fput (food.to.restock) shopping.list
set temp0 shopping.list ;;DEBUG
  ]
end

to consume-meal [mymeal]
  let i 0
  while [i <= ((length mymeal) - 1)]
  [
    let item.position 0
    foreach house.food.storage
    [
      if (item i mymeal) = (item 0 ?) ;; Here "?" refers to "house.food.storage" list, the code compare the name of the food between the lists
      [
        ;; If ingredient in the planned meal matches the item in the house food storage, than save the position of that item
        set item.position (position ? house.food.storage)
        let current.stock.of.food.i (item 1 ?)
        ;;  list to update                position in the wider list [[X],[]]  what item replace    repeat previous position          define the new value
        set house.food.storage (replace-item item.position house.food.storage (replace-item 1 (item item.position house.food.storage) (current.stock.of.food.i - 1) )) ;; See last part of "Changing list items" from the Programming guide for help
        world-monitor (item i mymeal)
      ]
    ]
    set i i + 1
  ]
end

to food-shopping
  let i 0
  while [i <= ((length shopping.list) - 1)]
  [
    let item.position 0
    foreach house.food.storage
    [
      if (item i shopping.list) = (item 0 ?) ;; Here "?" refers to "house.food.storage" list
      [
        ;; If ingredient in the planned meal matches the item in the house food storage, than save the position of that item
        set item.position (position ? house.food.storage)
        let current.stock.of.food.i (item 1 ?)
        let food.restock.value 10
        ;;  list to update                position in the wider list [[X],[]]  what item replace    repeat previous position          define the new value
        set house.food.storage (replace-item item.position house.food.storage (replace-item 1 (item item.position house.food.storage) (current.stock.of.food.i + food.restock.value  ) )) ;; See last part of "Changing list items" from the Programming guide for help
      ]
    ]
    set i i + 1
  ]
end


;;;;;;;;;;;;;;;;;;;;
;; UPDATEs/PLOTS  ;;
;;;;;;;;;;;;;;;;;;;;


to new-tick-reset
  set world.beef 0
end

to world-monitor [food.consumed]
  if (food.consumed) = "beef" [ set world.beef (world.beef + 1)]
end
@#$#@#$#@
GRAPHICS-WINDOW
224
10
469
201
-1
-1
20.0
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
7
0
7
0
0
1
ticks
30.0

BUTTON
8
86
71
119
NIL
setup\n
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
77
86
140
119
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

MONITOR
404
90
852
135
Turtle 0 - [Ingredients units_available]
[house.food.storage] of turtle 0
17
1
11

MONITOR
404
139
563
184
Turtle 0 - Planned meal
[planned.meal] of turtle 0
17
1
11

MONITOR
223
206
394
251
NIL
temp0
17
1
11

TEXTBOX
9
14
134
42
DERK - Diet emergence from recipes knowledge
11
0.0
1

PLOT
870
17
1250
208
Overall daily units of beef consumed
NIL
NIL
0.0
10.0
0.0
1.0
true
false
"" ""
PENS
"default" 1.0 0 -16777216 true "" "plot world.beef"

MONITOR
403
40
851
85
Turtle 0 - Recipes known
[memory.recipes] of turtle 0
17
1
11

BUTTON
148
86
211
119
Run
go
T
1
T
OBSERVER
NIL
R
NIL
NIL
1

SLIDER
8
48
140
81
Number.of.People
Number.of.People
1
10
1
3
1
NIL
HORIZONTAL

@#$#@#$#@
## WHAT IS IT?

DERK creates one or more individuals each one endowed with a set of recipes (meaning, what foods can be paired). At each time step, an agent decides to consume a meal corresponding to a random recipe. Accordingly, it checks if all the ingredients required for the recipe are available: when they are available it consumes immediately the meal, otherwise it must first shop for the food it needs and then consume the meal. Food availability is checked after each consumed meals and food shopping.

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
NetLogo 5.3.1
@#$#@#$#@
@#$#@#$#@
@#$#@#$#@
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
