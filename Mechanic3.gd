extends Node2D

# Length in mm
@export var sling_length : float = 200
# F = kV where V is angular velocity F is friction force
@export var sling_air_resist : float = 0.00005
# Weight in grams
@export var projectile_weight : float = 200
# F = kV where V is linear velocity F is friction force
@export var projectile_air_resist : float = 0.01

# Angular position in radians
var projectile_position : float = PI
# Angular velocity in radians/s
var projectile_velocity : float = PI*1.5

var acceleration_amount = 20

var target_start_angle = TAU*(7.0/12)
var target_end_angle = TAU

func _ready():
  $Target.arc_angle = target_end_angle-target_start_angle
  $Target.rotation = target_start_angle + ($Target.arc_angle/2)
  pass

func _process(delta):
  if Input.is_action_pressed("secondary_action"):
    if projectile_position >= target_start_angle and projectile_position <= target_end_angle:
      projectile_velocity += acceleration_amount * delta
      $Target.color = Color("#b9f0c9")
    elif projectile_position >= target_start_angle - PI and projectile_position <= target_end_angle - PI:
      #projectile_velocity -= acceleration_amount * delta
      projectile_velocity = max(projectile_velocity, 0.5)
      $Target.color = Color("#f0c7b9")
  else:
    $Target.color = Color("#b9f0e5")

  if Input.is_action_just_pressed("secondary_action"):
    $ClickedSpot.visible = true
    $ClickedSpot.rotation = projectile_position
    $ClickedSpot/ShownTimer.start()
  if Input.is_action_just_released("secondary_action"):
    $ReleasedSpot.visible = true
    $ReleasedSpot.rotation = projectile_position
    $ReleasedSpot/ShownTimer.start()

  projectile_velocity -= sling_air_resist*projectile_velocity*projectile_velocity
  projectile_position += projectile_velocity * delta

  if projectile_position > TAU:
    projectile_position -= TAU

  $Ball.position = get_projectile_position_xy()
  $Rope.set_point_position(1, get_projectile_position_xy())

func get_projectile_position_xy():
  return Vector2(sling_length, 0).rotated(projectile_position)

func get_projectile_linear_velocity():
  return projectile_velocity * sling_length
