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
  GrabFocus()

func GrabFocus():
  get_parent().move_child(self, -1)

func DragCancelled():
  print("Reverting to undragged position")
  global_position = undragged_position

func DropInto(drop_area:DropArea):
  if drop_area == null \
      or drop_area.owner == null \
      or not drop_area.owner is InventorySlot:
    DragCancelled()
    return

  global_position = drop_area.global_position
  ChangedInventory.emit(current_slot, drop_area.owner)
  current_slot = drop_area.owner

func UpdatePosition(new_position, relative_change, drag_origin):
  #global_position += relative_change # *0.5
  global_position = new_position + drag_offset
