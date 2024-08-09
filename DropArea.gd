extends Area2D
class_name DropArea

# A draggable object was dropped into this area
signal DroppedInto(draggable:Draggable)
signal Rejected(draggable:Draggable)

signal Hovering(draggable:Draggable, accepted:bool)
signal StoppedHovering(draggable:Draggable, accepted:bool)
#signal HoverTarget(draggable:Draggable, accepted:bool)
#signal StoppedHoverTarget

@export var width:int = 100
@export var height:int = 100
@export var debug_color:Color = "#0099b36b":
  set(value):
    debug_color = value
    $CollisionBounds.debug_color = value

var will_accept:Callable = func(draggable:Draggable): return true
var current_hover:Draggable = null

func _ready():
  #will_accept = func(draggable:Draggable): return true

  SetCollisionBoundsShape(width,height) # TODO

func SetCollisionBoundsShape(c_width, c_height):
  #$CollisionBounds.shape = RectangleShape2D.new()
  $CollisionBounds.shape.size = Vector2(c_width, c_height)

func _process(delta):
  if has_overlapping_areas():
    for area in get_overlapping_areas():
      if area is Draggable:
        if current_hover == null:
          current_hover = area
          Hovering.emit(area, will_accept.call(area))
          break
  elif current_hover != null:
    StoppedHovering.emit(current_hover, will_accept.call(current_hover))
    current_hover = null

func DropInto(draggable:Draggable):
  if current_hover != null:
    StoppedHovering.emit(current_hover, will_accept.call(current_hover))
    current_hover = null
  # In theory, check if we want to accept this item or not.
  var accepted = will_accept.call(draggable)
  if accepted:
    DroppedInto.emit(draggable)
  else:
    Rejected.emit(draggable)
  return accepted
