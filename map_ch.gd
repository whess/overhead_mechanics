extends Node2D
class_name MapCH

class AdjacencyNode:
  var origin:int
  var target:int
  var path:int
  func _init(p_origin:int, p_target:int, path_index:int):
    origin = p_origin
    target = p_target
    path = path_index

var target_list:Array[MapTarget] = []
var path_list:Array[CityPath] = []
var adjacency_graph = []

var active_target = 0

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
    if adj_node.target == target2:
      return true
  return false
  
func _edge_between(target1:int, target2:int):
  for adj_node in adjacency_graph[target1]:
    if adj_node.target == target2:
      return adj_node.path
  return -1

func _set_adjacent_target_color(target_index:int, color:float):
  for adj_node in adjacency_graph[target_index]:
    target_list[adj_node.target].color = color

func _highlight_adjacent_paths(target_index:int):
  for adj_node in adjacency_graph[target_index]:
    path_list[adj_node.path].highlight_adjacent()
    
func _reset_adjacent_paths(target_index:int):
  for adj_node in adjacency_graph[target_index]:
    path_list[adj_node.path].reset_color()

func _reset_target_color(target_index:int):
  if target_list[target_index] is City:
    if target_index == active_target:
      target_list[target_index].color = active_color
    elif _is_adjacent(active_target, target_index):
      target_list[target_index].color = adjacent_color
    else:
      target_list[target_index].color = default_color
      
func _highlight_road_between(origin:int, target:int):
  var path_index = _edge_between(origin, target)
  if path_index != -1:
    path_list[path_index].highlight_hover()

func _on_target_hover(target_index:int, direct_hover:bool):
  if not is_traveling:
    target_list[target_index].color = hover_color
    _highlight_road_between(active_target, target_index)
  if direct_hover and target_list[target_index] is City:
    var tt_contents:Array[Tooltip.TooltipContents] = [Tooltip.TooltipContents.new(target_list[target_index].name, "")]
    $Control/Tooltip.set_contents(tt_contents)
    $Control/Tooltip.visible = true

func _on_target_stop_hover(target_index:int):
  _reset_target_color(target_index)
  $Control/Tooltip.visible = false
  # Undo the highlight from hovering
  _highlight_adjacent_paths(active_target)

func _on_target_click(target_index:int):
  if not is_traveling and _is_adjacent(target_index, active_target):
    _travel_to(target_index)
    
func _cardinal_for_direction_vector(direction:Vector2, use_16:bool = false):
  if direction.length() == 0:
    return "Inside"
    
  var index = floori((direction.angle() + PI) / (TAU / 32))
  
  const cardinals16 = [
    "West", "WNW", "NorthWest", "NNW", "North", "NNE", "NorthEast", "ENE",
    "East", "ESE", "SouthEast", "SSE", "South", "SSW", "SouthWest", "WSW",
  ]
  const cardinals8 = [
    "West", "NorthWest", "North", "NorthEast", "East", "SouthEast", "South", "SouthWest", 
  ]
  
  if use_16:
    return cardinals16[((index+1)%32)/2]
  else:
    return cardinals8[((index/2+1)%16)/2]
    
func _get_path_directions():
  var directions = []
  
  for adj_node in adjacency_graph[active_target]:
    var path = path_list[adj_node.path]
    var path_amount = 0.5
    var path_partial
    if path.start == target_list[active_target]:
      path_partial = path.position_for_t(path_amount)
    else:
      path_partial = path.position_for_t(1-path_amount)
    var path_direction_vector = path_partial - target_list[active_target].position
    
    directions.append({
      "direction_name": _cardinal_for_direction_vector(path_direction_vector),
      "path_id": adj_node.path,
      "target_id": adj_node.target,
    })
  
  return directions

func _travel_to(target_index:int):
  var speed_factor = 0.01
  is_traveling = true
  elapsed_travel_time = 0
  travel_target = target_index
  active_path = _edge_between(active_target, target_index)
  total_travel_time = path_list[active_path].path_length() * speed_factor
  $Control/TargetDisplay.hide()
  # Undo the highlight from hovering.
  _highlight_adjacent_paths(active_target)

func _set_active_target(target_index:int):
  # Reset current target colors
  target_list[active_target].color = default_color
  _set_adjacent_target_color(active_target, default_color)
  _reset_adjacent_paths(active_target)
  # Set new target colors
  target_list[target_index].color = active_color
  _set_adjacent_target_color(target_index, adjacent_color)
  _highlight_adjacent_paths(target_index)
  
  var edge_index = _edge_between(active_target, target_index)
  if edge_index != -1:
    last_distance = path_list[edge_index].path_length()
    total_distance += last_distance
    last_path_type = path_list[edge_index].path_type()
  
  active_target = target_index
  $Camera2D.position_smoothing_enabled = true
  $Camera2D.position = target_list[active_target].position
  
  $Player.position = target_list[target_index].position
  
  #var service_list = target_list[active_target].get_service_list()
  var direction_names = []
  var directions = _get_path_directions()
  for dir in directions:
    direction_names.append(dir["direction_name"])
  for child in %TravelOptionsContainer.get_children():
    %TravelOptionsContainer.remove_child(child)
    child.queue_free()
  for dir in directions:
    var button = Button.new()
    button.text = dir["direction_name"]
    button.mouse_entered.connect(_on_target_hover.bind(dir["target_id"], false))
    button.mouse_exited.connect(_on_target_stop_hover.bind(dir["target_id"]))
    button.pressed.connect(_on_target_click.bind(dir["target_id"]))
    %TravelOptionsContainer.add_child(button)

  _refresh_labels()

  for adj_node in adjacency_graph[active_target]:
    target_list[adj_node.target].known = true
    path_list[adj_node.path].visible = true

# Called when the node enters the scene tree for the first time.
func _ready():
  for child in $Contents.get_children(true):
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
    target_list[target_index].Hover.connect(_on_target_hover.bind(target_index, true))
    target_list[target_index].StopHover.connect(_on_target_stop_hover.bind(target_index))
    target_list[target_index].Click.connect(_on_target_click.bind(target_index))

  _set_active_target(active_target)
  total_distance = 0
  last_distance = 0
  _refresh_labels()

const zoom_factor = 0.1 # %

func _adjust_camera_for_player():
  # how close the player can get to the edge of the screen before it follows
  # in percentage of viewport size
  const player_camera_margin = 0.15
  var camera_rect = get_canvas_transform().affine_inverse().basis_xform(get_viewport_rect().size)
  var max_camera_dist = camera_rect * (1-player_camera_margin*2)
  var player_camera_dist = $Player.position - $Camera2D.position
  var clamped_player_dist = player_camera_dist.clamp(-max_camera_dist/2, max_camera_dist/2)
  var move_camera_amount = player_camera_dist - clamped_player_dist
  $Camera2D.position += move_camera_amount
  
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
    _adjust_camera_for_player()
    
  
  # Camera zoom
  var mouse_camera_offset = get_global_mouse_position() - $Camera2D.get_screen_center_position()

  if Input.is_action_just_pressed("zoom_in"):
    $Camera2D.position_smoothing_enabled = false
    $Camera2D.zoom *= (1 + zoom_factor)
    $Camera2D.position += mouse_camera_offset * zoom_factor
  if Input.is_action_just_pressed("zoom_out"):
    $Camera2D.position_smoothing_enabled = false
    $Camera2D.zoom /= (1 + zoom_factor)
    $Camera2D.position += mouse_camera_offset * zoom_factor

func _refresh_labels():
  if target_list[active_target] is City:
    $Control/TopLeft/VisitingValue.text = target_list[active_target].name
    $Control/TargetDisplay.show()
    %PlaceName.text = target_list[active_target].display_name
    %PlaceDescription.text = target_list[active_target].description
  else:
    $Control/TopLeft/VisitingValue.text = "On the road"
  $Control/TopLeft/DistanceValue.text = ("%.0f" % total_distance)
  $Control/TopLeft/LastValue.text = ("%.0f" % last_distance)
  $Control/TopLeft/LastTypeValue.text = last_path_type
