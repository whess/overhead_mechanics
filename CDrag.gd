extends ColorRect
class_name CDrag

# Called when the node enters the scene tree for the first time.
func _ready():
  pass # Replace with function body.

# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta):
  pass

func _get_drag_data(at_position):
  print("_get_drag_data")
  var data = {}
  data["color"] = color
  data["origin_node"] = self
  return data

func _can_drop_data(at_position, data):
  print("_can_drop_data")
  return true

func _drop_data(at_position, data):
  print("_drop_data")
  data["origin_node"].color = color
  color = data["color"]
