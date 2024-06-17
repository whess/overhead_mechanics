extends Node2D

var original_circle_time = 1.5
var circle_time = original_circle_time
var max_speed = 0.75
var progress = 0.0
var max_speedup_percent = 0.1
var target_arc_percent = 0.1

signal speed_changed
signal object_thrown

func _ready():
  circle_time = original_circle_time
  #$Target.arc_angle = target_arc_percent * TAU

func _process(delta):
  progress += delta

  if Input.is_action_just_pressed("secondary_action"):
    $HandAndRope.position.y = -20

  var rotation = -progress / circle_time * TAU;
  $Ball.set_rotation(rotation)
  $HandAndRope.rope_end = Vector2(200, 0).rotated(rotation)

func _on_circle_flash_timer_timeout():
  $CirclePath.color = Color.CADET_BLUE
