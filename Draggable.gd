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

@export var width:int = 100:
  set(value):
    width = value
    SetCollisionBoundsShape(width, height)
    queue_redraw()
@export var height:int = 100:
  set(value):
    height = value
    SetCollisionBoundsShape(width, height)
    queue_redraw()
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
  queue_redraw()

func SetCollisionBoundsShape(c_width, c_height):
  $CollisionBounds.scale = Vector2(c_width, c_height)
  $Control.size = Vector2(c_width, c_height)
  $Control.position = -(Vector2(c_width, c_height)/2)

# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta):
  if state == State.BEING_DRAGGED:
    # It's possible that the drag action can be released when the mouse is no
    # longer hovering over the draggable area. So we want to stop the drag if
    # the drag action is ever not being held.
    if not Input.is_action_pressed("primary_action"):
      state = State.STATIONARY
      var closest_drop = get_closest_drop_area()
      if closest_drop == null:
        Dropped.emit(null)
      elif closest_drop.DropInto(self):
        # If the drop area accepts the item (returns true) then emit Dropped
        Dropped.emit(closest_drop)
      else:
        DropRejected.emit(closest_drop)
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
    # Note: probably want to snap to the closest drop area even if "will_accept" is false
    if closest_area == null:
      closest_area = area
    elif ((global_position - area.global_position).length()
        < (global_position - closest_area.global_position).length()):
      # TODO: need to also sort by "focus" potentially? Or have some way for
      # the owning object to reject picking some drop areas that are being "obscured".
      closest_area = area
  return closest_area

func _on_mouse_entered():
  Hovering.emit()

func _on_mouse_exited():
  StoppedHovering.emit()

func _on_control_gui_input(event):
  if event.is_action_pressed("primary_action"):
    #TODO: Additionally check if the click would also fall within CollisionBounds
    $Control.accept_event()
    drag_origin = get_viewport().get_mouse_position()
    last_drag_position = drag_origin
    state = State.BEING_DRAGGED
    Dragged.emit(drag_origin)
