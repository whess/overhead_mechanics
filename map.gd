extends Node2D
class_name Map

class AdjacencyNode:
  var origin_city:int
  var target_city:int
  var path:int
  func _init(origin:int, target:int, path_index:int):
    origin_city = origin
    target_city = target
    path = path_index

var city_list:Array[City] = []
var path_list:Array[CityPath] = []
var adjacency_graph = []

var active_city = 0

var player_money = 500
var player_apples = 0

const default_color = 0.0
const hover_color = 0.14
const adjacent_color = 0.02
const active_color = 0.09

func _is_adjacent(city1:int, city2:int):
  for adj_node in adjacency_graph[city1]:
    if adj_node.target_city == city2:
      return true
  return false

func _set_adjacent_city_color(city_index:int, color:float):
  for adj_node in adjacency_graph[city_index]:
    city_list[adj_node.target_city].color = color

func _set_adjacent_path_color(city_index:int, color:Color):
  for adj_node in adjacency_graph[city_index]:
    path_list[adj_node.path].default_color = color

func _reset_city_color(city_index:int):
  if city_index == active_city:
    city_list[city_index].color = active_color
  elif _is_adjacent(active_city, city_index):
    city_list[city_index].color = adjacent_color
  else:
    city_list[city_index].color = default_color

func _on_city_hover(city_index:int):
  city_list[city_index].color = hover_color
  var tt_contents:Array[Tooltip.TooltipContents] = [Tooltip.TooltipContents.new(city_list[city_index].name, "")]
  $Control/Tooltip.set_contents(tt_contents)
  $Control/Tooltip.visible = true

func _on_city_stop_hover(city_index:int):
  _reset_city_color(city_index)
  $Control/Tooltip.visible = false

func _on_city_click(city_index:int):
  if _is_adjacent(city_index, active_city):
    _set_active_city(city_index)

func _set_active_city(city_index:int):
  # Reset current city colors
  city_list[active_city].color = default_color
  _set_adjacent_city_color(active_city, default_color)
  _set_adjacent_path_color(active_city, Color.WHITE)
  # Set new city colors
  city_list[city_index].color = active_color
  _set_adjacent_city_color(city_index, adjacent_color)
  _set_adjacent_path_color(city_index, Color.NAVAJO_WHITE)
  active_city = city_index
  $Camera2D.position_smoothing_enabled = true
  $Camera2D.position = city_list[active_city].position

  _refresh_labels()

  for adj_node in adjacency_graph[active_city]:
    city_list[adj_node.target_city].known = true
    path_list[adj_node.path].visible = true

# Called when the node enters the scene tree for the first time.
func _ready():
  for child in $Contents.get_children():
    if child is City:
      city_list.append(child)
    elif child is CityPath:
      path_list.append(child)

  # Build adjacency graph
  for city_index in range(city_list.size()):
    var adj_list = []
    var city = city_list[city_index]
    for path_index in range(path_list.size()):
      var path = path_list[path_index]
      if path.start != null and path.end != null and path.start != path.end:
        if path.start == city:
          adj_list.append(AdjacencyNode.new(city_index, city_list.find(path.end), path_index))
        elif path.end == city:
          adj_list.append(AdjacencyNode.new(city_index, city_list.find(path.start), path_index))
      else:
        print("Bad path: %s" % path.name)
      path.visible = path.start.known or path.end.known
    adjacency_graph.append(adj_list)

  # set up callbacks
  for city_index in range(city_list.size()):
    city_list[city_index].Hover.connect(_on_city_hover.bind(city_index))
    city_list[city_index].StopHover.connect(_on_city_stop_hover.bind(city_index))
    city_list[city_index].Click.connect(_on_city_click.bind(city_index))

  _set_active_city(active_city)
  _refresh_labels()

const zoom_factor = 0.1 # %

# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta):
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
  $Control/ScreenText/ApplesOwnedValue.text = str(player_apples)
  $Control/ScreenText/MoneyValue.text = str(player_money)
  $Control/ScreenText/VisitingValue.text = city_list[active_city].name
  $Control/ScreenText/ApplesValue.text = str(city_list[active_city].apples)
  $Control/ScreenText/ApplePriceValue.text = str(city_list[active_city].apple_price)

func _on_buy():
  if player_money > city_list[active_city].apple_price and city_list[active_city].apples > 0:
    city_list[active_city].apples -= 1
    player_apples += 1
    player_money -= city_list[active_city].apple_price
    _refresh_labels()

func _on_sell():
  if player_apples > 0:
    city_list[active_city].apples += 1
    player_apples -= 1
    player_money += city_list[active_city].apple_price
    _refresh_labels()
