extends Node2D

var color = 0.0

# Called when the node enters the scene tree for the first time.
func _ready():
  # Duplicate material for each instance because we can't have instance uniforms
  # in 2d. Only in 3d meshes :/
  # Otherwise, there is no way to set the unforms to be different values in each
  # City scene instance.
  $Sprite2D.material = $Sprite2D.material.duplicate()
  color = randf()

# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta):
  var mouse_pos = get_viewport().get_mouse_position()

  $RayCast2D.global_position = mouse_pos
  $RayCast2D.force_raycast_update()

  var shader = $Sprite2D.material as ShaderMaterial

  if $RayCast2D.is_colliding() and $RayCast2D.get_collider() == $Area2D:
    shader.set_shader_parameter("Shift_Hue", color)
  else:
    shader.set_shader_parameter("Shift_Hue", 0.0)
