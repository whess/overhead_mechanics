extends Area2D

class_name DraggableProto

signal Dragged

static var mouse_button_names = [
  "MOUSE_BUTTON_NONE",
  "MOUSE_BUTTON_LEFT",
  "MOUSE_BUTTON_RIGHT",
  "MOUSE_BUTTON_MIDDLE",
  "MOUSE_BUTTON_WHEEL_UP",
  "MOUSE_BUTTON_WHEEL_DOWN",
  "MOUSE_BUTTON_WHEEL_LEFT",
  "MOUSE_BUTTON_WHEEL_RIGHT",
  "MOUSE_BUTTON_XBUTTON1",
  "MOUSE_BUTTON_XBUTTON2",
]

enum State {
  STATIONARY,
  BEING_DRAGGED,
  BEING_DROPPED,
}

var state:State = State.STATIONARY
var click_offset:Vector2 = Vector2.ZERO
var item_name:String = "godot face"

# Called when the node enters the scene tree for the first time.
func _ready():
  pass # Replace with function body.

# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta):
  if state == State.BEING_DRAGGED:
    var mousepos = get_viewport().get_mouse_position()
    position = Vector2(mousepos.x, mousepos.y) + click_offset

func _on_mouse_entered():
  pass
  #print("Mouse entered")

func _on_mouse_exited():
  pass
  #print("Mouse exited")

func get_closest_drop_area():
  var drop_areas = get_overlapping_areas()
  if drop_areas.size() > 0:
    var closest_area = drop_areas[0]
    for area in drop_areas:
      if not area is DropAreaProto:
        continue
      if (position - area.position).length() < (position - closest_area.position).length():
        closest_area = area
    return closest_area
  else:
    return null

func _on_input_event(viewport, event, shape_idx):
  if event.is_action_pressed("primary_action"):
    click_offset = position - get_viewport().get_mouse_position()
    state = State.BEING_DRAGGED
    Dragged.emit()
  elif event.is_action_released("primary_action"):
    state = State.STATIONARY
    var closest_drop = get_closest_drop_area()
    if closest_drop != null:
      position = closest_drop.position
      closest_drop.recieve_dropped_item(self)


  #if event is InputEventMouseButton:
    #var button_name = mouse_button_names[event.button_index]
    #var up_down = "up" if not event.pressed else "down"
    #var canceled = "canceled" if event.canceled else " "
    #var double_click = "double_click" if event.double_click else " "
    #print("%s %s %s %s" % [button_name, up_down, canceled, double_click])
  #if event is InputEventScreenDrag:
    #print("input event screen drag")

