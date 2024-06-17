@tool
extends Area2D
class_name DropArea

# A draggable object was dropped into this area
signal DroppedInto
# A draggable object was pulled out of this area
signal DraggedOutOf

# A draggable object is hovering over this area
signal Hovering
signal StoppedHovering

# A draggable object is hovering AND would be the thing dropped into
signal IsHoverTarget
signal StoppedHoverTarget

@export var width:int = 100
@export var height:int = 100

func _ready():
  # Get information about the sprite used, what the object size is
  SetCollisionBoundsShape(width,height) # TODO

func _process(delta):
  # Check if anything is hovering over this area.
  # Emit

  pass

func _on_object_dropped_into(object:Draggable):
  DroppedInto.emit()

func SetCollisionBoundsShape(c_width, c_height):
  #$CollisionBounds.shape = RectangleShape2D.new()
  $CollisionBounds.shape.size = Vector2(c_width, c_height)
