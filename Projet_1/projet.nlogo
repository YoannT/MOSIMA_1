extensions [palette]

breed [agents agent]

globals [
  valposs ;domaine de valeurs à parcourir pour maximiser la réponse
  effortmoyen ;Effort moyen
  nb_agents ;Nombre total d'agents
  list_6_7 ;Liste pour les figures 6 et 7
  list_perc_high ;Liste des pourcentages d'agents high effort
  cpt ;compteur

  ;Listes pour la figure 9
  effort_noise_low
  effort_noise_medium
  effort_noise_high
  effort_perfect_observability
  mean_effort

  couleur_type ;Variable pour la figure 9
]


agents-own [
  class     ;type de l'agent
  col       ;couleur d'effort
  colt ;couleur du type
  effort ;effort
  profit ;profit
  cumprofit ;profit cumulé
  leffort ;dernier effort
  cumeffort ;effort cumulé
  lprofit ;dernier profit
  aeffort ;dernier effort antagoniste
  aprofit ;dernier profit antagoniste
  neffort ;moyenne efforts antagonistes
  nprofit ;moyenne profits antagonistes
  numinc ;nombre d'interactions
  game? ; bool pour savoir si l'agent joue ou pas

  ; Extensions

  ; Découragement
  nb_sans_interaction

  ; Limitation par type
  list_profits_par_type
  list_interactions_par_type
  cache_type

  ; Limitation des rencontres
  list_rencontres
]

patches-own [
]


;;;;;;;;;;;;;;;;;;
; SET UP DE BASE ;
;;;;;;;;;;;;;;;;;;


;Crée les agents selon leur nombre
;Leur donne des valeurs initiales d'attributs et les place sur le terrain
to setup-agents

  create-agents nb_null [
    set class 0
    set colt sky
    set effort effort_min
    ;set shape "default"
    set couleur_type colt
  ]

  create-agents nb_shrinking [
    set class 1
    set colt orange
    ifelse randomstart? [set effort effort_min + random-float (effort_max - effort_min)][set effort start_effort]
    ;set shape "airplane"
    set couleur_type colt
  ]

  create-agents nb_replicator [
    set class 2
    set colt yellow
    ifelse randomstart? [set effort effort_min + random-float (effort_max - effort_min)][set effort start_effort]
    ;set shape "arrow"
    set couleur_type colt
  ]

  create-agents nb_rational [
    set class 3
    set colt lime
    ifelse randomstart? [set effort effort_min + random-float (effort_max - effort_min)][set effort start_effort]
    ;set shape "bug"
    set couleur_type colt
  ]

  create-agents nb_profcomparator[
    set class 4
    set colt cyan
    ifelse randomstart? [set effort effort_min + random-float (effort_max - effort_min)][set effort start_effort]
    ;set shape "triangle"
    set couleur_type colt
  ]

  create-agents nb_high[
    set class 5
    set effort effort_max
    set colt red
    ;set shape "pentagon"
  ]

  create-agents nb_avgrational [
    set class 6
    set colt pink
    ifelse randomstart? [set effort effort_min + random-float (effort_max - effort_min)][set effort start_effort]
    ;set shape "house"
    set couleur_type colt
  ]

  create-agents nb_imitator [
    set class 7
    set effort effort_max
    set colt violet
    ;set shape "leaf"
    set couleur_type colt
  ]

  create-agents nb_effcomparator [
    set class 8
    set colt brown
    ifelse randomstart? [set effort effort_min + random-float (effort_max - effort_min)][set effort start_effort]
    ;set shape "turtle"
    set couleur_type colt
  ]

  create-agents nb_averager [
    set class 9
    set colt grey
    ifelse randomstart? [set effort effort_min + random-float (effort_max - effort_min)][set effort start_effort]
    ;set shape "person"
    set couleur_type colt
  ]

  ask agents [
    set color colt
    set numinc 0
    let ptch one-of patches with [not any? turtles-here]
    if ptch != nobody [move-to one-of patches with [not any? turtles-here]]
    set heading one-of [0 90 180 270]
    ;set shape "turtle"
    ; Si l'effort est nul, on l'augmente de manière à ce que les agents comparateurs ne restent pas à 0
    if effort = 0 [set effort 0.001]
    set leffort 0
    set lprofit 0

    set aeffort 0
    set profit 0

    set cumprofit 0
    set cumeffort 0
    set aprofit 0

    set neffort 0
    set nprofit 0

    if Decouragement?[set nb_sans_interaction 0]

    if Limitation_type?[
     set list_profits_par_type (list 0 0 0 0 0 0 0 0 0 0)
     set list_interactions_par_type (list 0 0 0 0 0 0 0 0 0 0)
     set cache_type (list 0 0 0 0 0 0 0 0 0 0)
    ]

  ]

end

; Fonction pour donner des valeurs aux populations d'agents
to setup-pop [null shrinking replicator rational profcomparator high avgrational imitator effcomparator averager]
  set nb_null null
  set nb_shrinking shrinking
  set nb_replicator replicator
  set nb_rational rational
  set nb_profcomparator profcomparator
  set nb_high high
  set nb_avgrational avgrational
  set nb_imitator imitator
  set nb_effcomparator effcomparator
  set nb_averager averager
  set nb_agents nb_null + nb_shrinking + nb_replicator + nb_rational + nb_profcomparator + nb_high + nb_avgrational + nb_imitator + nb_effcomparator + nb_averager
end

to setup
  clear-globals
  clear-ticks
  clear-turtles
  clear-patches
  clear-drawing
  clear-output

  reset-ticks
  ;set effort_min 0
  ;set effort_max 2
  ;setup-pop 5 5 5 5 5 5 5 5 5 5
  setup-agents

  set nb_agents nb_null + nb_shrinking + nb_replicator + nb_rational + nb_profcomparator + nb_high + nb_avgrational + nb_imitator + nb_effcomparator + nb_averager
  ask patches [
    ;; make background a slightly dark gray
    set pcolor white
  ]

  if Limitation_rencontres?[
     ask agents [set list_rencontres n-values nb_agents [0]]
  ]

  ; Initialisation du domaine servant aux agents rational et average rational
  set valposs n-values 201 [? / 100]

  ask agents[update-agent]
end

;;;;;;;;;;;;;;;;;;;;;
; GO ET JEU DE BASE ;
;;;;;;;;;;;;;;;;;;;;;

; On déplace les agents, on les fait interagir, on les adapte, on met à jour le terrain et on trace la courbe d'effort moyen
to go
  ask agents[
    move-agent
    game
    update-agent
  ]
  plotter_effort
  tick
end

; Fonction du jeu
; On repère si un agent fait face à l'agent courant
; On met à jour les attributs (on demande à l'antagoniste de mettre à jour le profit de son antagoniste grâce à celui de l'agent courant)
; On fait s'adapter l'agent (avec work-agent)
to game
  let antagonist nobody
  let enface? false

  let aheading heading
  if patch-ahead 1 != nobody
  [
    set antagonist one-of turtles-on patch-ahead 1
    ; On demande a l'agent en face s'il est en face aussi
    if antagonist != nobody [
      ask antagonist [
       set enface? abs (heading - aheading) = 180
      ]
    ]
  ]

  if enface?[
    set numinc (numinc + 1)
    set leffort effort
    set lprofit profit

    set aeffort [effort] of antagonist * bruiter
    set profit (func-profit effort aeffort)


    set cumprofit (cumprofit + profit)
    set cumeffort (cumeffort + effort)

    let prof profit
    ask antagonist [set aprofit prof]

    set neffort neffort + aeffort
    set nprofit nprofit + aprofit

    work-agent

  ]

  if Decouragement?[
    set nb_sans_interaction nb_sans_interaction + 1
    if nb_sans_interaction > limite_sans_interaction [
      set effort effort * 0.999
    ]
    if enface?[
      set nb_sans_interaction 0
      set effort effort * 1.001
    ]
  ]

end

; Fonction au nom trompeur pour mettre à jour les patches et les formes des agents
to update-agent

  ask patches with [not any? turtles-here] [set pcolor white]
  ifelse choisir_affichage = "Classe seule"[
    set color colt
  ]
  [
    ifelse choisir_affichage = "Effort seul"[
      set color palette:scale-gradient palette:scheme-colors "Divergent" "Spectral" 9 effort 2 0
    ]
    [
      set pcolor palette:scale-gradient palette:scheme-colors "Divergent" "Spectral" 9 effort 2 0
      set color colt
    ]
  ]

end

; Fonction pour faire se déplace l'agent
to move-agent
  set heading one-of [0 90 180 270]
  if [not any? turtles-here] of patch-ahead 1 [
    fd 1
  ]
end

; Fonction d'adaptation de l'agent selon sa classe
to work-agent
  ifelse class = 1 [set effort (aeffort / 2)]
  [ ifelse class = 2 [set effort aeffort]
  [  ifelse class = 3 [set effort best-reply]
  [  ifelse class = 4 [set effort compare-profit ]
  [  ifelse class = 6 [set effort best-reply-average]
  [  ifelse class = 7 [set effort imitate-winner ]
  [  ifelse class = 8 [set effort compare-effort ]
  [  ifelse class = 9 [set effort average-effort ]
  []
  ]]]]]]]
end

; Les différents reporters appliquent les formules pour calculer le nouvel effort de l'agent

to-report func-profit [eff aeff]
  report ((5 * sqrt(eff + aeff * bruiter)) - (eff ^ 2))
end

; Maximiser le profit selon l'effort et l'aeffort
to-report best-reply
  let profits []
  foreach valposs[
    let tmp func-profit ? aeffort
    set profits lput tmp profits
  ]
  report  (item position (max profits) profits valposs)
end

to-report compare-profit
  ifelse profit > aprofit [report (1.1 * effort)]
  [report (0.9 * effort)]
end

to-report compare-effort
  ifelse effort < aeffort [report (1.1 * effort)]
  [report (0.9 * effort)]
end

; Pareil que best reply mais sur la moyenne des efforts antagonistes
to-report best-reply-average
  let profits []
  foreach valposs[
    let tmp func-profit ? (neffort / numinc)
    set profits lput tmp profits
  ]
  report  (item position (max profits) profits valposs)
end

to-report imitate-winner
  ifelse profit < aprofit[report  aeffort]
  [report  effort]
end


to-report average-effort
  report  ((effort + aeffort) / 2)
end

; Rend une valeur de bruit comprise entre 1-noise/100 et 1+noise/100
to-report bruiter
  let rand random 2
  if rand = 0 [report 1 - (random-float noise / 100)]
  if rand = 1 [report 1 + (random-float noise / 100)]
end

; Assure que la valeur d'effort soit entre 0 et 2 (non utilisé)
to-report  return [eff]
  report median (list 0 eff 2)
end

; Trace la courbe d'effort moyen
to plotter_effort
  set-current-plot "Effort moyen"

  if any? agents [
    create-temporary-plot-pen (word "moyenne")
    set-plot-pen-color red
    plot mean [effort] of agents
    create-temporary-plot-pen (word "effort max")
    set-plot-pen-color black
    plot effort_max
  ]
end

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
; SET UP ET JEU FIGURES 6 ET 7 ;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

; Sert à initialiser une simulation pour les figures 6 et 7 (influence des agents high effort)
; On remplit le terrain avec la population d'agents choisie et on les initialise

to setup_figure_6_7

  clear-globals
  clear-ticks
  clear-turtles
  clear-patches
  clear-drawing
  clear-output

  reset-ticks

  set list_perc_high [0 0.6 5.6 33.3 66.7 100]
  set list_6_7 [-1 -1 -1 -1 -1 2]
  set cpt 0

  ask patches [
    set pcolor white
  ]

  set valposs n-values 100 [? / 100]

  setup-pop 0 0 0 0 0 0 0 0 0 0

  set nb_high (round item cpt list_perc_high * nb_agents_max / 100)

  ifelse type_impacte_high = "null effort" [set nb_null nb_agents_max - nb_high]
  [ ifelse type_impacte_high = "shrinking effort" [set nb_shrinking nb_agents_max - nb_high]
  [  ifelse type_impacte_high = "replicator" [set nb_replicator nb_agents_max - nb_high]
  [  ifelse type_impacte_high = "rational" [set nb_rational nb_agents_max - nb_high]
  [  ifelse type_impacte_high = "profit comparator" [set nb_profcomparator nb_agents_max - nb_high]
  [  ifelse type_impacte_high = "average rational" [set nb_avgrational nb_agents_max - nb_high]
  [  ifelse type_impacte_high = "winner imitator" [set nb_imitator nb_agents_max - nb_high]
  [  ifelse type_impacte_high = "averager" [set nb_averager nb_agents_max - nb_high]
  [  ifelse type_impacte_high = "effort comparator" [set nb_effcomparator nb_agents_max - nb_high]
  []
  ]]]]]]]]

  setup-pop nb_null nb_shrinking nb_replicator nb_rational nb_profcomparator nb_high nb_avgrational nb_imitator nb_effcomparator nb_averager
  setup-agents

end

; On effectue les mêmes opérations que précédemment (déplacement, interaction, mise à jour)
; On fait varier la population d'agents high effort si une certaine durée est atteinte et on enregistre l'effort moyen
; Si tous les pourcentages de population d'agents high effort ont été utilisés, on arrête la simulation et on trace les courbes

to go_figure_6_7
  ask agents[
    move-agent
    game
    update-agent
  ]


  if ticks > nb_ticks_high and cpt <= 4[
    reset-ticks
    set list_6_7 replace-item cpt list_6_7 (mean [effort] of agents)
    clear-turtles
    clear-patches

    set cpt cpt + 1

    set nb_high (round item cpt list_perc_high * nb_agents_max / 100)

    ifelse type_impacte_high = "null effort" [set nb_null nb_agents_max - nb_high]
    [ ifelse type_impacte_high = "shrinking effort" [set nb_shrinking nb_agents_max - nb_high]
    [  ifelse type_impacte_high = "replicator" [set nb_replicator nb_agents_max - nb_high]
    [  ifelse type_impacte_high = "rational" [set nb_rational nb_agents_max - nb_high]
    [  ifelse type_impacte_high = "profit comparator" [set nb_profcomparator nb_agents_max - nb_high]
    [  ifelse type_impacte_high = "average rational" [set nb_avgrational nb_agents_max - nb_high]
    [  ifelse type_impacte_high = "winner imitator" [set nb_imitator nb_agents_max - nb_high]
    [  ifelse type_impacte_high = "averager" [set nb_averager nb_agents_max - nb_high]
    [  ifelse type_impacte_high = "effort comparator" [set nb_effcomparator nb_agents_max - nb_high]
    []

    ]]]]]]]]
    setup-pop nb_null nb_shrinking nb_replicator nb_rational nb_profcomparator nb_high nb_avgrational nb_imitator nb_effcomparator nb_averager
    setup-agents

  ]

  if min list_6_7 != -1 or cpt > 4[
    plot_lists_6_7 list_perc_high list_6_7
    stop
  ]

  tick
end

; Trace les courbes reproduisant les figures 6 et 7
; Si les agents sont rational ou average rational, on trace la courbe "expected" obtenue à partir des valeurs indiquées dans l'article

to plot_lists_6_7 [list1 list2]
  set-current-plot "Impact des agents high effort"
  ;clear-plot

  let list_expected [0.92101 0.92701 0.98101 1.28100 1.64100 2.00100]

  (foreach list1 list2 list_expected[
    create-temporary-plot-pen (word "effort max")
    set-plot-pen-color black
    plotxy ?1 effort_max
    create-temporary-plot-pen (word type_impacte_high)
    set-plot-pen-color couleur_type
    plotxy ?1 ?2
    if type_impacte_high = "rational" or type_impacte_high = "average rational" [
      create-temporary-plot-pen (word "expected")
      set-plot-pen-color blue - 3
      plotxy ?1 ?3
    ]
  ])

end

;;;;;;;;;;;;;;;;;;;;;;;
; SET UP ET JEU NOISE ;
;;;;;;;;;;;;;;;;;;;;;;;

; Sert à initialiser une simulation pour les figures 8 et 9 (effet du bruit)
; On remplit le terrain avec des agents winner imitator et on les initialise

to setup_agents_noise
  create-agents nb_imitator [
  set class 7
  set effort effort_max
  set colt violet
  ]

  ask agents [
    set color colt
    set numinc 0
    let ptch one-of patches with [not any? turtles-here]
    if ptch != nobody [move-to one-of patches with [not any? turtles-here]]
    set heading one-of [0 90 180 270]
    ;set shape "turtle"
    ; Donner les valeurs de base aux agents null, max, random
    if effort = 0 [set effort 0.0001]
  ]
end

to setup_effet_bruit

  clear-globals
  clear-ticks
  clear-turtles
  clear-patches
  clear-drawing
  clear-output

  reset-ticks

  ask patches [
    set pcolor white
  ]

  set nb_imitator nb_agents_max
  setup-pop 0 0 0 0 0 0 0 nb_imitator 0 0
  setup_agents_noise

  set cpt 0

  set noise 0

  set mean_effort (list)

end

; On effectue les mêmes opérations que précédemment (déplacement, interaction, mise à jour) en enregistrant l'effort moyen à chaque tick
; On fait varier la valeur de bruit si une certaine durée est atteinte (0, 10 , 25 puis 50 %)
; Si toutes les valeurs de bruit ont été parcourues, on arrête la simulation et on trace les courbes

to go_effet_bruit
  ask agents[
    move-agent
    game
    update-agent
  ]

  if ticks > nb_ticks_noise[
    if cpt = 0 [
      set noise 10
      set effort_perfect_observability mean_effort
    ]
    if cpt = 1 [
      set noise 25
      set effort_noise_low mean_effort
    ]
    if cpt = 2 [
      set noise 50
      set effort_noise_medium mean_effort
    ]
    if cpt = 3 [
      set effort_noise_high mean_effort
    ]
    set cpt cpt + 1
    reset-ticks
    set mean_effort (list)
    clear-turtles
    setup_agents_noise

  ]

  if cpt > 3 [
    plot_noise effort_perfect_observability effort_noise_low effort_noise_medium effort_noise_high
    set noise 0
    stop
  ]

  set mean_effort lput (mean [effort] of agents) mean_effort

  tick
end


; Trace les courbes reproduisant la figure 9

to plot_noise [list_perfect list_low list_medium list_high]

  let list_ticks n-values (nb_ticks_noise + 1) [?]

  set-current-plot "Effet du bruit"
  clear-plot

  (foreach list_ticks list_perfect  [
    create-temporary-plot-pen (word "perfect observability")
    set-plot-pen-color blue
    plotxy ?1 ?2
  ])
  (foreach list_ticks list_low  [
    create-temporary-plot-pen (word "low noise")
    set-plot-pen-color magenta
    plotxy ?1 ?2
  ])
  (foreach list_ticks list_medium  [
    create-temporary-plot-pen (word "medium noise")
    set-plot-pen-color orange
    plotxy ?1 ?2
  ])
  (foreach list_ticks list_high  [
    create-temporary-plot-pen (word "high noise")
    set-plot-pen-color cyan
    plotxy ?1 ?2
  ])

end


;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
; LIMITATION DES RENCONTRES PAR TYPE ;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

; Pas de changement pour le go

to go_limitation_type
  ask agents[
    move-agent
    game_limitation_type
    update-agent
  ]
  plotter_effort
  ;print "--------------------------"
  ;print [cache_type] of agents with [class = 2 ]
  tick
end

; On enregistre le profit moyen apporté par chaque type
; Si le profit apporté par un type est trop bas, on exclut le type des interactions avec l'agent courant

to game_limitation_type
  let antagonist nobody
  let enface? false

  let aheading heading
  if patch-ahead 1 != nobody
  [
    set antagonist one-of turtles-on patch-ahead 1
    ; On demande a l'agent en face s'il est en face aussi
    if antagonist != nobody [
      ask antagonist [
       set enface? abs (heading - aheading) = 180
      ]
    ]
  ]

  if enface?[

    let aclass [class] of antagonist

    ifelse item aclass cache_type = 0[
      set numinc (numinc + 1)
      set leffort effort
      set lprofit profit

      set aeffort [effort] of antagonist * bruiter
      set profit (func-profit effort aeffort)

      ; On met à jour les listes selon le type
      set list_profits_par_type replace-item aclass list_profits_par_type (item aclass list_profits_par_type + profit)
      set list_interactions_par_type replace-item aclass list_interactions_par_type (item aclass list_interactions_par_type + 1)

      ;set list_profits_par_type replace-item aclass list_profits_par_type (item aclass list_profits_par_type + (profit - lprofit))

      set cumprofit (cumprofit + profit)
      set cumeffort (cumeffort + effort)

      let prof profit
      ask antagonist [set aprofit prof]

      set neffort neffort + aeffort
      set nprofit nprofit + aprofit

      work-agent

      ; Si le profit obtenu avec le type n'est pas suffisant, on l'ajoute au cache des types ignorés
      ;if (item aclass list_profits_par_type < 0) and ((item aclass list_interactions_par_type) > min_interactions_avec_type)[
      if ((item aclass list_profits_par_type) / (item aclass list_interactions_par_type) < profit_voulu) and ((item aclass list_interactions_par_type) > min_interactions_avec_type)[
        set cache_type replace-item aclass cache_type 1
      ]
    ]
    [
      print sentence sentence "Type ignoré:" aclass sentence "Par: " class
      print sentence "Types ignorés:" cache_type
    ]
  ]

  if Decouragement?[
    set nb_sans_interaction nb_sans_interaction + 1
    if nb_sans_interaction > limite_sans_interaction [
      set effort effort * 0.999
    ]
    if enface?[
      set nb_sans_interaction 0
      set effort effort * 1.001
    ]
  ]

end

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
; LIMITATION DES RENCONTRES D'UN AGENT ;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

; Pas de changement pour le go

to go_limitation_rencontre
  ask agents[
    move-agent
    game_limitation_rencontre
    update-agent
  ]
  plotter_effort
  tick
end

to game_limitation_rencontre
  let antagonist nobody
  let enface? false

  let aheading heading
  if patch-ahead 1 != nobody
  [
    set antagonist one-of turtles-on patch-ahead 1
    ; On demande a l'agent en face s'il est en face aussi
    if antagonist != nobody [
      ask antagonist [
       set enface? abs (heading - aheading) = 180
      ]
    ]
  ]

  if enface?[

    let id [who] of antagonist

    ifelse item id list_rencontres <= max_rencontres[
      set numinc (numinc + 1)
      set leffort effort
      set lprofit profit

      set aeffort [effort] of antagonist * bruiter
      set profit (func-profit effort aeffort)

      set cumprofit (cumprofit + profit)
      set cumeffort (cumeffort + effort)

      let prof profit
      ask antagonist [set aprofit prof]

      set neffort neffort + aeffort
      set nprofit nprofit + aprofit

      work-agent

      set list_rencontres replace-item id list_rencontres (item id list_rencontres + 1)

    ]
    [
     ;print sentence sentence "Agent " who sentence " a ignoré " id
    ]
  ]

  if Decouragement?[
    set nb_sans_interaction nb_sans_interaction + 1
    if nb_sans_interaction > limite_sans_interaction [
      set effort effort * 0.999
    ]
    if enface?[
      set nb_sans_interaction 0
      set effort effort * 1.001
    ]
  ]

end
@#$#@#$#@
GRAPHICS-WINDOW
607
13
957
384
-1
-1
34.0
1
10
1
1
1
0
1
1
1
0
9
0
9
0
0
1
ticks
30.0

SLIDER
178
130
351
163
nb_null
nb_null
0
nb_agents_max
10
10
1
NIL
HORIZONTAL

SLIDER
178
169
350
202
nb_shrinking
nb_shrinking
0
nb_agents_max
10
10
1
NIL
HORIZONTAL

SLIDER
179
213
351
246
nb_replicator
nb_replicator
0
nb_agents_max
10
10
1
NIL
HORIZONTAL

SLIDER
180
251
352
284
nb_rational
nb_rational
0
nb_agents_max
10
10
1
NIL
HORIZONTAL

SLIDER
180
290
355
323
nb_profcomparator
nb_profcomparator
0
nb_agents_max
10
10
1
NIL
HORIZONTAL

SLIDER
179
328
354
361
nb_high
nb_high
0
nb_agents_max
10
10
1
NIL
HORIZONTAL

SLIDER
181
369
353
402
nb_avgrational
nb_avgrational
0
nb_agents_max
10
10
1
NIL
HORIZONTAL

SLIDER
181
411
353
444
nb_imitator
nb_imitator
0
nb_agents_max
10
10
1
NIL
HORIZONTAL

SLIDER
183
493
353
526
nb_effcomparator
nb_effcomparator
0
nb_agents_max
10
10
1
NIL
HORIZONTAL

SLIDER
181
453
353
486
nb_averager
nb_averager
0
nb_agents_max
10
10
1
NIL
HORIZONTAL

BUTTON
410
139
548
172
Setup de base
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

BUTTON
410
182
548
222
Go de base
go
T
1
T
OBSERVER
NIL
NIL
NIL
NIL
0

SLIDER
80
609
255
642
effort_min
effort_min
0
1.9
0
0.1
1
NIL
HORIZONTAL

SLIDER
80
649
252
682
effort_max
effort_max
0.1
2
2
0.1
1
NIL
HORIZONTAL

SLIDER
81
780
253
813
noise
noise
0
50
0
1
1
NIL
HORIZONTAL

SLIDER
76
690
248
723
start_effort
start_effort
0
2
0
0.1
1
NIL
HORIZONTAL

PLOT
970
14
1645
383
Effort moyen
Temps
Effort
0.0
2.1
0.0
2.1
true
true
"" ""
PENS

SWITCH
80
734
221
767
randomstart?
randomstart?
0
1
-1000

TEXTBOX
77
138
149
176
Null effort
15
95.0
1

TEXTBOX
38
178
151
197
Shrinking effort
15
25.0
1

TEXTBOX
68
215
157
255
Replicators
15
45.0
1

TEXTBOX
89
259
150
278
Rational
15
65.0
1

TEXTBOX
17
300
155
319
Profit comparator
15
85.0
1

TEXTBOX
71
336
153
355
High effort
15
15.0
1

TEXTBOX
28
377
152
396
Average rational
15
135.0
1

TEXTBOX
35
420
150
439
Winner imitator
15
115.0
1

TEXTBOX
23
501
158
520
Effort comparator
15
35.0
1

TEXTBOX
79
457
154
476
Averager
15
5.0
1

CHOOSER
408
80
567
125
choisir_affichage
choisir_affichage
"Classe seule" "Effort seul" "Classe et effort"
2

TEXTBOX
59
10
350
70
NE PAS METTRE PLUS DE 6 TYPES A LA FOIS. \nNE PAS METTRE PLUS DE 100 AGENTS SUR UN TERRAIN 10x10 (PRECISER LE NOMBRE DANS nb_agents_max)
12
0.0
1

PLOT
662
409
1351
762
Impact des agents high effort
Pourcentage d'agents high effort
Effort moyen
0.0
1.0
0.0
2.1
true
true
"" ""
PENS

BUTTON
426
693
567
726
Setup figures 6 et 7
setup_figure_6_7
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
155
179
175
212
1
16
0.0
1

TEXTBOX
155
217
174
237
2
16
0.0
1

TEXTBOX
157
258
182
278
3
16
0.0
1

TEXTBOX
156
299
171
319
4
16
0.0
1

TEXTBOX
158
336
173
356
5
16
0.0
1

TEXTBOX
159
377
176
399
6
16
0.0
1

TEXTBOX
158
417
179
436
7
16
0.0
1

TEXTBOX
159
458
183
486
8
16
0.0
1

TEXTBOX
161
501
176
521
9
16
0.0
1

TEXTBOX
155
139
170
159
0
16
0.0
1

TEXTBOX
388
410
664
563
Choisir le type dont l'effort doit être affiché en fonction du pourcentage d'agents high effort \nChoisir le nombre de ticks (il y aura nb_ticks_high * simulations)\nAppuyer sur Setup puis Go pour obtenir le graphe\nChoisir le nombre de ticks (il y aura nb_ticks_high * simulations)
13
0.0
1

CHOOSER
423
576
571
621
type_impacte_high
type_impacte_high
"null effort" "shrinking effort" "replicator" "rational" "profit comparator" "average rational" "winner imitator" "averager" "effort comparator"
8

BUTTON
426
734
550
767
Go figures 6 et 7
go_figure_6_7
T
1
T
OBSERVER
NIL
NIL
NIL
NIL
0

INPUTBOX
425
628
520
688
nb_ticks_high
5000
1
0
Number

BUTTON
419
921
560
954
Setup effet du bruit
setup_effet_bruit
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
418
962
542
995
Go effet du bruit
go_effet_bruit
T
1
T
OBSERVER
NIL
NIL
NIL
NIL
0

INPUTBOX
419
852
509
912
nb_ticks_noise
1000
1
0
Number

PLOT
662
764
1351
1106
Effet du bruit
Effort moyen
Temps
0.0
1.0
0.0
2.1
true
true
"" ""
PENS

BUTTON
417
305
518
338
Clear All plot
clear-all-plots
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
178
66
339
126
nb_agents_max
100
1
0
Number

TEXTBOX
13
554
406
603
Sliders sur les valeurs d'effort et le bruit\nMettre randomstart sur On pour donner une valeur initiale d'effort aléatoire comprise entre effort_min et effort_max
12
0.0
1

TEXTBOX
414
281
564
299
Vider tous les graphes
12
0.0
1

TEXTBOX
400
790
641
836
Choisir le nombre de ticks pour voir l'effet du bruit sur une population d'agents winner imitator
12
0.0
1

TEXTBOX
1356
457
1867
532
- Motivation / Découragement:\nSi un agent n'a pas eu d'interactions depuis un certain temps, son effort décroît automatiquement\nMettre Decouragement? à On, choisir une limite de ticks sans interaction et lancer la simulation de base
12
0.0
1

INPUTBOX
1555
534
1716
594
limite_sans_interaction
55
1
0
Number

TEXTBOX
1359
789
1871
879
- Limitation des interactions avec un certain type d'agent:\nSi un agent a rencontré trop d'agents de même type qui ne lui ont pas donné un profit satisfaisant, il ne joue plus avec eux\nMettre Limitation_type? à On\nChoisir un nombre d'interactions minimal avant de commencer à limiter, et une valeur de profit désirée par les agents
12
0.0
1

TEXTBOX
1357
614
1870
674
- Limitation des interactions avec des agents trop rencontrés:\nSi un agent a rencontré un autre agent trop souvent, il ne joue plus avec lui\nMettre Limitation_rencontres? à On \nChoisir une valeur maximale de rencontres avec un même agent
12
0.0
1

TEXTBOX
1489
417
1639
441
EXTENSIONS:
20
0.0
1

SWITCH
1357
550
1537
583
Decouragement?
Decouragement?
0
1
-1000

SWITCH
1355
904
1526
937
Limitation_type?
Limitation_type?
1
1
-1000

SWITCH
1358
685
1567
718
Limitation_rencontres?
Limitation_rencontres?
1
1
-1000

INPUTBOX
1581
686
1742
746
max_rencontres
1000
1
0
Number

BUTTON
1355
950
1516
983
Go Limitation type
go_limitation_type
T
1
T
OBSERVER
NIL
NIL
NIL
NIL
0

INPUTBOX
1540
963
1701
1023
profit_voulu
3
1
0
Number

INPUTBOX
1540
896
1701
956
min_interactions_avec_type
100
1
0
Number

BUTTON
1358
729
1567
762
Go Limitation rencontres
go_limitation_rencontre
T
1
T
OBSERVER
NIL
NIL
NIL
NIL
0

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
NetLogo 5.3
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
