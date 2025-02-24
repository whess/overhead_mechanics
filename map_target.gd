extends Node2D
class_name MapTarget


@export var known:bool = true:
  set(value):
    known = value
    visible = value
var is_hovering = false

signal Hover
signal StopHover
signal Click

func _ready():
  visible = known

# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(_delta):
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
    
func get_service_list():
  var service_names = []
  
  for child in get_children():
    if child is MapService:
      service_names.append(child.display_name)
    
  return service_names
