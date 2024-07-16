extends Node2D
class_name Bag

var inventory_slots:Array[InventorySlot]

# Called when the node enters the scene tree for the first time.
func _ready():
  var slots = find_children("*", "InventorySlot")
  inventory_slots.resize(slots.size())

  for i in range(slots.size()):
    inventory_slots[i] = slots[i]

func BagDragged(new_position, relative_change, drag_origin):
  global_position += relative_change
  for slot in inventory_slots:
    if slot.held_item != null:
      slot.held_item.global_position += relative_change

func PrintAllSlots():
  for i in range(inventory_slots.size()):
    var slot = inventory_slots[i]
    var item_string = "null"
    if slot.held_item != null:
      item_string = slot.held_item.item_name
    print("%d: %s has %s" % [i, slot.get_parent().name, item_string])
