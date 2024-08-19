extends Node
class_name BodyPart

const body_specific_gravity = 1010 # kg/m^3

var skin_temp:float # C
var core_temp # C
# var skin_wetness:float # %
var sweat_mass # grams

var vasoconstriction:float # % of normal blood flow to skin
var equipped_clo:float = 0.0

# Constants
var part_name:String
var mass:float # kg
var surface_area:float # sq m
var skin_thickness:float # mm, generally 1mm to 5mm averaged

func skin_mass():
  return body_specific_gravity * surface_area * (skin_thickness/1000.0)

func core_mass():
  return mass - skin_mass()

# 10,000 sq cm in 1 sqm
const skin_saturation_weight = 0.001 * 10000 # g per sqm

#func add_sweat(sweat_grams:float):
  #sweat_mass += sweat_grams

func skin_wetness():
  return sweat_mass / skin_saturation_weight / surface_area

func set_skin_wetness(wetness_percent:float):
  sweat_mass = surface_area * skin_saturation_weight * wetness_percent
