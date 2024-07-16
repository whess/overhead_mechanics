extends Node2D
class_name Item

signal ChangedInventory(from:InventorySlot, to:InventorySlot)

enum Type {
  FOOD,
  ARMOR,
}

@export var item_name:String = "GenericItem"
@export var item_type:Type = Type.FOOD

var drag_offset:Vector2 = Vector2(0,0)
var undragged_position:Vector2
var current_slot:InventorySlot = null

func StartDrag(drag_origin):
  undragged_position = global_position
  drag_offset = global_position - drag_origin

func DropInto(drop_area:DropArea):
  if (drop_area == null):
    global_position = undragged_position
  else:
    global_position = drop_area.global_position
    if drop_area.owner is InventorySlot:
      ChangedInventory.emit(current_slot, drop_area.owner)
      var from_name = "null" if current_slot == null else current_slot.get_parent().name
      print("moved from inventory slot %s" % from_name)
      current_slot = drop_area.owner
      print("moved to inventory slot %s" % current_slot.get_parent().name)

func UpdatePosition(new_position, relative_change, drag_origin):
  #global_position += relative_change # *0.5
  global_position = new_position + drag_offset
