extends Node2D
class_name Inventory

var tooltip_scene = preload("res://tooltip.tscn")

# Environment variables
var air_temp:float = 22 # C
var wind_speed:float = 0.1 # km/h
var humidity:float = 0.2 # % relative

var time_rate = 1.0
var total_time_passed = 0
var total_weight_lost = 0.0

# Body total variables
var body_metabolic_rate = 1.0 # in mets: 58.2 watts/sq meter
var body_average_core_temp = 37

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
var tooltip_node:Tooltip
var tooltip_bounding_rect:Rect2
var tooltip_shown = false

var debug_stats = {"head": {}, "torso": {}, "arms": {}, "legs": {}, "feet": {}}
var parts_by_name:Dictionary

func pick_color(value:float, color_dict:Dictionary):
  var has_above_value = false
  var above_value:float
  var above_color:Color
  var has_below_value = false
  var below_value:float
  var below_color:Color

  for pin_value in color_dict:
    if pin_value > value and (not has_above_value or pin_value < above_value):
      has_above_value = true
      above_value = pin_value
      above_color = color_dict[pin_value]
    elif pin_value <= value and (not has_below_value or pin_value > below_value):
      has_below_value = true
      below_value = pin_value
      below_color = color_dict[pin_value]

  if has_above_value and has_below_value:
    var t = (value - below_value) / (above_value - below_value)
    return below_color.lerp(above_color, t)
  elif has_above_value:
    return above_color
  elif has_below_value:
    return below_color
  else:
    return Color.WHITE

func get_core_temp_color(temp:float):
  var color_dict = {
    35.0: Color("#c19df2"),
    36.1: Color.BISQUE,
    37.2: Color.BISQUE,
    40.0: Color("#e36f6f")
  }
  return pick_color(temp, color_dict)

func get_skin_temp_color(temp:float):
  var color_dict = {
    15.0: Color("#595cff"),
    30.0: Color("#88e7eb"),
    32.7: Color.BISQUE,
    34.3: Color.BISQUE,
    40.0: Color("#ff7559"),
    45.0: Color("#ed2424")
  }
  return pick_color(temp, color_dict)

func show_tooltip(part_name:String, bounding_rect:Rect2):
  if not tooltip_shown and not debug_stats["head"].is_empty():
    tooltip_bounding_rect = bounding_rect
    tooltip_shown = true
    add_child(tooltip_node)
    var contents:Array[Tooltip.TooltipContents]
    contents.append(Tooltip.TooltipContents.new("Core Temp (C):", "%.2f" % [parts_by_name[part_name].core_temp], get_core_temp_color(parts_by_name[part_name].core_temp)))
    contents.append(Tooltip.TooltipContents.new("Skin Temp (C):", "%.2f" % [parts_by_name[part_name].skin_temp], get_skin_temp_color(parts_by_name[part_name].skin_temp)))
    contents.append(Tooltip.TooltipContents.new("Metabolic Rate (watts):", "%.2f" % [debug_stats[part_name]["part_metabolic_rate"]]))
    contents.append(Tooltip.TooltipContents.new("Core-Skin Rate (watts):", "%.2f" % [debug_stats[part_name]["skin_energy_exchange_rate"]]))
    contents.append(Tooltip.TooltipContents.new("Sensible Rate (watts):", "%.2f" % [debug_stats[part_name]["sensible_heat_rate"]]))
    contents.append(Tooltip.TooltipContents.new("Evaporation Rate (watts):", "%.2f" % [debug_stats[part_name]["evaporation_watts"]]))
    contents.append(Tooltip.TooltipContents.new("Sweat Rate (g/min):", "%.2f" % [debug_stats[part_name]["sweat_rate"]]))
    contents.append(Tooltip.TooltipContents.new("Skin blood flow (L/min):", "%.2f" % [debug_stats[part_name]["skin_blood_flow"]]))
    contents.append(Tooltip.TooltipContents.new("Vasoconstriction (%):", "%.0f" % [parts_by_name[part_name].vasoconstriction*100]))
    contents.append(Tooltip.TooltipContents.new("Internal body rate (watts):", "%.2f" % [debug_stats[part_name]["body_blood_flow_rate"]]))
    tooltip_node.set_contents(contents)

func hide_tooltip():
  tooltip_shown = false
  remove_child(tooltip_node)

func connect_tooltip_function(control:Control, debug_index:String):
  control.mouse_entered.connect(show_tooltip.bind(debug_index, control.get_global_rect()))

func equip_clothing(clothing:Item, body_part:BodyPart):
  print("Equipping clo %.2f on %s" % [clothing.clo_factor, body_part.part_name])
  body_part.equipped_clo = clothing.clo_factor

func unequip_clothing(clothing:Item, body_part:BodyPart):
  print("Unequipping clothing on %s, %.2f to 0" % [body_part.part_name, body_part.equipped_clo])
  body_part.equipped_clo = 0

func connect_inventory_slot(slot:InventorySlot, body_part:BodyPart):
  slot.AcceptedItem.connect(equip_clothing.bind(body_part))
  slot.RemovedItem.connect(unequip_clothing.bind(body_part))

# Called when the node enters the scene tree for the first time.
func _ready():
  _on_air_temp_slider_value_changed(air_temp)
  _on_wind_speed_slider_value_changed(wind_speed)
  _on_humidity_slider_value_changed(humidity*100)
  _on_metabolic_rate_slider_value_changed(body_metabolic_rate)

  tooltip_node = tooltip_scene.instantiate()
  connect_tooltip_function($Head/Control, "head")
  connect_tooltip_function($Torso/Control, "torso")
  connect_tooltip_function($Arms/Control, "arms")
  connect_tooltip_function($Legs/Control, "legs")
  connect_tooltip_function($Feet/Control, "feet")

  # Avg adult male total surface area: 1.85 sq/m
  # var body_surface_area = 1.85
  # var body_total_mass = 70
  var body_starting_wetness = 0.5
  var body_starting_core_temp = 37
  var body_starting_skin_temp = 33.5

  whole_body = BodyPart.new()
  whole_body.part_name = "Whole Body"
  whole_body.mass = body_total_mass
  whole_body.surface_area = body_surface_area
  whole_body.skin_temp = body_starting_skin_temp
  whole_body.set_skin_wetness(body_starting_wetness)
  whole_body.skin_thickness = 5
  whole_body.core_temp = body_starting_core_temp

  head = BodyPart.new()
  head.part_name = "Head"
  head.mass = 0.08 * body_total_mass
  head.surface_area = 0.10 * body_surface_area
  head.skin_temp = body_starting_skin_temp
  head.set_skin_wetness(body_starting_wetness)
  head.skin_thickness = 2
  head.core_temp = body_starting_core_temp

  torso = BodyPart.new()
  torso.part_name = "Torso"
  torso.mass = 0.50 * body_total_mass
  torso.surface_area = 0.36 * body_surface_area
  torso.skin_temp = body_starting_skin_temp
  torso.set_skin_wetness(body_starting_wetness)
  torso.skin_thickness = 4
  torso.core_temp = body_starting_core_temp

  arms = BodyPart.new()
  arms.part_name = "Arms"
  arms.mass = 0.15 * body_total_mass
  arms.surface_area = 0.25 * body_surface_area
  arms.skin_temp = body_starting_skin_temp
  arms.set_skin_wetness(body_starting_wetness)
  arms.skin_thickness = 2.5
  arms.core_temp = body_starting_core_temp

  legs = BodyPart.new()
  legs.part_name = "Legs"
  legs.mass = 0.24 * body_total_mass
  legs.surface_area = 0.21 * body_surface_area
  legs.skin_temp = body_starting_skin_temp
  legs.set_skin_wetness(body_starting_wetness)
  legs.skin_thickness = 3
  legs.core_temp = body_starting_core_temp

  feet = BodyPart.new()
  feet.part_name = "Feet"
  feet.mass = 0.03 * body_total_mass
  feet.surface_area = 0.08 * body_surface_area
  feet.skin_temp = body_starting_skin_temp
  feet.set_skin_wetness(body_starting_wetness)
  feet.skin_thickness = 4.5
  feet.core_temp = body_starting_core_temp

  parts_by_name = {"head": head, "torso": torso, "arms": arms, "legs": legs, "feet": feet}

  connect_inventory_slot($Head/InventorySlot, head)
  connect_inventory_slot($Torso/InventorySlot, torso)
  connect_inventory_slot($Arms/InventorySlot, arms)
  connect_inventory_slot($Legs/InventorySlot, legs)
  connect_inventory_slot($Feet/InventorySlot, feet)

const body_specific_heat = 3500 # J/(kg*C)
const body_vascular_conduction_rate_base = 1.0 # watts * m^-2 * delta degrees C
const sweat_latent_heat = 2448 # J/g
const watts_per_met = 58.2 # watts per square meter

# C -> Torr
func water_pressure_from_temp(temp:float):
  return 7.50062 * 0.61078 * exp(17.27 * temp / (temp + 237.3))

func clo_to_efficiency_factor(clo:float, sensible_rate:float):
  return 1 / (1 + 0.1545 * clo * sensible_rate)

#
## 10,000 sq cm in 1 sqm
#const skin_saturation_weight = 0.001 * 10000 # g per sqm
#
#func mass_from_wetness(surface_area:float, wetness:float):
  #return surface_area * skin_saturation_weight * wetness
#
#func wetness_from_mass(surface_area:float, sweat_mass:float):
  #return sweat_mass / skin_saturation_weight / surface_area

func update_body_part(part:BodyPart, delta):
  var debug_data = {}
  #var skin_mass = body_specific_gravity * part.surface_area * (part.skin_thickness/1000.0)
  #var core_mass = part.mass - skin_mass

  # Core temp from blood movement around body
  var blood_temp_delta = body_average_core_temp - part.core_temp
  # TODO: This is my own random guess. This should be improved and/or researched.
  # TODO: This should also take into account vasoconstriction in the limbs
  # TODO: This should also make sure that energy is not created or destroyed
  var internal_body_conductance = 10.0 # watts / C
  var body_blood_flow_rate = internal_body_conductance * blood_temp_delta
  debug_data["body_blood_flow_rate"] = body_blood_flow_rate
  var body_blood_flow_energy = body_blood_flow_rate * delta
  var body_blood_flow_delta_t = body_blood_flow_energy / body_specific_heat / part.core_mass()

  # Metabolic heat generation proportional by body mass
  # Increase core temp by amount of metabolic heat generation
  # Metabolic rate is based on surface area, but we will distribute it based on weight
  var part_metabolic_rate = (body_metabolic_rate * watts_per_met * body_surface_area) * (part.mass / body_total_mass)
  debug_data["part_metabolic_rate"] = part_metabolic_rate
  var part_metabolic_energy = part_metabolic_rate * delta
  var core_delta_t_met = part_metabolic_energy / body_specific_heat / part.core_mass()

  # Core to skin heat transfer
  var minimal_skin_conductance = 5.28 # watts / sqm / C
  var blood_thermal_capacity = 1.163 # watt hours per liter per C
  var neutral_skin_blood_flow = 6.3 # l per square meters per hour
  var adjusted_skin_blood_flow = neutral_skin_blood_flow * part.vasoconstriction
  debug_data["skin_blood_flow"] = adjusted_skin_blood_flow
  var blood_based_conductance = adjusted_skin_blood_flow * blood_thermal_capacity
  var total_skin_conductance = (minimal_skin_conductance + blood_based_conductance) * part.surface_area
  var skin_energy_exchange_rate = total_skin_conductance * (part.core_temp - part.skin_temp) # watts
  debug_data["skin_energy_exchange_rate"] = skin_energy_exchange_rate
  var skin_energy_exchanged = skin_energy_exchange_rate * delta
  var core_delta_t_skin_conductance = -skin_energy_exchanged / body_specific_heat / part.core_mass()
  var skin_delta_t_skin_conductance = skin_energy_exchanged / body_specific_heat / part.skin_mass()

  # ========= Skin temp adjustment ==========
  #  = Sensible heat sources: Convection and Radiation =
  # Using sitting model of hc
  var h_convection_constant = 0 # 11.6 + sqrt(wind_speed)
  # Sitting value of hr
  var h_radiation_constant = 4.5
  var h_combined = h_convection_constant + h_radiation_constant
  # Major oversimplification. Assuming MRT == air temp
  var operative_temperature = air_temp
  # Not taking clothing into account
  var sensible_heat_rate = clo_to_efficiency_factor(part.equipped_clo, h_combined) * h_combined * (operative_temperature - part.skin_temp) * part.surface_area
  debug_data["sensible_heat_rate"] = sensible_heat_rate
  var sensible_heat_energy = sensible_heat_rate * delta
  var skin_delta_t_sensible = sensible_heat_energy / body_specific_heat / part.skin_mass()

  #  = Insensible heat loss: Evaporation =
  var sweat_vapor_pressure = water_pressure_from_temp(part.skin_temp)
  var air_vapor_pressure = water_pressure_from_temp(air_temp) * humidity
  var mass_transfer_constant = 23.2 * sqrt(wind_speed)
  var mass_transfer_rate = part.skin_wetness() * part.surface_area * mass_transfer_constant * (sweat_vapor_pressure - air_vapor_pressure) / 60.0
  debug_data["mass_transfer_rate"] = mass_transfer_rate
  var adjusted_mass_trasnsfer_rate = 0.0 if mass_transfer_rate < 0.0 else mass_transfer_rate
  var mass_evaporated = adjusted_mass_trasnsfer_rate * delta
  var mass_available = part.sweat_mass
  var actual_mass_evaporated = min(mass_evaporated, mass_available)
  debug_data["mass_evaporated"] = actual_mass_evaporated
  var evaporation_energy = actual_mass_evaporated * sweat_latent_heat
  debug_data["evaporation_watts"] = -evaporation_energy / delta
  var skin_delta_t_evaporation = -evaporation_energy / body_specific_heat / part.skin_mass()

  part.core_temp += body_blood_flow_delta_t
  part.core_temp += core_delta_t_met
  part.core_temp += core_delta_t_skin_conductance
  part.skin_temp += skin_delta_t_skin_conductance
  part.skin_temp += skin_delta_t_evaporation
  part.skin_temp += skin_delta_t_sensible
  part.sweat_mass -= actual_mass_evaporated

  # === Body response ===
  # Sweating
  var alpha = part.skin_mass()/part.mass
  var threshold_temp = alpha*33.5 + (1-alpha)*37.0
  var signal_temp = alpha*part.skin_temp + (1-alpha)*part.core_temp
  #var threshold_temp = 33.5
  #var signal_temp = part.skin_temp
  var signal_degrees = max(0, signal_temp - threshold_temp)
  var sweating_control_coefficient = 200 # g / sqm / hour / C
  var sweat_rate = sweating_control_coefficient * signal_degrees / 3600 * part.surface_area # g/s
  # Based on 0.5 g/min for the whole body for skin diffusion and respiration
  var diffusion_respiration_rate = 0.5 * (part.surface_area / body_surface_area) / 60
  sweat_rate += diffusion_respiration_rate

  debug_data["sweat_rate"] = sweat_rate * 60.0 # recording g/min
  var sweat_amount = sweat_rate * delta

  part.sweat_mass += sweat_amount
  if part.skin_wetness() > 1.0:
    # Dripping sweat
    part.set_skin_wetness(1.0)

  # TODO: shivering
  # TODO: bring back convection

  var cold_skin_signal = -(part.skin_temp - 34)
  var warm_core_signal = part.core_temp - 36.8
  #cold_skin_signal = clampf(cold_skin_signal, 0.0, 1.0)
  #warm_core_signal = clampf(warm_core_signal, 0.0, 1.0)
  cold_skin_signal = max(0.0, cold_skin_signal)
  warm_core_signal = max(0.0, warm_core_signal)

  part.vasoconstriction = (neutral_skin_blood_flow + 150.0*warm_core_signal) / (1.0 + 0.5*cold_skin_signal) / neutral_skin_blood_flow

  return debug_data

# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta):
  if tooltip_shown and not tooltip_bounding_rect.has_point(get_viewport().get_mouse_position()):
    hide_tooltip()

  delta *= time_rate
  total_time_passed += delta

  body_average_core_temp = 0.0
  body_average_core_temp += (head.core_temp * head.mass / body_total_mass)
  body_average_core_temp += (torso.core_temp * torso.mass / body_total_mass)
  body_average_core_temp += (arms.core_temp * arms.mass / body_total_mass)
  body_average_core_temp += (legs.core_temp * legs.mass / body_total_mass)
  body_average_core_temp += (feet.core_temp * feet.mass / body_total_mass)

  # Update all body parts
  debug_stats["head"] = update_body_part(head, delta)
  debug_stats["torso"] = update_body_part(torso, delta)
  debug_stats["arms"] = update_body_part(arms, delta)
  debug_stats["legs"] = update_body_part(legs, delta)
  debug_stats["feet"] = update_body_part(feet, delta)

  for debug_values in debug_stats.values():
    total_weight_lost += debug_values["mass_evaporated"]

  $Stats/WeightLostValue.text = "%.1fg (%.0f%%)" % [total_weight_lost, total_weight_lost/1000.0/body_total_mass*100.0]
  $Stats/CoreTempValue.text = "%2.2f" % [body_average_core_temp]
  $Stats/TimePassedValue.text = "%2.0fh %2.0fm %2.0fs" % [total_time_passed / 3600, fmod(total_time_passed, 3600)/60, fmod(total_time_passed,60)]

  $Head/SkinTempValue.text = "%2.2f" % [head.skin_temp]
  $Head/CoreTempValue.text = "%2.2f" % [head.core_temp]
  $Head/SkinWetnessValue.text = "%2.2f" % [head.skin_wetness() * 100]

  $Torso/SkinTempValue.text = "%2.0f" % [torso.skin_temp]
  $Torso/SkinWetnessValue.text = "%2.0f" % [torso.skin_wetness() * 100]
  $Arms/SkinTempValue.text = "%2.0f" % [arms.skin_temp]
  $Arms/SkinWetnessValue.text = "%2.0f" % [arms.skin_wetness() * 100]
  $Legs/SkinTempValue.text = "%2.0f" % [legs.skin_temp]
  $Legs/SkinWetnessValue.text = "%2.0f" % [legs.skin_wetness() * 100]
  $Feet/SkinTempValue.text = "%2.0f" % [feet.skin_temp]
  $Feet/SkinWetnessValue.text = "%2.0f" % [feet.skin_wetness() * 100]

func _on_air_temp_slider_value_changed(value):
  air_temp = value
  $Stats/AirTempValue.text = "%2.0f" % [air_temp]

func _on_wind_speed_slider_value_changed(value):
  wind_speed = value
  $Stats/WindSpeedValue.text = "%2.1f km/h" % [wind_speed]

func _on_humidity_slider_value_changed(value):
  humidity = value/100.0
  $Stats/HumidityValue.text = "%2.0f%%" % [humidity * 100.0]

func _on_metabolic_rate_slider_value_changed(value):
  body_metabolic_rate = value
  $Stats/MetabolicRateValue.text = "%2.0f met" % [body_metabolic_rate]

func _on_time_rate_slider_value_changed(value):
  time_rate = value
