extends Node2D
class_name MapCH

class AdjacencyNode:
  var origin_target:int
  var target_target:int
  var path:int
  func _init(origin:int, target:int, path_index:int):
    origin_target = origin
    target_target = target
    path = path_index

var target_list:Array[MapTarget] = []
var path_list:Array[CityPath] = []
var adjacency_graph = []

var active_target = 0

var player_money = 500
var player_apples = 0

var total_distance = 0
var last_distance = 0
var last_path_type = "asdf"

var is_traveling = false
var active_path = -1
var travel_target = 0
var total_travel_time = 0
var elapsed_travel_time = 0

const default_color = 0.0
const hover_color = 0.14
const adjacent_color = 0.02
const active_color = 0.09

func _is_adjacent(target1:int, target2:int):
  for adj_node in adjacency_graph[target1]:
    if adj_node.target_target == target2:
      return true
  return false
  
func _edge_between(target1:int, target2:int):
  for adj_node in adjacency_graph[target1]:
    if adj_node.target_target == target2:
      return adj_node.path
  return -1

func _set_adjacent_target_color(target_index:int, color:float):
  for adj_node in adjacency_graph[target_index]:
    target_list[adj_node.target_target].color = color

func _set_adjacent_path_color(target_index:int, color:Color):
  for adj_node in adjacency_graph[target_index]:
    path_list[adj_node.path].default_color = color

func _reset_target_color(target_index:int):
  if target_index == active_target:
    target_list[target_index].color = active_color
  elif _is_adjacent(active_target, target_index):
    target_list[target_index].color = adjacent_color
  else:
    target_list[target_index].color = default_color

func _on_target_hover(target_index:int):
  target_list[target_index].color = hover_color
  var tt_contents:Array[Tooltip.TooltipContents] = [Tooltip.TooltipContents.new(target_list[target_index].name, "")]
  $Control/Tooltip.set_contents(tt_contents)
  $Control/Tooltip.visible = true

func _on_target_stop_hover(target_index:int):
  _reset_target_color(target_index)
  $Control/Tooltip.visible = false

func _on_target_click(target_index:int):
  if _is_adjacent(target_index, active_target):
    _travel_to(target_index)

func _travel_to(target_index:int):
  var speed_factor = 0.01
  is_traveling = true
  elapsed_travel_time = 0
  travel_target = target_index
  active_path = _edge_between(active_target, target_index)
  total_travel_time = path_list[active_path].path_length() * speed_factor

func _set_active_target(target_index:int):
  # Reset current target colors
  target_list[active_target].color = default_color
  _set_adjacent_target_color(active_target, default_color)
  _set_adjacent_path_color(active_target, Color.WHITE)
  # Set new target colors
  target_list[target_index].color = active_color
  _set_adjacent_target_color(target_index, adjacent_color)
  _set_adjacent_path_color(target_index, Color.NAVAJO_WHITE)
  
  var edge_index = _edge_between(active_target, target_index)
  if edge_index != -1:
    last_distance = path_list[edge_index].path_length()
    total_distance += last_distance
    last_path_type = path_list[edge_index].path_type()
  
  active_target = target_index
  $Camera2D.position_smoothing_enabled = true
  $Camera2D.position = target_list[active_target].position
  
  $Player.position = target_list[target_index].position

  _refresh_labels()

  for adj_node in adjacency_graph[active_target]:
    target_list[adj_node.target_target].known = true
    path_list[adj_node.path].visible = true

# Called when the node enters the scene tree for the first time.
func _ready():
  for child in $Contents.get_children():
    if child is MapTarget:
      target_list.append(child)
    elif child is CityPath:
      path_list.append(child)

  # Build adjacency graph
  for target_index in range(target_list.size()):
    var adj_list = []
    var target = target_list[target_index]
    for path_index in range(path_list.size()):
      var path = path_list[path_index]
      if path.start != null and path.end != null and path.start != path.end:
        if path.start == target:
          adj_list.append(AdjacencyNode.new(target_index, target_list.find(path.end), path_index))
        elif path.end == target:
          adj_list.append(AdjacencyNode.new(target_index, target_list.find(path.start), path_index))
      else:
        print("Bad path: %s" % path.name)
      path.visible = path.start.known or path.end.known
    adjacency_graph.append(adj_list)

  # set up callbacks
  for target_index in range(target_list.size()):
    if target_list[target_index] is City:
      target_list[target_index].Hover.connect(_on_target_hover.bind(target_index))
      target_list[target_index].StopHover.connect(_on_target_stop_hover.bind(target_index))
    target_list[target_index].Click.connect(_on_target_click.bind(target_index))

  _set_active_target(active_target)
  total_distance = 0
  last_distance = 0
  _refresh_labels()

const zoom_factor = 0.1 # %

# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta):
  
  # travel animation
  if is_traveling:
    elapsed_travel_time += delta
    if elapsed_travel_time > total_travel_time:
      is_traveling = false
      _set_active_target(travel_target)
    var t = elapsed_travel_time/total_travel_time
    if path_list[active_path].start == target_list[travel_target]:
      t = 1-t
    $Player.position = path_list[active_path].position_for_t(t)
  
  # Camera zoom
  var mouse_camera_offset = get_viewport_transform().affine_inverse() * get_viewport().get_mouse_position() - $Camera2D.get_screen_center_position()

  if Input.is_action_just_pressed("zoom_in"):
    $Camera2D.position_smoothing_enabled = false
    $Camera2D.zoom *= (1 + zoom_factor)
    $Camera2D.position += mouse_camera_offset * zoom_factor
  if Input.is_action_just_pressed("zoom_out"):
    $Camera2D.position_smoothing_enabled = false
    $Camera2D.zoom /= (1 + zoom_factor)
    $Camera2D.position += mouse_camera_offset * zoom_factor

func _refresh_labels():
  $Control/BottomLeft/ApplesOwnedValue.text = str(player_apples)
  $Control/BottomLeft/MoneyValue.text = str(player_money)
  if target_list[active_target] is City:
    $Control/TopLeft/VisitingValue.text = target_list[active_target].name
  else:
    $Control/TopLeft/VisitingValue.text = "On the road"
  $Control/TopLeft/DistanceValue.text = ("%.0f" % total_distance)
  $Control/TopLeft/LastValue.text = ("%.0f" % last_distance)
  $Control/TopLeft/LastTypeValue.text = last_path_type

func _on_buy():
  if false: #player_money > target_list[active_target].apple_price and target_list[active_target].apples > 0:
    target_list[active_target].apples -= 1
    player_apples += 1
    player_money -= target_list[active_target].apple_price
    _refresh_labels()

func _on_sell():
  if false: #player_apples > 0:
    target_list[active_target].apples += 1
    player_apples -= 1
    player_money += target_list[active_target].apple_price
    _refresh_labels()
