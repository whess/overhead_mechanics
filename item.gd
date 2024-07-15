extends Node2D
class_name Item

@export var item_name:String = "GenericItem"

var drag_offset:Vector2 = Vector2(0,0)
var undragged_position:Vector2

func StartDrag(drag_origin):
  undragged_position = global_position
  drag_offset = global_position - drag_origin

func DropInto(drop_area:DropArea):
  if (drop_area == null):
    global_position = undragged_position
  else:
    global_position = drop_area.global_position

func UpdatePosition(new_position, relative_change, drag_origin):
  #global_position += relative_change # *0.5
  global_position = new_position + drag_offset
