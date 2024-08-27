extends PanelContainer
class_name Tooltip

var tooltip_row_scene = preload("res://tooltip_row.tscn")

class TooltipContents:
  var label:String
  var value:String
  var value_color:Color = Color.WHITE

  func _init(p_label:String, p_value:String, p_value_color:Color = Color.WHITE):
    label = p_label
    value = p_value
    value_color = p_value_color

func set_contents(contents:Array[TooltipContents]):
  var list:Container = $MarginContainer/VList

  for child in list.get_children():
    list.remove_child(child)
    child.queue_free()

  for new_row in contents:
    var row_node = tooltip_row_scene.instantiate()
    row_node.get_node("Label").text = new_row.label
    row_node.get_node("Value").text = new_row.value
    var label_settings = LabelSettings.new()
    label_settings.font_color = new_row.value_color
    row_node.get_node("Value").label_settings = label_settings
    list.add_child(row_node)

# Called when the node enters the scene tree for the first time.
func _ready():
  var rows:Array[TooltipContents] = [
    TooltipContents.new("a", "b")
  ]
  set_contents(rows)

# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta):
  var viewport = get_viewport()
  var mouse_position = get_viewport_transform().affine_inverse() * get_viewport().get_mouse_position()

  global_position = mouse_position

  if mouse_position.x + size.x > viewport.size.x:
    global_position.x -= size.x
  if mouse_position.y + size.y > viewport.size.y:
    global_position.y -= size.y

