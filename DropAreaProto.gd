extends Area2D

class_name DropAreaProto

var held_item:DraggableProto = null

# Called when the node enters the scene tree for the first time.
func _ready():
  $Polygon2D.color = "99ffe248"
  pass # Replace with function body.

# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta):
  if has_item():
    $Polygon2D.color = "45ff6a48"
  elif self.has_overlapping_areas():
    var areas = self.get_overlapping_areas()
    if areas[0] is DraggableProto:
      var closest = areas[0].get_closest_drop_area()
      if closest == self:
        $Polygon2D.color = "ffffff48"
      else:
        $Polygon2D.color = "ff999948"

func has_item():
  return held_item != null

func recieve_dropped_item(item:DraggableProto):
  print("%s: Got item with name: \"%s\"" % [self.name, item.item_name])
  item.Dragged.connect(on_held_item_removed)
  held_item = item

func on_held_item_removed():
  if held_item == null:
    print("%s: held item being removed is null" % [self.name])
    return
  print("%s: Item being removed: \"%s\"" % [self.name, held_item.item_name])
  held_item.Dragged.disconnect(on_held_item_removed)
  held_item = null

func _on_area_entered(area):
  $Polygon2D.color = "ff999948"

func _on_area_exited(area):
  $Polygon2D.color = "99ffe248"
