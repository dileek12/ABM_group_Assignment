extensions [gis table csv]

; ==========================
; Breeds
; ==========================

breed [suppliers supplier]
breed [distributors distributor]
breed [consumers consumer]

; ==========================
; Agent Properties
; ==========================

suppliers-own [
  energy-type          ; "solar", "wind", "hydro", "thermal", "biomass"
  max-capacity         ; MW
  current-output       ; MW
  efficiency           ; 0.0-1.0
  battery-capacity     ; MWh
  current-storage      ; MWh
  storage-efficiency   ; 0.0-1.0
  max-charge-rate      ; MW - maximum charging rate
  max-discharge-rate   ; MW - maximum discharging rate
  region              ; Region name
  weather-factor      ; Current weather impact (0.0-1.0)
  production-cost     ; Rs/MWh
  maintenance-cost    ; Rs/hour
  revenue            ; Total revenue earned
  profit             ; Current profit/loss
  battery-cycles     ; Total charge/discharge cycles
  energy-to-battery  ; MW currently going to battery
  energy-from-battery ; MW currently coming from battery
]

distributors-own [
  company-type        ; "CEB" or "LECO"
  region             ; Service region
  transmission-capacity  ; MW
  grid-losses           ; Percentage loss
  total-demand          ; Current MW demand
  residential-demand    ; MW
  industrial-demand     ; MW
  commercial-demand     ; MW
  buying-price         ; Rs/MWh from suppliers
  selling-price        ; Rs/MWh to consumers
  transmission-cost    ; Rs/MWh
  revenue             ; Total revenue
  expenses            ; Total expenses
  supply-deficit      ; MW shortage
  blackout-risk       ; 0.0-1.0 probability
]

consumers-own [
  region
  consumer-type        ; "residential", "industrial", "commercial"
  base-demand         ; MW baseline
  peak-demand         ; MW maximum
  current-demand      ; MW current actual demand
  demand-elasticity   ; Price sensitivity
  willingness-to-pay  ; Rs/MWh maximum
  current-price      ; Rs/MWh current
  total-cost         ; Total electricity cost paid
  power-reliability   ; 0.0-1.0 satisfaction with reliability
  price-satisfaction  ; 0.0-1.0 satisfaction with pricing
]

; ==========================
; Globals
; ==========================

globals [
  ; GIS datasets
  country-boundary
  provinces-data
  districts-data

  ; Weather conditions
  ;solar-irradiance    ; 0.0-1.0 normalized
  ;wind-speed          ; 0.0-1.0 normalized
  ;rainfall-level      ; 0.0-1.0 normalized
  ;temperature         ; Celsius
  cloud-cover         ; 0.0-1.0 normalized

  ; Time tracking
  current-hour        ; 0-23
  current-day         ; 1-365
  current-season      ; "dry" or "wet"

  ; Market conditions
  ;fuel-price-index    ; Global fuel price multiplier
  ;carbon-tax-rate     ; Rs/ton CO2
  ;renewable-subsidy   ; Rs/MWh for renewables

  ; System metrics
  total-generation    ; MW
  total-consumption   ; MW
  grid-stability      ; 0.0-1.0
  renewable-percentage ; 0-100%
  thermal-percentage   ; 0-100%
  average-price       ; Rs/MWh

  ; Battery metrics
  total-battery-capacity    ; Total MWh
  total-battery-storage     ; Current MWh stored
  total-battery-charging    ; MW currently charging
  total-battery-discharging ; MW currently discharging
  battery-utilization       ; Percentage of capacity used

  ; Control switches
  ;pause-simulation?
  ;auto-weather?
  ;show-consumer-satisfaction
  ;weather-volatility
  simulation-speed

  ; Graph tracking lists
  renewable-energy-history
  thermal-energy-history
  battery-charge-history
  battery-discharge-history
  time-history

          ; Currently commented out
           ; Exists but might need initialization
            ; Exists but might need initialization
          ; Exists but might need initialization
]

; ==========================
; SETUP
; ==========================

to setup
  clear-all
  load-gis-data
  setup-world
  draw-maps
  initialize-globals
  create-suppliers-agents
  create-distributors-agents
  create-consumers-agents
  setup-initial-connections
  calculate-initial-metrics
  initialize-graphs
  display-agent-info
  reset-ticks
end

; --------------------------
; GIS Setup
; --------------------------

to load-gis-data
  set country-boundary gis:load-dataset "map_data/lka_admbnda_adm0_slsd_20220816.shp"
  set provinces-data  gis:load-dataset "map_data/lka_admbnda_adm1_slsd_20220816.shp"
  set districts-data  gis:load-dataset "map_data/lka_admbnda_adm2_slsd_20220816.shp"
end

to setup-world
  gis:set-world-envelope gis:envelope-of country-boundary
end

to draw-maps
  clear-drawing
  gis:set-drawing-color red
  gis:draw country-boundary 3
  gis:set-drawing-color blue
  gis:draw provinces-data 1.5
  gis:set-drawing-color gray
  gis:draw districts-data 0.8
end

; --------------------------
; Initialize Global Variables
; --------------------------

to initialize-globals
  ; Weather initialization
  set solar-irradiance 0.7
  set wind-speed 0.5
  set rainfall-level 0.3
  set temperature 28
  set cloud-cover 0.4
  set current-hour 12
  set current-day 1
  set current-season "dry"

  ; Market conditions
  set fuel-price-index 1.0
  set carbon-tax-rate 5000
  set renewable-subsidy 2000

  ; System metrics
  set total-generation 0
  set total-consumption 0
  set grid-stability 1.0
  set renewable-percentage 0
  set thermal-percentage 0
  set average-price 17000

  ; Battery metrics
  set total-battery-capacity 0
  set total-battery-storage 0
  set total-battery-charging 0
  set total-battery-discharging 0
  set battery-utilization 0

  ; Control switches
  set pause-simulation? false
  set auto-weather? true
  set show-consumer-satisfaction false
  set weather-volatility 0.3
  set simulation-speed 1

  ; Initialize graph tracking
  set renewable-energy-history []
  set thermal-energy-history []
  set battery-charge-history []
  set battery-discharge-history []
  set time-history []

  if weather-volatility = 0 [ set weather-volatility 0.3 ]
  if fuel-price-index = 0 [ set fuel-price-index 1.0 ]
  if carbon-tax-rate = 0 [ set carbon-tax-rate 5000 ]
  if renewable-subsidy = 0 [ set renewable-subsidy 2000 ]
end

to initialize-graphs
  ; Clear any existing plots
  clear-all-plots
end

; ==========================
; SUPPLIERS
; ==========================

to create-suppliers-agents
  ;; Hambantota Solar Farm
  create-suppliers 1 [
    setxy 4 -14
    set shape "square" set color yellow set size 0.8
    set label "Hambantota Solar"
    set energy-type "solar" set max-capacity 300 set efficiency 0.85
    set battery-capacity 150 set current-storage 75 set storage-efficiency 0.90
    set max-charge-rate 120 set max-discharge-rate 100
    set region "Southern" set production-cost 12000 set maintenance-cost 2000
    initialize-supplier-vars
  ]

  ;; Hambantota Wind Farm
  create-suppliers 1 [
    setxy 5 -14
    set shape "triangle" set color cyan set size 0.8
    set label "Hambantota Wind"
    set energy-type "wind" set max-capacity 200 set efficiency 0.80
    set battery-capacity 100 set current-storage 50 set storage-efficiency 0.88
    set max-charge-rate 120 set max-discharge-rate 100
    set region "Southern" set production-cost 15000 set maintenance-cost 3000
    initialize-supplier-vars
  ]

  ;; Mannar Wind Farm
  create-suppliers 1 [
    setxy -7 10
    set shape "triangle" set color cyan set size 0.8
    set label "Mannar Wind"
    set energy-type "wind" set max-capacity 250 set efficiency 0.82
    set battery-capacity 125 set current-storage 62 set storage-efficiency 0.88
    set max-charge-rate 120 set max-discharge-rate 100
    set region "Northern" set production-cost 14500 set maintenance-cost 2800
    initialize-supplier-vars
  ]

  ;; Victoria Hydro Plant
  create-suppliers 1 [
    setxy 0 -4
    set shape "circle" set color blue set size 0.8
    set label "Victoria Hydro"
    set energy-type "hydro" set max-capacity 500 set efficiency 0.95
    set battery-capacity 0 set current-storage 0 set storage-efficiency 0
    set max-charge-rate 120 set max-discharge-rate 100
    set region "Central" set production-cost 8000 set maintenance-cost 1500
    initialize-supplier-vars
  ]

  ;; Kelanitissa Coal Plant (Thermal backup)
  create-suppliers 1 [
    setxy -6 -9
    set shape "x" set color red set size 0.8
    set label "Kelanitissa Coal"
    set energy-type "thermal" set max-capacity 600 set efficiency 0.65
    set battery-capacity 0 set current-storage 0 set storage-efficiency 0
    set max-charge-rate 120 set max-discharge-rate 100
    set region "Western" set production-cost 25000 set maintenance-cost 5000
    initialize-supplier-vars
  ]

  ;; Western Solar Farm
  create-suppliers 1 [
    setxy -6 -10
    set shape "square" set color yellow set size 0.8
    set label "Western Solar"
    set energy-type "solar" set max-capacity 400 set efficiency 0.88
    set battery-capacity 200 set current-storage 100 set storage-efficiency 0.92
    set max-charge-rate 120 set max-discharge-rate 100
    set region "Western" set production-cost 11500 set maintenance-cost 2200
    initialize-supplier-vars
  ]

  ;; Eastern Wind Farm
  create-suppliers 1 [
    setxy 7 1
    set shape "triangle" set color cyan set size 0.8
    set label "Eastern Wind"
    set energy-type "wind" set max-capacity 180 set efficiency 0.78
    set battery-capacity 90 set current-storage 45 set storage-efficiency 0.87
    set max-charge-rate 120 set max-discharge-rate 100
    set region "Eastern" set production-cost 15500 set maintenance-cost 3200
    initialize-supplier-vars
  ]

  ;; Norochcholai Coal Plant (Major thermal plant)
  create-suppliers 1 [
    setxy -8 1
    set shape "x" set color red set size 0.8
    set label "Norochcholai Coal"
    set energy-type "thermal" set max-capacity 900 set efficiency 0.70
    set battery-capacity 0 set current-storage 0 set storage-efficiency 0
    set max-charge-rate 120 set max-discharge-rate 100
    set region "Western" set production-cost 24000 set maintenance-cost 4500
    initialize-supplier-vars
  ]

  ;; Mahaweli Hydro Complex
  create-suppliers 1 [
    setxy 1 -2
    set shape "circle" set color blue set size 0.8
    set label "Mahaweli Hydro"
    set energy-type "hydro" set max-capacity 800 set efficiency 0.92
    set battery-capacity 0 set current-storage 0 set storage-efficiency 0
    set max-charge-rate 120 set max-discharge-rate 100
    set region "Central" set production-cost 7000 set maintenance-cost 1200
    initialize-supplier-vars
  ]

  ;; Badulla Hydro Complex
  create-suppliers 1 [
    setxy 6 -5
    set shape "circle" set color blue set size 0.8
    set label "Badulla Hydro"
    set energy-type "hydro" set max-capacity 1000 set efficiency 0.92
    set battery-capacity 0 set current-storage 0 set storage-efficiency 0
    set max-charge-rate 120 set max-discharge-rate 100
    set region "Uva" set production-cost 7000 set maintenance-cost 1200
    initialize-supplier-vars
  ]

  ;; Trincomalee Wind Farm
  create-suppliers 1 [
    setxy 5 5
    set shape "triangle" set color cyan set size 0.8
    set label "Trincomalee Wind"
    set energy-type "wind" set max-capacity 300 set efficiency 0.80
    set battery-capacity 150 set current-storage 75 set storage-efficiency 0.90
    set max-charge-rate 120 set max-discharge-rate 100
    set region "Eastern" set production-cost 16000 set maintenance-cost 3500
    initialize-supplier-vars
  ]

  ;; Anuradhapura Solar Farm
  create-suppliers 1 [
    setxy -1 3
    set shape "square" set color yellow set size 0.8
    set label "Anuradhapura Solar"
    set energy-type "solar" set max-capacity 350 set efficiency 0.86
    set battery-capacity 175 set current-storage 87 set storage-efficiency 0.91
    set max-charge-rate 120 set max-discharge-rate 100
    set region "Central" set production-cost 12500 set maintenance-cost 2100
    initialize-supplier-vars
  ]

  ; Polonnaruwa Solar Farm
  create-suppliers 1 [
    setxy 3 1.5
    set shape "square" set color yellow set size 0.8
    set label "Polonnaruwa Solar"
    set energy-type "solar" set max-capacity 400 set efficiency 0.88
    set battery-capacity 200 set current-storage 100 set storage-efficiency 0.92
    set max-charge-rate 120 set max-discharge-rate 100
    set region "Central" set production-cost 11600 set maintenance-cost 2000
    initialize-supplier-vars
  ]

  ; Kilinochchi Solar Park
  create-suppliers 1 [
    setxy -3.5 13.5
    set shape "square" set color yellow set size 0.8
    set label "Kilinochchi Solar"
    set energy-type "solar" set max-capacity 350 set efficiency 0.87
    set battery-capacity 175 set current-storage 87 set storage-efficiency 0.91
    set max-charge-rate 120 set max-discharge-rate 100
    set region "Northern" set production-cost 11900 set maintenance-cost 2100
    initialize-supplier-vars
  ]

  ;; Jaffna Solar Farm
  create-suppliers 1 [
    setxy -4 16
    set shape "square" set color yellow set size 0.8
    set label "Jaffna Solar"
    set energy-type "solar" set max-capacity 600 set efficiency 0.86
    set battery-capacity 300 set current-storage 90 set storage-efficiency 0.91
    set max-charge-rate 120 set max-discharge-rate 100
    set region "Nothern" set production-cost 11500 set maintenance-cost 2500
    initialize-supplier-vars
  ]

  ;; Embilipitiya Solar Farm
  create-suppliers 1 [
    setxy 1 -14
    set shape "square" set color yellow set size 0.8
    set label "Embilipitiya Solar"
    set energy-type "solar" set max-capacity 250 set efficiency 0.84
    set battery-capacity 125 set current-storage 62 set storage-efficiency 0.89
    set max-charge-rate 120 set max-discharge-rate 100
    set region "Southern" set production-cost 13000 set maintenance-cost 2300
    initialize-supplier-vars
  ]

  ;; Kalpitiya Wind Farm
  create-suppliers 1 [
    setxy -8 3
    set shape "triangle" set color cyan set size 0.8
    set label "Kalpitiya Wind"
    set energy-type "wind" set max-capacity 200 set efficiency 0.82
    set battery-capacity 100 set current-storage 50 set storage-efficiency 0.88
    set max-charge-rate 120 set max-discharge-rate 100
    set region "Western" set production-cost 15200 set maintenance-cost 2900
    initialize-supplier-vars
  ]

  ;; Nuwara Eliya Wind Farm
  create-suppliers 1 [
    setxy 0 -8
    set shape "triangle" set color cyan set size 0.8
    set label "Nuwara Eliya Wind"
    set energy-type "wind" set max-capacity 160 set efficiency 0.84
    set battery-capacity 80 set current-storage 40 set storage-efficiency 0.88
    set max-charge-rate 120 set max-discharge-rate 100
    set region "Central" set production-cost 15900 set maintenance-cost 3400
    initialize-supplier-vars
  ]

    ;; Monaragala Wind Farm
  create-suppliers 1 [
    setxy 6 -11
    set shape "triangle" set color cyan set size 0.8
    set label "Monaragala Wind"
    set energy-type "wind" set max-capacity 220 set efficiency 0.81
    set battery-capacity 110 set current-storage 55 set storage-efficiency 0.88
    set max-charge-rate 120 set max-discharge-rate 100
    set region "Southern" set production-cost 15800 set maintenance-cost 3100
    initialize-supplier-vars
  ]

  ;; Kurunegala Solar Park
  create-suppliers 1 [
    setxy -3.5 -2
    set shape "square" set color yellow set size 0.8
    set label "Kurunegala Solar"
    set energy-type "solar" set max-capacity 450 set efficiency 0.87
    set battery-capacity 225 set current-storage 112 set storage-efficiency 0.92
    set max-charge-rate 120 set max-discharge-rate 100
    set region "Western" set production-cost 11800 set maintenance-cost 2200
    initialize-supplier-vars
  ]

  ;; Ampara Solar Farm
  create-suppliers 1 [
    setxy 8 -6
    set shape "square" set color yellow set size 0.8
    set label "Ampara Solar"
    set energy-type "solar" set max-capacity 380 set efficiency 0.85
    set battery-capacity 190 set current-storage 95 set storage-efficiency 0.90
    set max-charge-rate 120 set max-discharge-rate 100
    set region "Eastern" set production-cost 12200 set maintenance-cost 2300
    initialize-supplier-vars
  ]

  ;; Vavuniya Wind Farm
  create-suppliers 1 [
    setxy -2.5 8
    set shape "triangle" set color cyan set size 0.8
    set label "Vavuniya Wind"
    set energy-type "wind" set max-capacity 190 set efficiency 0.80
    set battery-capacity 95 set current-storage 47 set storage-efficiency 0.88
    set max-charge-rate 120 set max-discharge-rate 100
    set region "Northern" set production-cost 15600 set maintenance-cost 3200
    initialize-supplier-vars
  ]

  ;; Diesel Emergency Generators (Distributed)
  create-suppliers 1 [
    setxy -2 -8
    set shape "x" set color orange set size 0.8
    set label "Emergency Diesel"
    set energy-type "thermal" set max-capacity 200 set efficiency 0.45
    set battery-capacity 0 set current-storage 0 set storage-efficiency 0
    set max-charge-rate 120 set max-discharge-rate 100
    set region "Western" set production-cost 35000 set maintenance-cost 7000
    initialize-supplier-vars
  ]

  ;; Biomass Plant (Gampaha)
  create-suppliers 1 [
    setxy -5 -6
    set shape "circle" set color brown set size 0.8
    set label "Gampaha Biomass"
    set energy-type "biomass" set max-capacity 150 set efficiency 0.75
    set battery-capacity 0 set current-storage 0 set storage-efficiency 0
    set max-charge-rate 120 set max-discharge-rate 100
    set region "Western" set production-cost 18000 set maintenance-cost 3500
    initialize-supplier-vars
  ]

end

to initialize-supplier-vars
  set weather-factor 1.0
  set current-output 0
  set revenue 0
  set profit 0
  set battery-cycles 0
  set energy-to-battery 0
  set energy-from-battery 0
end

; ==========================
; ENHANCED BATTERY MANAGEMENT SYSTEM
; ==========================

to update-supplier-output
  ; Reset global battery metrics
  set total-battery-charging 0
  set total-battery-discharging 0

  ask suppliers [
    set weather-factor calculate-weather-factor energy-type
    set energy-to-battery 0
    set energy-from-battery 0

    ; Calculate renewable generation potential
    let renewable-potential 0
    if energy-type != "thermal" and energy-type != "battery" [
      let base-output max-capacity * weather-factor * efficiency
      let time-factor get-time-factor energy-type current-hour
      set renewable-potential base-output * time-factor
    ]

    ; Check system-wide supply-demand balance
    let system-demand sum [total-demand] of distributors
    let current-system-supply sum [current-output] of suppliers with [self != myself]
    let system-deficit system-demand - current-system-supply

    ; BATTERY LOGIC: Enhanced charging and discharging
    if battery-capacity > 0 [
      let available-storage-space battery-capacity - current-storage
      let available-energy current-storage

      ; CHARGING PHASE: When there's excess renewable energy
      if renewable-potential > 0 and system-deficit <= 0 and available-storage-space > 0 [
        let excess-energy renewable-potential * 0.4  ; 40% of excess to battery
        let max-charge min list max-charge-rate available-storage-space
        let charge-amount min list excess-energy max-charge
        let actual-charge charge-amount * storage-efficiency

        set current-storage current-storage + actual-charge
        set energy-to-battery charge-amount
        set renewable-potential renewable-potential - charge-amount
        set battery-cycles battery-cycles + (charge-amount / battery-capacity)
      ]

      ; DISCHARGING PHASE: When demand exceeds supply
      if system-deficit > 0 and available-energy > 0 [
        let max-discharge min list max-discharge-rate available-energy
        let needed-discharge min list max-discharge system-deficit
        let discharge-amount min list needed-discharge max-discharge

        set current-storage current-storage - discharge-amount
        set energy-from-battery discharge-amount * storage-efficiency
        set battery-cycles battery-cycles + (discharge-amount / battery-capacity)
      ]
    ]

    ; Set final output
    ifelse energy-type = "thermal" [
      ; Thermal plants ramp up when there's deficit
      ifelse system-deficit > 0 [
        let thermal-output min list max-capacity (system-deficit * 1.2)
        set current-output thermal-output
      ] [
        set current-output max-capacity * 0.2  ; Minimum thermal operation
      ]
    ] [
      ifelse energy-type = "battery" [
        ; Pure battery storage facility
        set current-output energy-from-battery
      ] [
        ; Renewable sources
        set current-output renewable-potential + energy-from-battery
      ]
    ]

    ; Ensure output doesn't exceed capacity
    set current-output min list current-output max-capacity

    ; Update global battery metrics
    set total-battery-charging total-battery-charging + energy-to-battery
    set total-battery-discharging total-battery-discharging + energy-from-battery

    ; Update financial calculations
    update-supplier-financials
  ]
end

to update-supplier-financials
  let hourly-production-cost (current-output * production-cost / 1000)
  let hourly-maintenance maintenance-cost
  let battery-operation-cost (energy-to-battery + energy-from-battery) * 500 / 1000

  let hourly-revenue (current-output * average-price / 1000)
  if energy-type != "thermal" [
    set hourly-revenue hourly-revenue + (renewable-subsidy * current-output / 1000)
  ]

  set revenue revenue + hourly-revenue
  set profit profit + hourly-revenue - hourly-production-cost - hourly-maintenance - battery-operation-cost
end

; ==========================
; DISTRIBUTORS (Updated to work with enhanced battery system)
; ==========================

to create-distributors-agents
  ; Western Province
  create-distributors 1 [
    setxy -7 -8 set shape "star" set color red set size 0.8
    set label "CEB Western"
    set company-type "CEB" set region "Western"
    set transmission-capacity 500 set grid-losses 0.08
    set residential-demand 800 set industrial-demand 600 set commercial-demand 400
    set buying-price 13000 set selling-price 18000 set transmission-cost 2000
    initialize-distributor-vars
  ]

  ; Southern Province
  create-distributors 1 [
    setxy -1 -15 set shape "star" set color red set size 0.8
    set label "CEB Southern"
    set company-type "CEB" set region "Southern"
    set transmission-capacity 400 set grid-losses 0.09
    set residential-demand 600 set industrial-demand 300 set commercial-demand 200
    set buying-price 12500 set selling-price 17500 set transmission-cost 1800
    initialize-distributor-vars
  ]

  ; Central Province
  create-distributors 1 [
    setxy 0 -6 set shape "star" set color red set size 0.8
    set label "CEB Central"
    set company-type "CEB" set region "Central"
    set transmission-capacity 600 set grid-losses 0.07
    set residential-demand 700 set industrial-demand 500 set commercial-demand 300
    set buying-price 11000 set selling-price 16000 set transmission-cost 1500
    initialize-distributor-vars
  ]

  ; Northern Province
  create-distributors 1 [
    setxy -3 11 set shape "star" set color red set size 0.8
    set label "CEB Northern"
    set company-type "CEB" set region "Northern"
    set transmission-capacity 300 set grid-losses 0.10
    set residential-demand 400 set industrial-demand 150 set commercial-demand 100
    set buying-price 14000 set selling-price 19500 set transmission-cost 2500
    initialize-distributor-vars
  ]
end

to initialize-distributor-vars
  set total-demand residential-demand + industrial-demand + commercial-demand
  set revenue 0 set expenses 0 set supply-deficit 0 set blackout-risk 0
end

; ==========================
; CONSUMERS (Unchanged from original)
; ==========================

to create-consumers-agents
  ; Sri Lankan district population data with coordinates
  let district-data table:make

  ; Population data: [population province center-x center-y min-x max-x min-y max-y]
  ; Western Province districts
  table:put district-data "Colombo" [474.9 "Western" -6 -8 -7 -4.5 -9 -7.8]
  table:put district-data "Gampaha" [486.7 "Western" -6 -6 -7 -4.5 -7.8 -5]
  table:put district-data "Kalutara" [261.1 "Western" -5.8 -10 -6 -4 -12.5 -8]

  ; Southern Province districts
  table:put district-data "Galle" [219.3 "Southern" -4 -14 -5 -2 -15 -12.5]
  table:put district-data "Matara" [167.6 "Southern" -2 -14 -2 -1 -16 -13]
  table:put district-data "Hambantota" [134.2 "Southern" 1 -14 0 4 -14.8 -13.5]

  ; Central Province districts
  table:put district-data "Kandy" [292.3 "Central" 0 -5 -1 2 -6 -4]
  table:put district-data "Matale" [105.3 "Central" 0 -2 -1 1 -4 0]
  table:put district-data "Nuwara Eliya" [145 "Central" 0 -7 -2 1 -9 -7]

  ; Northern Province districts
  table:put district-data "Jaffna" [119 "Northern" -4 14 -6 -3.5 15 16]
  table:put district-data "Mannar" [24.7 "Northern" -5 8 -6 -5 6 10]
  table:put district-data "Vavuniya" [34.5 "Northern" -2 8 -3.5 -0.5 7 9.5]
  table:put district-data "Kilinochchi" [24.5 "Northern" -4 13 -5 -2 12 15]
  table:put district-data "Mullaitivu" [27.3 "Northern" -1 12 -4 0 11 13]

  ; Eastern Province districts
  table:put district-data "Trincomalee" [88.5 "Eastern" 3 5 2 4 3 8]
  table:put district-data "Batticaloa" [148.8 "Eastern" 6 -1 5 7 -3 2]
  table:put district-data "Ampara" [119 "Eastern" 8 -6 7 9 -11 -4]

  ; North Western Province districts
  table:put district-data "Kurunegala" [352.2 "Western" -4 -2 -5.5 -2 -4.5 1]
  table:put district-data "Puttalam" [163.6 "Western" -7 2 -7 -6 -7 3]

  ; North Central Province districts
  table:put district-data "Anuradhapura" [192 "Central" -2 4 -5 1 1 6]
  table:put district-data "Polonnaruwa" [98.5 "Central" 3 1 1 4.5 -1 3]

  ; Uva Province districts
  table:put district-data "Badulla" [174.4 "Central" 3 -8 2 3.5 -12 -3]
  table:put district-data "Monaragala" [105.5 "Southern" 5 -10.5 3 7 -11 -5]

  ; Sabaragamuwa Province districts
  table:put district-data "Ratnapura" [229 "Central" -1 -11 -3 1 -12 -10]
  table:put district-data "Kegalle" [174 "Central" -3 -7 -4 -2 -8 -5]

  ; Create consumer agents based on population
  let district-names table:keys district-data
  foreach district-names [ district-name ->
    let district-info table:get district-data district-name
    let population item 0 district-info
    let province item 1 district-info
    let center-x item 2 district-info
    let center-y item 3 district-info
    let min-x item 4 district-info
    let max-x item 5 district-info
    let min-y item 6 district-info
    let max-y item 7 district-info

    ; Calculate number of agents based on population (scaled down for visualization)
    let residential-agents ceiling (population / 10)
    let industrial-agents ceiling (population / 70)
    let commercial-agents ceiling (population / 50)

    ; Create residential consumers
    repeat residential-agents [
      create-consumers 1 [
        set region province
        set consumer-type "residential"
        set base-demand 2 + random-float 3
        set peak-demand base-demand * 1.3
        set current-demand base-demand
        set demand-elasticity 0.20 + random-float 0.15
        set willingness-to-pay 16000 + random 6000
        set current-price 16000 + random 2000
        set total-cost 0
        set power-reliability 0.8 + random-float 0.2
        set price-satisfaction 0.7 + random-float 0.3

        set shape "house" set color green set size 0.3
        setxy (min-x + random-float (max-x - min-x)) (min-y + random-float (max-y - min-y))
      ]
    ]

    ; Create industrial consumers (if sufficient population)
    if population > 200 [
      repeat industrial-agents [
        create-consumers 1 [
          set region province
          set consumer-type "industrial"
          set base-demand 5 + random-float 10
          set peak-demand base-demand * 1.2
          set current-demand base-demand
          set demand-elasticity 0.30 + random-float 0.20
          set willingness-to-pay 13000 + random 5000
          set current-price 13000 + random 2000
          set total-cost 0
          set power-reliability 0.85 + random-float 0.15
          set price-satisfaction 0.6 + random-float 0.3

          set shape "factory" set color brown set size 0.4
          setxy (min-x + random-float (max-x - min-x)) (min-y + random-float (max-y - min-y))
        ]
      ]
    ]

    ; Create commercial consumers (for all districts, not just population > 200)
    repeat commercial-agents [
      create-consumers 1 [
        set region province
        set consumer-type "commercial"
        set base-demand 3 + random-float 7
        set peak-demand base-demand * 1.4
        set current-demand base-demand
        set demand-elasticity 0.25 + random-float 0.20
        set willingness-to-pay 14000 + random 4000
        set current-price 14000 + random 2000
        set total-cost 0
        set power-reliability 0.8 + random-float 0.2
        set price-satisfaction 0.65 + random-float 0.3

        set shape "building institution" set color violet set size 0.35
        setxy (min-x + random-float (max-x - min-x)) (min-y + random-float (max-y - min-y))
      ]
    ]
  ]
end

; ==========================
; INITIALIZATION HELPERS
; ==========================

to setup-initial-connections
  ask suppliers [
    set weather-factor calculate-weather-factor energy-type
    update-supplier-output
  ]
  ask distributors [ update-demand-profile ]
  ask consumers [ update-consumer-demand ]
end

to calculate-initial-metrics
  set total-generation sum [current-output] of suppliers
  set total-consumption sum [current-demand] of consumers

  let renewable-generation sum [current-output] of suppliers with [energy-type != "thermal"]
  let thermal-generation sum [current-output] of suppliers with [energy-type = "thermal"]

  ifelse total-generation > 0 [
    set renewable-percentage (renewable-generation / total-generation) * 100
    set thermal-percentage (thermal-generation / total-generation) * 100
  ] [
    set renewable-percentage 0
    set thermal-percentage 0
  ]

  ; Calculate total battery metrics
  set total-battery-capacity sum [battery-capacity] of suppliers
  set total-battery-storage sum [current-storage] of suppliers
  ifelse total-battery-capacity > 0 [
    set battery-utilization (total-battery-storage / total-battery-capacity) * 100
  ] [
    set battery-utilization 0
  ]

  set grid-stability calculate-grid-stability
  set average-price calculate-average-price
end

; ==========================
; WEATHER SYSTEM (Unchanged)
; ==========================

to update-weather
  let season-factor get-season-factor current-day

  ; Weather variations with volatility control
  set solar-irradiance max list 0.1 min list 1.0 (solar-irradiance + (random-float (weather-volatility * 2) - weather-volatility) * season-factor)
  set wind-speed max list 0.05 min list 1.0 (wind-speed + (random-float (weather-volatility * 2) - weather-volatility) * season-factor)
  set rainfall-level max list 0.0 min list 1.0 (rainfall-level + (random-float (weather-volatility * 2) - weather-volatility) * season-factor)
  set temperature max list 20 min list 35 (temperature + random-float 6 - 3)
  set cloud-cover max list 0.0 min list 1.0 (cloud-cover + random-float 0.4 - 0.2)

  ; Cloud cover affects solar
  set solar-irradiance solar-irradiance * (1 - cloud-cover * 0.6)

  ; Update season
  ifelse current-day >= 90 and current-day <= 270 [
    set current-season "wet"
  ] [
    set current-season "dry"
  ]
end

to-report get-season-factor [day]
  if day >= 90 and day <= 150 [ report 1.3 ]  ; Southwest monsoon
  if day >= 300 or day <= 60 [ report 0.8 ]   ; Dry season
  report 1.0    ; Inter-monsoon
end

to-report calculate-weather-factor [energy-source]
  if energy-source = "solar" [
    report solar-irradiance * (1 - cloud-cover * 0.4)
  ]
  if energy-source = "wind" [ report wind-speed ]
  if energy-source = "hydro" [
    report max list 0.3 min list 1.0 (0.4 + rainfall-level * 0.6)
  ]
  if energy-source = "thermal" [ report 1.0 ]
  if energy-source = "biomass" [ report 1.0 ]
  if energy-source = "battery" [ report 1.0 ]
  report 1.0
end

; ==========================
; DEMAND AND TIME FACTORS (Unchanged)
; ==========================

to update-demand-profile
  ask distributors [
    let time-multiplier get-demand-time-factor current-hour

    ; Calculate actual demand from consumers in region
    let local-residential sum [current-demand] of consumers with [region = [region] of myself and consumer-type = "residential"]
    let local-industrial sum [current-demand] of consumers with [region = [region] of myself and consumer-type = "industrial"]
    let local-commercial sum [current-demand] of consumers with [region = [region] of myself and consumer-type = "commercial"]

    set residential-demand local-residential * time-multiplier
    set industrial-demand local-industrial * time-multiplier * 0.9
    set commercial-demand local-commercial * time-multiplier * 1.1
    set total-demand residential-demand + industrial-demand + commercial-demand

    ; Calculate supply deficit
    let local-supply sum [current-output] of suppliers with [region = [region] of myself]
    set supply-deficit max list 0 (total-demand - local-supply)

    ; Calculate blackout risk
    ifelse total-demand > 0 [
      set blackout-risk min list 1.0 (supply-deficit / total-demand)
    ] [
      set blackout-risk 0
    ]

    ; Update financials
    set revenue revenue + (total-demand * selling-price / 1000)
    set expenses expenses + (total-demand * buying-price / 1000)
  ]
end

to update-consumer-demand
  ask consumers [
    let time-multiplier get-demand-time-factor current-hour
    let price-effect 1 - (demand-elasticity * (current-price - willingness-to-pay) / willingness-to-pay)
    set price-effect max list 0.3 min list 1.5 price-effect

    set current-demand base-demand * time-multiplier * price-effect

    ; Update satisfaction
    let local-distributors distributors with [region = [region] of myself]
    let avg-blackout-risk 0
    if any? local-distributors [
      set avg-blackout-risk mean [blackout-risk] of local-distributors
    ]
    set power-reliability max list 0.0 min list 1.0 (1 - avg-blackout-risk)
    set price-satisfaction max list 0.0 min list 1.0 (1 - (current-price - willingness-to-pay) / willingness-to-pay)
    set total-cost total-cost + (current-demand * current-price / 1000)
  ]
end

; ==========================
; TIME FACTORS
; ==========================

to-report get-time-factor [energy-source hour]
  if energy-source = "solar" [
    if hour >= 6 and hour <= 18 [
      let hour-from-noon abs(hour - 12)
      report 0.2 + 0.8 * (1 - hour-from-noon / 6)
    ]
    report 0.0
  ]

  if energy-source = "wind" [
    if hour >= 22 or hour <= 6 [ report 1.0 + random-float 0.3 ]
    if hour >= 7 and hour <= 17 [ report 0.6 + random-float 0.3 ]
    report 0.8 + random-float 0.3
  ]

  report 0.9 + random-float 0.2  ; Hydro and thermal
end

to-report get-demand-time-factor [hour]
  if hour >= 6 and hour <= 9 [ report 1.1 + random-float 0.2 ]    ; Morning peak
  if hour >= 10 and hour <= 17 [ report 0.8 + random-float 0.2 ]  ; Midday
  if hour >= 18 and hour <= 22 [ report 1.3 + random-float 0.2 ]  ; Evening peak
  report 0.6 + random-float 0.2  ; Night
end

; ==========================
; SYSTEM CALCULATIONS
; ==========================

to-report calculate-grid-stability
  let supply-demand-ratio 0
  if total-consumption > 0 [
    set supply-demand-ratio total-generation / total-consumption
  ]

  let balance-factor min list 1.0 supply-demand-ratio
  let renewable-instability (renewable-percentage / 100) * 0.15
  let battery-stability-bonus (battery-utilization / 100) * 0.1
  report max list 0.0 min list 1.0 (balance-factor - renewable-instability + battery-stability-bonus)
end

to-report calculate-average-price
  let total-price-weighted 0
  let total-demand-weighted 0

  ask distributors [
    set total-price-weighted total-price-weighted + (selling-price * total-demand)
    set total-demand-weighted total-demand-weighted + total-demand
  ]

  ifelse total-demand-weighted > 0 [
    report total-price-weighted / total-demand-weighted
  ] [
    report 17000
  ]
end

; ==========================
; MAIN SIMULATION LOOP
; ==========================

to go
  if pause-simulation? [ stop ]

  ; Update time
  set current-hour current-hour + 1
  if current-hour >= 24 [
    set current-hour 0
    set current-day current-day + 1
    if current-day > 365 [ set current-day 1 ]
  ]

  ; Update weather if enabled
  if auto-weather? [ update-weather ]

  ; Update all agents in correct order
  update-consumer-demand
  update-demand-profile
  update-supplier-output  ; Enhanced with better battery management

  ; Update market conditions
  update-market-dynamics

  ; Calculate system metrics
  calculate-system-metrics

  ; Update graph data
  update-graph-data

  ; Update visualizations
  update-agent-colors

  tick

  ; Handle simulation speed
  if simulation-speed > 1 [
    repeat (simulation-speed - 1) [
      set current-hour current-hour + 1
      if current-hour >= 24 [ set current-hour 0 set current-day current-day + 1 ]
      if auto-weather? [ update-weather ]
      update-consumer-demand
      update-demand-profile
      update-supplier-output
      update-market-dynamics
      calculate-system-metrics
      update-graph-data
      tick
    ]
  ]
end

to update-market-dynamics
  ; Fuel price volatility
  set fuel-price-index fuel-price-index * (0.98 + random-float 0.04)
  set fuel-price-index max list 0.5 min list 2.0 fuel-price-index

  ; Update thermal costs
  ask suppliers with [energy-type = "thermal"] [
    set production-cost 25000 * fuel-price-index + carbon-tax-rate * 0.8
  ]
end

to calculate-system-metrics
  set total-generation sum [current-output] of suppliers
  set total-consumption sum [current-demand] of consumers

  let renewable-generation sum [current-output] of suppliers with [energy-type != "thermal"]
  let thermal-generation sum [current-output] of suppliers with [energy-type = "thermal"]

  ifelse total-generation > 0 [
    set renewable-percentage (renewable-generation / total-generation) * 100
    set thermal-percentage (thermal-generation / total-generation) * 100
  ] [
    set renewable-percentage 0
    set thermal-percentage 0
  ]

  ; Update battery metrics
  set total-battery-capacity sum [battery-capacity] of suppliers
  set total-battery-storage sum [current-storage] of suppliers
  set total-battery-charging sum [energy-to-battery] of suppliers
  set total-battery-discharging sum [energy-from-battery] of suppliers

  ifelse total-battery-capacity > 0 [
    set battery-utilization (total-battery-storage / total-battery-capacity) * 100
  ] [
    set battery-utilization 0
  ]

  set grid-stability calculate-grid-stability
  set average-price calculate-average-price
end

; ==========================
; GRAPH DATA MANAGEMENT
; ==========================

to update-graph-data
  ; Keep only last 100 data points to prevent memory issues
  if length renewable-energy-history > 100 [
    set renewable-energy-history but-first renewable-energy-history
    set thermal-energy-history but-first thermal-energy-history
    set battery-charge-history but-first battery-charge-history
    set battery-discharge-history but-first battery-discharge-history
    set time-history but-first time-history
  ]

  ; Add current data points
  set renewable-energy-history lput renewable-percentage renewable-energy-history
  set thermal-energy-history lput thermal-percentage thermal-energy-history
  set battery-charge-history lput total-battery-charging battery-charge-history
  set battery-discharge-history lput total-battery-discharging battery-discharge-history
  set time-history lput ticks time-history
end

; ==========================
; VISUALIZATION
; ==========================

to update-agent-colors
  ask suppliers [
    let utilization 0
    if max-capacity > 0 [ set utilization current-output / max-capacity ]

    ; Enhanced coloring for battery systems
    ifelse battery-capacity > 0 [
      let storage-ratio current-storage / battery-capacity

      ; Color coding based on battery state and operation
      if energy-to-battery > 0 [
        set color green  ; Charging - green
      ]
      if energy-from-battery > 0 [
        set color orange  ; Discharging - orange
      ]
      if energy-to-battery = 0 and energy-from-battery = 0 [
        ; Idle state - color based on storage level
        if storage-ratio < 0.2 [ set color red ]      ; Low battery
        if storage-ratio >= 0.2 and storage-ratio < 0.8 [ set color yellow ]  ; Medium
        if storage-ratio >= 0.8 [ set color lime ]    ; Full battery
      ]
    ]
    [
      ; Standard colors for non-battery sources
      if energy-type = "solar" [ set color scale-color yellow utilization 0 1.2 ]
      if energy-type = "wind" [ set color scale-color cyan utilization 0 1.2 ]
      if energy-type = "hydro" [ set color scale-color blue utilization 0 1.2 ]
      if energy-type = "thermal" [ set color scale-color red utilization 0 1.2 ]
    ]
  ]

  ask distributors [
    let deficit-ratio 0
    if total-demand > 0 [ set deficit-ratio supply-deficit / total-demand ]
    set color scale-color red deficit-ratio 1 0
  ]
end

; ==========================
; INTERFACE PROCEDURES
; ==========================

to toggle-pause
  set pause-simulation? not pause-simulation?
end

to emergency-demand-increase
  ask consumers [ set base-demand base-demand * 1.2 ]
  print "Emergency: System demand increased by 20%!"
end

to emergency-demand-decrease
  ask consumers [ set base-demand base-demand * 0.8 ]
  print "Emergency: System demand decreased by 20%!"
end

; ==========================
; ENHANCED REPORTING PROCEDURES
; ==========================

to-report total-renewable-capacity
  report sum [max-capacity] of suppliers with [energy-type != "thermal"]
end

to-report total-storage-capacity
  report sum [battery-capacity] of suppliers
end

to-report current-storage-level
  report sum [current-storage] of suppliers
end

to-report storage-utilization-percentage
  ifelse total-battery-capacity > 0 [
    report (total-battery-storage / total-battery-capacity) * 100
  ] [
    report 0
  ]
end

to-report battery-charge-rate
  report total-battery-charging
end

to-report battery-discharge-rate
  report total-battery-discharging
end

to-report net-battery-flow
  report total-battery-discharging - total-battery-charging
end

to-report average-consumer-satisfaction
  let total-satisfaction sum [(power-reliability + price-satisfaction) / 2] of consumers
  let consumer-count count consumers
  ifelse consumer-count > 0 [
    report total-satisfaction / consumer-count
  ] [
    report 0
  ]
end

to-report system-efficiency
  ifelse total-consumption > 0 [
    report (total-generation / total-consumption) * grid-stability
  ] [
    report 0
  ]
end

to-report renewable-vs-thermal-ratio
  ifelse thermal-percentage > 0 [
    report renewable-percentage / thermal-percentage
  ] [
    report renewable-percentage  ; If no thermal, return renewable percentage
  ]
end

; ==========================
; BATTERY MANAGEMENT PROCEDURES
; ==========================

to add-battery-storage
  let target one-of suppliers with [energy-type != "thermal" and battery-capacity < 500]
  if target != nobody [
    ask target [
      set battery-capacity battery-capacity + 100
      set current-storage current-storage + 50
      set max-charge-rate max-charge-rate + 30
      set max-discharge-rate max-discharge-rate + 25
      print (word "Battery storage added to " label ": +100 MWh capacity, +30 MW charge rate")
    ]
  ]
end

to optimize-battery-charging
  ask suppliers with [battery-capacity > 0] [
    ; Increase charge rate during high renewable generation periods
    if energy-type != "thermal" and weather-factor > 0.8 [
      let available-space battery-capacity - current-storage
      if available-space > 0 [
        let optimal-charge min list (max-charge-rate * 1.2) available-space
        set energy-to-battery optimal-charge * 0.5
      ]
    ]
  ]
end

to emergency-battery-discharge
  ask suppliers with [battery-capacity > 0 and current-storage > 0] [
    let emergency-discharge min list (current-storage * 0.3) max-discharge-rate
    set current-storage current-storage - emergency-discharge
    set energy-from-battery emergency-discharge * storage-efficiency
    print (word "Emergency battery discharge from " label ": " precision emergency-discharge 1 " MW")
  ]
end

; ==========================
; UTILITY PROCEDURES
; ==========================

to display-agent-info
  print "=== ENHANCED POWER GRID SIMULATION STATUS ==="
  print (word "Time: Day " current-day ", Hour " current-hour ":00 (" current-season " season)")
  print (word "Weather: Solar=" precision solar-irradiance 2 " Wind=" precision wind-speed 2 " Rain=" precision rainfall-level 2)
  print ""

  print "=== SUPPLIERS WITH BATTERY STATUS ==="
  ask suppliers [
    let utilization-pct 0
    if max-capacity > 0 [ set utilization-pct precision (current-output / max-capacity * 100) 1 ]

    let battery-info ""
    if battery-capacity > 0 [
      let storage-pct precision (current-storage / battery-capacity * 100) 1
      set battery-info (word " | Battery: " precision current-storage 1 "/" battery-capacity " MWh (" storage-pct "%)")
      if energy-to-battery > 0 [ set battery-info (word battery-info " CHARGING+" precision energy-to-battery 1 "MW") ]
      if energy-from-battery > 0 [ set battery-info (word battery-info " DISCHARGING-" precision energy-from-battery 1 "MW") ]
    ]

    print (word label ": " precision current-output 1 " MW / " max-capacity " MW (" utilization-pct "%)" battery-info)
  ]
  print ""

  print "=== SYSTEM SUMMARY ==="
  print (word "Total Generation: " precision total-generation 1 " MW")
  print (word "Total Consumption: " precision total-consumption 1 " MW")
  print (word "Supply/Demand Ratio: " precision (total-generation / (total-consumption + 0.001)) 2)
  print (word "Renewable Energy: " precision renewable-percentage 1 "% | Thermal: " precision thermal-percentage 1 "%")
  print (word "Grid Stability: " precision (grid-stability * 100) 1 "%")
  print ""

  print "=== BATTERY SYSTEM STATUS ==="
  print (word "Total Battery Capacity: " precision total-battery-capacity 1 " MWh")
  print (word "Current Storage Level: " precision total-battery-storage 1 " MWh (" precision battery-utilization 1 "%)")
  print (word "System Charging Rate: " precision total-battery-charging 1 " MW")
  print (word "System Discharge Rate: " precision total-battery-discharging 1 " MW")
  print (word "Net Battery Flow: " precision net-battery-flow 1 " MW")
  print ""
end

; ==========================
; EMERGENCY SCENARIOS
; ==========================

to simulate-power-plant-failure
  let target one-of suppliers with [current-output > 0 and energy-type != "battery"]
  if target != nobody [
    ask target [
      set current-output 0
      set color black
      print (word "EMERGENCY: " label " has failed! Battery systems compensating...")
    ]
    emergency-battery-discharge
  ]
end

to simulate-transmission-failure
  let target one-of distributors
  if target != nobody [
    ask target [
      set transmission-capacity transmission-capacity * 0.5
      set grid-losses grid-losses * 1.5
      print (word "EMERGENCY: " label " transmission capacity reduced by 50%!")
    ]
  ]
end

to restore-all-systems
  ask suppliers [
    ; Restore normal colors based on energy type
    if energy-type = "solar" [ set color yellow ]
    if energy-type = "wind" [ set color cyan ]
    if energy-type = "hydro" [ set color blue ]
    if energy-type = "thermal" [ set color red ]
    if energy-type = "battery" [ set color violet ]
  ]
  ask distributors [
    ; Restore transmission capacity (approximate)
    set transmission-capacity transmission-capacity * 1.5
    set grid-losses grid-losses / 1.2
  ]
  print "All systems restored to normal operation."
end

; ==========================
; WEATHER CONTROL
; ==========================

to set-sunny-weather
  set solar-irradiance 0.9
  set cloud-cover 0.1
  set wind-speed 0.4
  set rainfall-level 0.1
  print "Weather set to sunny conditions - optimal for solar generation"
end

to set-windy-weather
  set wind-speed 0.9
  set solar-irradiance 0.6
  set cloud-cover 0.6
  set rainfall-level 0.3
  print "Weather set to windy conditions - optimal for wind generation"
end

to set-rainy-weather
  set rainfall-level 0.9
  set cloud-cover 0.8
  set solar-irradiance 0.2
  set wind-speed 0.3
  print "Weather set to rainy conditions - optimal for hydro generation"
end

to set-cloudy-weather
  set cloud-cover 0.9
  set solar-irradiance 0.3
  set wind-speed 0.5
  set rainfall-level 0.6
  print "Weather set to cloudy conditions - reduced solar generation"
end

;; Add these to the end of your NetLogo code

;; Final metrics reporters for BehaviorSpace
to-report final-renewable-percentage
  report renewable-percentage
end

to-report final-grid-stability
  report grid-stability
end

to-report final-battery-utilization
  report battery-utilization
end

to-report final-average-price
  report average-price
end

to-report final-total-generation
  report total-generation
end

to-report final-total-consumption
  report total-consumption
end

to-report supply-demand-balance
  ifelse total-consumption > 0 [
    report total-generation / total-consumption
  ] [
    report 1
  ]
end

to-report average-blackout-risk
  let distributors-with-risk distributors with [blackout-risk > 0]
  ifelse any? distributors-with-risk [
    report mean [blackout-risk] of distributors-with-risk
  ] [
    report 0
  ]
end

to-report battery-charging-efficiency
  let total-charging sum [energy-to-battery] of suppliers
  let total-discharging sum [energy-from-battery] of suppliers
  ifelse total-charging > 0 [
    report total-discharging / total-charging
  ] [
    report 0
  ]
end

to-report renewable-capacity-factor
  let renewable-suppliers suppliers with [energy-type != "thermal"]
  ifelse any? renewable-suppliers [
    let actual-output sum [current-output] of renewable-suppliers
    let max-possible sum [max-capacity] of renewable-suppliers
    ifelse max-possible > 0 [
      report actual-output / max-possible
    ] [
      report 0
    ]
  ] [
    report 0
  ]
end
@#$#@#$#@
GRAPHICS-WINDOW
395
18
972
596
-1
-1
17.242424242424242
1
10
1
1
1
0
1
1
1
-16
16
-16
16
0
0
1
ticks
30.0

BUTTON
16
23
110
63
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
1

BUTTON
15
482
141
515
NIL
display-agent-info
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
1219
46
1306
91
NIL
count suppliers
17
1
11

MONITOR
1315
46
1417
91
NIL
count distributors
17
1
11

MONITOR
1427
45
1527
90
NIL
count consumers
17
1
11

SLIDER
10
84
182
117
solar-irradiance
solar-irradiance
0
1
0.7
0.1
1
NIL
HORIZONTAL

SLIDER
11
124
183
157
wind-speed
wind-speed
0
1
0.5846061176283812
0.1
1
NIL
HORIZONTAL

SLIDER
94
169
266
202
rainfall-level
rainfall-level
0
1
0.0
0.1
1
NIL
HORIZONTAL

MONITOR
994
48
1061
93
residential
count consumers with [consumer-type = \"residential\"]
17
1
11

MONITOR
1070
48
1132
93
industrial
count consumers with [consumer-type = \"industrial\"]
17
1
11

MONITOR
1141
47
1211
92
commercial
count consumers with [consumer-type = \"commercial\"]
17
1
11

MONITOR
996
112
1131
157
base demand
sum [base-demand] of consumers
17
1
11

BUTTON
121
22
208
64
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
1

BUTTON
221
23
291
66
Step
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
192
84
364
117
weather-volatility
weather-volatility
0
1
0.3
0.1
1
NIL
HORIZONTAL

SLIDER
192
126
364
159
temperature
temperature
20
40
22.681805612114996
1
1
°C
HORIZONTAL

SLIDER
15
233
187
266
fuel-price-index
fuel-price-index
0.5
3
0.6359584074925252
0.1
1
NIL
HORIZONTAL

SLIDER
197
234
369
267
carbon-tax-rate
carbon-tax-rate
0
20000
5000.0
500
1
Rs/ton
HORIZONTAL

SLIDER
77
279
331
312
renewable-subsidy
renewable-subsidy
0
5000
2000.0
250
1
 Rs/MWh
HORIZONTAL

SWITCH
16
333
164
366
pause-simulation?
pause-simulation?
1
1
-1000

SWITCH
177
335
378
368
show-consumer-satisfaction
show-consumer-satisfaction
1
1
-1000

SWITCH
16
378
188
411
auto-weather?
auto-weather?
0
1
-1000

SWITCH
200
379
377
412
enable-market-volatility
enable-market-volatility
0
1
-1000

PLOT
999
368
1258
518
Power Generation
Time
MW
0.0
10.0
0.0
10.0
true
true
"" ""
PENS
"Renewable" 1.0 1 -10899396 true "" "plot sum [current-output] of suppliers with [energy-type != \"thermal\"]"
"Thermal" 1.0 1 -2674135 true "" "plot sum [current-output] of suppliers with [energy-type = \"thermal\"]"

PLOT
1276
369
1494
519
Energy Generation Mix
Time (Hours)
Power Output (MW)
0.0
10.0
0.0
10.0
true
true
"" ""
PENS
"Solar" 1.0 0 -1184463 true "" "plot sum [current-output] of suppliers with [energy-type = \"solar\"]"
"Wind" 1.0 0 -11221820 true "" "plot sum [current-output] of suppliers with [energy-type = \"wind\"]"
"Hydro" 1.0 0 -13345367 true "" "plot sum [current-output] of suppliers with [energy-type = \"hydro\"]"
"Thermal" 1.0 0 -2674135 true "" "plot sum [current-output] of suppliers with [energy-type = \"thermal\"]"

PLOT
998
187
1273
337
Supply vs Demand
Time (Hours)
Power (MW)
0.0
10.0
0.0
10.0
true
true
"" ""
PENS
"Supply" 1.0 0 -10899396 true "" "plot total-generation"
"Demand" 1.0 0 -2674135 true "" "plot total-consumption"
"Deficit" 1.0 0 -955883 true "" "plot max list 0 (total-consumption - total-generation)"

BUTTON
15
437
174
470
NIL
emergency-demand-decrease
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
195
437
366
470
NIL
emergency-demand-increase
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
1144
112
1282
157
renewable-percentage
renewable-percentage
17
1
11

PLOT
1005
600
1205
750
battery-charge-rate
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
"default" 1.0 0 -14070903 true "" "Plot battery-charge-rate"

PLOT
1221
601
1421
751
battery-discharge-rate
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
"default" 1.0 0 -955883 true "" "Plot battery-discharge-rate"

PLOT
1453
599
1653
749
net-battery-flow
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
"default" 1.0 0 -10141563 true "" "Plot net-battery-flow"

PLOT
1283
188
1483
338
Battery status
NIL
NIL
0.0
200.0
0.0
2000.0
true
true
"set-plot-x-range 0 200\nset-plot-y-range 0 2000" "set-current-plot-pen \"Storage Level\"\nplot total-battery-storage\n\nset-current-plot-pen \"Charging\" \nplot total-battery-charging\n\nset-current-plot-pen \"Discharging\"\nplot total-battery-discharging\n\nset-current-plot-pen \"Capacity\"\nplot total-battery-capacity"
PENS
"Storage Level" 1.0 0 -10899396 true "" ""
"Charging" 1.0 0 -13345367 true "" ""
"Discharging" 1.0 0 -2674135 true "" ""
"Capacity" 1.0 0 -7500403 true "" ""

BUTTON
391
611
522
644
NIL
set-sunny-weather
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
535
611
666
644
NIL
set-windy-weather
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
683
612
809
645
NIL
set-rainy-weather
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
826
612
959
645
NIL
set-cloudy-weather
NIL
1
T
OBSERVER
NIL
NIL
NIL
NIL
1

@#$#@#$#@
# An Agent-Based Approach for Sri Lanka’s Renewable Energy Transition

## WHAT IS IT?

This model simulates Sri Lanka's electrical power grid system with enhanced battery energy storage capabilities. It models the complex interactions between renewable energy sources (solar, wind, hydro), thermal power plants, energy storage systems, electricity distributors, and consumers across different regions of the country. The simulation incorporates real-world factors including weather variations, time-of-day demand patterns, regional distribution, and advanced battery management systems.

## HOW IT WORKS

### Agent Types

**Suppliers (Power Plants):**
- **Solar Farms**: Generate power based on solar irradiance and cloud cover
- **Wind Farms**: Generate power based on wind speed conditions  
- **Hydro Plants**: Generate power based on rainfall levels and water availability
- **Thermal Plants**: Coal and diesel plants that provide baseline and backup power
- **Biomass Plants**: Use organic materials for power generation
- **Battery Storage**: Advanced energy storage systems that charge during excess generation and discharge during high demand

**Distributors:**
- **CEB (Ceylon Electricity Board)**: Main national electricity distributor
- **LECO**: Regional electricity company
- Handle transmission, manage grid losses, and distribute power to consumers

**Consumers:**
- **Residential**: Households with typical daily usage patterns
- **Industrial**: Factories and manufacturing with high, steady demand
- **Commercial**: Businesses and institutions with variable demand patterns

### Key Features

**Enhanced Battery Management System:**
- Intelligent charging during excess renewable generation
- Strategic discharging during peak demand periods
- Battery degradation tracking through charge/discharge cycles
- Dynamic charge and discharge rate optimization
- Real-time battery utilization monitoring

**Weather System:**
- Dynamic weather patterns affecting renewable energy generation
- Seasonal variations (dry and wet seasons)
- Solar irradiance, wind speed, rainfall, and cloud cover simulation
- Weather volatility controls for scenario testing

**Time-Based Operations:**
- 24-hour daily cycles with realistic demand patterns
- Seasonal variations over 365-day cycles
- Morning and evening peak demand periods
- Solar generation following daylight hours
- Wind generation with higher nighttime productivity

**Regional Distribution:**
- Geographically accurate placement using Sri Lankan district boundaries
- Regional power generation and consumption balancing
- Transmission capacity and grid loss modeling
- Blackout risk calculations for each region

**Economic Modeling:**
- Production costs varying by energy source
- Market price dynamics based on supply and demand
- Carbon tax implementation for thermal plants
- Renewable energy subsidies
- Fuel price volatility effects

## HOW TO USE IT

### Setup and Basic Operation

1. **Initial Setup**: Click "Setup" to initialize the simulation with all power plants, distributors, and consumers placed on the Sri Lankan map.

2. **Run Simulation**: Click "Go" to start the simulation. The model will automatically progress through hours and days.

3. **Monitor Performance**: Watch the real-time displays showing:
   - Power generation and consumption
   - Battery storage status
   - Renewable vs thermal energy mix
   - Grid stability metrics

### Controls and Parameters

**Weather Controls:**
- `solar-irradiance`: Adjust solar power generation potential (0.0-1.0)
- `wind-speed`: Control wind farm output levels (0.0-1.0)
- `rainfall-level`: Affect hydro plant generation (0.0-1.0)
- `weather-volatility`: Set how much weather conditions fluctuate (0.0-1.0)
- `auto-weather?`: Enable automatic weather pattern changes

**Market Parameters:**
- `fuel-price-index`: Global fuel price multiplier affecting thermal plants
- `carbon-tax-rate`: Tax per ton of CO2 emissions (Rs/ton)
- `renewable-subsidy`: Government subsidy for renewable energy (Rs/MWh)

**System Controls:**
- `pause-simulation?`: Pause the simulation
- `show-consumer-satisfaction`: Display consumer satisfaction metrics
- `simulation-speed`: Control how fast time progresses

**Weather Scenario Buttons:**
- `set-sunny-weather`: Optimize conditions for solar generation
- `set-windy-weather`: Optimize conditions for wind generation  
- `set-rainy-weather`: Optimize conditions for hydro generation
- `set-cloudy-weather`: Reduce solar generation

**Emergency Scenarios:**
- `emergency-demand-increase`: Increase system demand by 20%
- `emergency-demand-decrease`: Decrease system demand by 20%
- `simulate-power-plant-failure`: Random power plant failure
- `simulate-transmission-failure`: Transmission capacity reduction
- `emergency-battery-discharge`: Emergency battery power release
- `restore-all-systems`: Restore normal operations

### Understanding the Displays

**Supply vs Demand Graph**: Shows the balance between power generation and consumption over time, including supply deficits.

**Battery Status Graph**: Displays:
- Storage Level: Current energy stored in all batteries
- Charging Rate: Power currently charging batteries
- Discharging Rate: Power currently being released
- Battery Capacity: Maximum storage capability

**Power Generation Graph**: Shows total system generation over time split between renewable and thermal sources.

**Energy Generation Mix**: Pie chart showing the current energy mix by source type (Solar, Wind, Hydro, Thermal).

**Battery Flow Monitors**: Real-time displays of:
- `battery-charge-rate`: Current charging power (MW)
- `battery-discharge-rate`: Current discharging power (MW)  
- `net-battery-flow`: Net power flow (positive = discharging, negative = charging)

### Key Metrics

**Performance Indicators:**
- `renewable-percentage`: Portion of generation from renewable sources
- `grid-stability`: Overall system stability (0-100%)
- `base-demand`: Current baseline power demand
- `battery-utilization`: Percentage of battery capacity currently used

**Agent Counts:**
- Number of residential, industrial, and commercial consumers
- Count of suppliers and distributors in the system

## THINGS TO NOTICE

**Battery System Behavior:**
- Batteries charge (green) during high renewable generation periods
- Batteries discharge (orange) during peak demand periods
- Battery storage levels fluctuate based on generation and demand patterns
- Battery utilization affects overall grid stability

**Renewable Energy Patterns:**
- Solar generation peaks at midday and drops at night
- Wind generation is often higher at night
- Hydro generation depends on seasonal rainfall patterns
- Weather conditions significantly affect renewable output

**System Dynamics:**
- Thermal plants ramp up when renewable generation is insufficient
- Grid stability decreases with higher renewable penetration without adequate storage
- Regional variations in supply and demand create transmission needs
- Consumer satisfaction varies based on reliability and pricing

**Color Coding:**
- **Green agents**: Currently charging batteries or high satisfaction
- **Orange agents**: Currently discharging batteries  
- **Yellow agents**: Solar farms or medium storage levels
- **Cyan agents**: Wind farms
- **Blue agents**: Hydro plants
- **Red agents**: Thermal plants or low battery/high deficit
- **Black agents**: Failed systems (during emergency scenarios)

## THINGS TO TRY

**Scenario Testing:**

1. **High Renewable Scenario**: Increase solar and wind capacity, observe battery charging patterns and grid stability effects.

2. **Peak Demand Events**: Use emergency demand increases to test system response and battery deployment.

3. **Weather Impact Studies**: 
   - Set different weather conditions and observe generation patterns
   - Test system resilience during prolonged cloudy or calm weather periods

4. **Battery Optimization**: 
   - Add more battery storage using `add-battery-storage`
   - Observe how increased storage affects renewable integration

5. **Economic Analysis**:
   - Adjust carbon tax and renewable subsidies
   - Monitor how market conditions affect the energy mix

6. **Emergency Response**:
   - Simulate power plant failures
   - Test system recovery using battery storage
   - Evaluate blackout risk under different scenarios

**Parameter Experiments:**
- Vary weather volatility to test system robustness
- Adjust fuel prices to see thermal vs renewable competition
- Change consumer demand elasticity to study price responsiveness

## EXTENDING THE MODEL

**Potential Enhancements:**

1. **Advanced Storage Technologies**: Add pumped hydro storage, compressed air, or hydrogen storage systems

2. **Smart Grid Features**: Implement demand response programs and dynamic pricing

3. **Electric Vehicle Integration**: Add EV charging loads and vehicle-to-grid capabilities

4. **Microgrids**: Model distributed generation and local energy communities

5. **International Trade**: Add electricity import/export with neighboring regions

6. **Climate Change Scenarios**: Long-term weather pattern changes and adaptation strategies

## RELATED MODELS

This model extends concepts found in:
- Energy market simulations
- Renewable energy integration studies  
- Power system reliability analysis
- Battery energy storage system optimization
- Agent-based energy policy modeling

## CREDITS AND REFERENCES

**Data Sources:**
- Sri Lankan electricity generation data from Ceylon Electricity Board
- Geographic boundaries from Sri Lanka Survey Department
- Weather patterns based on Department of Meteorology data
- Population and demand data from Department of Census and Statistics

**Model Development:**
- Based on real power plants and transmission infrastructure in Sri Lanka
- Battery management algorithms inspired by modern grid-scale storage systems
- Economic modeling based on current electricity tariff structures

**Technical References:**
- Power system operations and control principles
- Renewable energy forecasting methodologies
- Battery energy storage system design principles
- Agent-based modeling of complex energy systems

## AUTHORS

- **Sudam Jayawardana**  
  Department of Mathematics, University of Colombo  
  Email: 2021s18850@stu.cmb.ac.lk

- **Kavindu Eranda**  
  Department of Mathematics, University of Colombo  
  Email: 2021s18804@stu.cmb.ac.lk

- **Pasindu Charith**  
  Department of Mathematics, University of Colombo  
  Email: 2021s18777@stu.cmb.ac.lk

- **Tharusha Dileek**  
  Department of Mathematics, University of Colombo  
  Email: 2021s18984@stu.cmb.ac.lk

- **Buddhi Pramod**  
  Department of Mathematics, University of Colombo  
  Email: 2021s18941@stu.cmb.ac.lk


## COPYRIGHT AND LICENSE

This model is designed for educational and research purposes to understand power grid operations, renewable energy integration, and battery storage systems. It provides insights into the challenges and opportunities of transitioning to a more sustainable electricity system.

---
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

building institution
false
0
Rectangle -7500403 true true 0 60 300 270
Rectangle -16777216 true false 130 196 168 256
Rectangle -16777216 false false 0 255 300 270
Polygon -7500403 true true 0 60 150 15 300 60
Polygon -16777216 false false 0 60 150 15 300 60
Circle -1 true false 135 26 30
Circle -16777216 false false 135 25 30
Rectangle -16777216 false false 0 60 300 75
Rectangle -16777216 false false 218 75 255 90
Rectangle -16777216 false false 218 240 255 255
Rectangle -16777216 false false 224 90 249 240
Rectangle -16777216 false false 45 75 82 90
Rectangle -16777216 false false 45 240 82 255
Rectangle -16777216 false false 51 90 76 240
Rectangle -16777216 false false 90 240 127 255
Rectangle -16777216 false false 90 75 127 90
Rectangle -16777216 false false 96 90 121 240
Rectangle -16777216 false false 179 90 204 240
Rectangle -16777216 false false 173 75 210 90
Rectangle -16777216 false false 173 240 210 255
Rectangle -16777216 false false 269 90 294 240
Rectangle -16777216 false false 263 75 300 90
Rectangle -16777216 false false 263 240 300 255
Rectangle -16777216 false false 0 240 37 255
Rectangle -16777216 false false 6 90 31 240
Rectangle -16777216 false false 0 75 37 90
Line -16777216 false 112 260 184 260
Line -16777216 false 105 265 196 265

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

factory
false
0
Rectangle -7500403 true true 76 194 285 270
Rectangle -7500403 true true 36 95 59 231
Rectangle -16777216 true false 90 210 270 240
Line -7500403 true 90 195 90 255
Line -7500403 true 120 195 120 255
Line -7500403 true 150 195 150 240
Line -7500403 true 180 195 180 255
Line -7500403 true 210 210 210 240
Line -7500403 true 240 210 240 240
Line -7500403 true 90 225 270 225
Circle -1 true false 37 73 32
Circle -1 true false 55 38 54
Circle -1 true false 96 21 42
Circle -1 true false 105 40 32
Circle -1 true false 129 19 42
Rectangle -7500403 true true 14 228 78 270

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
  <experiment name="renewable_stability_analysis" repetitions="20" runMetricsEveryStep="true">
    <setup>setup</setup>
    <go>go</go>
    <timeLimit steps="720"/>
    <exitCondition>ticks &gt;= 720</exitCondition>
    <metric>final-renewable-percentage</metric>
    <metric>final-grid-stability</metric>
    <metric>final-battery-utilization</metric>
    <metric>final-average-price</metric>
    <metric>supply-demand-balance</metric>
    <metric>average-blackout-risk</metric>
    <metric>renewable-capacity-factor</metric>
    <metric>weather-volatility</metric>
    <metric>renewable-subsidy</metric>
    <metric>fuel-price-index</metric>
    <steppedValueSet variable="weather-volatility" first="0.1" step="0.2" last="0.3"/>
    <steppedValueSet variable="renewable-subsidy" first="1000" step="1500" last="2000"/>
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
