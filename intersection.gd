extends MapTarget
class_name Intersection

var color = 0.0:
  set(value):
    color = value
    _update_color()

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
