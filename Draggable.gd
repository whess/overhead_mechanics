@tool
extends Area2D
class_name Draggable

signal Dragged
signal Dropped

# A cursor is hovering over the object
signal Hovering
signal StoppedHovering

@export var width:int = 100
@export var height:int = 100
@export var icon_texture:Texture2D

enum State {
  STATIONARY,
  BEING_DRAGGED,
}

var state:State = State.STATIONARY
var click_offset:Vector2

# Called when the node enters the scene tree for the first time.
func _ready():
  SetupIcon()
  SetCollisionBoundsShape(width, height)

# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta):
  pass

func SetCollisionBoundsShape(c_width, c_height):
  $CollisionBounds.shape.size = Vector2(c_width, c_height)

func SetupIcon():
  $Icon.texture = icon_texture
  # Set size based on top level params
  $Icon.polygon[0] = Vector2(-width/2, -height/2)
  $Icon.polygon[1] = Vector2(-width/2,  height/2)
  $Icon.polygon[2] = Vector2( width/2,  height/2)
  $Icon.polygon[3] = Vector2( width/2, -height/2)
  # But UV is based on pixel size of the texture
  $Icon.uv[0] = Vector2(0,0)
  $Icon.uv[1] = Vector2(0,icon_texture.get_height())
  $Icon.uv[2] = Vector2(icon_texture.get_width(),icon_texture.get_height())
  $Icon.uv[3] = Vector2(icon_texture.get_width(),0)

# Scans all currently colliding DropAreas and returns the closest one, or null.
func get_closest_drop_area():
  var drop_areas = get_overlapping_areas()
  var closest_area = null
  for area in drop_areas:
    if not area is DropArea:
      continue
    elif closest_area == null:
      closest_area = area
    elif (position - area.position).length() < (position - closest_area.position).length():
      closest_area = area
  return closest_area

func _on_mouse_entered():
  Hovering.emit()

func _on_mouse_exited():
  StoppedHovering.emit()

func _on_input_event(viewport, event, shape_idx):
  if event.is_action_pressed("primary_action"):
    click_offset = position - get_viewport().get_mouse_position()
    state = State.BEING_DRAGGED
    Dragged.emit()
  elif event.is_action_released("primary_action"):
    if state == State.BEING_DRAGGED:
      state = State.STATIONARY
      var closest_drop = get_closest_drop_area()
      Dropped.emit() # TODO provide what we dropped into or null
      if closest_drop != null:
        position = closest_drop.position # TODO let the drop area handle changing the position
        closest_drop.recieve_dropped_item(self)
