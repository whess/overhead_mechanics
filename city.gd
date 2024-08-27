extends Node2D
class_name City

@export var known:bool = true:
  set(value):
    known = value
    visible = value

class Product:
  var buy_orders:Array[int]
  var sell_orders:Array[int]
  var production_rate:int
  var consumption_rate:int
  var maximum_price:int
  var minimum_price:int


@export var apples:int = 5
@export var bananas:int = 5
@export var peaches:int = 5

var color = 0.0:
  set(value):
    color = value
    _update_color()
var is_hovering = false

signal Hover
signal StopHover
signal Click

func _update_color():
  var shader = $Sprite2D.material as ShaderMaterial
  shader.set_shader_parameter("Shift_Hue", color)

# Called when the node enters the scene tree for the first time.
func _ready():
  # Duplicate material for each instance because we can't have instance uniforms
  # in 2d. Only in 3d meshes :/
  # Otherwise, there is no way to set the unforms to be different values in each
  # City scene instance.
  $Sprite2D.material = $Sprite2D.material.duplicate()
  visible = known

# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta):
  var mouse_pos = get_viewport_transform().affine_inverse() * get_viewport().get_mouse_position()
  $RayCast2D.global_position = mouse_pos
  $RayCast2D.force_raycast_update()

  if $RayCast2D.is_colliding() and $RayCast2D.get_collider() == $Area2D and visible:
    if not is_hovering:
      is_hovering = true
      Hover.emit()
  else:
    if is_hovering:
      is_hovering = false
      StopHover.emit()

func _input(event):
  if event.is_action_pressed("primary_action") and is_hovering:
    Click.emit()
