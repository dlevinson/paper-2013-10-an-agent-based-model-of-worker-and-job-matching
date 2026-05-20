;ABODE (Agent Based Orign-Destination Estimation)
;last edited 04/02/2011
;Nebiyou Y. Tilahun
breed [jobcenters jobcenter]
breed [agents agent ]
breed [emp_positions emp_position] ;; jobs are places of employment held by many people
breed [firms firm]
;breed [area1 area2 area3 area4]

agents-own [curr_npv htenr wtenr workloc trvldist salary jbpath talent1 talent2 talent3 
skill-class rand-selector activew? employed? candidate-jobs minpay expected-pay vot-based-on-expectation
offers-considered  best-offer best-offer-travel-cost jobcount wxcor wycor search-effort
vot vot-best-offer contact_used contact_influential contact_used_current_job unemp_duration p-emp
wtenr0 wtenr1 wtenr2 wtenr3 wtenr4 wtenr5 wtenr6 wtenr7 wtenr8 beta1w myjobcenter effort]

emp_positions-own [pos-jobcenter yrs-pos-open criteria1 criteria2 criteria3 job-class match pay offer-pay employee open? wfirm candidate-list chosen-candidate emp_logit_denom emp-rand-selector]

firms-own [location firmsize firm-jobcenter]

patches-own [access price job_dist area]

globals [z sum-curr-npv sum-prev-npv ratio-prev-curr-npv] ;empty-pos-annual-increase annual-wage-increase unemp_askng_pay_cut]

to setup
  ca
;  random-seed 876956587564
  setup-patches
  if (distributed_employment = false)[
  setup-jobcenters]
  setup-firms 
  setup-emp_postions
  calc-firm-size
  setup-agents
  move-agents-to-homes
  set sum-curr-npv 1
  set sum-prev-npv 1
;  set empty-pos-annual-increase 0
;  set annual-wage-increase 0
;  set unemp_askng_pay_cut 0
;  random-seed (random-float 1000000000000000)
end


;;;;;;;;;;;;;;;;;;;;;;;;;;
;setup job centers and patches
;;;;;;;;;;;;;;;;;;;;;;;;;;
to setup-jobcenters
    create-jobcenters njob-centers
  [
    if (njob-centers = 1) [move-to patch 0 0]
;    [move-to one-of patches with [not any? turtles-here and min ([distance myself] of other jobcenters) > 25 ]]
    ask jobcenter 0 [move-to patch 15 15]
    ask jobcenter 1 [move-to patch -15 15]
    ask jobcenter 2 [move-to patch -15 -15]
    ask jobcenter 3 [move-to patch 15 -15]
    set color red
    set shape "circle"
    set size 2
  ]
end

to setup-patches
  ask   patches  [ set pcolor   green ]
  ask patches with [pxcor < 0 and pycor < 0] [set area 1]
  ask patches with [pxcor <= 0 and pycor >= 0] [set area 2]
  ask patches with [pxcor > 0 and pycor > 0] [set area 3]
  ask patches with [pxcor > 0 and pycor < 0] [set area 4]
end

;;;;;;;;;;;;;;;;;;;;;;;;;;
;setup firms
;;;;;;;;;;;;;;;;;;;;;;;;;;
to setup-firms
  create-firms nfirms
  ask firms[
  ifelse (distributed_employment = false)

  [set firm-jobcenter one-of jobcenters
  move-to [patch-here] of firm-jobcenter]; patches with [any? jobcenters-here]]
  [move-to one-of patches with [not any? turtles-here]]
  set color red

  ]
end


;;;;;;;;;;;;;;;;;;;;;;;;;;
;setup employment locations
;;;;;;;;;;;;;;;;;;;;;;;;;;
to setup-emp_postions
  create-emp_positions floor (emp_position_multiplier * agent-density * .01 * count patches ) 
  ask emp_positions [
;  ifelse (distributed_employment = false) 
  set wfirm one-of firms 
  move-to [patch-here] of wfirm
  set pos-jobcenter [firm-jobcenter] of wfirm
;  [move-to one-of patches with [not any? turtles-here]]
;    ifelse (random-float 1 < 0.5) [set criteria1 1] [set criteria1 0]
;    ifelse (random-float 1 < 0.3) [set criteria2 1] [set criteria2 0]
;    ifelse (random-float 1 < 0.2) [set criteria3 1] [set criteria3 0]
;  set job-class criteria1 * 1 + criteria2 * 2 + criteria3 * 4 ;each combination of criteria 1 - 3 gives a unique job-class (8 in all job classes)
  set job-class random n-job-classes 
  set employee nobody
  set candidate-list nobody
  set chosen-candidate nobody
  set yrs-pos-open 0
  set offer-pay ((random (10000)  + ((job-class + 1) * 10000)) * wage-dispersion) + ((1 - wage-dispersion) * (job-class + 1) * 10000)
  set open? false
  set match 999
  set color red
  set size 0.5
  
  if (distributed_employment = false) [
  if (equalize-jobs-at-jc = true) [
  let n_emp_per (count emp_positions / count jobcenters)
  ask emp_positions [move-to patch 0 0]
  ask n-of n_emp_per emp_positions with [patch-here = patch 0 0] [move-to [patch-here] of jobcenter 0
                                                                  set pos-jobcenter jobcenter 0]
  ask n-of n_emp_per emp_positions with [patch-here = patch 0 0] [move-to [patch-here] of jobcenter 1
                                                                set pos-jobcenter jobcenter 1]
  ask n-of n_emp_per emp_positions with [patch-here = patch 0 0] [move-to [patch-here] of jobcenter 2
                                                                  set pos-jobcenter jobcenter 2]
  ask emp_positions with [patch-here = patch 0 0] [move-to [patch-here] of jobcenter 3
                                                                  set pos-jobcenter jobcenter 3]
  ]
  ]
  ]
  
end

;;;;;;;;;;;;;;;;;;;;;;;;;;
;calculate firm size
;;;;;;;;;;;;;;;;;;;;;;;;;;
to calc-firm-size
 ask firms[
  set firmsize count emp_positions with [wfirm = myself]
 ]
end

;;;;;;;;;;;;;;;;;;;;;;;;;;
;setup agents
;;;;;;;;;;;;;;;;;;;;;;;;;;
to setup-agents
  create-agents floor (agent-density * .01 * count patches )
  ask agents
  [  set wtenr 0
    set jobcount 0
;    ifelse (random-float 1 < 0.5) [set talent1 1] [set talent1 0]
;     ifelse (random-float 1 < 0.3) [set talent2 1] [set talent2 0]
;     ifelse (random-float 1 < 0.2) [set talent3 1] [set talent3 0]
;    set skill-class talent1 * 1 + talent2 * 2 + talent3 * 4 ;each comination of talent 1 - 3 gives a unique skill-class (8 in all skill classes)
    set skill-class random n-job-classes
    set activew? false
    set employed? false
    set workloc nobody
    set offers-considered nobody
;    set minpay (talent1 * 10000 + talent2 * 20000 + talent3 * 40000) * 0.75
    set minpay  ((random (5000) + (skill-class + 1) * 5000) * wage-dispersion) + ((1 - wage-dispersion) * (skill-class + 1) * 5000)
    set expected-pay minpay
    set curr_npv minpay 
    set best-offer nobody
    set best-offer-travel-cost 0
    set candidate-jobs nobody
    set unemp_duration 0
    set shape "box"
    set color white
;    move-to one-of patches with [not any? turtles-here]
    move-to patch 0 0
    set size 0.5
    ]
end

to move-agents-to-homes
    let v1 floor (agent-density * .01 * count patches) / 4
    let v2 floor (agent-density * .01 * count patches ) - (3 * v1)
    ask n-of v1 agents with [patch-here = patch 0 0] [move-to one-of patches with [area = 1 and not any? turtles-here]]
    ask n-of v1 agents with [patch-here = patch 0 0] [move-to one-of patches with [area = 2 and not any? turtles-here]]
    ask n-of v1 agents with [patch-here = patch 0 0] [move-to one-of patches with [area = 3 and not any? turtles-here]]
    ask n-of v2 agents with [patch-here = patch 0 0] [move-to one-of patches with [area = 4 and not any? turtles-here]]
end


;;;;;;;;;;;;;;;;;;;;;;;;;;
;go procedure
;;;;;;;;;;;;;;;;;;;;;;;;;;
to go
if show_h_w_links [
clear-links
if (ticks > 0) [ask agents with [employed? = True] [create-link-with workloc [set color white]]] ]
if (ticks = 500) [stop]
if (ticks > 50) [if (count agents with [wtenr < 15] = 0 and count agents with [employed? = false] = 0) [stop]]
reset-agents
reset-emp_positions
update-emp_positions
update-agents
look-for-work
ask agents with [activew? = true] [sample-open-jobs]
ask emp_positions with [open? = true] [accept-apps-choose-candidate] 
set z no-turtles
set z [chosen-candidate] of emp_positions with [open? = true] 
ask agents with [member? self z] [determine-best-offer]
calculate-match
if (count agents with [employed? = true] > 0) [do-plots]
tick
end


to update-z
  set z no-turtles
  set z [chosen-candidate] of emp_positions with [open? = true]
end
;;;;;;;;;;;;;;;;;;;;;;;;;;
;Calculate aggregate NPV
;;;;;;;;;;;;;;;;;;;;;;;;;;
to calc-agg-npv
set sum-prev-npv sum-curr-npv
set sum-curr-npv sum [curr_npv] of agents
set ratio-prev-curr-npv ((sum-curr-npv - sum-prev-npv) / sum-prev-npv)
end

;;;;;;;;;;;;;;;;;;;;;;;;;;
;reset agents
;;;;;;;;;;;;;;;;;;;;;;;;;;
to reset-agents
ask agents[
set offers-considered nobody
set best-offer nobody
set best-offer-travel-cost 0
set candidate-jobs nobody
set vot-best-offer 0
set contact_used 0
set contact_influential 0
]
end

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;reset employment positions
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;; ;;;;;;;;;;;;;;;;;;

to reset-emp_positions
ask emp_positions [
set candidate-list nobody
set chosen-candidate nobody
]
end
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;update employment positions and agents
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
to update-emp_positions 
ask emp_positions [
      ifelse (employee = nobody) 
      [set open? true
      set pay 0
      set match -999] 
      [set open? false]
      if (ticks > 10)[
      ifelse (open? = true) [
              set yrs-pos-open (yrs-pos-open + (1 / 12))
              set offer-pay (offer-pay * (1 + (wage-dispersion * random-float empty-pos-annual-increase / 12)) ^ (med_tenure - yrs-pos-open))
              ]
              [
              let y [wtenr] of employee 
              ifelse (y > med_tenure) [set pay pay] [set pay (pay * (1 + (wage-dispersion * random-float annual-wage-increase / 12)) ^ (med_tenure - y))]
              set [salary] of employee pay
             ; ]              
              ]
      ]]
end

to update-agents
  ask agents [
         set search-effort min-search-effort + random max-search-effort  ; )); could also be made f(age, unemp_duration, njobs)  
;         set search-effort max (list min-search-effort (min (list unemp_duration max-search-effort))); could also be made f(age, unemp_duration, njobs)  
  if (ticks > 1)[
  if (activew? = true)[
              ifelse (employed? = true) [set expected-pay (salary *  (1 + random-float annual-wage-increase))]
                                        [set unemp_duration unemp_duration + 1
                                         set curr_npv minpay 
                                         set expected-pay max (list (expected-pay - random unemp_askng_pay_cut * expected-pay) minpay)]
                                                       ]]

  if (employed? = true) [
            set wtenr (wtenr + (1 / 12))
            set vot (vot_prop_of_wage * salary / (52 * 40)) 
            set curr_npv (salary - (vot * (trvldist / trvlspeed) * 2 * 52 * 5))
         ;
            if (curr_npv < minpay)[
              let k [workloc] of self
              set [open?] of k true
              set [pay] of k 0
              set [employee] of k nobody
              set [yrs-pos-open] of k 0
              set [match] of k -999
              set employed? false
              set workloc nobody
              set salary 0
              set activew? true
              ]
            ]  
        ]
 end



;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;decide to look for work or not
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;currently if a person was looking for work in the last step and hasn't found one, they go on looking for work in the next step as well
;(might be reasonable for them to stop at some time)
;if tenure is greater than some given value, then the search probability is greater than 0.5
to look-for-work
    ask agents [
    ifelse (employed? = false) [set activew? true] [ifelse (random-float 1 < ( 1 - (exp (wtenr  - med_tenure)/(1 + exp (wtenr - med_tenure))))) [set activew? true] [set activew? false]]
    ]
end
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;sample among open positions 
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;search effort can not exceed the number of openings
to sample-open-jobs
    ifelse (count emp_positions with [open? = true] = 0 and count agents with [wtenr < 15] = 0)
    [stop]
      [
    let x count emp_positions with [open? = true and abs (job-class - [skill-class] of myself) <= matching_precision]
    ifelse (x > search-effort) [set effort search-effort] [set effort x]
    let temp-candidate-jobs emp_positions with [open? = true and (abs (job-class - [skill-class] of myself) <= matching_precision)]
    set candidate-jobs n-of effort temp-candidate-jobs 
    ifelse (random-float 1 < prop-using-contacts) [set contact_used 1][set contact_used 0]
    ifelse (contact_used = 1)[
    ifelse (random-float 1 < contact_influential-prop)[set contact_influential 1][set contact_influential 0]][set contact_influential 0]
      ]
end

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;Employment positions...accept applications and make offer
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
to accept-apps-choose-candidate    
      let temp_agentset agents with [activew? = true and skill-class >= ([job-class] of myself - contact_influential)]
      set candidate-list temp_agentset with [member? myself candidate-jobs = true] 
      set chosen-candidate one-of candidate-list with [skill-class + contact_influential >= [job-class] of myself]
end

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;Agents ...  Evaluate offers and accept/reject offers
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
to determine-best-offer
      if (jobcount = 0) [set wtenr0  ticks / 12]
      set offers-considered emp_positions with [chosen-candidate = myself ] 
       set vot-based-on-expectation (vot_prop_of_wage * expected-pay / (52 * 40))
       set beta1w (-1 * vot-based-on-expectation * beta2 )
      ifelse (agents_logit = false) 
      [
;      set best-offer max-one-of offers-considered [offer-pay - (vot_prop_of_wage * (offer-pay / (52 * 40)) * (distance myself * factor *  0.0006213711 / trvlspeed) * 2 * 52 * 5)]
;  set offers-considered emp_positions with [chosen-candidate = myself and offer-pay >= [expected-pay] of myself] 
;      set best-offer min-one-of offers-considered [distance myself] with [offer-pay >= expected-pay]
      set best-offer max-one-of offers-considered [offer-pay]
      ]
      [ 
        ifelse (count emp_positions with [chosen-candidate = myself] = 1 )
          [
            set best-offer one-of emp_positions with [chosen-candidate = myself]
          ] 
          [
            set p-emp emp_positions with [member? self [offers-considered] of myself]
;            let logit-denom sum [exp (beta1 * ln (0.05 + (distance myself * factor *  0.0006213711 / trvlspeed)) + beta2 * ln (offer-pay / (52 * 40)))] of p-emp
;            let logit-denom sum ([exp (beta1 * (60 * distance myself * factor *  0.0006213711 / trvlspeed) + beta2 * ((offer-pay - [expected-pay] of myself) / (52 * 40)))] of p-emp)
;            let logit-denom sum ([exp (beta1 * ((60 * distance myself * factor *  0.0006213711 - [trvldist] of myself) / trvlspeed) + beta2 * ((offer-pay - [salary] of myself) / (52 * 40)))] of p-emp)
            let logit-denom sum ([exp ([beta1w] of myself * ((2 *  distance myself) / trvlspeed) + beta2 * (offer-pay / (52 * 5)))] of p-emp)
            set rand-selector random-float logit-denom
            set best-offer selected-best-offer]
          ;;;;;
          ]
      if (best-offer != nobody) [
         set best-offer-travel-cost ([distance myself] of best-offer)
         set vot-best-offer (vot_prop_of_wage * [offer-pay] of best-offer / (52 * 40))
         set vot-based-on-expectation (vot_prop_of_wage * expected-pay / (52 * 40))
         if ( ([offer-pay] of best-offer - (vot-best-offer * (best-offer-travel-cost / trvlspeed) * 2 * 52 * 5))  > curr_npv)[
;          if ( [offer-pay] of best-offer > curr_npv)[
              if (workloc != nobody) [ 
                  let k [workloc] of self
                  set [open?] of k true
                  set [pay] of k 0
                  set [employee] of k nobody
                  set [yrs-pos-open] of k 0
                  set [match] of k 999
;                  if (jobcount = 1) [set wtenr1  ticks - wtenr0]
;                  if (jobcount = 2) [set wtenr2  ticks - wtenr0 - wtenr1]
;                  if (jobcount = 3) [set wtenr3  ticks - wtenr0 - wtenr1 - wtenr2 ]
;                  if (jobcount = 4) [set wtenr4  ticks - wtenr0 - wtenr1 - wtenr2 - wtenr3]
;                  if (jobcount = 5) [set wtenr5  ticks - wtenr0 - wtenr1 - wtenr2 - wtenr3 - wtenr4]
;                  if (jobcount = 6) [set wtenr6  ticks - wtenr0 - wtenr1 - wtenr2 - wtenr3 - wtenr4 - wtenr5]
;                  if (jobcount = 7) [set wtenr7  ticks - wtenr0 - wtenr1 - wtenr2 - wtenr3 - wtenr4 - wtenr5 - wtenr6]
;                  if (jobcount = 8) [set wtenr8  ticks - wtenr0 - wtenr1 - wtenr2 - wtenr3 - wtenr4 - wtenr5 - wtenr6 - wtenr7]
                  ]
            set workloc best-offer
;            set wtaz [wfirm] of workloc
            set wtenr 0
            ifelse (expected-pay < [offer-pay] of best-offer)
                [set salary [offer-pay] of best-offer]
                [
                  let p1 random-float 1
                  set salary (p1 * [offer-pay] of best-offer + (1 - p1) * expected-pay)
                ]
            set trvldist best-offer-travel-cost
            set myjobcenter [pos-jobcenter] of workloc
            set vot (vot_prop_of_wage * salary / (52 * 40))
            set curr_npv (salary - (vot * (trvldist / trvlspeed) * 2 * 52 * 5)); may reduce the number of days travelled to work but won't affect outcome
            set contact_used_current_job contact_used
            set jobcount jobcount + 1
            set activew? false
            set employed? true
            set unemp_duration 0 
            let q [workloc] of self
            set [pay] of q salary
            set [employee] of q self
            set [open?] of q false
            set [chosen-candidate] of q  nobody
            set [yrs-pos-open] of q 0
            set wxcor [xcor] of q  
            set wycor [ycor] of q
            set z agents with [member? self z and activew? = true]  
          ]]
end

to-report selected-best-offer
   set best-offer nobody
   ask emp_positions with [member? self [p-emp] of myself]; [offers-considered] of myself]
     [
       if ([best-offer] of myself = nobody)
;       [ifelse ( exp (beta1 * ((60 * distance myself * factor *  0.0006213711 - [trvldist] of myself) / trvlspeed) + beta2 * ((offer-pay - [salary] of myself) / (52 * 40))) > [rand-selector] of myself)
       [ifelse ( exp ([beta1w] of myself * (2 * 60 * distance myself / trvlspeed) + beta2 * (offer-pay / (52 * 5))) > [rand-selector] of myself)
       [set [best-offer] of myself self]
       [set [rand-selector] of myself ([rand-selector] of myself - ( exp ([beta1w] of myself * ((2 * 60 * distance myself)  / trvlspeed) + beta2 * ((offer-pay) / (52 * 5))))) ]
    ]]
    report best-offer    
end


to calculate-match
ask emp_positions[
      let v employee
      ifelse (open? = false)
          [set match ([skill-class] of v - job-class)]
          [set match -999]]
end


to do-plots
set-current-plot "distance distribution all"
  plot-pen-reset
  set-plot-x-range 0 floor (max [trvldist] of agents + 2)
  histogram [trvldist] of agents with [employed? = true]
;  histogram [jobcount] of agents 

set-current-plot "salary distribution all"
  plot-pen-reset
  set-plot-x-range 0 floor (max [expected-pay] of agents + 2)
  histogram [expected-pay] of agents with [employed? = true]



set-current-plot "salary"
  set-current-plot-pen "mean" 
  plot mean [salary] of agents with [employed? = true]
  set-current-plot-pen "median" 
  plot median [salary] of agents with [employed? = true]
  set-current-plot-pen "max" 
  plot max [salary] of agents with [employed? = true]
  set-current-plot-pen "min" 
  plot min [salary] of agents with [employed? = true]


set-current-plot "distance"
  set-current-plot-pen "mean" 
  plot mean [trvldist] of agents with [employed? = true]
  set-current-plot-pen "median" 
  plot median [trvldist] of agents with [employed? = true]
  set-current-plot-pen "max" 
  plot max [trvldist] of agents with [employed? = true]
  set-current-plot-pen "min" 
  plot min [trvldist] of agents with [employed? = true]
  
  
;set-current-plot "beta1w_plot"
;  plot-pen-reset
;  set-current-plot-pen "default"
;  histogram [beta1w] of agents
end




@#$#@#$#@
GRAPHICS-WINDOW
355
67
894
627
30
30
8.67213115
1
10
1
1
1
0
0
0
1
-30
30
-30
30
1
1
1
ticks

CC-WINDOW
5
764
1351
859
Command Center
0

BUTTON
354
636
555
669
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

BUTTON
561
637
727
670
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

SLIDER
29
330
277
363
matching_precision
matching_precision
0
3
0
1
1
NIL
HORIZONTAL

BUTTON
735
637
895
670
go-once
go
NIL
1
T
OBSERVER
NIL
NIL
NIL
NIL

SLIDER
29
467
250
500
min-search-effort
min-search-effort
0
40
3
1
1
NIL
HORIZONTAL

SLIDER
30
80
199
113
agent-density
agent-density
0
100
8
1
1
%
HORIZONTAL

SLIDER
205
80
332
113
njob-centers
njob-centers
4
4
4
1
1
NIL
HORIZONTAL

SWITCH
33
195
218
228
distributed_employment
distributed_employment
1
1
-1000

SLIDER
204
118
329
151
nfirms
nfirms
4
100
32
4
1
NIL
HORIZONTAL

MONITOR
1048
214
1161
259
mean wrk-tenure
mean [wtenr] of agents with [employed? = true] 
1
1
11

MONITOR
931
467
1051
512
mean h2w distance
mean [trvldist] of agents
1
1
11

MONITOR
931
262
1039
307
mean salary
mean [salary] of agents with [employed? = true]
1
1
11

MONITOR
1048
264
1161
309
# srchng 4 wrk
count agents with [activew? = true]
1
1
11

MONITOR
1050
140
1176
185
# Jobs
count emp_positions
1
1
11

SLIDER
30
118
198
151
emp_position_multiplier
emp_position_multiplier
0
3
1.2
.1
1
NIL
HORIZONTAL

PLOT
931
520
1131
670
distance distribution all
NIL
NIL
0.0
10.0
0.0
10.0
true
false
PENS
"distance" 1.0 1 -16777216 true

PLOT
1102
312
1275
440
salary
NIL
NIL
0.0
10.0
0.0
10.0
true
false
PENS
"mean" 1.0 0 -2674135 true
"median" 1.0 0 -8630108 true
"max" 1.0 0 -13345367 true
"min" 1.0 0 -13345367 true

PLOT
1142
519
1342
672
distance
NIL
NIL
0.0
10.0
0.0
10.0
true
false
PENS
"mean" 1.0 0 -2674135 true
"max" 1.0 0 -13345367 true
"min" 1.0 0 -13345367 true
"median" 1.0 0 -10899396 true

MONITOR
931
212
1039
257
Unemployed %
100 * count agents with [employed? = false] / count agents
1
1
11

MONITOR
1171
214
1305
259
Average Jobs Taken
mean [jobcount] of agents
2
1
11

SLIDER
32
234
219
267
trvlspeed
trvlspeed
0
60
45
1
1
mph
HORIZONTAL

MONITOR
933
140
1044
185
NIL
count agents
17
1
11

SLIDER
29
538
251
571
prop-using-contacts
prop-using-contacts
0
1
0
0.01
1
NIL
HORIZONTAL

SLIDER
29
575
252
608
contact_influential-prop
contact_influential-prop
0
1
0
0.01
1
NIL
HORIZONTAL

PLOT
931
311
1094
440
salary distribution all
NIL
NIL
0.0
10.0
0.0
10.0
true
false
PENS
"default" 2500.0 1 -16777216 true

SLIDER
174
652
302
685
med_tenure
med_tenure
1
10
6
1
1
NIL
HORIZONTAL

SLIDER
30
370
276
403
empty-pos-annual-increase
empty-pos-annual-increase
0
.1
0.02
.01
1
NIL
HORIZONTAL

SLIDER
31
408
277
441
annual-wage-increase
annual-wage-increase
0
.1
0.01
.01
1
NIL
HORIZONTAL

SLIDER
29
502
250
535
max-search-effort
max-search-effort
1
40
6
1
1
NIL
HORIZONTAL

SLIDER
175
694
305
727
beta2
beta2
0
3
1
0.1
1
NIL
HORIZONTAL

TEXTBOX
9
273
232
301
Job related settings
11
0.0
1

TEXTBOX
1000
95
1150
113
Simulation Monitors
14
0.0
1

SLIDER
30
613
256
646
unemp_askng_pay_cut
unemp_askng_pay_cut
0
0.1
0
0.01
1
NIL
HORIZONTAL

SLIDER
26
692
167
725
vot_prop_of_wage
vot_prop_of_wage
0
1
1
.1
1
NIL
HORIZONTAL

SWITCH
27
652
167
685
agents_logit
agents_logit
0
1
-1000

SLIDER
153
290
274
323
wage-dispersion
wage-dispersion
0
1
0
1
1
NIL
HORIZONTAL

BUTTON
517
676
654
709
Clear links
clear-links
NIL
1
T
OBSERVER
NIL
NIL
NIL
NIL

SLIDER
30
290
146
323
n-job-classes
n-job-classes
1
5
1
1
1
NIL
HORIZONTAL

SWITCH
31
158
219
191
equalize-jobs-at-jc
equalize-jobs-at-jc
0
1
-1000

BUTTON
356
717
511
750
show-zones
if (distributed_employment = false)[\nask patches with [area = 1][set pcolor green]\nask patches with [area = 2][set pcolor brown]\nask patches with [area = 3][set pcolor green]\nask patches with [area = 4][set pcolor brown]]
NIL
1
T
OBSERVER
NIL
NIL
NIL
NIL

TEXTBOX
13
57
163
75
Model Setup Parameters
11
0.0
1

TEXTBOX
8
446
158
464
Worker related settings
11
0.0
1

SWITCH
355
676
511
709
show_h_w_links
show_h_w_links
0
1
-1000

BUTTON
517
716
655
749
hide-zones
ask patches [set pcolor green]
NIL
1
T
OBSERVER
NIL
NIL
NIL
NIL

TEXTBOX
917
119
1067
137
General
11
0.0
1

TEXTBOX
917
193
1067
211
Labor market
11
0.0
1

TEXTBOX
917
446
1067
464
Commute
11
0.0
1

TEXTBOX
250
14
1253
50
ABODE (Agent Based Model of Origin Destination Estimation)
30
0.0
1

BUTTON
661
676
790
709
Show links
ask agents with [employed? = True] [create-link-with workloc [set color white]]
NIL
1
T
OBSERVER
NIL
NIL
NIL
NIL

@#$#@#$#@
WHAT IS IT?
-----------
The model proposed here matches origins and destinations using employment search methods at the individual level.  The outcomes depend on skills of the searcher, compensation, travel preferences, the locations of employment opportunities, and the willingness of firms to employ the searcher. The geographic plain on which the modeling is undertaken contains both employment locations which may be flexibly arranged into one or multiple employment zones or be randomly distributed as well as residential locations. Firm and housing locations are assumed to be exogenous in the model.  Workers will search for employment from fixed home locations. 

The model contains both active agents which interact with one another through out the simulation and inactive agents which are mainly used to mark location and to house employment opportunities.The inactive agents in this model are job centers, where firms are located, and the firms where employment positions are housed. Job centers and firms are present to give structure to the location of employment opportunities.  Job centers (which may be one or many) house firms, and firms house employment opportunities.  The presence of job centers is optional. When job centers are not present firms can be distributed through out the modeled area randomly. All employment opportunities are housed within a firm to which they are randomly assigned. The active agents in this model are the workers and employment positions which interact with one another in determining job opportunities and pay scales, and negotiate agreeable arrangements for employment. Each of these agents are discussed below.


AGENTS
------------

Job Centers
The purpose of job centers is to house firms.  These are established as optional fields where a mono-centric,  poly-centric, or a city with distributed employment can be modeled in the the home-job matching process. The location of the job centers can be at any location on the plain that is being modeled, though when mono-centric models are considered the location has been fixed at the center of the geographic area.

Firms
Firms house employment locations. When job centers are present, firms can only locate in only one of the job centers.  Assignment of firms to job centers is done randomly at the start of the simulation. In the current model, once a firm chooses a location, it does not relocate. Employment locations are also assigned to the firm randomly. Once employment positions are assigned to them, firms know how big they are what types of positions they have. Though the number of employees at a particular firm may change, the number of positions that are available at each of the firms does not change throughout the simulation. %Currently however they are primarily used as containers that mark a geographic location for employment positions.

Employment Positions and Workers
Employment positions are housed in Firms.  Each employment position has characteristics that it requires fulfilled by potential employees (or a minimum skill set that is needed to be fulfilled).  The skill set required by any position is assigned as a randomly generated integer ranging from one to five. Each of these is assumed to be increasing in specialization and commands an average pay that is higher than the preceding level.  Each position is assumed to have an amount that it is willing to pay an employee.  At the start of the simulation, the pay that positions are willing to offer is assigned to the jobs by pulling from a uniform distribution whose mean is a function of the position's skill level. Alternatively, wage dispersion can be set to 0, leaving the wage to be only a function of the desired skill.

HOW IT WORKS
------------

At any given time, a positions can be open or taken (closed). When a position is open, it automatically advertises itself, and job seekers who encounter it can apply to occupy the position.  When a position is already occupied by a worker, it is not searchable and does not take any applications. Employment positions know how well applicants as well as the person occupying them matches the requirements of the job.  Each employment position acts as would a human resources department in real life, by accepting and screening applications as well as making offers, and negotiating a salary with qualified applicants. When they have difficulty attracting talent, positions increase their offer pay at each iteration.  

Workers start out randomly assigned to residential locations from which they search for jobs.  Workers residences are assumed to be stationary.  Each worker is randomly assigned a skill class similar to the job-classes for the employment positions.  At the start of the simulation all workers are seeking employment. They search for open positions that fit their skills and put in applications reporting their qualifications. Each worker is also assumed to have a minimum wage that they would want to accept any job offer.  Once the searcher is employed, their expected wage  will be set greater then or equal to their earnings at the time of search. 

Workers are assumed to have limited information on available positions that match their skills.  To find information, workers have to start searching for opportunities with some intensity $I$.  Different workers can have different search intensities that describes how many applications they put in at any given time slice. A worker only receives offers from those positions to which it has applied.  

Though skill matching is an important part of the model, workers can be allowed to apply to positions for which they are slightly under or over qualified.  Some portion of the searchers can also use a contact to gain access to employment. A proportion of these contacts are assumed to be influential and can leverage their position to increase the match between the applicant and the open position even though the match of skills to criteria may not be perfect (or perhaps better matches may be available).

The model allows for individuals to receive any number of offers at a given time given they have applied to the positions and the employer has selected as the best applicant for that position.  When several job offers are made to the respondent within a given iteration, the model assumes they arrive such that they can be compared against one another simultaneously.  Once an offer is made to a worker, searchers choose which offer is the best. The selection process may be specified so that a deterministic decision framework is adopted where the highest offer is chosen, or a probabilistic decision is made based on travel time and salary considerations within an Expected Utility framework.  They then decide to accept or reject the offer by comparing the best offer selection to their current situation.  Decisions are also assumed to be made only on the basis of offers and current wages or reservation wages.  Workers do not know what the likelihood of offers in the next time slice will be.  Offers that improve the net present value of their net income (wages minus commuting costs discounted over expected tenure) are always accepted. Further all workers' residential locations are assumed to be fixed. 

When searching, those that are already employed adjust their asking pay so that it is higher than their current salary.  Those that are unemployed will lower their asking wage until it reaches their reservation wage for each iteration that they remain unemployed.  To stay competitive employment positions also offer annual increases for their employees.  In part these raises ensure long term employment is realized.  The raise amount is randomly generated from a uniform distribution and implies a variability in the wages offered for similar positions. Researchers have empirically shown that similar workers receive markedly different wages for similar types of jobs \cite{Murphy1987,Krueger1988} whose existence has been theorized to arise from different reasons including employer wage policies, as well as unmeasured worker abilities \cite{Christensen2005}

HOW TO USE IT
-------------
There are three general family of parameters that can be defined to control the agents and modeling environment. The first set, the Modle Setup Parameters, allow us to define diffferent urban lanscapes. Agent density and Employment Location Multiplier define how many agents and employment locations there are in the model.  

Two possibilities exist for defining where employment is located, one with a four job-centers located at centers of four quadrants each having equal jobs (by turning on equalize jobs at job centers), and another where firms can locate freely (randomly) at any location in the modeling landscape (by turning on distribute employment).  We also have to choose how many firms exist in the area. Travel speed defines the average travel speed in the region used to calculate travel time between home and work places.

Job related settings: Here the first two variables control whether there is skill differentiation in jobs and skills (n-job-classes) and whether there is wage dispersion at a given skill level (wage-dispersion). Matching precsion controls how exact the matching between skill requirements and worker skills need to be for a worker to be considered as a viable employee by the employer. Variable empty-pos-annual-increase controls the annual rate at which empty positions increase their wage offers to attract other employees, while variable annual-wage-increase controls the annual rate wage increases are made to employees. Since employers have limited budgets to expand the offer wage, both these rates increase at a decreasing rate and eventually level off.

Variables min-search-effort and max-search-effort define the range of minimum and maximum search intensities.  Each employee that decides to search for employment randomly selects and intensity between these two numbers. Prop-using-contancts and contact_influential-prop define the proportion of searchers finding work through contacts, and the proportion of those where the contact can play a role in bridging the skill gap between the employer and the applicant.  

Variable unemp_askng_pay_cut allows searchers to make them selves attractive by cutting their asking pay. Agents-logit deals with the decision mechanism of how workers choose among alternative offers.  When the agents_logit switch is on, the agent chooses probabilistically using wages and travel time, and when not, the best offer based on wage offers is chosen. This best offer is then compared to the current status of the worker. 

Finally, variable med_tenure referes to an empirical value of the tenure period for the population beyond which workers are less likely to want to switch jobs. 

Currently the model stops if any one of the following condistions are satisfied:
- All employment positions are filled and the shortest tenure is at least 15 years
- All agents are employed and the shortest tenure is at least 15 years
- Iteration has reached 500 (in general distances do not change significantly by the time the tick count has reached 500)

After selecting the parameters, click on setup to generate the agents and their locations, and go to run the model.  One unit distance is assumed to be one mile, and for time period counts, each tick is considered to be 1 month.  

CREDITS AND REFERENCES
----------------------
For more description of the model see Tilahun, N. and D. Levinson (working paper) An Agent-Based Model of Worker and Job Matching.
@#$#@#$#@
default
true
0
Polygon -7500403 true true 150 5 40 250 150 205 260 250

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

bee
true
0
Polygon -1184463 true false 151 152 137 77 105 67 89 67 66 74 48 85 36 100 24 116 14 134 0 151 15 167 22 182 40 206 58 220 82 226 105 226 134 222
Polygon -16777216 true false 151 150 149 128 149 114 155 98 178 80 197 80 217 81 233 95 242 117 246 141 247 151 245 177 234 195 218 207 206 211 184 211 161 204 151 189 148 171
Polygon -7500403 true true 246 151 241 119 240 96 250 81 261 78 275 87 282 103 277 115 287 121 299 150 286 180 277 189 283 197 281 210 270 222 256 222 243 212 242 192
Polygon -16777216 true false 115 70 129 74 128 223 114 224
Polygon -16777216 true false 89 67 74 71 74 224 89 225 89 67
Polygon -16777216 true false 43 91 31 106 31 195 45 211
Line -1 false 200 144 213 70
Line -1 false 213 70 213 45
Line -1 false 214 45 203 26
Line -1 false 204 26 185 22
Line -1 false 185 22 170 25
Line -1 false 169 26 159 37
Line -1 false 159 37 156 55
Line -1 false 157 55 199 143
Line -1 false 200 141 162 227
Line -1 false 162 227 163 241
Line -1 false 163 241 171 249
Line -1 false 171 249 190 254
Line -1 false 192 253 203 248
Line -1 false 205 249 218 235
Line -1 false 218 235 200 144

bird1
false
0
Polygon -7500403 true true 2 6 2 39 270 298 297 298 299 271 187 160 279 75 276 22 100 67 31 0

bird2
false
0
Polygon -7500403 true true 2 4 33 4 298 270 298 298 272 298 155 184 117 289 61 295 61 105 0 43

boat1
false
0
Polygon -1 true false 63 162 90 207 223 207 290 162
Rectangle -6459832 true false 150 32 157 162
Polygon -13345367 true false 150 34 131 49 145 47 147 48 149 49
Polygon -7500403 true true 158 33 230 157 182 150 169 151 157 156
Polygon -7500403 true true 149 55 88 143 103 139 111 136 117 139 126 145 130 147 139 147 146 146 149 55

boat2
false
0
Polygon -1 true false 63 162 90 207 223 207 290 162
Rectangle -6459832 true false 150 32 157 162
Polygon -13345367 true false 150 34 131 49 145 47 147 48 149 49
Polygon -7500403 true true 157 54 175 79 174 96 185 102 178 112 194 124 196 131 190 139 192 146 211 151 216 154 157 154
Polygon -7500403 true true 150 74 146 91 139 99 143 114 141 123 137 126 131 129 132 139 142 136 126 142 119 147 148 147

boat3
false
0
Polygon -1 true false 63 162 90 207 223 207 290 162
Rectangle -6459832 true false 150 32 157 162
Polygon -13345367 true false 150 34 131 49 145 47 147 48 149 49
Polygon -7500403 true true 158 37 172 45 188 59 202 79 217 109 220 130 218 147 204 156 158 156 161 142 170 123 170 102 169 88 165 62
Polygon -7500403 true true 149 66 142 78 139 96 141 111 146 139 148 147 110 147 113 131 118 106 126 71

box
true
0
Polygon -7500403 true true 45 255 255 255 255 45 45 45

butterfly1
true
0
Polygon -16777216 true false 151 76 138 91 138 284 150 296 162 286 162 91
Polygon -7500403 true true 164 106 184 79 205 61 236 48 259 53 279 86 287 119 289 158 278 177 256 182 164 181
Polygon -7500403 true true 136 110 119 82 110 71 85 61 59 48 36 56 17 88 6 115 2 147 15 178 134 178
Polygon -7500403 true true 46 181 28 227 50 255 77 273 112 283 135 274 135 180
Polygon -7500403 true true 165 185 254 184 272 224 255 251 236 267 191 283 164 276
Line -7500403 true 167 47 159 82
Line -7500403 true 136 47 145 81
Circle -7500403 true true 165 45 8
Circle -7500403 true true 134 45 6
Circle -7500403 true true 133 44 7
Circle -7500403 true true 133 43 8

circle
false
0
Circle -7500403 true true 35 35 230

link
true
0
Line -7500403 true 150 0 150 300

link direction
true
0
Line -7500403 true 150 150 30 225
Line -7500403 true 150 150 270 225

person
false
0
Circle -7500403 true true 155 20 63
Rectangle -7500403 true true 158 79 217 164
Polygon -7500403 true true 158 81 110 129 131 143 158 109 165 110
Polygon -7500403 true true 216 83 267 123 248 143 215 107
Polygon -7500403 true true 167 163 145 234 183 234 183 163
Polygon -7500403 true true 195 163 195 233 227 233 206 159

sheep
false
15
Rectangle -1 true true 90 75 270 225
Circle -1 true true 15 75 150
Rectangle -16777216 true false 81 225 134 286
Rectangle -16777216 true false 180 225 238 285
Circle -16777216 true false 1 88 92

spacecraft
true
0
Polygon -7500403 true true 150 0 180 135 255 255 225 240 150 180 75 240 45 255 120 135

thin-arrow
true
0
Polygon -7500403 true true 150 0 0 150 120 150 120 293 180 293 180 150 300 150

truck-down
false
0
Polygon -7500403 true true 225 30 225 270 120 270 105 210 60 180 45 30 105 60 105 30
Polygon -8630108 true false 195 75 195 120 240 120 240 75
Polygon -8630108 true false 195 225 195 180 240 180 240 225

truck-left
false
0
Polygon -7500403 true true 120 135 225 135 225 210 75 210 75 165 105 165
Polygon -8630108 true false 90 210 105 225 120 210
Polygon -8630108 true false 180 210 195 225 210 210

truck-right
false
0
Polygon -7500403 true true 180 135 75 135 75 210 225 210 225 165 195 165
Polygon -8630108 true false 210 210 195 225 180 210
Polygon -8630108 true false 120 210 105 225 90 210

turtle
true
0
Polygon -7500403 true true 138 75 162 75 165 105 225 105 225 142 195 135 195 187 225 195 225 225 195 217 195 202 105 202 105 217 75 225 75 195 105 187 105 135 75 142 75 105 135 105

wolf
false
0
Rectangle -7500403 true true 15 105 105 165
Rectangle -7500403 true true 45 90 105 105
Polygon -7500403 true true 60 90 83 44 104 90
Polygon -16777216 true false 67 90 82 59 97 89
Rectangle -1 true false 48 93 59 105
Rectangle -16777216 true false 51 96 55 101
Rectangle -16777216 true false 0 121 15 135
Rectangle -16777216 true false 15 136 60 151
Polygon -1 true false 15 136 23 149 31 136
Polygon -1 true false 30 151 37 136 43 151
Rectangle -7500403 true true 105 120 263 195
Rectangle -7500403 true true 108 195 259 201
Rectangle -7500403 true true 114 201 252 210
Rectangle -7500403 true true 120 210 243 214
Rectangle -7500403 true true 115 114 255 120
Rectangle -7500403 true true 128 108 248 114
Rectangle -7500403 true true 150 105 225 108
Rectangle -7500403 true true 132 214 155 270
Rectangle -7500403 true true 110 260 132 270
Rectangle -7500403 true true 210 214 232 270
Rectangle -7500403 true true 189 260 210 270
Line -7500403 true 263 127 281 155
Line -7500403 true 281 155 281 192

wolf-left
false
3
Polygon -6459832 true true 117 97 91 74 66 74 60 85 36 85 38 92 44 97 62 97 81 117 84 134 92 147 109 152 136 144 174 144 174 103 143 103 134 97
Polygon -6459832 true true 87 80 79 55 76 79
Polygon -6459832 true true 81 75 70 58 73 82
Polygon -6459832 true true 99 131 76 152 76 163 96 182 104 182 109 173 102 167 99 173 87 159 104 140
Polygon -6459832 true true 107 138 107 186 98 190 99 196 112 196 115 190
Polygon -6459832 true true 116 140 114 189 105 137
Rectangle -6459832 true true 109 150 114 192
Rectangle -6459832 true true 111 143 116 191
Polygon -6459832 true true 168 106 184 98 205 98 218 115 218 137 186 164 196 176 195 194 178 195 178 183 188 183 169 164 173 144
Polygon -6459832 true true 207 140 200 163 206 175 207 192 193 189 192 177 198 176 185 150
Polygon -6459832 true true 214 134 203 168 192 148
Polygon -6459832 true true 204 151 203 176 193 148
Polygon -6459832 true true 207 103 221 98 236 101 243 115 243 128 256 142 239 143 233 133 225 115 214 114

wolf-right
false
3
Polygon -6459832 true true 170 127 200 93 231 93 237 103 262 103 261 113 253 119 231 119 215 143 213 160 208 173 189 187 169 190 154 190 126 180 106 171 72 171 73 126 122 126 144 123 159 123
Polygon -6459832 true true 201 99 214 69 215 99
Polygon -6459832 true true 207 98 223 71 220 101
Polygon -6459832 true true 184 172 189 234 203 238 203 246 187 247 180 239 171 180
Polygon -6459832 true true 197 174 204 220 218 224 219 234 201 232 195 225 179 179
Polygon -6459832 true true 78 167 95 187 95 208 79 220 92 234 98 235 100 249 81 246 76 241 61 212 65 195 52 170 45 150 44 128 55 121 69 121 81 135
Polygon -6459832 true true 48 143 58 141
Polygon -6459832 true true 46 136 68 137
Polygon -6459832 true true 45 129 35 142 37 159 53 192 47 210 62 238 80 237
Line -16777216 false 74 237 59 213
Line -16777216 false 59 213 59 212
Line -16777216 false 58 211 67 192
Polygon -6459832 true true 38 138 66 149
Polygon -6459832 true true 46 128 33 120 21 118 11 123 3 138 5 160 13 178 9 192 0 199 20 196 25 179 24 161 25 148 45 140
Polygon -6459832 true true 67 122 96 126 63 144

@#$#@#$#@
NetLogo 4.0.4
@#$#@#$#@
@#$#@#$#@
@#$#@#$#@
<experiments>
  <experiment name="experiment" repetitions="1" runMetricsEveryStep="false">
    <setup>setup</setup>
    <go>go</go>
    <timeLimit steps="60"/>
    <metric>[trvldist] of agents</metric>
    <metric>[salary] of agents</metric>
    <metric>[beta1w] of agents</metric>
    <enumeratedValueSet variable="max-search-effort">
      <value value="5"/>
      <value value="10"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="nfirms">
      <value value="30"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="search-in-expanding-radii">
      <value value="false"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="vot_prop_of_wage">
      <value value="0.5"/>
      <value value="1"/>
      <value value="1.5"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="Discount-Rate">
      <value value="0"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="agents_logit">
      <value value="true"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="annual-wage-increase">
      <value value="0"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="distributed_employment">
      <value value="false"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="unemp_askng_pay_cut">
      <value value="0"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="contact_influential-prop">
      <value value="0"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="empty-pos-annual-increase">
      <value value="0"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="beta1">
      <value value="0"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="matching_precision">
      <value value="0"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="beta2">
      <value value="1"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="agent-density">
      <value value="14"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="emp_position_multiplier">
      <value value="1.3"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="prop-using-contacts">
      <value value="0"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="min-search-effort">
      <value value="1"/>
      <value value="5"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="trvlspeed">
      <value value="40"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="njob-centers">
      <value value="4"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="med_tenure">
      <value value="8"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="wage-dispersion">
      <value value="0"/>
      <value value="1"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="n-job-classes">
      <value value="1"/>
      <value value="3"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="equalize-jobs-at-jc">
      <value value="true"/>
    </enumeratedValueSet>
  </experiment>
  <experiment name="experiment" repetitions="25" runMetricsEveryStep="false">
    <setup>setup</setup>
    <go>go</go>
    <timeLimit steps="70"/>
    <metric>mean [trvldist] of agents</metric>
    <metric>variance [trvldist] of agents</metric>
    <metric>min [trvldist] of agents</metric>
    <metric>max [trvldist] of agents</metric>
    <enumeratedValueSet variable="search-in-expanding-radii">
      <value value="false"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="equalize-jobs-at-jc">
      <value value="true"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="beta1">
      <value value="0"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="beta2">
      <value value="1"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="min-search-effort">
      <value value="0"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="med_tenure">
      <value value="8"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="vot_prop_of_wage">
      <value value="1"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="max-search-effort">
      <value value="5"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="matching_precision">
      <value value="0"/>
      <value value="1"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="emp_position_multiplier">
      <value value="1.3"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="n-job-classes">
      <value value="1"/>
      <value value="3"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="prop-using-contacts">
      <value value="0"/>
      <value value="0.25"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="njob-centers">
      <value value="4"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="unemp_askng_pay_cut">
      <value value="0.05"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="nfirms">
      <value value="30"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="trvlspeed">
      <value value="40"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="annual-wage-increase">
      <value value="0.05"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="agent-density">
      <value value="14"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="distributed_employment">
      <value value="false"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="wage-dispersion">
      <value value="0"/>
      <value value="1"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="Discount-Rate">
      <value value="0"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="agents_logit">
      <value value="true"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="contact_influential-prop">
      <value value="1"/>
    </enumeratedValueSet>
    <enumeratedValueSet variable="empty-pos-annual-increase">
      <value value="0.05"/>
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
