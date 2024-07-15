@tool
extends Area2D
class_name Draggable

signal Dragged(drag_origin)
signal Dropped(drop_area)
signal DropRejected(drop_area)
signal PositionChanged(new_position, relative_change, drag_origin)

# A cursor is hovering over the object
signal Hovering
signal StoppedHovering

@export var width:int = 100
@export var height:int = 100
@export var owner_class:Node

enum State {
  STATIONARY,
  BEING_DRAGGED,
}

var state:State = State.STATIONARY

# All coordinates are in global space.
var drag_origin:Vector2
var last_drag_position:Vector2

# Called when the node enters the scene tree for the first time.
func _ready():
  #SetupIcon()
  SetCollisionBoundsShape(width, height)

func SetCollisionBoundsShape(c_width, c_height):
  $CollisionBounds.shape.size = Vector2(c_width, c_height)

# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta):
  if state == State.BEING_DRAGGED:
    # It's possible that the drag action can be released when the mouse is no
    # longer hovering over the draggable area. So we want to stop the drag if
    # the drag action is ever not being held.
    if not Input.is_action_pressed("primary_action"):
      state = State.STATIONARY
      var closest_drop = get_closest_drop_area()
      if closest_drop != null:
        if closest_drop.DropInto(self):
          # If the drop area accepts the item (returns true) then emit Dropped
          Dropped.emit(closest_drop)
    else:
      # Still being dragged. Update signal based on mouse position.
      var mousepos = get_viewport().get_mouse_position()
      PositionChanged.emit(mousepos, mousepos - last_drag_position, drag_origin)
      last_drag_position = mousepos

func SnapTo(new_position):
  PositionChanged.emit(new_position, new_position - last_drag_position, drag_origin)

# Scans all currently colliding DropAreas and returns the closest one, or null.
func get_closest_drop_area():
  var drop_areas = get_overlapping_areas()
  var closest_area = null
  for area in drop_areas:
    if not area is DropArea:
      continue
    elif closest_area == null:
      closest_area = area
    elif ((global_position - area.global_position).length()
        < (global_position - closest_area.global_position).length()):
      closest_area = area
  return closest_area

func _on_mouse_entered():
  Hovering.emit()

func _on_mouse_exited():
  StoppedHovering.emit()

func _on_input_event(viewport, event, shape_idx):
  if event.is_action_pressed("primary_action"):
    drag_origin = get_viewport().get_mouse_position()
    last_drag_position = drag_origin
    state = State.BEING_DRAGGED
    Dragged.emit(drag_origin)
