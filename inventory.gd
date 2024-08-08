extends Node2D
class_name Inventory

class BodyPart:
  var skin_temp:float # C
  var core_temp # C
  var skin_wetness:float # %
  var vasoconstriction:float # % of normal blood flow to skin

  # Constants
  var mass:float # kg
  var surface_area:float # sq m
  var skin_thickness:float # mm, generally 1mm to 5mm averaged

# Environment variables
var air_temp:float = 22 # C
var wind_speed:float = 5 # km/h
var humidity:float = 0.2 # % relative

# Body total variables
var body_metabolic_rate = 1.0 # in mets: 58.2 watts/sq meter

# Body total constants
var body_surface_area = 1.85
var body_total_mass = 70

# Body parts
var head:BodyPart
var torso:BodyPart
var arms:BodyPart
var legs:BodyPart
var feet:BodyPart

var whole_body:BodyPart

# Called when the node enters the scene tree for the first time.
func _ready():
  # Avg adult male total surface area: 1.85 sq/m
  # var body_surface_area = 1.85
  # var body_total_mass = 70
  var body_starting_wetness = 0.5
  var body_starting_core_temp = 36.6

  whole_body = BodyPart.new()
  whole_body.mass = body_total_mass
  whole_body.surface_area = body_surface_area
  whole_body.skin_temp = air_temp
  whole_body.skin_wetness = body_starting_wetness
  whole_body.skin_thickness = 5
  whole_body.core_temp = body_starting_core_temp

  head = BodyPart.new()
  head.mass = 0.08 * body_total_mass
  head.surface_area = 0.10 * body_surface_area
  head.skin_temp = air_temp
  head.skin_wetness = body_starting_wetness
  head.skin_thickness = 2
  head.core_temp = body_starting_core_temp

  torso = BodyPart.new()
  torso.mass = 0.50 * body_total_mass
  torso.surface_area = 0.36 * body_surface_area
  torso.skin_temp = air_temp
  torso.skin_wetness = body_starting_wetness
  torso.skin_thickness = 4
  torso.core_temp = body_starting_core_temp

  arms = BodyPart.new()
  arms.mass = 0.15 * body_total_mass
  arms.surface_area = 0.25 * body_surface_area
  arms.skin_temp = air_temp
  arms.skin_wetness = body_starting_wetness
  arms.skin_thickness = 2.5
  arms.core_temp = body_starting_core_temp

  legs = BodyPart.new()
  legs.mass = 0.24 * body_total_mass
  legs.surface_area = 0.21 * body_surface_area
  legs.skin_temp = air_temp
  legs.skin_wetness = body_starting_wetness
  legs.skin_thickness = 3
  legs.core_temp = body_starting_core_temp

  feet = BodyPart.new()
  feet.mass = 0.03 * body_total_mass
  feet.surface_area = 0.08 * body_surface_area
  feet.skin_temp = air_temp
  feet.skin_wetness = body_starting_wetness
  feet.skin_thickness = 4.5
  feet.core_temp = body_starting_core_temp

const body_specific_gravity = 1010 # kg/m^3
const body_specific_heat = 3500 # J/(kg*C)
const body_vascular_conduction_rate_base = 1.0 # watts * m^-2 * delta degrees C
const sweat_latent_heat = 2448 # J/g
const watts_per_met = 58.2 # watts per square meter

# C -> Torr
func water_pressure_from_temp(temp:float):
  return 7.50062 * 0.61078 * exp(17.27 * temp / (temp + 237.3))

# 10,000 sq cm in 1 sqm
const skin_saturation_weight = 0.01 * 10000 # g per sqm

func mass_from_wetness(surface_area:float, wetness:float):
  return surface_area * skin_saturation_weight * wetness

func wetness_from_mass(surface_area:float, sweat_mass:float):
  return sweat_mass / skin_saturation_weight / surface_area

func update_body_part(part:BodyPart, delta):
  var debug_data = {}
  var skin_mass = body_specific_gravity * part.surface_area * (part.skin_thickness/1000.0)
  var core_mass = part.mass - skin_mass

  # Metabolic heat generation proportional by body mass
  # Increase core temp by amount of metabolic heat generation
  # Metabolic rate is based on surface area, but we will distribute it based on weight
  var part_metabolic_rate = (body_metabolic_rate * watts_per_met * body_surface_area) * (part.mass / body_total_mass)
  debug_data["part_metabolic_rate"] = part_metabolic_rate
  var part_metabolic_energy = part_metabolic_rate * delta
  var core_delta_t_met = part_metabolic_energy / body_specific_heat / core_mass

  # Core to skin heat transfer
  var minimal_skin_conductance = 5.28 # watts / sqm / C
  var blood_thermal_capacity = 1.163 # watt hours per liter per C
  var neutral_skin_blood_flow = 6.3 # l per square meters per hour
  var adjusted_skin_blood_flow = neutral_skin_blood_flow # TODO: Adjust for vasoconstriction
  var blood_based_conductance = neutral_skin_blood_flow * blood_thermal_capacity / 3600
  var total_skin_conductance = (minimal_skin_conductance + blood_based_conductance) * part.surface_area
  var skin_energy_exchange_rate = total_skin_conductance * (part.core_temp - part.skin_temp) # watts
  debug_data["skin_energy_exchange_rate"] = skin_energy_exchange_rate
  var skin_energy_exchanged = skin_energy_exchange_rate * delta
  var core_delta_t_skin_conductance = -skin_energy_exchanged / body_specific_heat / core_mass
  var skin_delta_t_skin_conductance = skin_energy_exchanged / body_specific_heat / skin_mass

  # ========= Skin temp adjustment ==========
  #  = Sensible heat sources: Convection and Radiation =
  # Using sitting model of hc
  var h_convection_constant = 11.6 + sqrt(wind_speed)
  # Sitting value of hr
  var h_radiation_constant = 4.5
  var h_combined = h_convection_constant + h_radiation_constant
  # Major oversimplification. Assuming MRT == air temp
  var operative_temperature = air_temp
  # Not taking clothing into account
  var sensible_heat_rate = h_combined * (operative_temperature - part.skin_temp)
  debug_data["sensible_heat_rate"] = sensible_heat_rate
  var sensible_heat_energy = sensible_heat_rate * delta
  var skin_delta_t_sensible = sensible_heat_energy / body_specific_heat / skin_mass

  #  = Insensible heat loss: Evaporation =
  var sweat_vapor_pressure = water_pressure_from_temp(part.skin_temp)
  # TODO: This might not be right for calculating air vapor pressure
  var air_vapor_pressure = water_pressure_from_temp(air_temp) * humidity
  var mass_transfer_constant = 23.2 * sqrt(wind_speed)
  var mass_transfer_rate = part.skin_wetness * part.surface_area * mass_transfer_constant * (sweat_vapor_pressure - air_vapor_pressure) / 60.0
  debug_data["mass_transfer_rate"] = mass_transfer_rate
  var adjusted_mass_trasnsfer_rate = 0.0 if mass_transfer_rate < 0.0 else mass_transfer_rate
  var mass_evaporated = adjusted_mass_trasnsfer_rate * delta
  var mass_available = mass_from_wetness(part.surface_area, part.skin_wetness)
  var actual_mass_evaporated = min(mass_evaporated, mass_available)
  var evaporation_energy = actual_mass_evaporated * sweat_latent_heat
  debug_data["evaporation_watts"] = evaporation_energy / delta
  var skin_delta_t_evaporation = -evaporation_energy / body_specific_heat / skin_mass

  part.core_temp += core_delta_t_met
  part.core_temp += core_delta_t_skin_conductance
  part.skin_temp += skin_delta_t_skin_conductance
  part.skin_wetness -= wetness_from_mass(part.surface_area, actual_mass_evaporated)
  part.skin_temp += skin_delta_t_evaporation
  part.skin_temp += skin_delta_t_sensible


  # === Body response ===
  # Sweating
  var alpha = skin_mass/part.mass
  var threshold_temp = alpha*33.5 + (1-alpha)*37.0
  var signal_temp = alpha*part.skin_temp + (1-alpha)*part.core_temp
  #var threshold_temp = 33.5
  #var signal_temp = part.skin_temp
  var signal_degrees = max(0, signal_temp - threshold_temp)
  var sweating_control_coefficient = 200 # g / sqm / hour / C
  var sweat_rate = sweating_control_coefficient * signal_degrees / 3600 * part.surface_area # g/s
  debug_data["sweat_rate"] = sweat_rate
  var sweat_amount = sweat_rate * delta

  part.skin_wetness += wetness_from_mass(part.surface_area, sweat_amount)
  if part.skin_wetness > 1.0:
    # Dripping sweat
    part.skin_wetness = 1.0

  # TODO: shivering
  # TODO: vasoconstriction

  return debug_data

# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta):
  # Update all body parts
  var debug_data = update_body_part(head, delta)
  update_body_part(torso, delta)
  update_body_part(arms, delta)
  update_body_part(legs, delta)
  update_body_part(feet, delta)

  $Stats/HeadMetabolicRateValue.text = "%f" % [debug_data["part_metabolic_rate"]]
  $Stats/SensibleHeatRateValue.text = "%f" % [debug_data["sensible_heat_rate"]]
  $Stats/SkinEnergyRateValue.text = "%f" % [debug_data["skin_energy_exchange_rate"]]
  $Stats/MassTransferValue.text = "%f" % [debug_data["evaporation_watts"]]

  $Head/SkinTempValue.text = "%2.2f" % [head.skin_temp]
  $Head/CoreTempValue.text = "%2.2f" % [head.core_temp]
  $Head/SkinWetnessValue.text = "%2.2f" % [head.skin_wetness * 100]

  $Torso/SkinTempValue.text = "%2.0f" % [torso.skin_temp]
  $Torso/SkinWetnessValue.text = "%2.0f" % [torso.skin_wetness * 100]
  $Arms/SkinTempValue.text = "%2.0f" % [arms.skin_temp]
  $Arms/SkinWetnessValue.text = "%2.0f" % [arms.skin_wetness * 100]
  $Legs/SkinTempValue.text = "%2.0f" % [legs.skin_temp]
  $Legs/SkinWetnessValue.text = "%2.0f" % [legs.skin_wetness * 100]
  $Feet/SkinTempValue.text = "%2.0f" % [feet.skin_temp]
  $Feet/SkinWetnessValue.text = "%2.0f" % [feet.skin_wetness * 100]

func _on_air_temp_slider_value_changed(value):
  air_temp = value
  $Stats/AirTempValue.text = "%2.0f" % [air_temp]

func _on_wind_speed_slider_value_changed(value):
  wind_speed = value
  $Stats/WindSpeedValue.text = "%2.0f km/h" % [wind_speed]

func _on_humidity_slider_value_changed(value):
  humidity = value/100.0
  $Stats/HumidityValue.text = "%2.0f%%" % [humidity * 100.0]

func _on_metabolic_rate_slider_value_changed(value):
  body_metabolic_rate = value
  $Stats/MetabolicRateValue.text = "%2.0f met" % [body_metabolic_rate]
