turtles-own [ specialization
              species
              energy
              suitability-range-min
              suitability-range-max
              specialist-or-generalist
              random-identifier
]

patches-own [ suitability
              food
              identity
              unique-species-count   ;; New variable to track unique species on each patch
              previous-species-list
              current-species-list
              density                ;; New variable to track the number of agents on each patch
              typeA-count-x   ;; Count of Type A agents in step x
              typeB-count-x   ;; Count of Type B agents in step x
              typeA-count-x1  ;; Count of Type A agents in step x+1
              typeB-count-x1  ;; Count of Type B agents in step x+1
              turnover-detail ;; Details of species turnover
]
globals [
  years
  output-file-name
  total-species
]
to update-and-log-patch-species-diversity
  ; Check if it's a 50-tick interval
  if ticks mod 50 = 0 [
    ; Increment the years counter
    set years years + 1

    ; Initialize lists to hold patch data
    let patch-diversity-list []
    let specialists-list []
    let generalists-list []

    ; Gather diversity data for each patch
    ask patches [
      let patch-species-list remove-duplicates [species] of turtles-here
      let specialization-list [specialist-or-generalist] of turtles-here
      set unique-species-count length patch-species-list

      ; Add patches with species to the list
      if unique-species-count > 0 [
        set patch-diversity-list lput (list self unique-species-count patch-species-list specialization-list) patch-diversity-list

        ; Separate specialists and generalists
        foreach patch-species-list [current-species ->
          let spec-type one-of [specialist-or-generalist] of turtles with [species = current-species]
          if spec-type = "specialist" [
            set specialists-list lput current-species specialists-list
          ]
          if spec-type = "generalist" [
            set generalists-list lput current-species generalists-list
          ]
        ]
      ]
    ]

    ; Sort patches by species count in descending order
    set patch-diversity-list custom-sort-by-count patch-diversity-list

    ; Display species and their types for the current year
    show (word "Year " years ": Specialists: " remove-duplicates specialists-list ", Generalists: " remove-duplicates generalists-list)

    ; Display each patch in the sorted list
foreach patch-diversity-list [patch-item ->
  let patch-agent item 0 patch-item
  let species-count item 1 patch-item
  let patch-species-list item 2 patch-item
  let specialization-list remove-duplicates item 3 patch-item

  ; Display the information
  show (word "Year " years ": Patch " [pxcor] of patch-agent ", " [pycor] of patch-agent ": " patch-species-list " (Count: " species-count ", Types: " specialization-list ")")
]
  ]
end

; Custom sorting function
to-report custom-sort-by-count [lst]
  let sorted-list lst
  let n length lst
  let swapped? true

  ; Bubble sort logic for descending order
  while [swapped?] [
    set swapped? false
    foreach range (n - 1) [i ->
      let current-item item i sorted-list
      let next-item item (i + 1) sorted-list

      if item 1 current-item < item 1 next-item [
        ; Swap items
        set sorted-list replace-item i sorted-list next-item
        set sorted-list replace-item (i + 1) sorted-list current-item
        set swapped? true
      ]
    ]
  ]
  report sorted-list
end

to color-patches-by-diversity
  ask patches [
    if unique-species-count = 0 [ set pcolor white ]
    if unique-species-count = 1 [ set pcolor yellow ]
    if unique-species-count = 2 [ set pcolor green ]
    if unique-species-count >= 3 [ set pcolor blue ]
  ]
  display
end

; Main simulation procedure
to run-simulation
  ; Stop if maximum ticks reached or no turtles left
  if ticks >= num-runs [ stop ]
  if count turtles = 0 [ stop ]

  ; Main simulation steps
  check-patches
  disperse
  arrive
  species-interact
  die-off

  ; Update patch diversity and color patches
  update-and-log-patch-species-diversity
  color-patches-by-diversity

  ; Increment the tick counter
  tick
end

to add-specialists
  create-turtles specialists [
    setxy random-xcor random-ycor
    set size 0.25
    set shape "dot"
    set energy 10
    if number-of-species = 10 [ set species random 9
     (ifelse
        species >= 0 and species <= 4 [ set specialization random-float 0.2 ]
        species > 4 and species <= 8 [ set specialization (random-float 0.2) + 0.3 ] ) ]

    if number-of-species = 20 [ set species random 18
     (ifelse
        species >= 0 and species <= 7 [ set specialization random-float 0.2 ]
        species > 7 and species <= 17 [ set specialization (random-float 0.2) + 0.3 ] ) ]

    if number-of-species = 50 [ set species random 45
     (ifelse
        species >= 0 and species < 22 [ set specialization random-float 0.2 ]
        species >= 22 and species < 45 [ set specialization (random-float 0.2) + 0.3 ] ) ]

    set specialist-or-generalist "specialist"

    if view-by = "specialization" [ set color white - ( specialization * 8 ) ]
    if view-by = "species" [ set color random 140 ]

    let x random-float 0.5
    let y random-float 0.5
       set suitability-range-min ( x + 0.25 ) - ( y * suitability-constant )
       set suitability-range-max ( x + 0.25 ) + ( y * suitability-constant )

    ifelse show-specialization?  [ set label precision specialization 2 ] [ set label " "]
]
end

to add-generalists
  create-turtles generalists [
    setxy random-xcor random-ycor
    set size 0.25
    set shape "dot"
    set energy 10

    if number-of-species = 10 [ set species 9
     set specialization (random-float 0.5) + 0.5 ]

    if number-of-species = 20 [ set species one-of [ 18 19 ]
     set specialization (random-float 0.5) + 0.5 ]

    if number-of-species = 50 [ set species one-of [ 45 46 47 48 49 ]
     set specialization (random-float 0.5) + 0.5 ]

    set specialist-or-generalist "generalist"

    if view-by = "specialization" [ set color white - ( specialization * 8 ) ]
    if view-by = "species" [ set color random 140 ]

    let x random-float 1
    let y random-float 0.6
      set suitability-range-min x - ( y * suitability-constant * 2 )
      set suitability-range-max x + ( y * suitability-constant * 2 )

   ifelse show-specialization?  [ set label precision specialization 2 ] [ set label " "]

  ]
end

to calculate-and-export-turnover
  ;; Update patch data for the current tick
  ask patches [
    ;; Save the previous step's data
    set previous-species-list current-species-list
    set typeA-count-x typeA-count-x1
    set typeB-count-x typeB-count-x1

    ;; Update the current step's data
    set current-species-list remove-duplicates [species] of turtles-here
    set typeA-count-x1 count turtles-here with [specialist-or-generalist = "specialist"]
    set typeB-count-x1 count turtles-here with [specialist-or-generalist = "generalist"]
    set density count turtles-here ;; Update patch density

    ;; Calculate turnover
    let shared-species filter [species-item -> member? species-item previous-species-list] current-species-list
    let lost-species filter [species-item -> not member? species-item shared-species] previous-species-list
    let gained-species filter [species-item -> not member? species-item shared-species] current-species-list
    let turnover length lost-species + length gained-species

    ;; Store species turnover details
    set turnover-detail (word "Lost: " lost-species
                              " | Gained: " gained-species
                              " | Shared: " shared-species)

    ;; Log results to a file every 50 ticks
    if ticks mod 50 = 0 [
      file-open output-file-name
      file-print (word years ", " pxcor ", " pycor ", " previous-species-list ", " current-species-list
                    ", " turnover ", " turnover-detail ", " typeA-count-x1 ", " typeB-count-x1
                    ", " suitability ", " density ", " total-species)
      file-close
    ]
  ]
end
to calculate-total-species
  ;; Collect all species present in the simulation
  let all-species remove-duplicates [species] of turtles
  ;; Update the global variable with the count of unique species
  set total-species length all-species
end

to calculate-patch-densities
  ask patches [
    set density count turtles-here ;; Count turtles on the patch
  ]
end

to setup
  clear-all
  set years 0
  set output-file-name "patch_turnover_data.csv"

  ; Initialize patches for turnover calculations
  ask patches [
    set previous-species-list []
    set current-species-list []
    set density 0 ;; Initialize density to 0
  ]

  ; Prepare CSV file for output
  file-open output-file-name
  file-print "Year, Patch X, Patch Y, Previous Species List, Current Species List, Turnover, Turnover Detail, Type A Count, Type B Count, Patch Suitability, Patch Density, Total Species"
  file-close

  ; 1. Creating agents (specialists/generalists) depending on specialization setting (SS)
  if species-specialization = "HIGH"
  [ create-turtles ( %-generalists * initial-species ) [
    setxy random-xcor random-ycor
    set size 0.25
    set shape "dot"
    set random-identifier 20
     if specialist-or-generalist = "specialist" [ set random-identifier random 6 ]
     if specialist-or-generalist = "generalist" [ set random-identifier (random 6) + 6 ]
    set energy 10
    if number-of-species = 10 [ set species 9 ]
    if number-of-species = 20 [ set species one-of [ 18 19 ] ]
    if number-of-species = 50 [ set species one-of [ 45 46 47 48 49 ] ] ]

    create-turtles ( (1 - %-generalists ) * initial-species ) [
    setxy random-xcor random-ycor
    set size 0.25
    set shape "dot"
    set energy 10
    if number-of-species = 10 [ set species random 9 ]
    if number-of-species = 20 [ set species random 18 ]
    if number-of-species = 50 [ set species random 45 ] ] ]

  if species-specialization = "LOW"
  [ create-turtles ( %-generalists * initial-species ) [
    setxy random-xcor random-ycor
    set size 0.25
    set shape "dot"
    set energy 10
    if number-of-species = 10 [ set species one-of [ 8 9 ] ]
    if number-of-species = 20 [ set species one-of [ 17 18 19 ] ]
    if number-of-species = 50 [ set species one-of [ 43 44 45 46 47 48 49 ] ] ]

    create-turtles ( (1 - %-generalists ) * initial-species ) [
    setxy random-xcor random-ycor
    set size 0.25
    set shape "dot"
    set energy 10
    if number-of-species = 10 [ set species random 8 ]
    if number-of-species = 20 [ set species random 17 ]
    if number-of-species = 50 [ set species random 43 ] ] ]

  if species-specialization =  "RANDOM"
  [ create-turtles ( %-generalists * initial-species ) [
    setxy random-xcor random-ycor
    set size 0.25
    set shape "dot"
    set energy 10
    if number-of-species = 10 [ set species one-of ( range 5 10 ) ]
    if number-of-species = 20 [ set species one-of ( range 10 20 ) ]
    if number-of-species = 50 [ set species one-of ( range 25 50 ) ] ]

    create-turtles ( (1 - %-generalists ) * initial-species ) [
    setxy random-xcor random-ycor
    set size 0.25
    set shape "dot"
    set energy 10
    if number-of-species = 10 [ set species random 5 ]
    if number-of-species = 20 [ set species random 10 ]
    if number-of-species = 50 [ set species random 25 ] ] ]

  if species-specialization = "NONE"
  [ create-turtles ( %-generalists * initial-species ) [
    setxy random-xcor random-ycor
    set size 0.25
    set shape "dot"
    set energy 10
    if number-of-species = 10 [ set species one-of ( range 5 10 ) ]
    if number-of-species = 20 [ set species one-of ( range 10 20 ) ]
    if number-of-species = 50 [ set species one-of ( range 25 50 ) ] ]

    create-turtles ( (1 - %-generalists ) * initial-species ) [
    setxy random-xcor random-ycor
    set size 0.25
    set shape "dot"
    set energy 10
    if number-of-species = 10 [ set species random 5 ]
    if number-of-species = 20 [ set species random 10 ]
    if number-of-species = 50 [ set species random 25 ] ] ]

; 2. Assigning specialization values
ask turtles [

     if species-specialization = "HIGH"
      [ if number-of-species = 10  [
        (ifelse
        species >= 0 and species <= 4 [ set specialization random-float 0.2 ]
        species > 4 and species <= 8 [ set specialization (random-float 0.2) + 0.2 ]
        species = 9 [ set specialization (random-float 0.5) + 0.5 ] ) ]

        if number-of-species = 20 [
        (ifelse
        species >= 0 and species < 7 [ set specialization random-float 0.2 ]
        species >= 7 and species < 18 [ set specialization (random-float 0.2) + 0.2 ]
        species >= 18 and species < 20 [ set specialization (random-float 0.5) + 0.5 ] ) ]

        if number-of-species = 50 [
        (ifelse
        species >= 0 and species < 22 [ set specialization random-float 0.2 ]
        species >= 22 and species < 45 [ set specialization (random-float 0.2) + 0.2 ]
        species >= 45 or species < 50 [ set specialization (random-float 0.5) + 0.5] ) ]
      ]

     if species-specialization = "RANDOM"
    [  if number-of-species = 10 [
       (ifelse
        species >= 0 and species < 5 [ set specialization random-float 0.5 ]
        species >= 5 and species < 10 [ set specialization (random-float 0.5) + 0.5 ] ) ]

      if number-of-species = 20  [
      (ifelse
        species >= 0 and species < 10 [ set specialization random-float 0.5  ]
        species >= 10 and species < 20 [ set specialization (random-float 0.5) + 0.5 ] ) ]

      if number-of-species = 50 [
       (ifelse
        species >= 0 and species < 25 [ set specialization random-float 0.5 ]
        species >= 25 and species < 50 [ set specialization (random-float 0.5) + 0.5 ] ) ]
      ]

     if species-specialization = "LOW"
      [  if number-of-species = 10 [
       (ifelse
        species >= 0 and species < 5 [ set specialization (random-float 0.2) + 0.1 ]
        species >= 5 and species < 7 [ set specialization (random-float 0.2) + 0.3 ]
        species >= 8  and species < 10 [ set specialization (random-float 0.4) + 0.6 ] )  ]

        if number-of-species = 20  [
        (ifelse
        species >= 0 and species < 8 [ set specialization (random-float 0.2) + 0.1 ]
        species >= 8 and species < 17 [ set specialization (random-float 0.2) + 0.3 ]
        species >= 17 and species < 20 [ set specialization (random-float 0.4) + 0.6 ] ) ]

       if number-of-species = 50 [
        (ifelse
        species >= 0 and species < 21 [ set specialization (random-float 0.2) + 0.1 ]
        species >= 21 and species < 43 [ set specialization (random-float 0.2) + 0.3 ]
        species >= 43 and species < 50 [ set specialization (random-float 0.4) + 0.6 ] ) ]
      ]

     if species-specialization = "NONE"
      [ if number-of-species = 10  [
        (ifelse
        species >= 0 and species < 5 [ set specialization ( 0.5 - random-float 0.1 ) ]
        species >= 5 and species < 10 [ set specialization ( 0.5 + random-float 0.1 ) ]  ) ]

        if number-of-species = 20 [
        (ifelse
        species >= 0 and species < 10 [ set specialization ( 0.5 - random-float 0.1 ) ]
        species >= 10 and species < 20 [ set specialization ( 0.5 + random-float 0.1) ] ) ]

        if number-of-species = 50 [
        (ifelse
        species >= 0 and species < 25 [ set specialization ( 0.5 - random-float 0.1) ]
        species >= 25 and species < 50 [ set specialization ( 0.5 + random-float 0.1 ) ] ) ]
      ]

; 3. View settings (view the color of the agents based on specialization or species)
     if view-by = "specialization" [ set color white - ( specialization * 8 ) ]

    if view-by = "species" [
        if species = 0 [ set color red + 1 ]
        if species = 1 [ set color orange + 1 ]
        if species = 2 [ set color yellow ]
        if species = 3 [ set color cyan - 2 ]
        if species = 4 [ set color sky - 1 ]
        if species = 5 [ set color gray - 2 ]
        if species = 6 [ set color violet + 1 ]
        if species = 7 [ set color magenta + 1 ]
        if species = 8 [ set color magenta ]
        if species = 9 [ set color pink - 2 ]
        if species = 10 [ set color yellow - 2 ]
        if species = 11 [ set color sky + 2.5  ]
        if species = 12 [ set color cyan + 2.5 ]
        if species = 13 [ set color brown - 1.5 ]
        if species = 14 [ set color gray - 2.5 ]
        if species = 15 [ set color red - 0.5 ]
        if species = 16 [ set color blue - 3 ]
        if species = 17 [ set color brown + 2 ]
        if species = 18 [ set color magenta - 2 ]
        if species = 19 [ set color turquoise + 2 ]
        if number-of-species = 50 [ set color ( species * 2 ) ]  ]

     if specialization <= 0.5 [ set specialist-or-generalist "specialist" ]
     if specialization > 0.5 [ set specialist-or-generalist "generalist" ]

; 4. Assigning suitability range for each species/agent
    if specialization <= 0.5
    [ let x random-float 0.5
      let y random-float 0.5
     set suitability-range-min ( x + 0.25 ) - ( y * suitability-constant )
     set suitability-range-max ( x + 0.25 ) + ( y * suitability-constant )  ]

   if specialization > 0.5
    [ let x random-float 1
      let y random-float 0.6
      set suitability-range-min x - ( y * suitability-constant * 2 )
      set suitability-range-max x + ( y * suitability-constant * 2 )   ]

 ]

; 5. Code for the output monitor to display suitability ranges


   output-print "SPECIALISTS"
   output-type "mean suitability range: "
      ifelse ( mean [ suitability-range-min ] of turtles with [ specialization <= 0.5 ] )  < 0
        [ output-type 0 ]
        [ output-type precision ( mean [ suitability-range-min ] of turtles with [ specialization <= 0.5 ]) 2 ]
      output-type " to "
      ifelse ( mean [ suitability-range-max ] of turtles with [ specialization <= 0.5 ] ) > 1
        [ output-type 1 ]
        [ output-type precision ( mean [ suitability-range-max ] of turtles with [ specialization <= 0.5 ] ) 2 ]
      output-print " "
      output-type "mean size of range: "
      output-type precision ( ( mean [ suitability-range-max ] of turtles with [ specialization <= 0.5 ] ) - ( mean [ suitability-range-min ] of turtles with [ specialization <= 0.5 ] ) ) 2

     output-print " "
     output-print " "

     output-print "GENERALISTS"
     output-type "mean suitability range: "
      ifelse ( mean [ suitability-range-min ] of turtles with [ specialization > 0.5 ] ) < 0
      [ output-type 0 ]
      [ output-type precision ( mean [ suitability-range-min ] of turtles with [ specialization > 0.5 ] ) 2 ]
     output-type " to "
      ifelse ( mean [ suitability-range-max ] of turtles with [ specialization > 0.5 ] ) > 1
      [ output-type 1 ]
      [ output-type precision ( mean [ suitability-range-max ] of turtles with [ specialization > 0.5 ] ) 2 ]
     output-print " "
      output-type "mean size of range: "
      output-type precision ( ( mean [ suitability-range-max ] of turtles with [ specialization > 0.5 ] ) - ( mean [ suitability-range-min ] of turtles with [ specialization > 0.5 ] ) ) 2

  ; 6. Assigning suitability values for patches
  ask patches [
    set identity random 10

    if interhabitat-differences = "HIGH"
      [ (ifelse
        identity >= 0 and identity < 5 [ set suitability random-float 0.5 ]
        identity >= 5 and identity < 10 [ set suitability (random-float 0.5) + 0.5 ])  ]

    if interhabitat-differences = "RANDOM"
    [ set suitability random-float 1 ]

    if interhabitat-differences = "LOW - GOOD"
    [ (ifelse
      identity = 0 [ set suitability random-float 1  ]
      identity >= 1 and  identity < 4 [ set suitability (random-float 0.6) + 0.4 ]
      identity >= 4 and  identity < 7 [ set suitability (random-float 0.4) + 0.6 ]
      identity >= 7 and identity < 10 [ set suitability (random-float 0.2) + 0.8 ]) ]

    if interhabitat-differences = "LOW - POOR"
     [ (ifelse
        identity = 0  [ set suitability random-float 1 ]
        identity >= 1 and  identity < 3 [ set suitability random-float 0.5 ]
        identity >= 3 and identity < 6 [ set suitability  (random-float 0.3) + 0.1 ]
        identity >= 6 and identity < 10 [ set suitability (random-float 0.1) + 0.1 ] ) ]

    if interhabitat-differences = "NONE"
    [ (ifelse
      identity >= 0 and identity < 5 [ set suitability 0.5 - (random-float 0.1) ]
      identity >= 5 and identity < 10 [ set suitability 0.5 + (random-float 0.1) ] )  ]

; 7. Setting the color of patches based on their suitability values (a higher suitability/quality = a darker shade)
    (ifelse
      suitability >= 0 and suitability < 0.2 [ set pcolor green + 2 ]
      suitability >= 0.2 and suitability < 0.4 [ set pcolor green + 1]
      suitability >= 0.4 and suitability < 0.6 [ set pcolor green ]
      suitability >= 0.6 and suitability < 0.8 [ set pcolor green - 1]
      suitability >= 0.8 and suitability < 1 [ set pcolor green - 2] )

    set food initial-food-per-patch

 ]

; 8. On/off switches for labels of agents/patches (specialization/suitability)
  ask turtles [
    ifelse show-specialization?  [ set label precision specialization 2 ] [ set label " "] ]

  ask patches [ set plabel-color black
    ifelse show-suitability? [ set plabel precision suitability 2 ] [ set plabel " " ] ]

  reset-ticks
end

; added this code (October 7th, 2024)
to print-specialists-and-generalists
  let specialists-list []
  let generalists-list []

  ; Build the lists of specialists and generalists
  ask turtles [
    if specialist-or-generalist = "specialist" [
      set specialists-list lput species specialists-list
    ]
    if specialist-or-generalist = "generalist" [
      set generalists-list lput species generalists-list
    ]
  ]

  ; Remove duplicates in both lists
  set specialists-list remove-duplicates specialists-list
  set generalists-list remove-duplicates generalists-list

  ; Print the final lists once
  print "Specialists:"
  print specialists-list
  print "Generalists:"
  print generalists-list
end

;added on jan 26 for logging patch diversity and tracking density
to go
  if ticks >= num-runs or count turtles = 0 [
    print-specialists-and-generalists
    stop
  ]

  calculate-patch-densities ;; Update patch densities
  calculate-total-species  ;; Update the total species count globally

  ; Main simulation logic
  check-patches
  disperse
  arrive
  species-interact
  die-off

  update-and-log-patch-species-diversity
  calculate-and-export-turnover

  tick
end
; Individual Procedures:
to check-patches
  ask patches [
    if food <= 50 and random-float 1 < patch-regrowth-rate [
    set food food + initial-food-per-patch ] ]
end

to disperse
  if effective-dispersal = "HIGH"
  [ ask turtles [ if suitability < suitability-range-min or suitability > suitability-range-max [
    right random 360 fd 2
       if specialization <= 0.5 [ set energy energy - 1 ]
       if specialization > 0.5  [ set energy energy - 2 ]  ] ] ]

  if effective-dispersal = "NON-LIMITING"
  [ ask n-of (0.5 * count turtles ) turtles [
    if  suitability  < suitability-range-min or suitability > suitability-range-max [
       right random 360 fd 2
           if specialization <= 0.5 [ set energy energy - 1 ]
           if specialization > 0.5  [ set energy energy - 2 ]  ] ] ]

   if effective-dispersal = "RANDOM"
  [ ask n-of (random-float 1 * count turtles) turtles [
    if  suitability  < suitability-range-min or suitability > suitability-range-max [
       right random 360 fd 2
         if specialization <= 0.5 [ set energy energy - 1 ]
         if specialization > 0.5  [ set energy energy - 2 ]  ] ]   ]

  if effective-dispersal = "LOW"
  [ ask n-of (0.05 * count turtles ) turtles [
       if  suitability  < suitability-range-min or suitability > suitability-range-max [
          right random 360 fd 2
             if specialization <= 0.5 [ set energy energy - 1 ]
             if specialization > 0.5  [ set energy energy - 2 ]  ] ] ]

  if effective-dispersal = "NONE" [ ]
end

to arrive
   ask turtles [
   ; 1. Specialists
    if specialization <= 0.5
    [ (ifelse
        suitability >= suitability-range-min and suitability <= suitability-range-max
      [
        if food > 50 [ set energy energy + 20 ask patch-here [ set food food - 10 ]]
        if food > 0 and food <= 50 [ set energy energy + 10 ask patch-here [ set food food - 5]]
        if food <= 0 [ die ]

          let K (max-agents-on-a-patch * 25 * fraction) * specialist-K
          let N (count turtles with [ specialization <= 0.5 ] )
          let reproduction-K ( reproduction-rate * (K - N) / N )
          let boost-reproduction ( 0.5 - specialization )

        ifelse K-always-on?
         [  ifelse boost-reproduction?
            [ if energy > 10 and random-float 1 <  ( reproduction-K + boost-reproduction ) [ hatch 1 [ set energy 5 right random 360 fd 1 ] set energy energy - 5 ] ]
            [ if energy > 10 and random-float 1 <  reproduction-K [ hatch 1 [ set energy 5 right random 360 fd 1 ] set energy energy - 5 ] ]  ]

         [ ifelse boost-reproduction?
            [ if N < K [ if energy > 10 and random-float 1 < ( reproduction-rate + boost-reproduction ) [ hatch 1 [ set energy 5 right random 360 fd 1 ] set energy energy - 5 ] ]
              if N >= K [ if energy > 10 and random-float 1 < ( reproduction-K + boost-reproduction ) [ hatch 1 [ set energy 5 right random 360 fd 1 ] set energy energy -  5 ] ]  ]
            [ if N < K [ if energy > 10 and random-float 1 <  reproduction-rate  [ hatch 1 [ set energy 5 right random 360 fd 1 ] set energy energy - 5 ] ]
              if N >= K [ if energy > 10 and random-float 1 <  reproduction-K  [ hatch 1 [ set energy 5 right random 360 fd 1 ] set energy energy -  5 ] ]  ]  ]
    ]

      suitability < suitability-range-min or suitability > suitability-range-max
      [ set energy energy - 1 ]  ) ]

    ; 2. Generalists
    if specialization > 0.5
    [ (ifelse
       suitability >= suitability-range-min and suitability <= suitability-range-max
       [
         if food > 50 [ set energy energy + 10 ask patch-here [ set food food - 5 ]]
         if food > 0 and food <= 50 [ set energy energy + 5 ask patch-here [ set food food - 2.5 ] ]
         if food <= 0 [ die ]

         let K (max-agents-on-a-patch * 25 * fraction) * specialist-K
         let N (count turtles with [ specialization > 0.5 ] )
         let reproduction-K ( reproduction-rate * (K - N) / N )
         let lower-reproduction ( 0.5 - specialization )

       ifelse K-always-on?
        [  ifelse boost-reproduction?
          ; reproduction boost - ON
            [ if energy > 10 and random-float 1 <  ( reproduction-K + lower-reproduction ) [ hatch 1 [ set energy 5 right random 360 fd 1 ] set energy energy - 5 ] ]
          ; reproduction boost - OFF
            [ if energy > 10 and random-float 1 <  reproduction-K [ hatch 1 [ set energy 5 right random 360 fd 1 ] set energy energy - 5 ] ] ]

        [ ifelse boost-reproduction?
          ; reproduction boost - ON
             [ if N < K [ if energy > 10 and random-float 1 < ( reproduction-rate + lower-reproduction ) [ hatch 1 [ set energy 5 right random 360 fd 1 ] set energy energy - 5 ] ]
              if N >= K [ if energy > 10 and random-float 1 < ( reproduction-K + lower-reproduction ) [ hatch 1 [ set energy 5 right random 360 fd 1 ] set energy energy -  5 ] ]  ]
          ; reproduction boost - OFF
            [ if N < K [ if energy > 10 and random-float 1 <  reproduction-rate  [ hatch 1 [ set energy 5 right random 360 fd 1 ] set energy energy - 5 ] ]
              if N >= K [ if energy > 10 and random-float 1 <  reproduction-K  [ hatch 1 [ set energy 5 right random 360 fd 1 ] set energy energy -  5 ] ]  ] ]
      ]

      suitability < suitability-range-min or suitability > suitability-range-max
      [ right random 360 fd 1 set energy energy - 2  ] ) ]
 ]
end

to species-interact
   if species-interactions = "NONE" [   ]

   if species-interactions = "SPECIALIST-GENERALIST"
    [ ask turtles [
        if specialist-or-generalist = "specialist" [
            ask turtles in-radius 0.75 [ if specialist-or-generalist = "specialist" [ set energy ( energy + ss-reward ) ] ]
            ask turtles in-radius 0.75 [ if specialist-or-generalist = "generalist" [ set energy ( energy + sg-reward ) ] ] ]

        if specialist-or-generalist = "generalist" [
            ask turtles in-radius 0.75 [ if specialist-or-generalist = "generalist" [ set energy ( energy + gg-reward ) ] ]
            ask turtles in-radius 0.75 [ if specialist-or-generalist = "specialist" [ set energy ( energy + gs-reward ) ] ] ] ]
      ]

   if species-interactions = "SPEC-GEN-SLIDER"  ;; 9 combinations of interactions

  ;; Combination 1-3
  [ if SI-specialists = -1 and SI-generalists = -1 ; specialist x specialist reward, generalist x specialist reward
    [ ask turtles [
       if specialist-or-generalist = "specialist" [ ask turtles in-radius 0.75 [ if specialist-or-generalist = "specialist" [ set energy ( energy + ss-reward ) ] ] ]
       if specialist-or-generalist = "generalist" [ ask turtles in-radius 0.75 [ if specialist-or-generalist = "specialist" [ set energy ( energy + gs-reward ) ] ] ]     ] ]

    if SI-specialists = -1 and SI-generalists = 0 ; specialist x specialist reward, NONE for generalists
     [ ask turtles [
        if specialist-or-generalist = "specialist" [ ask turtles in-radius 0.75 [ if specialist-or-generalist = "specialist" [ set energy ( energy + ss-reward ) ] ] ] ] ]

    if SI-specialists = -1 and SI-generalists = 1 ; specialist x specialist reward, generalist x generalist reward
     [ ask turtles [
         if specialist-or-generalist = "specialist" [ ask turtles in-radius 0.75 [ if specialist-or-generalist = "specialist" [ set energy ( energy + ss-reward ) ] ] ]
         if specialist-or-generalist = "generalist" [ ask turtles in-radius 0.75 [ if specialist-or-generalist = "generalist" [ set energy ( energy + gg-reward ) ] ] ]     ] ]

   ;; Combination 4-6
    if SI-specialists = 0 and SI-generalists = -1 ; NONE for specialists, generalist x specialist reward
    [ ask turtles [
       if specialist-or-generalist = "generalist" [ ask turtles in-radius 0.75 [ if specialist-or-generalist = "specialist" [ set energy ( energy + gs-reward ) ] ] ]     ] ]

    if SI-specialists = 0 and SI-generalists = 0 ; NONE for specialists, NONE for generalists
    [ ]

    if SI-specialists = 0 and SI-generalists = 1 ; NONE for specialists, generalist x generalist reward
    [ ask turtles [ if specialist-or-generalist = "generalist" [ ask turtles in-radius 0.75 [ if specialist-or-generalist = "generalist" [ set energy ( energy + gg-reward ) ] ] ]   ] ]

   ;;Combination 7-9
    if SI-specialists = 1 and SI-generalists = -1 ; specialist x generalist reward, generalist x specialist reward
    [ ask turtles [
       if specialist-or-generalist = "specialist" [ ask turtles in-radius 0.75 [ if specialist-or-generalist = "generalist" [ set energy ( energy + sg-reward ) ] ] ]
       if specialist-or-generalist = "generalist" [ ask turtles in-radius 0.75 [ if specialist-or-generalist = "specialist" [ set energy ( energy + gs-reward ) ] ] ]    ] ]

    if SI-specialists = 1 and SI-generalists = 0 ; specialist x generalist reward, NONE for generalists
    [ ask turtles [
      if specialist-or-generalist = "specialist" [ ask turtles in-radius 0.75 [ if specialist-or-generalist = "generalist" [ set energy ( energy + sg-reward ) ] ] ]      ] ]

    if SI-specialists = 1 and SI-generalists = 1 ; specialist x generalist reward, generalist x generalist reward
    [ ask turtles [
      if specialist-or-generalist = "specialist" [ ask turtles in-radius 0.75 [ if specialist-or-generalist = "generalist" [ set energy ( energy + sg-reward ) ] ] ]
      if specialist-or-generalist = "generalist" [ ask turtles in-radius 0.75 [ if specialist-or-generalist = "generalist" [ set energy ( energy + gg-reward ) ] ] ]     ]  ]
  ]

    ;;;;;;;;


   if species-interactions = "HIGH"
   [ ask turtles [
    if number-of-species = 10 [
    if species = random 10 [ ask turtles in-radius 0.75 [ if species = random 10 [ set energy energy * 2 ]]]
    if species = random 10 [ ask turtles in-radius 0.75 [ if species = random 10 [ set energy energy / 2 ]]]   ]

    if number-of-species = 20 [
    if species = random 20 [ ask turtles in-radius 0.75 [ if species = random 20 [ set energy energy * 2 ]]]
    if species = random 20 [ ask turtles in-radius 0.75 [ if species = random 20 [ set energy energy / 2 ]]]   ]

    if number-of-species = 50 [
    if species = random 50 [ ask turtles in-radius 0.75 [ if species = random 50 [ set energy energy * 2 ]]]
    if species = random 50 [ ask turtles in-radius 0.75 [ if species = random 50 [ set energy energy / 2 ]]]   ] ]]

  if species-interactions = "LOW" ; (0.2 * number of species) positive and negative interactions
   [ ask turtles [

  if number-of-species = 10 [
    if species = 2 [ ask turtles in-radius 0.75 [ if species = random 10 and species != 2 [ set energy energy * 2 ]]]
    if species = 6 [ ask turtles in-radius 0.75 [ if species = random 10 and species != 6 [ set energy energy * 2 ]]]

    if species = 5 [ ask turtles in-radius 0.75 [ if species = random 10 and species != 5 [ set energy energy / 2 ]]]
    if species = 7 [ ask turtles in-radius 0.75 [ if species = random 10 and species != 7 [ set energy energy / 2 ]]]  ]

  if number-of-species = 20 [
     if species = 0 [ ask turtles in-radius 0.75 [ if species = random 10 and species != 0 [ set energy energy * 2 ]]]
     if species = 4 [ ask turtles in-radius 0.75 [ if species = random 10 and species != 4 [ set energy energy * 2 ]]]
     if species = 12 [ ask turtles in-radius 0.75 [ if species = random 10 and species != 12 [ set energy energy * 2 ]]]
     if species = 18 [ ask turtles in-radius 0.75 [ if species = random 10 and species != 18 [ set energy energy * 2 ]]]

     if species = 3 [ ask turtles in-radius 0.75 [ if species = random 10 and species != 3 [ set energy energy / 2 ]]]
     if species = 7 [ ask turtles in-radius 0.75 [ if species = random 10 and species != 7 [ set energy energy / 2 ]]]
     if species = 15 [ ask turtles in-radius 0.75 [ if species = random 10 and species != 15 [ set energy energy / 2 ]]]
     if species = 19 [ ask turtles in-radius 0.75 [ if species = random 10 and species != 19 [ set energy energy / 2 ]]]  ]

 if number-of-species = 50 [
      if species = 0 [ ask turtles in-radius 0.75 [ if species = random 10 and species != 0 [ set energy energy * 2 ]]]
      if species = 4 [ ask turtles in-radius 0.75 [ if species = random 10 and species != 4 [ set energy energy * 2 ]]]
      if species = 12 [ ask turtles in-radius 0.75 [ if species = random 10 and species != 12 [ set energy energy * 2 ]]]
      if species = 18 [ ask turtles in-radius 0.75 [ if species = random 10 and species != 18 [ set energy energy * 2 ]]]
      if species = 22 [ ask turtles in-radius 0.75 [ if species = random 10 and species != 0 [ set energy energy * 2 ]]]
      if species = 26 [ ask turtles in-radius 0.75 [ if species = random 10 and species != 4 [ set energy energy * 2 ]]]
      if species = 32 [ ask turtles in-radius 0.75 [ if species = random 10 and species != 12 [ set energy energy * 2 ]]]
      if species = 48 [ ask turtles in-radius 0.75 [ if species = random 10 and species != 18 [ set energy energy * 2 ]]]
      if species = 43 [ ask turtles in-radius 0.75 [ if species = random 10 and species != 0 [ set energy energy * 2 ]]]
      if species = 48 [ ask turtles in-radius 0.75 [ if species = random 10 and species != 4 [ set energy energy * 2 ]]]

     if species = 3 [ ask turtles in-radius 0.75 [ if species = random 10 and species != 3 [ set energy energy / 2 ]]]
     if species = 7 [ ask turtles in-radius 0.75 [ if species = random 10 and species != 7 [ set energy energy / 2 ]]]
     if species = 15 [ ask turtles in-radius 0.75 [ if species = random 10 and species != 15 [ set energy energy / 2 ]]]
     if species = 19 [ ask turtles in-radius 0.75 [ if species = random 10 and species != 19 [ set energy energy / 2 ]]]
     if species = 25 [ ask turtles in-radius 0.75 [ if species = random 10 and species != 3 [ set energy energy / 2 ]]]
     if species = 29 [ ask turtles in-radius 0.75 [ if species = random 10 and species != 7 [ set energy energy / 2 ]]]
     if species = 33 [ ask turtles in-radius 0.75 [ if species = random 10 and species != 15 [ set energy energy / 2 ]]]
     if species = 39 [ ask turtles in-radius 0.75 [ if species = random 10 and species != 19 [ set energy energy / 2 ]]]
     if species = 45 [ ask turtles in-radius 0.75 [ if species = random 10 and species != 3 [ set energy energy / 2 ]]]
     if species = 49 [ ask turtles in-radius 0.75 [ if species = random 10 and species != 7 [ set energy energy / 2 ]]]  ]
  ] ]
end

to die-off
  ask turtles [
    if energy <= 0 [ die ]  ]
end
@#$#@#$#@
GRAPHICS-WINDOW
522
62
989
530
-1
-1
91.8
1
8
1
1
1
0
1
1
1
-2
2
-2
2
1
1
1
ticks
30.0

BUTTON
358
402
511
435
setup
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
19
117
193
150
initial-species
initial-species
10
1000
458.0
1
1
individuals
HORIZONTAL

SWITCH
161
58
324
91
show-specialization?
show-specialization?
1
1
-1000

BUTTON
359
502
510
535
go
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

SLIDER
16
153
257
186
max-agents-on-a-patch
max-agents-on-a-patch
1
250
25.0
1
1
individuals
HORIZONTAL

SLIDER
190
153
334
186
reproduction-rate
reproduction-rate
0
1.00
0.57
0.01
1
NIL
HORIZONTAL

INPUTBOX
358
438
511
498
num-runs
250.0
1
0
Number

SWITCH
331
59
494
92
show-suitability?
show-suitability?
0
1
-1000

PLOT
1220
853
1725
1198
specialists vs. generalists 
time
population
0.0
10.0
0.0
10.0
true
true
"" ""
PENS
"specialists (<0.5)" 1.0 0 -3026479 true "" "plot count turtles with [ specialization <= 0.5 ]"
"generalists (>0.5)" 1.0 0 -16777216 true "" "plot count turtles with [ specialization > 0.5 ]"

PLOT
1221
421
1726
847
species abundance 
time
population
0.0
10.0
0.0
10.0
true
true
"" ""
PENS
"sp0" 1.0 0 -2139308 true "" "plot count turtles with [ species = 0 ]"
"sp1" 1.0 0 -817084 true "" "plot count turtles with [ species = 1 ]"
"sp2" 1.0 0 -1184463 true "" "plot count turtles with [ species = 2 ]"
"sp3" 1.0 0 -13403783 true "" "plot count turtles with [ species = 3 ]"
"sp4" 1.0 0 -14454117 true "" "plot count turtles with [ species = 4 ]"
"sp5" 1.0 0 -11053225 true "" "plot count turtles with [ species = 5 ]"
"sp6" 1.0 0 -6917194 true "" "plot count turtles with [ species = 6 ]"
"sp7" 1.0 0 -4699768 true "" "plot count turtles with [ species = 7 ]"
"sp8" 1.0 0 -5825686 true "" "plot count turtles with [ species = 8 ]"
"sp9" 1.0 0 -7713188 true "" "plot count turtles with [ species = 9 ]"
"sp10" 1.0 0 -7171555 true "" "plot count turtles with [ species = 10 ]"
"sp11" 1.0 0 -6895906 true "" "plot count turtles with [ species = 11 ]"
"sp12" 1.0 0 -5643807 true "" "plot count turtles with [ species = 12 ]"
"sp13" 1.0 0 -8431303 true "" "plot count turtles with [ species = 13 ]"
"sp14" 1.0 0 -11053225 true "" "plot count turtles with [ species = 14 ]"
"sp15" 1.0 0 -5298144 true "" "plot count turtles with [ species = 15 ]"
"sp16" 1.0 0 -15390905 true "" "plot count turtles with [ species = 16 ]"
"sp17" 1.0 0 -3889007 true "" "plot count turtles with [ species = 17 ]"
"sp18" 1.0 0 -10022847 true "" "plot count turtles with [ species = 18 ]"
"sp19" 1.0 0 -8862290 true "" "plot count turtles with [ species = 19 ]"
"sp20" 1.0 0 -7500403 true "" "plot count turtles with [ species = 20 ]"
"sp21" 1.0 0 -2674135 true "" "plot count turtles with [ species = 21 ]"
"sp22" 1.0 0 -955883 true "" "plot count turtles with [ species = 22 ]"
"sp23" 1.0 0 -6459832 true "" "plot count turtles with [ species = 23 ]"
"sp24" 1.0 0 -10899396 true "" "plot count turtles with [ species = 24]"
"sp25" 1.0 0 -15582384 true "" "plot count turtles with [ species = 25 ]"
"sp26" 1.0 0 -14835848 true "" "plot count turtles with [ species = 26 ]"
"sp27" 1.0 0 -11221820 true "" "plot count turtles with [ species = 27 ]"
"sp28" 1.0 0 -13791810 true "" "plot count turtles with [ species = 28 ]"
"sp29" 1.0 0 -13345367 true "" "plot count turtles with [ species = 29 ]"
"sp30" 1.0 0 -8630108 true "" "plot count turtles with [ species = 30 ]"
"sp31" 1.0 0 -2064490 true "" "plot count turtles with [ species = 31 ]"
"sp32" 1.0 0 -5204280 true "" "plot count turtles with [ species = 32 ]"
"sp33" 1.0 0 -5207188 true "" "plot count turtles with [ species = 33 ]"
"sp34" 1.0 0 -12186836 true "" "plot count turtles with [ species = 34 ]"
"sp35" 1.0 0 -1872023 true "" "plot count turtles with [ species = 35 ]"
"sp36" 1.0 0 -14070903 true "" "plot count turtles with [ species = 36 ]"
"sp37" 1.0 0 -6995700 true "" "plot count turtles with [ species = 37 ]"
"sp38" 1.0 0 -8862290 true "" "plot count turtles with [ species = 38 ]"
"sp39" 1.0 0 -10146808 true "" "plot count turtles with [ species = 39 ]"
"sp40" 1.0 0 -10899396 true "" "plot count turtles with [ species = 40 ]"
"sp41" 1.0 0 -13360827 true "" "plot count turtles with [ species = 41 ]"
"sp42" 1.0 0 -8020277 true "" "plot count turtles with [ species = 42 ]"
"sp43" 1.0 0 -12186836 true "" "plot count turtles with [ species = 43 ]"
"sp44" 1.0 0 -612749 true "" "plot count turtles with [ species = 44 ]"
"sp45" 1.0 0 -1264960 true "" "plot count turtles with [ species = 45 ]"
"sp46" 1.0 0 -408670 true "" "plot count turtles with [ species = 46 ]"
"sp47" 1.0 0 -2139308 true "" "plot count turtles with [ species = 47 ]"
"sp48" 1.0 0 -3026479 true "" "plot count turtles with [ species = 48 ]"
"sp49" 1.0 0 -14350824 true "" "plot count turtles with [ species = 49 ]"

CHOOSER
22
47
154
92
view-by
view-by
"specialization" "species"
1

TEXTBOX
18
98
128
116
Parameters
12
0.0
1

TEXTBOX
25
31
175
49
View options 
12
0.0
1

SLIDER
16
189
185
222
initial-food-per-patch
initial-food-per-patch
22
250
250.0
1
1
NIL
HORIZONTAL

SLIDER
190
190
348
223
patch-regrowth-rate
patch-regrowth-rate
0
1
0.9
0.01
1
NIL
HORIZONTAL

CHOOSER
14
332
171
377
species-specialization
species-specialization
"HIGH" "RANDOM" "LOW" "NONE"
0

CHOOSER
179
331
331
376
interhabitat-differences
interhabitat-differences
"HIGH" "RANDOM" "LOW - GOOD" "LOW - POOR" "NONE"
0

TEXTBOX
13
292
204
310
Dimensions to control
14
94.0
1

TEXTBOX
22
11
172
29
Initial Set Up
14
84.0
1

TEXTBOX
15
312
165
330
Species specialization (SS)
12
0.0
1

TEXTBOX
177
312
343
330
Interhabitat differences (IH)
12
0.0
1

CHOOSER
15
396
168
441
species-interactions
species-interactions
"SPECIALIST-GENERALIST" "HIGH" "LOW" "SPEC-GEN-SLIDER"
1

TEXTBOX
14
380
162
398
Species interactions (SI)
12
0.0
1

TEXTBOX
182
379
332
397
Effective dispersal (ED)
12
0.0
1

CHOOSER
181
397
332
442
effective-dispersal
effective-dispersal
"HIGH" "NON-LIMITING" "RANDOM" "LOW" "NONE"
0

TEXTBOX
362
240
512
258
Carrying capacity, K
14
125.0
1

SLIDER
358
265
508
298
fraction
fraction
0.2
1
0.5
0.01
1
NIL
HORIZONTAL

MONITOR
1338
105
1440
150
total species, N
count turtles
1
1
11

MONITOR
1216
106
1320
151
K-total
max-agents-on-a-patch * 49 * fraction
1
1
11

TEXTBOX
1216
64
1308
82
Monitors
14
114.0
1

TEXTBOX
359
379
493
397
Running the model
14
54.0
1

PLOT
11
811
516
1158
Total species population
time
population
0.0
10.0
0.0
10.0
true
true
"" ""
PENS
"Total species, N" 1.0 0 -14454117 true "" "plot count turtles"
"Carrying capacity" 1.0 0 -5298144 true "" "plot max-agents-on-a-patch * 49 * fraction"

SWITCH
358
337
507
370
K-always-on?
K-always-on?
0
1
-1000

TEXTBOX
536
734
870
752
Reporting results (based on patch suitability)
14
103.0
1

MONITOR
536
792
599
837
0.0-0.1
length remove-duplicates sort [species] of turtles-on patches with [ suitability >= 0 and suitability < 0.1 ]
1
1
11

TEXTBOX
538
760
602
789
Species diversity\n
11
0.0
1

MONITOR
535
834
600
879
0.1-0.2
length remove-duplicates sort [species] of turtles-on patches with [ suitability >= 0.1 and suitability < 0.2 ]
1
1
11

MONITOR
535
875
600
920
0.2-0.3
length remove-duplicates sort [species] of turtles-on patches with [ suitability >= 0.2 and suitability < 0.3 ]
1
1
11

MONITOR
536
920
600
965
0.3-0.4
length remove-duplicates sort [species] of turtles-on patches with [ suitability >= 0.3 and suitability < 0.4 ]
1
1
11

MONITOR
536
964
601
1009
0.4-0.5
length remove-duplicates sort [species] of turtles-on patches with [ suitability >= 0.4 and suitability < 0.5 ]
1
1
11

MONITOR
535
1008
600
1053
0.5-0.6
length remove-duplicates sort [species] of turtles-on patches with [ suitability >= 0.5 and suitability < 0.6 ]
17
1
11

MONITOR
535
1052
601
1097
0.6-0.7
length remove-duplicates sort [species] of turtles-on patches with [ suitability >= 0.6 and suitability < 0.7 ]
1
1
11

MONITOR
534
1096
601
1141
0.7-0.8
length remove-duplicates sort [species] of turtles-on patches with [ suitability >= 0.7 and suitability < 0.8 ]
1
1
11

MONITOR
534
1142
601
1187
0.8-0.9
length remove-duplicates sort [species] of turtles-on patches with [ suitability >= 0.8 and suitability < 0.9 ]
1
1
11

MONITOR
534
1184
600
1229
0.9-1.0
length remove-duplicates sort [species] of turtles-on patches with [ suitability >= 0.9 and suitability < 1 ]
1
1
11

SLIDER
352
190
504
223
suitability-constant
suitability-constant
0.1
0.8
0.18
0.01
1
NIL
HORIZONTAL

SLIDER
357
301
507
334
specialist-K
specialist-K
0.2
0.8
0.32
0.01
1
NIL
HORIZONTAL

MONITOR
1216
156
1320
201
specialist K
( max-agents-on-a-patch * 49 * fraction ) * specialist-k
1
1
11

MONITOR
1216
205
1321
250
generalist K
( max-agents-on-a-patch * 49 * fraction ) * ( 1 - specialist-K )
1
1
11

MONITOR
1338
155
1439
200
# of specialists
count turtles with [ specialist-or-generalist = \"specialist\" ]
1
1
11

MONITOR
1338
205
1439
250
# of generalists 
count turtles with [ specialist-or-generalist = \"generalist\" ]
1
1
11

TEXTBOX
1452
77
1737
96
Number of species remaining after x years
14
94.0
1

MONITOR
1453
103
1587
148
number of species, S
length remove-duplicates sort [species] of turtles
1
1
11

MONITOR
1592
104
1733
149
years
ticks
1
1
11

MONITOR
1453
152
1587
197
# of specialist species
length remove-duplicates sort [species] of turtles with [ specialist-or-generalist = \"specialist\" ]
1
1
11

MONITOR
1592
153
1733
198
# of generalist species
length remove-duplicates sort [species] of turtles with [ specialist-or-generalist = \"generalist\" ]
1
1
11

CHOOSER
320
103
503
148
number-of-species
number-of-species
10 20 50
2

TEXTBOX
1271
257
1421
275
Suitability Ranges
14
74.0
1

OUTPUT
1268
283
1557
408
13

TEXTBOX
599
760
678
790
Number of patches 
11
0.0
1

MONITOR
598
793
683
838
0-0.1
count patches with [ suitability >= 0 and suitability < 0.1 ]
1
1
11

MONITOR
599
835
683
880
0.1-0.2
count patches with [ suitability >= 0.1 and suitability < 0.2 ]
1
1
11

MONITOR
598
877
684
922
0.2-0.3
count patches with [ suitability >= 0.2 and suitability < 0.3 ]
17
1
11

MONITOR
599
923
683
968
0.3-0.4
count patches with [ suitability >= 0.3 and suitability < 0.4 ]
17
1
11

MONITOR
600
967
682
1012
0.4-0.5
count patches with [ suitability >= 0.4 and suitability < 0.5 ]
17
1
11

MONITOR
600
1010
683
1055
0.5-0.6
count patches with [ suitability >= 0.5 and suitability < 0.6 ]
17
1
11

MONITOR
599
1051
682
1096
0.6-0.7
count patches with [ suitability >= 0.6 and suitability < 0.7 ]
17
1
11

MONITOR
598
1095
682
1140
0.7-0.8
count patches with [ suitability >= 0.7 and suitability < 0.8 ]
17
1
11

MONITOR
598
1139
683
1184
0.8-0.9
count patches with [ suitability >= 0.8 and suitability < 0.9 ]
17
1
11

MONITOR
599
1182
684
1227
0.9-1.0
count patches with [ suitability >= 0.9 and suitability < 1 ]
17
1
11

TEXTBOX
691
757
770
789
# of empty patches
11
0.0
1

MONITOR
684
790
766
835
0-0.1
count patches with [ suitability >= 0 and suitability < 0.1 and count turtles-on self  = 0 ]
1
1
11

MONITOR
684
833
767
878
0.1-0.2
count patches with [ suitability >= 0.1 and suitability < 0.2 and count turtles-on self  = 0 ]
1
1
11

MONITOR
684
875
767
920
0.2-0.3
count patches with [ suitability >= 0.2 and suitability < 0.3 and count turtles-on self  = 0 ]
1
1
11

MONITOR
684
921
767
966
0.3-0.4
count patches with [ suitability >= 0.3 and suitability < 0.4 and count turtles-on self  = 0 ]
1
1
11

MONITOR
684
965
767
1010
0.4-0.5
count patches with [ suitability >= 0.3 and suitability < 0.5 and count turtles-on self  = 0 ]
1
1
11

MONITOR
684
1010
767
1055
0.5-0.6
count patches with [ suitability >= 0.5 and suitability < 0.6 and count turtles-on self  = 0 ]
1
1
11

MONITOR
685
1052
768
1097
0.6-0.7
count patches with [ suitability >= 0.6 and suitability < 0.7 and count turtles-on self  = 0 ]
1
1
11

MONITOR
685
1094
769
1139
0.7-0.8
count patches with [ suitability >= 0.9 and suitability < 0.8 and count turtles-on self  = 0 ]
1
1
11

MONITOR
684
1138
768
1183
0.8-0.9
count patches with [ suitability >= 0.8 and suitability < 0.9 and count turtles-on self  = 0 ]
1
1
11

MONITOR
684
1181
769
1226
0.9-1.0
count patches with [ suitability >= 0.9 and suitability < 1 and count turtles-on self  = 0 ]
1
1
11

TEXTBOX
769
760
852
788
# of species (specialists)
11
0.0
1

MONITOR
767
791
848
836
0.0-0.1
length remove-duplicates sort [species] of turtles with [ specialization <= 0.5 and suitability >= 0 and suitability < 0.1 ]
17
1
11

MONITOR
766
834
850
879
0.1-0.2
length remove-duplicates sort [species] of turtles with [ specialization <= 0.5 and suitability >= 0.1 and suitability < 0.2 ]
17
1
11

MONITOR
766
876
849
921
0.2-0.3
length remove-duplicates sort [species] of turtles with [ specialization <= 0.5 and suitability >= 0.2 and suitability < 0.3 ]
17
1
11

MONITOR
766
922
849
967
0.3-0.4
length remove-duplicates sort [species] of turtles with [ specialization <= 0.5 and suitability >= 0.3 and suitability < 0.4 ]
17
1
11

TEXTBOX
843
757
925
786
# of species (generalists)
11
0.0
1

MONITOR
843
789
925
834
0-0.1
length remove-duplicates sort [species] of turtles with [ specialization > 0.5 and suitability >= 0 and suitability < 0.1 ]
17
1
11

MONITOR
766
967
849
1012
0.4-0.5
length remove-duplicates sort [species] of turtles with [ specialization <= 0.5 and suitability >= 0.4 and suitability < 0.5 ]
17
1
11

MONITOR
766
1011
849
1056
0.5-0.6
length remove-duplicates sort [species] of turtles with [ specialization <= 0.5 and suitability > 0.5 and suitability <= 0.6 ]
17
1
11

MONITOR
768
1054
850
1099
0.6-0.7
length remove-duplicates sort [species] of turtles with [ specialization <= 0.5 and suitability > 0.6 and suitability <= 0.7 ]
17
1
11

MONITOR
768
1096
850
1141
0.7-0.8
length remove-duplicates sort [species] of turtles with [ specialization <= 0.5 and suitability > 0.7 and suitability <= 0.8 ]
17
1
11

MONITOR
766
1139
850
1184
0.8-0.9
length remove-duplicates sort [species] of turtles with [ specialization <= 0.5 and suitability > 0.8 and suitability <= 0.9 ]
17
1
11

MONITOR
766
1182
849
1227
0.9-1.0
length remove-duplicates sort [species] of turtles with [ specialization <= 0.5 and suitability > 0.9 and suitability <= 1 ]
17
1
11

MONITOR
844
833
926
878
0.1-0.2
length remove-duplicates sort [species] of turtles with [ specialization > 0.5 and suitability >= 0.1 and suitability < 0.2 ]
17
1
11

MONITOR
844
875
926
920
0.2-0.3
length remove-duplicates sort [species] of turtles with [ specialization > 0.5 and suitability >= 0.2 and suitability < 0.3 ]
17
1
11

MONITOR
845
922
926
967
0.3-0.4
length remove-duplicates sort [species] of turtles with [ specialization > 0.5 and suitability >= 0.3 and suitability < 0.4 ]
17
1
11

MONITOR
845
967
926
1012
0.4-0.5
length remove-duplicates sort [species] of turtles with [ specialization > 0.5 and suitability >= 0.4 and suitability < 0.5 ]
17
1
11

MONITOR
845
1010
926
1055
0.5-0.6
length remove-duplicates sort [species] of turtles with [ specialization > 0.5 and suitability > 0.5 and suitability <= 0.6 ]
17
1
11

MONITOR
846
1051
927
1096
0.6-0.7
length remove-duplicates sort [species] of turtles with [ specialization > 0.5 and suitability > 0.6 and suitability <= 0.7 ]
17
1
11

MONITOR
846
1095
927
1140
0.7-0.8
length remove-duplicates sort [species] of turtles with [ specialization > 0.5 and suitability > 0.7 and suitability <= 0.8 ]
17
1
11

MONITOR
846
1140
928
1185
0.8-0.9
length remove-duplicates sort [species] of turtles with [ specialization > 0.5 and suitability > 0.8 and suitability <= 0.9 ]
17
1
11

MONITOR
846
1183
928
1228
0.9-1.0
length remove-duplicates sort [species] of turtles with [ specialization > 0.5 and suitability > 0.9 and suitability <= 1 ]
17
1
11

MONITOR
1566
363
1691
408
mean suitability
mean [ suitability ] of patches
2
1
11

SWITCH
339
153
503
186
boost-reproduction?
boost-reproduction?
0
1
-1000

TEXTBOX
1215
85
1346
103
Carrying capacities
12
0.0
1

TEXTBOX
1340
87
1407
105
Totals
12
0.0
1

SLIDER
15
245
166
278
%-generalists
%-generalists
0.1
0.5
0.19
0.01
1
%
HORIZONTAL

TEXTBOX
18
228
168
246
Initial % of generalists
12
0.0
1

MONITOR
171
235
348
280
% generalists in the population
( count turtles with [ specialist-or-generalist = \"generalist\" ] / count turtles ) * 100
0
1
11

TEXTBOX
10
731
160
749
Adding in species
14
83.0
1

SLIDER
10
766
146
799
specialists
specialists
0
100
47.0
1
1
NIL
HORIZONTAL

SLIDER
251
766
387
799
generalists
generalists
0
100
50.0
1
1
NIL
HORIZONTAL

TEXTBOX
11
749
356
767
Select how many agents to add, and then press the add buttons
11
0.0
1

BUTTON
150
766
247
799
add specialists
add-specialists
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
390
766
513
799
add generalists
add-generalists
NIL
1
T
OBSERVER
NIL
NIL
NIL
NIL
1

TEXTBOX
11
586
248
604
For specialist-generalist interactions
13
94.0
1

TEXTBOX
11
604
211
622
Specialist-specialist SI reward 
11
0.0
1

SLIDER
10
621
270
654
ss-reward
ss-reward
-10
10
0.0
1
1
energy
HORIZONTAL

TEXTBOX
10
662
270
680
Generalist meeting specialists (reward/penalty)
11
0.0
1

TEXTBOX
278
601
470
619
Generalist-generalist SI reward
11
0.0
1

SLIDER
274
621
514
654
gg-reward
gg-reward
-10
10
-10.0
1
1
energy
HORIZONTAL

SLIDER
8
682
269
715
gs-reward
gs-reward
-10
10
-10.0
1
1
energy
HORIZONTAL

MONITOR
1565
312
1691
357
mean specialization
mean [ specialization ] of turtles
3
1
11

TEXTBOX
16
447
166
465
Gradient of interactions 
13
0.0
1

SLIDER
58
478
305
511
SI-specialists
SI-specialists
-1
1
-1.0
1
1
NIL
HORIZONTAL

TEXTBOX
30
510
90
540
meeting specialists
11
0.0
1

TEXTBOX
281
511
377
542
meeting generalists
11
0.0
1

SLIDER
276
684
515
717
sg-reward
sg-reward
-10
10
10.0
1
1
energy
HORIZONTAL

TEXTBOX
279
661
531
679
Specialist meeting generalists (reward/penalty)
11
0.0
1

TEXTBOX
167
518
195
536
none
11
0.0
1

SLIDER
58
541
307
574
SI-generalists
SI-generalists
-1
1
-1.0
1
1
NIL
HORIZONTAL

TEXTBOX
923
754
1046
790
mean abundance of specialists/patch
11
93.0
1

TEXTBOX
1028
753
1147
782
mean N \ngeneralist/patch
11
52.0
1

TEXTBOX
1130
750
1217
782
mean energy (food)/patch
11
14.0
1

MONITOR
922
788
1020
833
0.0-0.1
( count turtles with [specialist-or-generalist = \"specialist\" and suitability >= 0 and suitability < 0.1 ] ) / (count patches with [ suitability >= 0 and suitability < 0.1 ])
1
1
11

MONITOR
922
831
1021
876
0.1-0.2
(count turtles with [specialist-or-generalist = \"specialist\" and suitability >= 0.1 and suitability < 0.2 ] ) / (count patches with [ suitability >= 0.1 and suitability < 0.2 ])
1
1
11

MONITOR
922
875
1023
920
0.2-0.3
( count turtles with [specialist-or-generalist = \"specialist\" and suitability >= 0.2 and suitability < 0.3 ] ) / (count patches with [ suitability >= 0.2 and suitability < 0.3 ])
1
1
11

MONITOR
922
922
1024
967
0.3-0.4
( count turtles with [specialist-or-generalist = \"specialist\" and suitability >= 0.3 and suitability < 0.4 ] ) / (count patches with [ suitability >= 0.3 and suitability < 0.4 ])
1
1
11

MONITOR
925
967
1023
1012
0.4-0.5
( count turtles with [specialist-or-generalist = \"specialist\" and suitability >= 0.4 and suitability < 0.5 ] ) / (count patches with [ suitability >= 0.4 and suitability < 0.5 ])
1
1
11

MONITOR
925
1010
1022
1055
0.5-0.6
( count turtles with [specialist-or-generalist = \"specialist\" and suitability >= 0.5 and suitability < 0.6 ] ) / (count patches with [ suitability >= 0.5 and suitability < 0.6 ])
1
1
11

MONITOR
926
1051
1022
1096
0.6-0.7
( count turtles with [specialist-or-generalist = \"specialist\" and suitability >= 0.6 and suitability < 0.7 ] ) / (count patches with [ suitability >= 0.6 and suitability < 0.7 ])
1
1
11

MONITOR
926
1094
1022
1139
0.7-0.8
( count turtles with [specialist-or-generalist = \"specialist\" and suitability >= 0.7 and suitability < 0.8 ] ) / (count patches with [ suitability >= 0.7 and suitability < 0.8 ])
1
1
11

MONITOR
926
1141
1022
1186
0.8-0.9
( count turtles with [specialist-or-generalist = \"specialist\" and suitability >= 0.8 and suitability < 0.9 ] ) / (count patches with [ suitability >= 0.8 and suitability < 0.9 ])
1
1
11

MONITOR
927
1183
1023
1228
0.9-1.0
( count turtles with [specialist-or-generalist = \"specialist\" and suitability >= 0.9 and suitability < 1 ] ) / (count patches with [ suitability >= 0.9 and suitability < 1 ])
1
1
11

MONITOR
1030
788
1089
833
0.0-0.1
( count turtles with [specialist-or-generalist = \"generalist\" and suitability >= 0 and suitability < 0.1 ] ) / (count patches with [ suitability >= 0 and suitability < 0.1 ])
1
1
11

MONITOR
1031
830
1088
875
0.1-0.2
( count turtles with [specialist-or-generalist = \"generalist\" and suitability >= 0.1 and suitability < 0.2 ] ) / (count patches with [ suitability >= 0.1 and suitability < 0.2 ])
1
1
11

MONITOR
1033
874
1088
919
0.2-0.3
( count turtles with [specialist-or-generalist = \"generalist\" and suitability >= 0.2 and suitability < 0.3 ] ) / (count patches with [ suitability >= 0.2 and suitability < 0.3 ])
1
1
11

MONITOR
1030
920
1088
965
0.3-0.4
( count turtles with [specialist-or-generalist = \"generalist\" and suitability >= 0.3 and suitability < 0.4 ] ) / (count patches with [ suitability >= 0.3 and suitability < 0.4 ])
1
1
11

MONITOR
1030
965
1088
1010
0.4-0.5
( count turtles with [specialist-or-generalist = \"generalist\" and suitability >= 0.4 and suitability < 0.5 ] ) / (count patches with [ suitability >= 0.4 and suitability < 0.5 ])
1
1
11

MONITOR
1030
1007
1090
1052
0.5-0.6
( count turtles with [specialist-or-generalist = \"generalist\" and suitability >= 0.5 and suitability < 0.6 ] ) / (count patches with [ suitability >= 0.5 and suitability < 0.6 ])
1
1
11

MONITOR
1030
1047
1090
1092
0.6-0.7
( count turtles with [specialist-or-generalist = \"generalist\" and suitability >= 0.6 and suitability < 0.7 ] ) / (count patches with [ suitability >= 0.6 and suitability < 0.7 ])
1
1
11

MONITOR
1029
1090
1090
1135
0.7-0.8
( count turtles with [specialist-or-generalist = \"generalist\" and suitability >= 0.7 and suitability < 0.8 ] ) / (count patches with [ suitability >= 0.7 and suitability < 0.8 ])
1
1
11

MONITOR
1030
1137
1091
1182
0.8-0.9
( count turtles with [specialist-or-generalist = \"generalist\" and suitability >= 0.8 and suitability < 0.9 ] ) / (count patches with [ suitability >= 0.8 and suitability < 0.9 ])
1
1
11

MONITOR
1030
1182
1091
1227
0.9-1.0
( count turtles with [specialist-or-generalist = \"generalist\" and suitability >= 0.9 and suitability < 1 ] ) / (count patches with [ suitability >= 0.9 and suitability < 1 ])
1
1
11

MONITOR
1132
785
1191
830
0.0-0.1
( mean [food] of patches with [ suitability >= 0 and suitability < 0.1 ] )
1
1
11

MONITOR
1132
831
1192
876
0.1-0.2
( mean [food] of patches with [ suitability >= 0.1 and suitability < 0.2 ] )
1
1
11

MONITOR
1132
877
1192
922
0.2-0.3
( mean [food] of patches with [ suitability >= 0.2 and suitability < 0.3 ] )
1
1
11

MONITOR
1132
925
1192
970
0.3-0.4
( mean [food] of patches with [ suitability >= 0.3 and suitability < 0.4 ] )
1
1
11

MONITOR
1132
971
1193
1016
0.4-0.5
( mean [food] of patches with [ suitability >= 0.4 and suitability < 0.5 ] )
1
1
11

MONITOR
1132
1013
1194
1058
0.5-0.6
( mean [food] of patches with [ suitability >= 0.5 and suitability < 0.6 ] )
1
1
11

MONITOR
1131
1054
1195
1099
0.6-0.7
( mean [food] of patches with [ suitability >= 0.6 and suitability < 0.7 ] )
1
1
11

MONITOR
1131
1097
1196
1142
0.7-0.8
( mean [food] of patches with [ suitability >= 0.7 and suitability < 0.8 ] )
1
1
11

MONITOR
1132
1142
1197
1187
0.8-0.9
( mean [food] of patches with [ suitability >= 0.8 and suitability < 0.9 ] )
1
1
11

MONITOR
1132
1184
1198
1229
0.9-1.0
( mean [food] of patches with [ suitability >= 0.9 and suitability < 1 ] )
1
1
11

@#$#@#$#@
## WHAT IS IT?

An agent-based model involving a landscape composed of 81 habitat patches and 10-50 species of agents dispersed across the habitats.

Based on differences in these four dimensions: patch suitability, species specialization, inter-habitat differences and species interactions, and governed by various rules and procedures, this will determine whether agents can disperse, gain or lose energy, reproduce or die. 

We can let various numbers of species and agents occupy the landscape and test various combinations of settings to see the overall species diversity in the landscape and the number of specialists vs. generalists.


## HOW IT WORKS

Upon set up, agents are assigned with a species identity, suitability range (range of suitability values of patches that they can occupy) and specialization value.

After setting up the model with values for parameters and settings that the user can choose and control, the agents will move throughout the landscape depending on the effective dispersal (ED) settings and arrive at patches in the landscape. Agents are randomly assigned suitability ranges (the range of suitability of patches that they can land on and gain energy from), and depending on the patch which they land on with each time-step, agents may gain or lose energy. 

With sufficient energy, agents can also reproduce at the set reproduction rate, or continue to move if called upon to disperse. Agents of different species can also interact with one another, with varying consequences (energy gained/lost).

## HOW TO USE IT

You can select and change the initial values/options for different settings and parameters of the model (e.g. view options, initial population, reproduction rate, etc.), as well as control the settings of the 4 model dimensions: species specialization (SS), species interactions (SI), interhabitat differences (IH) and effective dispersal (ED). The values/settings for carrying capacity can also be varied, and the proportion of the carrying capacity allocated to specialists and generalists can also be controlled. 

Once the model is set up, the user can run the model indefinitely or set a number of runs to run the model for. Many values can then be assessed at the end of each model run, including the total population, N, number of species remaining (species diversity, S), number of patches of each suitability category, and many others, to investigate the dynamics of a meta-community model.

## EXTENDING THE MODEL

- More specific interactions can be implemented (instead of just random ones)
- There can be more realistic behaviors that are more representative of real life ecology (e.g. death rate, scavenging for better patches in the habitat instead of just random movements, etc.)

## CREDITS AND REFERENCES

By Joyce Yan 
July 2020
@#$#@#$#@
default
true
0
Polygon -7500403 true true 150 5 40 250 150 205 260 250

airplane
true
0
Polygon -7500403 true true 150 0 135 15 120 60 120 105 15 165 15 195 120 180 135 240 105 270 120 285 150 270 180 285 210 270 165 240 180 180 285 195 285 165 180 105 180 60 165 15

ant
true
0
Polygon -7500403 true true 136 61 129 46 144 30 119 45 124 60 114 82 97 37 132 10 93 36 111 84 127 105 172 105 189 84 208 35 171 11 202 35 204 37 186 82 177 60 180 44 159 32 170 44 165 60
Polygon -7500403 true true 150 95 135 103 139 117 125 149 137 180 135 196 150 204 166 195 161 180 174 150 158 116 164 102
Polygon -7500403 true true 149 186 128 197 114 232 134 270 149 282 166 270 185 232 171 195 149 186
Polygon -7500403 true true 225 66 230 107 159 122 161 127 234 111 236 106
Polygon -7500403 true true 78 58 99 116 139 123 137 128 95 119
Polygon -7500403 true true 48 103 90 147 129 147 130 151 86 151
Polygon -7500403 true true 65 224 92 171 134 160 135 164 95 175
Polygon -7500403 true true 235 222 210 170 163 162 161 166 208 174
Polygon -7500403 true true 249 107 211 147 168 147 168 150 213 150

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
NetLogo 6.4.0
@#$#@#$#@
@#$#@#$#@
@#$#@#$#@
<experiments>
  <experiment name="Experiment 1 - trial run (sort by species on  patch)" repetitions="10" runMetricsEveryStep="false">
    <setup>setup</setup>
    <go>go</go>
    <timeLimit steps="50"/>
    <metric>count turtles-on patches with [ suitability &gt;= 0 and suitability &lt; 0.2 ]</metric>
    <metric>sort [ species ] of turtles-on patches with [ suitability &gt;= 0 and suitability &lt; 0.2 ]</metric>
    <metric>count turtles-on patches with [ suitability &gt;= 0.2 and suitability &lt; 0.4 ]</metric>
    <metric>sort [ species ] of turtles-on patches with [ suitability &gt;= 0.2 and suitability &lt; 0.4 ]</metric>
    <metric>count turtles-on patches with [ suitability &gt;= 0.4 and suitability &lt; 0.6 ]</metric>
    <metric>sort [ species ] of turtles-on patches with [ suitability &gt;= 0.4 and suitability &lt; 0.6 ]</metric>
    <metric>count turtles-on patches with [ suitability &gt;= 0.6 and suitability &lt; 0.8 ]</metric>
    <metric>sort [ species ] of turtles-on patches with [ suitability &gt;= 0.6 and suitability &lt; 0.8 ]</metric>
    <metric>count turtles-on patches with [ suitability &gt;= 0.8 and suitability &lt; 1.0 ]</metric>
    <metric>sort [ species ] of turtles-on patches with [ suitability &gt;= 0.8 and suitability &lt; 1.0 ]</metric>
    <enumeratedValueSet variable="species-interactions?">
      <value value="true"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="good-patch-for-specialist">
      <value value="0.2"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="suitability-on?">
      <value value="true"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="initial-food-per-patch">
      <value value="100"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="patch-regrowth-rate">
      <value value="0.29"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="view-by">
      <value value="&quot;species&quot;"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="num-runs">
      <value value="50"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="good-patch-requirement">
      <value value="1.6"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="total-species">
      <value value="100"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="specialization-on?">
      <value value="true"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="show-specialization?">
      <value value="false"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="extinction-threshold">
      <value value="0.4"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="dispersal-properties?">
      <value value="true"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="show-suitability?">
      <value value="true"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="reproduction-rate">
      <value value="0.5"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="max-age">
      <value value="100"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="survival-threshold">
      <value value="1.4"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="specialization-gradient">
      <value value="&quot;in between&quot;"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="habitat-gradient">
      <value value="&quot;in between&quot;"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="max-agents-on-a-patch">
      <value value="17"/>
    </enumeratedValueSet>
  </experiment>
  <experiment name="Experiment 2 - # of diff. species in each patch type" repetitions="10" runMetricsEveryStep="false">
    <setup>setup</setup>
    <go>go</go>
    <timeLimit steps="100"/>
    <metric>length remove-duplicates sort [ species ] of turtles-on patches with [ suitability &gt;= 0 and suitability &lt; 0.1]</metric>
    <metric>length remove-duplicates sort [ species ] of turtles-on patches with [ suitability &gt;= 0.1 and suitability &lt; 0.2]</metric>
    <metric>length remove-duplicates sort [ species ] of turtles-on patches with [ suitability &gt;= 0.2 and suitability &lt; 0.3]</metric>
    <metric>length remove-duplicates sort [ species ] of turtles-on patches with [ suitability &gt;= 0.3 and suitability &lt; 0.4]</metric>
    <metric>length remove-duplicates sort [ species ] of turtles-on patches with [ suitability &gt;= 0.4 and suitability &lt; 0.5]</metric>
    <metric>length remove-duplicates sort [ species ] of turtles-on patches with [ suitability &gt;= 0.5 and suitability &lt; 0.6]</metric>
    <metric>length remove-duplicates sort [ species ] of turtles-on patches with [ suitability &gt;= 0.6 and suitability &lt; 0.7]</metric>
    <metric>length remove-duplicates sort [ species ] of turtles-on patches with [ suitability &gt;= 0.7 and suitability &lt; 0.8]</metric>
    <metric>length remove-duplicates sort [ species ] of turtles-on patches with [ suitability &gt;= 0.8 and suitability &lt; 0.9]</metric>
    <metric>length remove-duplicates sort [ species ] of turtles-on patches with [ suitability &gt;= 0.9 and suitability &lt; 1.0]</metric>
    <enumeratedValueSet variable="species-interactions?">
      <value value="true"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="positive-to-negative-interactions">
      <value value="2"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="good-patch-for-specialist">
      <value value="0.2"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="suitability-on?">
      <value value="true"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="initial-food-per-patch">
      <value value="100"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="patch-regrowth-rate">
      <value value="0.59"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="view-by">
      <value value="&quot;specialization&quot;"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="num-runs">
      <value value="100"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="good-patch-requirement">
      <value value="1.6"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="total-species">
      <value value="100"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="specialization-on?">
      <value value="true"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="show-specialization?">
      <value value="false"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="penalty">
      <value value="6"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="extinction-threshold">
      <value value="0.4"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="show-suitability?">
      <value value="true"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="reward">
      <value value="1.5"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="reproduction-rate">
      <value value="0.28"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="dispersal-properties?">
      <value value="true"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="max-age">
      <value value="100"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="survival-threshold">
      <value value="1.4"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="specialization-gradient">
      <value value="&quot;in between&quot;"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="habitat-gradient">
      <value value="&quot;in between&quot;"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="max-agents-on-a-patch">
      <value value="10"/>
    </enumeratedValueSet>
  </experiment>
  <experiment name="Experiment 3 - # of patches a species occupies" repetitions="10" runMetricsEveryStep="false">
    <setup>setup</setup>
    <go>go</go>
    <timeLimit steps="100"/>
    <metric>count patch-set [ patch-here ] of turtles with [ species = 0 ]</metric>
    <metric>count patch-set [ patch-here ] of turtles with [ species = 1 ]</metric>
    <metric>count patch-set [ patch-here ] of turtles with [ species = 2 ]</metric>
    <metric>count patch-set [ patch-here ] of turtles with [ species = 3 ]</metric>
    <metric>count patch-set [ patch-here ] of turtles with [ species = 4 ]</metric>
    <metric>count patch-set [ patch-here ] of turtles with [ species = 5 ]</metric>
    <metric>count patch-set [ patch-here ] of turtles with [ species = 6 ]</metric>
    <metric>count patch-set [ patch-here ] of turtles with [ species = 7 ]</metric>
    <metric>count patch-set [ patch-here ] of turtles with [ species = 8 ]</metric>
    <metric>count patch-set [ patch-here ] of turtles with [ species = 9 ]</metric>
    <enumeratedValueSet variable="species-interactions?">
      <value value="true"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="positive-to-negative-interactions">
      <value value="1"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="good-patch-for-specialist">
      <value value="0.2"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="suitability-on?">
      <value value="true"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="initial-food-per-patch">
      <value value="100"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="patch-regrowth-rate">
      <value value="0.6"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="view-by">
      <value value="&quot;species&quot;"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="num-runs">
      <value value="100"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="good-patch-requirement">
      <value value="1.65"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="total-species">
      <value value="300"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="specialization-on?">
      <value value="true"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="show-specialization?">
      <value value="false"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="penalty">
      <value value="6"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="extinction-threshold">
      <value value="0.4"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="dispersal-properties?">
      <value value="true"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="show-suitability?">
      <value value="true"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="reward">
      <value value="1.5"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="reproduction-rate">
      <value value="0.28"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="max-age">
      <value value="100"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="survival-threshold">
      <value value="1.4"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="specialization-gradient">
      <value value="&quot;in between&quot;"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="habitat-gradient">
      <value value="&quot;in between&quot;"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="max-agents-on-a-patch">
      <value value="15"/>
    </enumeratedValueSet>
  </experiment>
  <experiment name="Data collection 1 - CONNECTIVITY" repetitions="10" runMetricsEveryStep="false">
    <setup>setup</setup>
    <go>go</go>
    <metric>count turtles</metric>
    <metric>length remove-duplicates sort [species] of turtles</metric>
    <metric>remove-duplicates sort [species] of turtles</metric>
    <metric>count turtles with [ specialist-or-generalist = "specialist" ]</metric>
    <metric>length remove-duplicates sort [species] of turtles with [ specialist-or-generalist = "specialist" ]</metric>
    <metric>remove-duplicates sort [species] of turtles with [ specialist-or-generalist = "specialist" ]</metric>
    <metric>count turtles with [ specialist-or-generalist = "generalist" ]</metric>
    <metric>length remove-duplicates sort [species] of turtles with [ specialist-or-generalist = "generalist" ]</metric>
    <metric>remove-duplicates sort [species] of turtles with [ specialist-or-generalist = "specialist" ]</metric>
    <metric>count patches with [pcolor = green + 2]</metric>
    <metric>count patches with [pcolor = green + 2 and any? neighbors with [pcolor = green + 2]]</metric>
    <metric>count turtles-on patches with [pcolor = green + 2]</metric>
    <metric>count patches with [pcolor = green + 1]</metric>
    <metric>count patches with [pcolor = green + 1 and any? neighbors with [pcolor = green + 1]]</metric>
    <metric>count turtles-on patches with [pcolor = green + 1]</metric>
    <metric>count patches with [pcolor = green]</metric>
    <metric>count patches with [pcolor = green and any? neighbors with [pcolor = green]]</metric>
    <metric>count turtles-on patches with [pcolor = green]</metric>
    <metric>count patches with [pcolor = green - 1]</metric>
    <metric>count patches with [pcolor = green - 1 and any? neighbors with [pcolor = green - 1]]</metric>
    <metric>count turtles-on patches with [pcolor = green - 1]</metric>
    <metric>count patches with [pcolor = green - 2]</metric>
    <metric>count patches with [pcolor = green - 2 and any? neighbors with [pcolor = green - 2]]</metric>
    <metric>count turtles-on patches with [pcolor = green - 2]</metric>
    <enumeratedValueSet variable="initial-species">
      <value value="458"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="species-specialization">
      <value value="&quot;HIGH&quot;"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="species-interactions">
      <value value="&quot;HIGH&quot;"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="number-of-species">
      <value value="10"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="K-always-on?">
      <value value="true"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="interhabitat-differences">
      <value value="&quot;HIGH&quot;"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="initial-food-per-patch">
      <value value="250"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="%-generalists">
      <value value="0.19"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="view-by">
      <value value="&quot;specialization&quot;"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="fraction">
      <value value="0.57"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="num-runs">
      <value value="500"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="patch-regrowth-rate">
      <value value="0.64"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="suitability-constant">
      <value value="0.18"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="specialists">
      <value value="47"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="generalists">
      <value value="50"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="show-specialization?">
      <value value="false"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="effective-dispersal">
      <value value="&quot;HIGH&quot;"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="show-suitability?">
      <value value="true"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="reproduction-rate">
      <value value="0.57"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="boost-reproduction?">
      <value value="false"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="specialist-K">
      <value value="0.5"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="max-agents-on-a-patch">
      <value value="22"/>
    </enumeratedValueSet>
  </experiment>
  <experiment name="Data collection 2 - testing" repetitions="1" runMetricsEveryStep="false">
    <setup>setup</setup>
    <go>go</go>
    <metric>length remove-duplicates sort [ species ] of turtles-on patches with [ suitability &gt;= 0 and suitability &lt; 0.1]</metric>
    <metric>sort [ species ] of turtles-on patches with [ suitability &gt;= 0 and suitability &lt; 0.1]</metric>
    <metric>count patches with [ suitability &gt;= 0 and suitability &lt; 0.1 ]</metric>
    <metric>count patches with [ suitability &gt;= 0 and suitability &lt; 0.1 and count turtles-on self = 0 ]</metric>
    <metric>length remove-duplicates sort [ species ] of turtles-on patches with [ suitability &gt;= 0.1 and suitability &lt; 0.2]</metric>
    <metric>sort [ species ] of turtles-on patches with [ suitability &gt;= 0.1 and suitability &lt; 0.2]</metric>
    <metric>count patches with [ suitability &gt;= 0.1 and suitability &lt; 0.2 ]</metric>
    <metric>count patches with [ suitability &gt;= 0.1 and suitability &lt; 0.2 and count turtles-on self = 0 ]</metric>
    <metric>length remove-duplicates sort [ species ] of turtles-on patches with [ suitability &gt;= 0.2 and suitability &lt; 0.3]</metric>
    <metric>sort [ species ] of turtles-on patches with [ suitability &gt;= 0.2 and suitability &lt; 0.3]</metric>
    <metric>count patches with [ suitability &gt;= 0.2 and suitability &lt; 0.3 ]</metric>
    <metric>count patches with [ suitability &gt;= 0.2 and suitability &lt; 0.3 and count turtles-on self = 0 ]</metric>
    <metric>length remove-duplicates sort [ species ] of turtles-on patches with [ suitability &gt;= 0.3 and suitability &lt; 0.4]</metric>
    <metric>sort [ species ] of turtles-on patches with [ suitability &gt;= 0.3 and suitability &lt; 0.4 ]</metric>
    <metric>count patches with [ suitability &gt;= 0.3 and suitability &lt; 0.4 ]</metric>
    <metric>count patches with [ suitability &gt;= 0.3 and suitability &lt; 0.4 and count turtles-on self = 0 ]</metric>
    <metric>length remove-duplicates sort [ species ] of turtles-on patches with [ suitability &gt;= 0.4 and suitability &lt; 0.5 ]</metric>
    <metric>sort [ species ] of turtles-on patches with [ suitability &gt;= 0.4 and suitability &lt; 0.5 ]</metric>
    <metric>count patches with [ suitability &gt;= 0.4 and suitability &lt; 0.5 ]</metric>
    <metric>count patches with [ suitability &gt;= 0.4 and suitability &lt; 0.5 and count turtles-on self = 0 ]</metric>
    <metric>length remove-duplicates sort [ species ] of turtles-on patches with [ suitability &gt;= 0.5 and suitability &lt; 0.6]</metric>
    <metric>sort [ species ] of turtles-on patches with [ suitability &gt;= 0.5 and suitability &lt; 0.6 ]</metric>
    <metric>count patches with [ suitability &gt;= 0.5 and suitability &lt; 0.6 ]</metric>
    <metric>count patches with [ suitability &gt;= 0.5 and suitability &lt; 0.6 and count turtles-on self = 0 ]</metric>
    <metric>length remove-duplicates sort [ species ] of turtles-on patches with [ suitability &gt;= 0.6 and suitability &lt; 0.7]</metric>
    <metric>sort [ species ] of turtles-on patches with [ suitability &gt;= 0.6 and suitability &lt; 0.7 ]</metric>
    <metric>count patches with [ suitability &gt;= 0.6 and suitability &lt; 0.7 ]</metric>
    <metric>count patches with [ suitability &gt;= 0.6 and suitability &lt; 0.7 and count turtles-on self = 0 ]</metric>
    <metric>length remove-duplicates sort [ species ] of turtles-on patches with [ suitability &gt;= 0.7 and suitability &lt; 0.8]</metric>
    <metric>sort [ species ] of turtles-on patches with [  suitability &gt;= 0.7 and suitability &lt; 0.8 ]</metric>
    <metric>count patches with [  suitability &gt;= 0.7 and suitability &lt; 0.8 ]</metric>
    <metric>count patches with [  suitability &gt;= 0.7 and suitability &lt; 0.8 and count turtles-on self = 0 ]</metric>
    <metric>length remove-duplicates sort [ species ] of turtles-on patches with [ suitability &gt;= 0.8 and suitability &lt; 0.9]</metric>
    <metric>sort [ species ] of turtles-on patches with [ suitability &gt;= 0.8 and suitability &lt; 0.9 ]</metric>
    <metric>count patches with [ suitability &gt;= 0.8 and suitability &lt; 0.9 ]</metric>
    <metric>count patches with [ suitability &gt;= 0.8 and suitability &lt; 0.9 and count turtles-on self = 0 ]</metric>
    <metric>length remove-duplicates sort [ species ] of turtles-on patches with [ suitability &gt;= 0.9 and suitability &lt; 1.0 ]</metric>
    <metric>sort [ species ] of turtles-on patches with [ suitability &gt;= 0.9 and suitability &lt; 1.0 ]</metric>
    <metric>count patches with [ suitability &gt;= 0.9 and suitability &lt; 1.0 ]</metric>
    <metric>count patches with [ suitability &gt;= 0.9 and suitability &lt; 1.0 and count turtles-on self = 0 ]</metric>
    <enumeratedValueSet variable="initial-species">
      <value value="458"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="species-specialization">
      <value value="&quot;HIGH&quot;"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="species-interactions">
      <value value="&quot;HIGH&quot;"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="number-of-species">
      <value value="10"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="K-always-on?">
      <value value="true"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="interhabitat-differences">
      <value value="&quot;HIGH&quot;"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="initial-food-per-patch">
      <value value="250"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="%-generalists">
      <value value="0.19"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="view-by">
      <value value="&quot;specialization&quot;"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="fraction">
      <value value="0.57"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="num-runs">
      <value value="500"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="patch-regrowth-rate">
      <value value="0.64"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="suitability-constant">
      <value value="0.18"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="specialists">
      <value value="47"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="generalists">
      <value value="50"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="show-specialization?">
      <value value="false"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="effective-dispersal">
      <value value="&quot;HIGH&quot;"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="show-suitability?">
      <value value="true"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="reproduction-rate">
      <value value="0.57"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="boost-reproduction?">
      <value value="false"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="specialist-K">
      <value value="0.5"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="max-agents-on-a-patch">
      <value value="22"/>
    </enumeratedValueSet>
  </experiment>
  <experiment name="Testing model 1" repetitions="10" runMetricsEveryStep="false">
    <setup>setup</setup>
    <go>go</go>
    <timeLimit steps="250"/>
    <metric>length remove-duplicates sort [species] of turtles</metric>
    <metric>remove-duplicates sort [species] of turtles</metric>
    <metric>count turtles</metric>
    <metric>length remove-duplicates sort [species] of turtles with [ specialist-or-generalist = "specialist" ]</metric>
    <metric>remove-duplicates sort [species] of turtles with [ specialist-or-generalist = "specialist" ]</metric>
    <metric>count turtles with [ specialist-or-generalist = "specialist" ]</metric>
    <metric>length remove-duplicates sort [species] of turtles with [ specialist-or-generalist = "generalist" ]</metric>
    <metric>remove-duplicates sort [species] of turtles with [ specialist-or-generalist = "generalist" ]</metric>
    <metric>count turtles with [ specialist-or-generalist = "generalist" ]</metric>
    <metric>count patches with [ suitability &gt;= 0 and suitability &lt; 0.1 ]</metric>
    <metric>count patches with [ suitability &gt;= 0 and suitability &lt; 0.1 and count turtles-on self = 0 ]</metric>
    <metric>length remove-duplicates sort [ species ] of turtles-on patches with [ suitability &gt;= 0 and suitability &lt; 0.1]</metric>
    <metric>remove-duplicates sort [species] of turtles with [ specialization &lt;= 0.5 and suitability &gt;= 0 and suitability &lt; 0.1 ]</metric>
    <metric>remove-duplicates sort [species] of turtles with [ specialization &gt; 0.5 and suitability &gt;= 0 and suitability &lt; 0.1 ]</metric>
    <metric>count patches with [ suitability &gt;= 0.1 and suitability &lt; 0.2 ]</metric>
    <metric>count patches with [ suitability &gt;= 0.1 and suitability &lt; 0.2 and count turtles-on self = 0 ]</metric>
    <metric>length remove-duplicates sort [ species ] of turtles-on patches with [ suitability &gt;= 0.1 and suitability &lt; 0.2]</metric>
    <metric>remove-duplicates sort [species] of turtles with [ specialization &lt;= 0.5 and suitability &gt;= 0.1 and suitability &lt; 0.2 ]</metric>
    <metric>remove-duplicates sort [species] of turtles with [ specialization &gt; 0.5 and suitability &gt;= 0.1 and suitability &lt; 0.2 ]</metric>
    <metric>count patches with [ suitability &gt;= 0.2 and suitability &lt; 0.3 ]</metric>
    <metric>count patches with [ suitability &gt;= 0.2 and suitability &lt; 0.3 and count turtles-on self = 0 ]</metric>
    <metric>length remove-duplicates sort [ species ] of turtles-on patches with [ suitability &gt;= 0.2 and suitability &lt; 0.3]</metric>
    <metric>remove-duplicates sort [species] of turtles with [ specialization &lt;= 0.5 and suitability &gt;= 0.2 and suitability &lt; 0.3 ]</metric>
    <metric>remove-duplicates sort [species] of turtles with [ specialization &gt; 0.5 and suitability &gt;= 0.2 and suitability &lt; 0.3 ]</metric>
    <metric>count patches with [ suitability &gt;= 0.3 and suitability &lt; 0.4 ]</metric>
    <metric>count patches with [ suitability &gt;= 0.3 and suitability &lt; 0.4 and count turtles-on self = 0 ]</metric>
    <metric>length remove-duplicates sort [ species ] of turtles-on patches with [ suitability &gt;= 0.3 and suitability &lt; 0.4]</metric>
    <metric>remove-duplicates sort [species] of turtles with [ specialization &lt;= 0.5 and suitability &gt;= 0.3 and suitability &lt; 0.4 ]</metric>
    <metric>remove-duplicates sort [species] of turtles with [ specialization &gt; 0.5 and suitability &gt;= 0.3 and suitability &lt; 0.4 ]</metric>
    <metric>count patches with [ suitability &gt;= 0.4 and suitability &lt; 0.5 ]</metric>
    <metric>count patches with [ suitability &gt;= 0.4 and suitability &lt; 0.5 and count turtles-on self = 0 ]</metric>
    <metric>length remove-duplicates sort [ species ] of turtles-on patches with [ suitability &gt;= 0.4 and suitability &lt; 0.5]</metric>
    <metric>remove-duplicates sort [species] of turtles with [ specialization &lt;= 0.5 and suitability &gt;= 0.4 and suitability &lt; 0.5 ]</metric>
    <metric>remove-duplicates sort [species] of turtles with [ specialization &gt; 0.5 and suitability &gt;= 0.4 and suitability &lt; 0.5 ]</metric>
    <metric>count patches with [ suitability &gt;= 0.5 and suitability &lt; 0.6 ]</metric>
    <metric>count patches with [ suitability &gt;= 0.5 and suitability &lt; 0.6 and count turtles-on self = 0 ]</metric>
    <metric>length remove-duplicates sort [ species ] of turtles-on patches with [ suitability &gt;= 0.5 and suitability &lt; 0.6]</metric>
    <metric>remove-duplicates sort [species] of turtles with [ specialization &lt;= 0.5 and suitability &gt;= 0.5 and suitability &lt; 0.6 ]</metric>
    <metric>remove-duplicates sort [species] of turtles with [ specialization &gt; 0.5 and suitability &gt;= 0.5 and suitability &lt; 0.6 ]</metric>
    <metric>count patches with [ suitability &gt;= 0.6 and suitability &lt; 0.7 ]</metric>
    <metric>count patches with [ suitability &gt;= 0.6 and suitability &lt; 0.7 and count turtles-on self = 0 ]</metric>
    <metric>length remove-duplicates sort [ species ] of turtles-on patches with [ suitability &gt;= 0.6 and suitability &lt; 0.7]</metric>
    <metric>remove-duplicates sort [species] of turtles with [ specialization &lt;= 0.5 and suitability &gt;= 0.6 and suitability &lt; 0.7 ]</metric>
    <metric>remove-duplicates sort [species] of turtles with [ specialization &gt; 0.5 and suitability &gt;= 0.6 and suitability &lt; 0.7 ]</metric>
    <metric>count patches with [ suitability &gt;= 0.7 and suitability &lt; 0.8 ]</metric>
    <metric>count patches with [ suitability &gt;= 0.7 and suitability &lt; 0.8 and count turtles-on self = 0 ]</metric>
    <metric>length remove-duplicates sort [ species ] of turtles-on patches with [ suitability &gt;= 0.7 and suitability &lt; 0.8]</metric>
    <metric>remove-duplicates sort [species] of turtles with [ specialization &lt;= 0.5 and suitability &gt;= 0.7 and suitability &lt; 0.8 ]</metric>
    <metric>remove-duplicates sort [species] of turtles with [ specialization &gt; 0.5 and suitability &gt;= 0.7 and suitability &lt; 0.8 ]</metric>
    <metric>count patches with [ suitability &gt;= 0.8 and suitability &lt; 0.9 ]</metric>
    <metric>count patches with [ suitability &gt;= 0.8 and suitability &lt; 0.9 and count turtles-on self = 0 ]</metric>
    <metric>length remove-duplicates sort [ species ] of turtles-on patches with [ suitability &gt;= 0.8 and suitability &lt; 0.9]</metric>
    <metric>remove-duplicates sort [species] of turtles with [ specialization &lt;= 0.5 and suitability &gt;= 0.8 and suitability &lt; 0.9 ]</metric>
    <metric>remove-duplicates sort [species] of turtles with [ specialization &gt; 0.5 and suitability &gt;= 0.8 and suitability &lt; 0.8 ]</metric>
    <metric>count patches with [ suitability &gt;= 0.9 and suitability &lt; 1.0 ]</metric>
    <metric>count patches with [ suitability &gt;= 0.9 and suitability &lt; 1.0 and count turtles-on self = 0 ]</metric>
    <metric>length remove-duplicates sort [ species ] of turtles-on patches with [ suitability &gt;= 0.9 and suitability &lt; 1.0]</metric>
    <metric>remove-duplicates sort [species] of turtles with [ specialization &lt;= 0.5 and suitability &gt;= 0.9 and suitability &lt; 1.0 ]</metric>
    <metric>remove-duplicates sort [species] of turtles with [ specialization &gt; 0.5 and suitability &gt;= 0.9 and suitability &lt; 1.0 ]</metric>
    <enumeratedValueSet variable="initial-species">
      <value value="500"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="species-specialization">
      <value value="&quot;RANDOM&quot;"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="species-interactions">
      <value value="&quot;LOW&quot;"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="K-always-on?">
      <value value="true"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="number-of-species">
      <value value="10"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="interhabitat-differences">
      <value value="&quot;HIGH&quot;"/>
      <value value="&quot;LOW - POOR&quot;"/>
      <value value="&quot;LOW - GOOD&quot;"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="initial-food-per-patch">
      <value value="200"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="patch-regrowth-rate">
      <value value="0.8"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="%-generalists">
      <value value="0.15"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="view-by">
      <value value="&quot;specialization&quot;"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="num-runs">
      <value value="500"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="suitability-constant">
      <value value="0.2"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="fraction">
      <value value="0.75"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="specialists">
      <value value="47"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="generalists">
      <value value="50"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="effective-dispersal">
      <value value="&quot;NON-LIMITING&quot;"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="show-specialization?">
      <value value="false"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="show-suitability?">
      <value value="true"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="reproduction-rate">
      <value value="0.8"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="max-agents-on-a-patch">
      <value value="20"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="specialist-K">
      <value value="0.5"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="boost-reproduction?">
      <value value="false"/>
    </enumeratedValueSet>
  </experiment>
  <experiment name="Model 12 - Test/data" repetitions="10" runMetricsEveryStep="false">
    <setup>setup</setup>
    <go>go</go>
    <timeLimit steps="250"/>
    <metric>length remove-duplicates sort [species] of turtles</metric>
    <metric>count turtles</metric>
    <metric>length remove-duplicates sort [species] of turtles with [ specialist-or-generalist = "specialist" ]</metric>
    <metric>count turtles with [ specialist-or-generalist = "specialist" ]</metric>
    <metric>length remove-duplicates sort [species] of turtles with [ specialist-or-generalist = "generalist" ]</metric>
    <metric>count turtles with [ specialist-or-generalist = "generalist" ]</metric>
    <enumeratedValueSet variable="initial-species">
      <value value="500"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="species-specialization">
      <value value="&quot;HIGH&quot;"/>
      <value value="&quot;LOW&quot;"/>
      <value value="&quot;RANDOM&quot;"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="species-interactions">
      <value value="&quot;Specialist-Generalist&quot;"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="number-of-species">
      <value value="50"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="K-always-on?">
      <value value="true"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="interhabitat-differences">
      <value value="&quot;HIGH&quot;"/>
      <value value="&quot;LOW - POOR&quot;"/>
      <value value="&quot;LOW - GOOD&quot;"/>
      <value value="&quot;RANDOM&quot;"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="initial-food-per-patch">
      <value value="200"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="patch-regrowth-rate">
      <value value="0.8"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="view-by">
      <value value="&quot;specialization&quot;"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="fraction">
      <value value="0.75"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="num-runs">
      <value value="250"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="suitability-constant">
      <value value="0.2"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="%-generalists">
      <value value="0.1"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="specialists">
      <value value="47"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="generalists">
      <value value="50"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="show-specialization?">
      <value value="false"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="effective-dispersal">
      <value value="&quot;NONE&quot;"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="show-suitability?">
      <value value="true"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="reproduction-rate">
      <value value="0.8"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="boost-reproduction?">
      <value value="false"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="max-agents-on-a-patch">
      <value value="20"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="specialist-K">
      <value value="0.35"/>
    </enumeratedValueSet>
  </experiment>
  <experiment name="Model 13 - Data Gathering" repetitions="1" runMetricsEveryStep="true">
    <setup>setup</setup>
    <go>go</go>
    <timeLimit steps="250"/>
    <metric>length remove-duplicates sort [species] of turtles</metric>
    <metric>count turtles</metric>
    <metric>length remove-duplicates sort [species] of turtles with [ specialist-or-generalist = "specialist" ]</metric>
    <metric>count turtles with [ specialist-or-generalist = "specialist" ]</metric>
    <metric>length remove-duplicates sort [species] of turtles with [ specialist-or-generalist = "generalist" ]</metric>
    <metric>count turtles with [ specialist-or-generalist = "generalist" ]</metric>
    <enumeratedValueSet variable="species-interactions">
      <value value="&quot;LOW&quot;"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="number-of-species">
      <value value="50"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="K-always-on?">
      <value value="true"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="gs-reward">
      <value value="-10"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="gg-reward">
      <value value="-10"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="interhabitat-differences">
      <value value="&quot;HIGH&quot;"/>
      <value value="&quot;RANDOM&quot;"/>
      <value value="&quot;LOW - GOOD&quot;"/>
      <value value="&quot;LOW - POOR&quot;"/>
      <value value="&quot;NONE&quot;"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="patch-regrowth-rate">
      <value value="0.8"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="view-by">
      <value value="&quot;specialization&quot;"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="num-runs">
      <value value="250"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="show-suitability?">
      <value value="true"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="reproduction-rate">
      <value value="0.8"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="boost-reproduction?">
      <value value="false"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="initial-species">
      <value value="500"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="species-specialization">
      <value value="&quot;HIGH&quot;"/>
      <value value="&quot;RANDOM&quot;"/>
      <value value="&quot;LOW&quot;"/>
      <value value="&quot;NONE&quot;"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="initial-food-per-patch">
      <value value="200"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="%-generalists">
      <value value="0.1"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="fraction">
      <value value="0.75"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="suitability-constant">
      <value value="0.2"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="specialists">
      <value value="47"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="ss-reward">
      <value value="-10"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="sg-reward">
      <value value="-10"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="generalists">
      <value value="0"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="effective-dispersal">
      <value value="&quot;NONE&quot;"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="show-specialization?">
      <value value="false"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="SI-specialists">
      <value value="-1"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="max-agents-on-a-patch">
      <value value="20"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="specialist-K">
      <value value="0.35"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="SI-generalists">
      <value value="-1"/>
    </enumeratedValueSet>
  </experiment>
  <experiment name="Measuring abundance/patch energy" repetitions="5" runMetricsEveryStep="true">
    <setup>setup</setup>
    <go>go</go>
    <metric>( count turtles with [specialist-or-generalist = "specialist" and suitability &gt;= 0.0 and suitability &lt; 0.1 ] ) / (count patches with [ suitability &gt;= 0.0 and suitability &lt; 0.1 ])</metric>
    <metric>( count turtles with [specialist-or-generalist = "specialist" and suitability &gt;= 0.1 and suitability &lt; 0.2 ] ) / (count patches with [ suitability &gt;= 0.1 and suitability &lt; 0.2 ])</metric>
    <metric>( count turtles with [specialist-or-generalist = "specialist" and suitability &gt;= 0.2 and suitability &lt; 0.3 ] ) / (count patches with [ suitability &gt;= 0.2 and suitability &lt; 0.3 ])</metric>
    <metric>( count turtles with [specialist-or-generalist = "specialist" and suitability &gt;= 0.3 and suitability &lt; 0.4 ] ) / (count patches with [ suitability &gt;= 0.3 and suitability &lt; 0.4 ])</metric>
    <metric>( count turtles with [specialist-or-generalist = "specialist" and suitability &gt;= 0.4 and suitability &lt; 0.5 ] ) / (count patches with [ suitability &gt;= 0.4 and suitability &lt; 0.5 ])</metric>
    <metric>( count turtles with [specialist-or-generalist = "specialist" and suitability &gt;= 0.5 and suitability &lt; 0.6 ] ) / (count patches with [ suitability &gt;= 0.5 and suitability &lt; 0.6 ])</metric>
    <metric>( count turtles with [specialist-or-generalist = "specialist" and suitability &gt;= 0.6 and suitability &lt; 0.7 ] ) / (count patches with [ suitability &gt;= 0.6 and suitability &lt; 0.7 ])</metric>
    <metric>( count turtles with [specialist-or-generalist = "specialist" and suitability &gt;= 0.7 and suitability &lt; 0.8 ] ) / (count patches with [ suitability &gt;= 0.7 and suitability &lt; 0.8 ])</metric>
    <metric>( count turtles with [specialist-or-generalist = "specialist" and suitability &gt;= 0.8 and suitability &lt; 0.9 ] ) / (count patches with [ suitability &gt;= 0.8 and suitability &lt; 0.9 ])</metric>
    <metric>( count turtles with [specialist-or-generalist = "specialist" and suitability &gt;= 0.9 and suitability &lt; 1.0 ] ) / (count patches with [ suitability &gt;= 0.9 and suitability &lt; 1.0 ])</metric>
    <metric>( count turtles with [specialist-or-generalist = "generalist" and suitability &gt;= 0.0 and suitability &lt; 0.1 ] ) / (count patches with [ suitability &gt;= 0.0 and suitability &lt; 0.1 ])</metric>
    <metric>( count turtles with [specialist-or-generalist = "generalist" and suitability &gt;= 0.1 and suitability &lt; 0.2 ] ) / (count patches with [ suitability &gt;= 0.1 and suitability &lt; 0.2 ])</metric>
    <metric>( count turtles with [specialist-or-generalist = "generalist" and suitability &gt;= 0.2 and suitability &lt; 0.3 ] ) / (count patches with [ suitability &gt;= 0.2 and suitability &lt; 0.3 ])</metric>
    <metric>( count turtles with [specialist-or-generalist = "generalist" and suitability &gt;= 0.3 and suitability &lt; 0.4 ] ) / (count patches with [ suitability &gt;= 0.3 and suitability &lt; 0.4 ])</metric>
    <metric>( count turtles with [specialist-or-generalist = "generalist" and suitability &gt;= 0.4 and suitability &lt; 0.5 ] ) / (count patches with [ suitability &gt;= 0.4 and suitability &lt; 0.5 ])</metric>
    <metric>( count turtles with [specialist-or-generalist = "generalist" and suitability &gt;= 0.5 and suitability &lt; 0.6 ] ) / (count patches with [ suitability &gt;= 0.5 and suitability &lt; 0.6 ])</metric>
    <metric>( count turtles with [specialist-or-generalist = "generalist" and suitability &gt;= 0.6 and suitability &lt; 0.7 ] ) / (count patches with [ suitability &gt;= 0.6 and suitability &lt; 0.7 ])</metric>
    <metric>( count turtles with [specialist-or-generalist = "generalist" and suitability &gt;= 0.7 and suitability &lt; 0.8 ] ) / (count patches with [ suitability &gt;= 0.7 and suitability &lt; 0.8 ])</metric>
    <metric>( count turtles with [specialist-or-generalist = "generalist" and suitability &gt;= 0.8 and suitability &lt; 0.9 ] ) / (count patches with [ suitability &gt;= 0.8 and suitability &lt; 0.9 ])</metric>
    <metric>( count turtles with [specialist-or-generalist = "generalist" and suitability &gt;= 0.9 and suitability &lt; 1.0 ] ) / (count patches with [ suitability &gt;= 0.9 and suitability &lt; 1.0 ])</metric>
    <metric>mean [food] of patches with [ suitability &gt;= 0.0 and suitability &lt; 0.1 ]</metric>
    <metric>mean [food] of patches with [ suitability &gt;= 0.1 and suitability &lt; 0.2 ]</metric>
    <metric>mean [food] of patches with [ suitability &gt;= 0.2 and suitability &lt; 0.3 ]</metric>
    <metric>mean [food] of patches with [ suitability &gt;= 0.3 and suitability &lt; 0.4 ]</metric>
    <metric>mean [food] of patches with [ suitability &gt;= 0.4 and suitability &lt; 0.5 ]</metric>
    <metric>mean [food] of patches with [ suitability &gt;= 0.5 and suitability &lt; 0.6 ]</metric>
    <metric>mean [food] of patches with [ suitability &gt;= 0.6 and suitability &lt; 0.7 ]</metric>
    <metric>mean [food] of patches with [ suitability &gt;= 0.7 and suitability &lt; 0.8 ]</metric>
    <metric>mean [food] of patches with [ suitability &gt;= 0.8 and suitability &lt; 0.9 ]</metric>
    <metric>mean [food] of patches with [ suitability &gt;= 0.9 and suitability &lt; 1.0 ]</metric>
    <metric>( count turtles with [ suitability &gt;= 0.0 and suitability &lt; 0.1 ] ) / (count patches with [ suitability &gt;= 0.0 and suitability &lt; 0.1 ])</metric>
    <metric>( count turtles with [ suitability &gt;= 0.1 and suitability &lt; 0.2 ] ) / (count patches with [ suitability &gt;= 0.1 and suitability &lt; 0.2 ])</metric>
    <metric>( count turtles with [ suitability &gt;= 0.2 and suitability &lt; 0.3 ] ) / (count patches with [ suitability &gt;= 0.2 and suitability &lt; 0.3 ])</metric>
    <metric>( count turtles with [ suitability &gt;= 0.3 and suitability &lt; 0.4 ] ) / (count patches with [ suitability &gt;= 0.3 and suitability &lt; 0.4 ])</metric>
    <metric>( count turtles with [ suitability &gt;= 0.4 and suitability &lt; 0.5 ] ) / (count patches with [ suitability &gt;= 0.4 and suitability &lt; 0.5 ])</metric>
    <metric>( count turtles with [ suitability &gt;= 0.5 and suitability &lt; 0.6 ] ) / (count patches with [ suitability &gt;= 0.5 and suitability &lt; 0.6 ])</metric>
    <metric>( count turtles with [ suitability &gt;= 0.6 and suitability &lt; 0.7 ] ) / (count patches with [ suitability &gt;= 0.6 and suitability &lt; 0.7 ])</metric>
    <metric>( count turtles with [ suitability &gt;= 0.7 and suitability &lt; 0.8 ] ) / (count patches with [ suitability &gt;= 0.7 and suitability &lt; 0.8 ])</metric>
    <metric>( count turtles with [ suitability &gt;= 0.8 and suitability &lt; 0.9 ] ) / (count patches with [ suitability &gt;= 0.8 and suitability &lt; 0.9 ])</metric>
    <metric>( count turtles with [ suitability &gt;= 0.9 and suitability &lt; 1.0 ] ) / (count patches with [ suitability &gt;= 0.9 and suitability &lt; 1.0 ])</metric>
    <metric>length remove-duplicates sort [species] of turtles</metric>
    <enumeratedValueSet variable="species-interactions">
      <value value="&quot;HIGH&quot;"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="number-of-species">
      <value value="50"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="K-always-on?">
      <value value="true"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="gs-reward">
      <value value="-10"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="gg-reward">
      <value value="-10"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="interhabitat-differences">
      <value value="&quot;LOW - POOR&quot;"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="patch-regrowth-rate">
      <value value="0.96"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="view-by">
      <value value="&quot;specialization&quot;"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="num-runs">
      <value value="250"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="show-suitability?">
      <value value="true"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="reproduction-rate">
      <value value="0.8"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="boost-reproduction?">
      <value value="false"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="initial-species">
      <value value="500"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="species-specialization">
      <value value="&quot;HIGH&quot;"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="initial-food-per-patch">
      <value value="200"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="%-generalists">
      <value value="0.36"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="fraction">
      <value value="0.75"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="suitability-constant">
      <value value="0.2"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="specialists">
      <value value="47"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="ss-reward">
      <value value="0"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="sg-reward">
      <value value="10"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="generalists">
      <value value="0"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="effective-dispersal">
      <value value="&quot;HIGH&quot;"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="show-specialization?">
      <value value="false"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="SI-specialists">
      <value value="-1"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="max-agents-on-a-patch">
      <value value="25"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="specialist-K">
      <value value="0.35"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="SI-generalists">
      <value value="-1"/>
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
