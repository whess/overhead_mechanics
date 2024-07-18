extends Node2D
class_name InventorySlot

@export var held_item:Item = null
@export var accepted_item_types:Array[Item.Type] = [Item.Type.FOOD, Item.Type.ARMOR]

@export var normal_color:Color
@export var reject_color:Color
@export var accept_color:Color

# Called when the node enters the scene tree for the first time.
func _ready():
  $DropArea.will_accept = self.will_accept

func will_accept(draggable:Draggable):
  if not draggable.owner_class is Item:
    return false
  var as_item:Item = draggable.owner_class
  return as_item.item_type in accepted_item_types

func OnHover(draggable:Draggable, accepted:bool):
  if accepted:
    $DropArea.debug_color = accept_color
  else:
    $DropArea.debug_color = reject_color

func OnStopHover(draggable:Draggable, accepted:bool):
  $DropArea.debug_color = normal_color

func RecieveItem(draggable:Draggable):
  if not draggable.owner_class is Item:
    print("InventorySlot recieved something not an Item")
    return

  var new_item:Item = draggable.owner_class
  if new_item.current_slot != null:
    var previous_slot:InventorySlot = new_item.current_slot
    previous_slot.held_item = held_item
  held_item = new_item


    #held_item.ChangedInventory.connect(ItemRemoved)

#func ItemRemoved(from:InventorySlot, to:InventorySlot):
  #if to != self:
    #held_item.ChangedInventory.disconnect(ItemRemoved)
    #held_item = null

# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta):
  pass
