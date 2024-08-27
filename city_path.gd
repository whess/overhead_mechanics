@tool
extends Line2D
class_name CityPath

@export var start:City:
  set(value):
      start = value
      _update_line()
@export var end:City:
  set(value):
      end = value
      _update_line()

func _update_line():
  points[0] = start.position if start else points[0]
  points[-1] = end.position if end else points[-1]
  queue_redraw()

# Called when the node enters the scene tree for the first time.
func _ready():
  pass # Replace with function body.


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta):
  pass
