extends Node2D

var original_circle_time = 2.5
var circle_time
var max_speed = 0.75
var progress = 0.0
var max_speedup_percent = 0.1
var target_arc_percent = 0.1

signal speed_changed
signal object_thrown

func _ready():
  circle_time = original_circle_time
  $Target.arc_angle = target_arc_percent * TAU

func _process(delta):
  progress += delta

  if Input.is_action_just_pressed("secondary_action"):
    # Change speed based on timing
    var click_accuracy_percent = fmod(progress - circle_time, circle_time) / circle_time
    if click_accuracy_percent > .5:
      click_accuracy_percent -= 1
    var old_circle_time = circle_time
    print("click_accuracy_percentage: " + str(click_accuracy_percent*100.0))
    if abs(click_accuracy_percent) < target_arc_percent/2:
      # Hit target successfully. Speed up.
      circle_time -= circle_time * max_speedup_percent
      circle_time = max(circle_time, max_speed)
      $CirclePath.color = Color.PALE_GREEN
      $CircleFlashTimer.start()
      speed_changed.emit()
    else:
      circle_time += circle_time * abs(click_accuracy_percent) * 5
      circle_time = min(circle_time, original_circle_time)
      $CirclePath.color = Color.PALE_VIOLET_RED
      $CircleFlashTimer.start()
      speed_changed.emit()
    progress = fmod(progress-old_circle_time, old_circle_time) / old_circle_time * circle_time

  $Cursor.set_rotation(-progress / circle_time * TAU)

func _on_circle_flash_timer_timeout():
  $CirclePath.color = Color.CADET_BLUE
