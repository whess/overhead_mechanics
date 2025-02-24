@tool
extends Line2D
class_name CityPath

enum Type {
  Paved,
  Dirt,
  Trail,
  Bridge,
}

const TypeNames = {
  Type.Paved: "Paved road",
  Type.Dirt: "Dirt road",
  Type.Trail: "Dirt trail",
  Type.Bridge: "Stone Bridge",
}

@export var start:MapTarget:
  set(value):
      start = value
      _update_line()
@export var end:MapTarget:
  set(value):
      end = value
      _update_line()
@export var type:Type:
  set(value):
    type = value
    _update_line()

func _update_line():
  points[0] = start.position if start else points[0]
  points[-1] = end.position if end else points[-1]
  queue_redraw()
  
func path_length():
  var total_length = 0
  if points.size() < 2:
    return 0
  for i in range(0, points.size()-1):
    total_length += points[i].distance_to(points[i+1])
  return total_length
  
func path_type():
  return TypeNames[type]

func position_for_t(t):
  if points.size() < 2:
    return Vector2.ZERO
  if t <= 0:
    return points[0]
  if t >= 1:
    return points[-1]

  var target_length = path_length() * t
  var cumulative_length = 0
  for i in range(0, points.size()-1):
    var current_length = points[i].distance_to(points[i+1])
    if cumulative_length + current_length > target_length and current_length > 0:
      var line_t = (target_length - cumulative_length) / current_length
      return lerp(points[i], points[i+1], line_t)
    cumulative_length += current_length
  return points[-1]
  
func reset_color():
  default_color = Color("ffffff88")
  
func highlight_adjacent():
  default_color = Color("ffffffcc")
  
func highlight_hover():
  default_color = Color("ff0000ff")

func _ready():
  reset_color()
