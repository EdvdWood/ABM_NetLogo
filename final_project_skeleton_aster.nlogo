;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;; BONUS SKELETON FILE INTRODUCTION ABM 2020-2021                ;;
;; written by Natalie van der Wal & Igor Nikolic                 ;;
;; for extra help with starting up your model                    ;;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;


__includes [ "utilities.nls" "astaralgorithm.nls"]      ;; utilities: all the boring but important stuff not related to content astaralgorithm: A* path finding algorithm


globals [

  exit-north1                  ;; exit on top (left one of the two doors)
  exit-north2                  ;; exit on top (right one of the two doors)
  exit-west                    ;; exit on left
  exit-east                    ;; exit on right
 ;N-north1                     ;; number of agents evacauted through exit north1
 ;N-north2                     ;; number of agents evacauted through exit north2
 ;N-west                       ;; number of agents evacauted through exit west
 ;N-east                       ;; number of agents evacauted through exit east
  N-evacuated                  ;; total number of agents that have reached safety
  end_of_simulation            ;; maximum allowed ticks of one simulation run
  all-colors                   ;; temporary list of checking which colors are there
  obstacles                    ;; patches that an agent can not walk on (e.g. walls, furniture)
  astar_open                   ;; the open list of patches --> see astaralgorithm.nls
  astar_closed                 ;; the closed list of patches --> see astaralgorithm.nls
  optimal-path                 ;; the optimal path, list of patches from source to destination --> see astaralgorithm.nls
  alarm-time                   ;; the time at which the alarm goes off
                          ;; signs to guide people to the exit
  danger-spots                 ;; fire!
  total-evacuation-time        ;; total time to evacuate
  average-response-time        ;; how long it took the average turtle to find the exit
  event-duration               ;; how long the event has been running for
  n-open-doors                 ;; Counts open doors
  n                            ;; helper variable for anonymous function
  North-1-v
  North-2-v
  East-v
  West-v
  evacuation-started           ;;

]

breed [visitors visitor]       ;; agents that are visitors
breed [employees employee]     ;; agents that are employees
breed [dangerspots dangerspot] ;; agents that are dangerspots
breed [signs sign]

turtles-own [
  current-speed                ;; the current speed of the agent, which can be running or walking
  running-speed                ;; walking-speed of the agent
  walking-speed                ;; running speed of the agent
  destination                  ;; the exit the agent will choose to evacaute through [exit-north1, exit-north2, exit-south, exit-east]
  familiar-with-exits?         ;; is the agent familiar with where the exits are?
  evacuating?                 ;; is the agent evacuating or not?
  current-destination          ;; the patch the agent is currently going towards, used for random walk
  path                         ;; the optimal path from source to destination --> see astaralgorithm.nls
  current-path                 ;; part of the path that is left to be traversed --> see astaralgorithm.nls
  gender                       ;; gender of the visitor / employee
  age                          ;; age of the visitor/ employee
  enter-exit                   ;; exit through which the visitor entered.
  jumpiness                    ;; How affected by fear increases the person is.
  fear-level                   ;; fear level
  response-time                ;; time it takes for a agent to respond to the alarm and start evacuating
  evacuated?                   ;; whether an agent is evacuated
  evacuate-time                ;; time it takes for an agent to evacuate
  perception-risk              ;;
  telling?                     ;; whether the agent is telling another agent to leave

]


patches-own [
  parent-patch                 ;; patch's predecessor --> see astaralgorithm.nls
  f                            ;; the value of knowledge plus heuristic cost function f() --> see astaralgorithm.nls
  g                            ;; the value of knowledge cost function g() --> see astaralgorithm.nls
  h                            ;; the value of heuristic cost function h() --> see astaralgorithm.nls
]

to setup
  clear-all                     ;; start with clearing all
 ;random-seed 42                ;; choose to setup from a random seed or not, can be handy for debugging
  setupMap                      ;; setup the floor plan = part of the environment --> see utilities file, make sure to do this first, because for example the colours might be not perfectly white and black, so they are set to perfectly white and black for the code below to work
  set obstacles patches with [pcolor = 0]                                           ;; make all black patches obstacles (obstacles are walls, furniture, etc..) which are used in the avoid-obstacles procedure
  ifelse North-1? [set exit-north1 patches with [(pcolor = 14.8) and (pxcor > 109) and (pxcor < 118 )]][ask patches with [(pcolor = 14.8) and (pxcor > 109) and (pxcor < 118 )] [set pcolor 0]]     ;; setup exit-north1: when the patches are red and within these coordinates, then it is this exit.
  ifelse North-2? [set exit-north2 patches with [(pcolor = 14.8) and (pxcor > 118) and (pxcor < 130)]][ask patches with [(pcolor = 14.8) and (pxcor > 118) and (pxcor < 130)] [set pcolor 0]]    ;; setup exit-north2: when the patches are red and within these scoordinates, then it is this exit.
  ifelse West? [set exit-west patches with [(pcolor = 14.8) and (pxcor > 15) and (pxcor < 30)]][ask patches with [(pcolor = 14.8) and (pxcor > 15) and (pxcor < 30)] [set pcolor 0]]       ;; setup exit-west: when the patches are red and within these scoordinates, then it is this exit.
  ifelse East? [set exit-east patches with [(pcolor = 14.8) and (pxcor > 145) and (pxcor < 160)]][ask patches with [(pcolor = 14.8) and (pxcor > 145) and (pxcor < 160)] [set pcolor 0]]      ;; setup exit-east: when the patches are red and within these scoordinates, then it is this exit
  set N-evacuated 0             ;; the global variable N-evacuated is 0 at the start of the simulation
  set end_of_simulation 600     ;; maximum amount of ticks for one simulation run
  set alarm? false              ;; the alarm is turned off at the start
  set alarm-time 30             ;; the alarm goes off after 30 seconds
  ifelse North-1? [set North-1-v 1] [set North-1-v 0] ;; inferring booleans from the switches
  ifelse North-2? [set North-2-v 1] [set North-2-v 0]
  ifelse East? [set East-v 1] [set East-v 0]
  ifelse West? [set West-v 1] [set West-v 0]
  set n-open-doors 0 + North-1-v + North-2-v + East-v + West-v  ;; count the number of open doors (this would be so much easier if I could add booleans)
  setup-visitors                ;; ask turtles to perform the setup-visitors procedure
  setup-employees               ;; ask turtles to perform the setup-employees procedure
  setup-dangerspots             ;; determine the place where the danger (fire) is starting
  if signs? = true [setup-signs]
  reset-ticks                   ;; resets the tick counter to zero, goes at the end of setup procedure
  set evacuation-started false
end

to go                           ;; observer procedure
  if ticks = end_of_simulation [stop] ;; make a stop condition
  if N-evacuated = count visitors + count employees [ ;; if all turtles are evacuated, stop
    set total-evacuation-time (word (floor (ticks / 60)) " min " (ticks - (floor(ticks / 60)) * 60) " sec") ;; set total evacuation time in minutes and seconds
    stop ]
  if ticks = alarm-time [       ;; if alarm button is pressed or after 30 seconds
    set alarm? true
  set evacuation-started true]            ;; turn on the alarm ;; start the evacuating procedure

  if evacuation-started = false and alarm? = true [start-evacuation]

  ask visitors with [pcolor = 14.8 and evacuated? = false and evacuating? = true] [
      set evacuated? true
      set-evacuate-time
    ]

  if alarm? = true [
    spread-danger
    evacuate-visitors
    evacuate-employees
  ]             ;; the danger (fire) is spreading slowly
  ask visitors [if pcolor != 14.8 and telling? = false and evacuated? = false [move]]           ;; asking the visitors to do the move procedure
  ask employees [if pcolor != 14.8 and telling? = false and evacuated? = false [move]]
  set-metrics                 ;; determine the metrics
  tick                          ;; next time step

end

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;; setup procedures for environment and agents                  ;;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

to setupMap
  ;~~~~~choose the plan you want to use
  ;; MAKE SURE THE BMP FILES ARE IN THE SAME FOLDER WHERE YOU SAVE YOUR MODEL YOU CAN MAKE CHANGES USING THE BUCKET TOOL IN PAINT TO MAKE THE FLOORPLAN AS COMPLEX OR SIMPLE AS YOU WANT
  ;coloured floorplan has exits/entrances in red, internal stairwells in yellow, elevators in gray, doors in cyan, toilets in green and kitchen counters and reception in lila
  ;import-pcolors "data/coloured_plan.png"

  ; simplified floorplan only has the exits in red, walls in black
  import-pcolors "data/blackwhite_plan.png"
  clean-colors
end

to setup-visitors               ;; turtle procedure
  create-visitors num-visitors [move-to one-of patches with [pcolor = 9.9]] ;;place visitors on white patches
  ask visitors [
    set heading  (heading + 45 - (random 90)) ;;set a random heading at the start so the agents walk randomly until they start to evacuate
    set current-speed 0.5       ;; set the current speed of the agent
  ; set current-speed 0.5 + random-float 0.5  ;; example to make this random
    set enter-exit (random (n-open-doors - 1) + 1)   ;; randomly set the original entrance
    set shape "person"          ;; set the shape of the agent
    set size 1                  ;; set the size of the agent
    set color blue              ;; set the color of the agent
    set jumpiness random-float 0.55 + 0.1
    if-else random 99 < perc-adults
    [set age ["adult"]]
    [set age ["child"]]
    if-else random 99 < perc-female [
      set gender ["female"]][
      set gender ["male"]]
    if-else gender = "male" [
      set walking-speed 1.5
      set running-speed 2.25
      set perception-risk vision-distance] [
      set walking-speed 1.2
      set running-speed 1.8
      set perception-risk vision-distance * 1.2]
    set current-speed walking-speed
    set telling? false
    set evacuated? false
    set evacuating? false       ;; agent is not evacuating at the start of the simulation
    set familiar-with-exits? (random 99 < perc-familiar)  ;; set of the agent is familiar with the building or not, this will influence the exit choice in procedure choose-exit
    choose-exit                 ;; call the procedure choose-exit to choose an exit that the agent will move to when evacuating - Note_Joel: would remove this procedure here
    set current-destination one-of patches with [pcolor = 9.9]  ;; when the agent is walking randomly at the beginning (before evacuating) the agent needs this as a destination
  ]
end

to setup-employees              ;;turtle procedure
  create-employees num-staff [move-to one-of patches with [pcolor = 9.9]] ;;place employees on white patches
  ask employees [
    set shape "person"          ;; set the shape of the agent
    set size 1                  ;; set the size of the agent
    set color green             ;; set the color of the agents
    if-else random 99 < perc-female [
      set gender ["female"]][  ;; set for perc-female % of employees female
      set gender ["male"]]     ;; set the 100 - perc-female % of employees male
    set current-destination patch-here ;; employees do not move at the start
    if-else gender = "male" [
      set walking-speed 1
      set running-speed 1.5
      set perception-risk vision-distance] [
      set walking-speed 0.8
      set running-speed 1.2
      set perception-risk vision-distance ]
    set telling? false
    set evacuated? false
    set current-speed walking-speed ;; agents are walking at the start
    set familiar-with-exits? true  ;; employees are familiar with the building, thus familiar-with exits? 1
    choose-exit                 ;; call the procedure choose-exit to chose an exit that the agent will move to when evacuating
  ]

end

to setup-dangerspots ;; set one of the obstacles on fire that are close to the walking space, but not near the exits
  create-dangerspots 1 [move-to one-of patches with [(pcolor = 0) and any? patches in-radius 3 with [pcolor = 9.9] and (count patches in-radius vision-distance with [pcolor = 14.8] = 0)]]
  ask dangerspots [
  set color yellow
  set shape "plant" ;; plant looks like fire symbol ;)
  set size 4
  ]
end

to setup-signs
  let sign-locations patches at-points [[35 170] [46 170] [54 148] [80 159] [102 147] [119 146] [115 130] [151 112] [181 121] [170 76] [176 68] [189 44] [192 32] [201 28] [177 20] [104 27] [83 21] [64 21] [38 27]];; place exit signs in the building
  ask sign-locations [sprout-signs 1]

  ask signs [
    set shape "box"
    set color 56 ]              ;; make exit signs green
end

to spread-danger ;; the fire spreads to other obstacles nearby
  create-dangerspots 1 [move-to one-of patches with [(pcolor = 0) and any? patches in-radius 3 with [pcolor = 9.9] and any? dangerspots in-radius 8 and (count patches in-radius vision-distance with [pcolor = 14.8] = 0)]]
  ask dangerspots [
    set color yellow
    set size 5
    set shape "plant"
  ]
end


;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;; all other procedures                                          ;;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

to choose-exit

  let nearest-exit min-one-of (patches with [pcolor = 14.8]) [distance myself] ;; determine nearest exit
  if evacuating? = true [
  (ifelse
    familiar-with-exits? = true [
      set destination nearest-exit]
    enter-exit = 1 [
        (ifelse North-1? [
          set destination one-of exit-north1]
        North-2? [
            set destination one-of exit-north2]
          East? [
            set destination one-of exit-east]
          West? [
            set destination one-of exit-west])]
    enter-exit = 2 [
          (ifelse North-2? [
      set destination one-of exit-north2]
            East? [
            set destination one-of exit-east]
          West? [
            set destination one-of exit-west])]
    enter-exit = 3 [
            (ifelse East? [
            set destination one-of exit-east]
          West? [
            set destination one-of exit-west])]
    enter-exit = 4 [
      set destination one-of exit-west]
  )
  ]
end


to move                                   ;;turtle procedure
  crowd-control
  (if-else  evacuating? = true             ;; ifelse
  [
    set current-destination destination   ;; if agent is evacuating, change heading to "destination", which is the chosen exit
    face current-destination
    if pcolor = 0 [set current-speed 0.2 * walking-speed]
    fd current-speed
  ]

  [ if-else patch-here = current-destination   ;; else (agent is not evacuating), if agent is already at the current-destination, look for a new current-destination
    [set current-destination one-of patches with [pcolor = 9.9] ;;setting the new current-destination to a white patch
      face current-destination            ;; and face that destination
      avoid-obstacles  ]                   ;; let the agent avoid obstacles while randomly walking
    [face current-destination
      avoid-obstacles]
  ])

end


to crowd-control ;; make sure walking speed is reduced when in space is crowded and no more than 8 building users per square meter
  if (count visitors-here + count employees-here) > 7 and [pcolor] of patch-here != 14.8 [ask one-of visitors-here [rt 45 fd 1]] ;; if there 8 building users on a patch, one-of the buildings users turns 45 degrees. Except for the exits, where buildingsusers accumulate
  set current-speed (walking-speed * max (list (1 / (count visitors in-radius 1 + count employees in-radius 1)) 0.6)) ;; slows down buildings users non-linearly
end


to start-evacuation
   ask visitors [
  set fear-level jumpiness
  ]
end

to evacuate-employees
   ask employees [
    let visitors-visible visitors with [evacuating? = false] in-cone vision-distance vision-angle
    ifelse count visitors-visible > 0 and pcolor != 14.8 [
      set telling? true ;; if an employee sees a visitor
      if ticks mod 5 = 0 [
      ask one-of visitors-visible [;;the visitor that is being looked at
          set evacuating? true ;; decides to leave the building
          set familiar-with-exits? true ;; is being told where nearest exit is
          choose-exit ;; sets destination at nearest exit
          set-response-time
        ]
        set telling? false
      ]
    ]
       [
      set evacuating? true
      set telling? false
      choose-exit
      set label "evacuating"
      set label-color blue
      if-else count turtles in-radius 3 < 4 [ ;; if there are no turtles nearby, employees are running. else walking
        set current-speed running-speed][
        set current-speed walking-speed] ;; employees will leave via nearest exit when all visitor within visibility have left
    ]
  ]
    ;if count visitors-visible = 0 [move] ;; employees will leave via nearest exit when all visitor within visibility have left
end


to evacuate-visitors

  ask visitors [


    let visitors-visible (visitors in-cone vision-distance vision-angle with [evacuating? = false])
    if fear-level < 1 and count dangerspots in-cone vision-distance vision-angle > 0 ;;if a visitor can see the closest danger spot in its visible area
    [set fear-level 1] ;; its level of fear increases to 1

    set fear-level fear-level + 0.01 * jumpiness ;; fear increases over time, as the fire alarm keeps blaring and other people start to leave the building.
    set fear-level sum [fear-level] of visitors in-radius 10 / count(visitors in-radius 10) ;; set the fear level to the average level of fear of visitors in neighborhood
    if fear-level > 0.1 and color = blue [set color red]
    if fear-level > 0.6 and evacuating? = false [
      set evacuating? true
      if pcolor = 0 [move-to min-one-of (patches with [pcolor = 9.9]) [distance myself]]
      choose-exit
      set-response-time
    ]


    if evacuating? = true [ ;; if the visitor is evacuating
      set label "evacuating" set label-color blue
      if-else count turtles in-radius 3 < 4 and fear-level > 0.9 [
          set current-speed running-speed][
          set current-speed walking-speed
      ]
      if (response-time + alarm-time + 5) < ticks and count visitors-visible > 0 [
        set telling? true
      ]
      if (ticks - response-time) mod 10 = 0 and telling? = true [
          set telling? false
        if count visitors-visible > 0 [
          ask one-of visitors-visible [ ;; it tells other visitors in its visible area to do the same
            set evacuating? true
            choose-exit
            set-response-time
          ]
        ]
       ]
    ]


    if evacuating? = true and familiar-with-exits? = false and min-one-of (signs in-cone vision-distance vision-angle) [distance myself] = 1 and random 99 < (33 / vision-distance) ;; if visitor can see the closest signs in its visible area, it has a probability 1/3 to actually see it. We need to account for the period of time that the sign is in vision.
    [set familiar-with-exits? true ;; the visitor becomes familiar with the nearest exit displayed on the sign
     choose-exit ;; visitors sets destination at nearest exit
    ]

  ]

end

; make the turtle traverse (move through) the path all the way to the destination patch
to move-along-path
;;AANGEPAST
 ;; show current-path
  if any? patch-set current-path
    [ifelse count patch-set current-path > 10 [repeat 10
      [go-to-next-patch-in-current-path]]
      [repeat (count patch-set current-path)
      [go-to-next-patch-in-current-path]]
    ;;print "i moved"
      ;wait 0.05
    ]
;;EINDE AANGEPAST

end

to go-to-next-patch-in-current-path
  face first current-path
  fd running-speed
  move-to first current-path
  set current-path remove-item 0 current-path
end




to avoid-obstacles              ;;turtle procedure check if there is an obstacle free direct patch towards the exit, if so move towards it
  face current-destination      ;; agent faces the exit or current destination it wants to go to
  let visible-patches patches in-cone vision-distance (vision-angle / 3)
  let obstacles-here visible-patches with [pcolor = 0]

  if any? obstacles-here                ;; if there is a black patch or a fire in vision-distance then execute a random turn, and move one patch
  [
    if distance-nearest-obstacle obstacles-here < 2 * current-speed ; the distance we would cover in 1 step
    [ rt random 30 + 180
      set current-destination one-of patches with [pcolor = 9.9]]

  ]


  fd current-speed               ;; agent moves forward with current speed


  ;[ rt ( 90 + random 90 )]

  ;if patch-ahead i != nobody or member? patch-ahead i obstacles [ rt ( 90 + random 90 )] ;; if the patch ahead is not nobody or is an obstacle, then reverse 90 degrees + a random degrees below 90 degrees
end

to-report distance-nearest-obstacle [obstacleshere]
  let nearest-distance 9999

  ask obstacleshere [
    let distance-to-x distance myself
    if distance-to-x  < nearest-distance [set nearest-distance distance-to-x ]
  ]

  ;print nearest-distance
  report nearest-distance
end

to set-response-time ;; record the time between the number of ticks when a visitor start evacuating and the point where the alarm goes off.
  set response-time ticks - alarm-time

end

to set-evacuate-time
  set evacuate-time ticks - alarm-time
end

to set-metrics
 set N-evacuated count turtles-on patches with [pcolor =  14.8] ;; count turtles that reached the exits
  let average-response-ticks (sum [response-time] of visitors with [evacuating? = true]) / num-visitors ;; determine average number of ticks neccessary to respond to the alarm
  set average-response-time (word (floor (average-response-ticks / 60)) " min " (round (average-response-ticks) - (floor( average-response-ticks / 60)) * 60) " sec") ;; convert ticks to minutes and seconds
  set event-duration (word (floor (ticks / 60)) " min " (ticks - (floor(ticks / 60)) * 60) " sec") ;; show ticks in minutes and seconds

end
@#$#@#$#@
GRAPHICS-WINDOW
223
10
1508
1361
-1
-1
5.01
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
254
0
267
0
0
1
ticks
30.0

BUTTON
10
10
83
43
NIL
setup
NIL
1
T
OBSERVER
NIL
S
NIL
NIL
1

BUTTON
11
55
74
88
NIL
go
T
1
T
OBSERVER
NIL
G
NIL
NIL
1

SWITCH
11
105
132
138
verbose?
verbose?
1
1
-1000

SWITCH
12
159
122
192
debug?
debug?
1
1
-1000

OUTPUT
1586
40
2197
216
12

SLIDER
13
210
185
243
vision-distance
vision-distance
0
100
50.0
1
1
NIL
HORIZONTAL

SLIDER
16
260
188
293
vision-angle
vision-angle
0
360
210.0
1
1
NIL
HORIZONTAL

BUTTON
114
54
177
87
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

SLIDER
15
316
187
349
bump-distance
bump-distance
0
3
2.0
1
1
NIL
HORIZONTAL

SLIDER
18
370
190
403
num-visitors
num-visitors
0
400
400.0
1
1
NIL
HORIZONTAL

SLIDER
22
430
194
463
num-staff
num-staff
0
100
100.0
1
1
NIL
HORIZONTAL

SLIDER
21
472
193
505
perc-familiar
perc-familiar
0
100
50.0
1
1
NIL
HORIZONTAL

MONITOR
30
822
162
867
Total evacuation time
total-evacuation-time
17
1
11

MONITOR
30
655
143
700
Evacuated agents
N-evacuated
17
1
11

MONITOR
30
711
177
756
Average Response Time
average-response-time
17
1
11

SLIDER
23
511
195
544
perc-female
perc-female
0
100
28.0
1
1
NIL
HORIZONTAL

SLIDER
27
563
199
596
perc-adults
perc-adults
0
100
90.0
1
1
NIL
HORIZONTAL

SWITCH
137
105
240
138
alarm?
alarm?
0
1
-1000

MONITOR
31
766
127
811
Event Duration
event-duration
17
1
11

SWITCH
1567
323
1671
356
North-1?
North-1?
0
1
-1000

SWITCH
1717
337
1821
370
North-2?
North-2?
0
1
-1000

SWITCH
1592
382
1695
415
West?
West?
0
1
-1000

SWITCH
1741
397
1844
430
East?
East?
0
1
-1000

SWITCH
1577
465
1680
498
signs?
signs?
0
1
-1000

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
NetLogo 6.1.1
@#$#@#$#@
@#$#@#$#@
@#$#@#$#@
<experiments>
  <experiment name="Main Exit" repetitions="10" runMetricsEveryStep="false">
    <setup>setup</setup>
    <go>go</go>
    <metric>[response-time] of visitors</metric>
    <metric>[evacuating?] of visitors</metric>
    <metric>[evacuate-time] of visitors</metric>
    <metric>[evacuated?] of visitors</metric>
    <enumeratedValueSet variable="perc-adults">
      <value value="90"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="vision-distance">
      <value value="10"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="East?">
      <value value="false"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="bump-distance">
      <value value="2"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="West?">
      <value value="false"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="vision-angle">
      <value value="210"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="perc-female">
      <value value="28"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="verbose?">
      <value value="false"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="perc-familiar">
      <value value="100"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="North-1?">
      <value value="true"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="num-visitors">
      <value value="400"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="alarm?">
      <value value="false"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="debug?">
      <value value="false"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="num-staff">
      <value value="100"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="North-2?">
      <value value="true"/>
    </enumeratedValueSet>
  </experiment>
  <experiment name="All Exits" repetitions="10" runMetricsEveryStep="false">
    <setup>setup</setup>
    <go>go</go>
    <metric>[response-time] of visitors</metric>
    <metric>[evacuating?] of visitors</metric>
    <metric>[evacuate-time] of visitors</metric>
    <metric>[evacuated?] of visitors</metric>
    <enumeratedValueSet variable="perc-adults">
      <value value="90"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="vision-distance">
      <value value="10"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="East?">
      <value value="true"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="bump-distance">
      <value value="2"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="West?">
      <value value="true"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="vision-angle">
      <value value="210"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="perc-female">
      <value value="28"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="verbose?">
      <value value="false"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="perc-familiar">
      <value value="100"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="North-1?">
      <value value="true"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="num-visitors">
      <value value="400"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="alarm?">
      <value value="false"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="debug?">
      <value value="false"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="num-staff">
      <value value="100"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="North-2?">
      <value value="true"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="signs?">
      <value value="true"/>
    </enumeratedValueSet>
  </experiment>
  <experiment name="North by NorthWest" repetitions="10" runMetricsEveryStep="false">
    <setup>setup</setup>
    <go>go</go>
    <metric>[response-time] of visitors</metric>
    <metric>[evacuating?] of visitors</metric>
    <metric>[evacuate-time] of visitors</metric>
    <metric>[evacuated?] of visitors</metric>
    <enumeratedValueSet variable="perc-adults">
      <value value="90"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="vision-distance">
      <value value="10"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="East?">
      <value value="false"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="bump-distance">
      <value value="2"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="West?">
      <value value="true"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="vision-angle">
      <value value="210"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="perc-female">
      <value value="28"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="verbose?">
      <value value="false"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="perc-familiar">
      <value value="50"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="North-1?">
      <value value="true"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="num-visitors">
      <value value="400"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="alarm?">
      <value value="false"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="debug?">
      <value value="false"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="num-staff">
      <value value="100"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="North-2?">
      <value value="true"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="signs?">
      <value value="true"/>
    </enumeratedValueSet>
  </experiment>
  <experiment name="North by NorthEast" repetitions="10" runMetricsEveryStep="false">
    <setup>setup</setup>
    <go>go</go>
    <metric>[response-time] of visitors</metric>
    <metric>[evacuating?] of visitors</metric>
    <metric>[evacuate-time] of visitors</metric>
    <metric>[evacuated?] of visitors</metric>
    <enumeratedValueSet variable="perc-adults">
      <value value="90"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="vision-distance">
      <value value="10"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="East?">
      <value value="true"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="bump-distance">
      <value value="2"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="West?">
      <value value="false"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="vision-angle">
      <value value="210"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="perc-female">
      <value value="28"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="verbose?">
      <value value="false"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="perc-familiar">
      <value value="50"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="North-1?">
      <value value="true"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="num-visitors">
      <value value="400"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="alarm?">
      <value value="false"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="debug?">
      <value value="false"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="num-staff">
      <value value="100"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="North-2?">
      <value value="true"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="signs?">
      <value value="true"/>
    </enumeratedValueSet>
  </experiment>
  <experiment name="EastWest" repetitions="10" runMetricsEveryStep="false">
    <setup>setup</setup>
    <go>go</go>
    <metric>[response-time] of visitors</metric>
    <metric>[evacuating?] of visitors</metric>
    <metric>[evacuate-time] of visitors</metric>
    <metric>[evacuated?] of visitors</metric>
    <enumeratedValueSet variable="perc-adults">
      <value value="90"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="vision-distance">
      <value value="10"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="East?">
      <value value="true"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="bump-distance">
      <value value="2"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="West?">
      <value value="true"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="vision-angle">
      <value value="210"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="perc-female">
      <value value="28"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="verbose?">
      <value value="false"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="perc-familiar">
      <value value="50"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="North-1?">
      <value value="false"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="num-visitors">
      <value value="400"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="alarm?">
      <value value="false"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="debug?">
      <value value="false"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="num-staff">
      <value value="100"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="North-2?">
      <value value="false"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="signs?">
      <value value="true"/>
    </enumeratedValueSet>
  </experiment>
  <experiment name="East" repetitions="10" runMetricsEveryStep="false">
    <setup>setup</setup>
    <go>go</go>
    <metric>[response-time] of visitors</metric>
    <metric>[evacuating?] of visitors</metric>
    <metric>[evacuate-time] of visitors</metric>
    <metric>[evacuated?] of visitors</metric>
    <enumeratedValueSet variable="perc-adults">
      <value value="90"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="vision-distance">
      <value value="10"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="East?">
      <value value="true"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="bump-distance">
      <value value="2"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="West?">
      <value value="false"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="vision-angle">
      <value value="210"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="perc-female">
      <value value="28"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="verbose?">
      <value value="false"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="perc-familiar">
      <value value="100"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="North-1?">
      <value value="false"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="num-visitors">
      <value value="400"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="alarm?">
      <value value="false"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="debug?">
      <value value="false"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="num-staff">
      <value value="100"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="North-2?">
      <value value="false"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="signs?">
      <value value="true"/>
    </enumeratedValueSet>
  </experiment>
  <experiment name="Weast" repetitions="10" runMetricsEveryStep="false">
    <setup>setup</setup>
    <go>go</go>
    <metric>[response-time] of visitors</metric>
    <metric>[evacuating?] of visitors</metric>
    <metric>[evacuate-time] of visitors</metric>
    <metric>[evacuated?] of visitors</metric>
    <enumeratedValueSet variable="perc-adults">
      <value value="90"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="vision-distance">
      <value value="10"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="East?">
      <value value="false"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="bump-distance">
      <value value="2"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="West?">
      <value value="true"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="vision-angle">
      <value value="210"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="perc-female">
      <value value="28"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="verbose?">
      <value value="false"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="perc-familiar">
      <value value="100"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="North-1?">
      <value value="false"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="num-visitors">
      <value value="400"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="alarm?">
      <value value="false"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="debug?">
      <value value="false"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="num-staff">
      <value value="100"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="North-2?">
      <value value="false"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="signs?">
      <value value="true"/>
    </enumeratedValueSet>
  </experiment>
  <experiment name="NoSigns" repetitions="10" runMetricsEveryStep="false">
    <setup>setup</setup>
    <go>go</go>
    <metric>[response-time] of visitors</metric>
    <metric>[evacuating?] of visitors</metric>
    <metric>[evacuate-time] of visitors</metric>
    <metric>[evacuated?] of visitors</metric>
    <enumeratedValueSet variable="perc-adults">
      <value value="90"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="vision-distance">
      <value value="10"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="East?">
      <value value="true"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="bump-distance">
      <value value="2"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="West?">
      <value value="true"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="vision-angle">
      <value value="210"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="perc-female">
      <value value="28"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="verbose?">
      <value value="false"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="perc-familiar">
      <value value="50"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="North-1?">
      <value value="true"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="num-visitors">
      <value value="400"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="alarm?">
      <value value="false"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="debug?">
      <value value="false"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="num-staff">
      <value value="100"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="North-2?">
      <value value="true"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="signs?">
      <value value="false"/>
    </enumeratedValueSet>
  </experiment>
  <experiment name="Signs" repetitions="10" runMetricsEveryStep="false">
    <setup>setup</setup>
    <go>go</go>
    <metric>[response-time] of visitors</metric>
    <metric>[evacuating?] of visitors</metric>
    <metric>[evacuate-time] of visitors</metric>
    <metric>[evacuated?] of visitors</metric>
    <enumeratedValueSet variable="perc-adults">
      <value value="90"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="vision-distance">
      <value value="10"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="East?">
      <value value="true"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="bump-distance">
      <value value="2"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="West?">
      <value value="true"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="vision-angle">
      <value value="210"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="perc-female">
      <value value="28"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="verbose?">
      <value value="false"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="perc-familiar">
      <value value="50"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="North-1?">
      <value value="true"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="num-visitors">
      <value value="400"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="alarm?">
      <value value="false"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="debug?">
      <value value="false"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="num-staff">
      <value value="100"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="North-2?">
      <value value="true"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="signs?">
      <value value="true"/>
    </enumeratedValueSet>
  </experiment>
  <experiment name="Familiarity" repetitions="5" runMetricsEveryStep="false">
    <setup>setup</setup>
    <go>go</go>
    <metric>[response-time] of visitors</metric>
    <metric>[evacuating?] of visitors</metric>
    <metric>[evacuate-time] of visitors</metric>
    <metric>[evacuated?] of visitors</metric>
    <enumeratedValueSet variable="perc-adults">
      <value value="90"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="vision-distance">
      <value value="10"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="East?">
      <value value="true"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="bump-distance">
      <value value="2"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="West?">
      <value value="true"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="vision-angle">
      <value value="210"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="perc-female">
      <value value="28"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="verbose?">
      <value value="false"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="perc-familiar">
      <value value="10"/>
      <value value="20"/>
      <value value="30"/>
      <value value="40"/>
      <value value="50"/>
      <value value="60"/>
      <value value="70"/>
      <value value="80"/>
      <value value="90"/>
      <value value="100"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="North-1?">
      <value value="true"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="num-visitors">
      <value value="400"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="alarm?">
      <value value="false"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="debug?">
      <value value="false"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="num-staff">
      <value value="100"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="North-2?">
      <value value="true"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="signs?">
      <value value="true"/>
    </enumeratedValueSet>
  </experiment>
  <experiment name="Gender" repetitions="5" runMetricsEveryStep="false">
    <setup>setup</setup>
    <go>go</go>
    <metric>[response-time] of visitors</metric>
    <metric>[evacuating?] of visitors</metric>
    <metric>[evacuate-time] of visitors</metric>
    <metric>[evacuated?] of visitors</metric>
    <enumeratedValueSet variable="perc-adults">
      <value value="90"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="vision-distance">
      <value value="10"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="East?">
      <value value="true"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="bump-distance">
      <value value="2"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="West?">
      <value value="true"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="vision-angle">
      <value value="210"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="perc-female">
      <value value="10"/>
      <value value="20"/>
      <value value="30"/>
      <value value="40"/>
      <value value="50"/>
      <value value="60"/>
      <value value="70"/>
      <value value="80"/>
      <value value="90"/>
      <value value="100"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="verbose?">
      <value value="false"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="perc-familiar">
      <value value="50"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="North-1?">
      <value value="true"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="num-visitors">
      <value value="400"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="alarm?">
      <value value="false"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="debug?">
      <value value="false"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="num-staff">
      <value value="100"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="North-2?">
      <value value="true"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="signs?">
      <value value="true"/>
    </enumeratedValueSet>
  </experiment>
  <experiment name="Vision Cone" repetitions="5" runMetricsEveryStep="false">
    <setup>setup</setup>
    <go>go</go>
    <metric>[response-time] of visitors</metric>
    <metric>[evacuating?] of visitors</metric>
    <metric>[evacuate-time] of visitors</metric>
    <metric>[evacuated?] of visitors</metric>
    <enumeratedValueSet variable="perc-adults">
      <value value="90"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="vision-distance">
      <value value="10"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="East?">
      <value value="true"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="bump-distance">
      <value value="2"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="West?">
      <value value="true"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="vision-angle">
      <value value="45"/>
      <value value="90"/>
      <value value="135"/>
      <value value="180"/>
      <value value="210"/>
      <value value="225"/>
      <value value="270"/>
      <value value="315"/>
      <value value="360"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="perc-female">
      <value value="28"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="verbose?">
      <value value="false"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="perc-familiar">
      <value value="50"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="North-1?">
      <value value="true"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="num-visitors">
      <value value="400"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="alarm?">
      <value value="false"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="debug?">
      <value value="false"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="num-staff">
      <value value="100"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="North-2?">
      <value value="true"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="signs?">
      <value value="true"/>
    </enumeratedValueSet>
  </experiment>
  <experiment name="Vision Distance" repetitions="5" runMetricsEveryStep="false">
    <setup>setup</setup>
    <go>go</go>
    <metric>[response-time] of visitors</metric>
    <metric>[evacuating?] of visitors</metric>
    <metric>[evacuate-time] of visitors</metric>
    <metric>[evacuated?] of visitors</metric>
    <enumeratedValueSet variable="perc-adults">
      <value value="90"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="vision-distance">
      <value value="2"/>
      <value value="4"/>
      <value value="6"/>
      <value value="8"/>
      <value value="10"/>
      <value value="12"/>
      <value value="14"/>
      <value value="16"/>
      <value value="18"/>
      <value value="20"/>
      <value value="25"/>
      <value value="30"/>
      <value value="40"/>
      <value value="50"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="East?">
      <value value="true"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="bump-distance">
      <value value="2"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="West?">
      <value value="true"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="vision-angle">
      <value value="210"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="perc-female">
      <value value="28"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="verbose?">
      <value value="false"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="perc-familiar">
      <value value="50"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="North-1?">
      <value value="true"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="num-visitors">
      <value value="400"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="alarm?">
      <value value="false"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="debug?">
      <value value="false"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="num-staff">
      <value value="100"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="North-2?">
      <value value="true"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="signs?">
      <value value="true"/>
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
