extends Node2D

class Keyframe:
  var duration: float
  var torso: float
  var upper: float
  var lower: float
  var wrist: float
  var rope: float

var throw_keyframes = []
var total_animation_length
var current_time

const START_SWING_RPM = 70
const MAX_SWING_RPM = 100

var swing_rpm = START_SWING_RPM

var throw_start_time

enum State {IDLE, SWINGING, THROWING, THROWN}
var current_state : State = State.IDLE

func add_keyframe(keyframes, duration, torso, upper, lower, wrist, rope):
  var keyframe = Keyframe.new()
  keyframe.duration = duration
  keyframe.torso = deg_to_rad(torso)
  keyframe.upper = deg_to_rad(upper)
  keyframe.lower = deg_to_rad(lower)
  keyframe.wrist = deg_to_rad(wrist)
  keyframe.rope = deg_to_rad(rope)
  keyframes.append(keyframe)

func set_rotations(keyframe):
  $Torso.rotation = keyframe.torso
  $Torso/UpperArm.rotation = keyframe.upper
  $Torso/UpperArm/LowerArm.rotation = keyframe.lower
  $Torso/UpperArm/LowerArm/Wrist.rotation = keyframe.wrist
  $Torso/UpperArm/LowerArm/Wrist/Rope.rotation = keyframe.rope

func lerp_keyframes(keya, keyb, t):
  var ret = Keyframe.new()
  ret.torso = lerp(keya.torso, keyb.torso, t)
  ret.upper = lerp(keya.upper, keyb.upper, t)
  ret.lower = lerp(keya.lower, keyb.lower, t)
  ret.wrist = lerp(keya.wrist, keyb.wrist, t)
  ret.rope = lerp(keya.rope, keyb.rope, t)
  return ret

func find_current_frame(keyframes, playback_time):
  for i in range(keyframes.size()-1):
    if playback_time > keyframes[i].duration:
      playback_time -= keyframes[i].duration
    else:
      $FrameId.text = str(i+1)
      return lerp_keyframes(keyframes[i], keyframes[i+1],
        playback_time/keyframes[i].duration)

  # We fell off to the last frame which is frozen for its duration
  $FrameId.text = str(keyframes.size())
  return keyframes.back()

func play_animation_from(keyframes, playback_time):
  var frame = find_current_frame(keyframes, playback_time)
  set_rotations(frame)

func add_rotation(object: Node, rotation_amount: float):
  object.rotation += rotation_amount
  object.rotation = correct_rotation(object.rotation)

func _ready():
  current_time = 0
  add_keyframe(throw_keyframes, .5, 90, 0, 0, 0, 10)
  add_keyframe(throw_keyframes, .25, 165, 10, -80, 0, 10)
  add_keyframe(throw_keyframes, .3, 165, 20, -160, 0, 10)
  add_keyframe(throw_keyframes, .2, 90, 30, -220, 0, 10)
  add_keyframe(throw_keyframes, .25, 45, 30, -240, 15, 70)
  add_keyframe(throw_keyframes, .1, 0, 0, -280, 15, 70)
  add_keyframe(throw_keyframes, .05, -15, 0, -340, 15, 70)
  add_keyframe(throw_keyframes, .05, -15, 0, -360, 0, 0)
  total_animation_length = 0
  for frame in throw_keyframes:
    total_animation_length += frame.duration
  go_idle()

func correct_rotation(unbalanced_rotation):
  while unbalanced_rotation < 0:
    unbalanced_rotation += TAU
  while unbalanced_rotation > TAU:
    unbalanced_rotation -= TAU
  return unbalanced_rotation

static func hit_target(target, cursor):
  return abs(target.rotation - cursor.rotation) < target.arc_angle/2

func show_thumbdown():
  $Indicator/ThumbsDown.show()
  $Indicator/ThumbsDown/HideTimer.start()

class TargetChecker:
  var target
  var cursor
  var inside_block
  var could_be_hit_now

  func _init(p_target, p_cursor):
    target = p_target
    cursor = p_cursor
    inside_block = hit_target()
    could_be_hit_now = false

  func hit_target():
    return abs(target.rotation - cursor.rotation) < target.arc_angle/2

  func degrees_off():
    return rad_to_deg(abs(target.rotation - cursor.rotation))

  func missed():
    var hit = hit_target()
    if inside_block:
      if not hit:
        # Moved outside of the target after being inside initially.
        inside_block = false
      return false
    else:
      if not could_be_hit_now and hit:
        # Moved into the target
        could_be_hit_now = true
      elif could_be_hit_now and not hit:
        # We were inside the target and now no longer are.
        return true
      return false

  func reset_block():
    inside_block = true
    could_be_hit_now = false

# State transitions
func go_idle(text = "Waiting on first right click"):
  current_state = State.IDLE
  current_time = 0
  $Indicator/Circle.color = Color.WHITE
  $Indicator/Cursor.visible = false
  $Indicator/SwingTarget.visible = false
  $Indicator/ThrowTarget.visible = false
  $Indicator/LeftClickIndicatorTop.visible = false
  $Indicator/LeftClickIndicatorBottom.visible = false
  $Indicator/RightClickIndicator.visible = false
  $CurrentTime.text = text
  set_rotations(throw_keyframes[0])

var swing_target_checker
func start_swinging():
  current_state = State.SWINGING
  current_time = 0
  swing_rpm = START_SWING_RPM
  $Indicator/Cursor.rotation = deg_to_rad(90)
  $Indicator/Cursor.visible = true
  $Indicator/SwingTarget.visible = true
  $Indicator/RightClickIndicator.visible = true
  swing_target_checker = TargetChecker.new($Indicator/SwingTarget, $Indicator/Cursor)
  $CurrentTime.text = "Right: Speed up\nLeft: throw"

var throw_target_checker
var throw_stage
var throw_total_inaccuracy
func start_throwing():
  current_state = State.THROWING
  throw_start_time = current_time
  throw_stage = 0
  throw_total_inaccuracy = 0
  $Indicator/ThrowTarget.visible = true
  $Indicator/LeftClickIndicatorTop.visible = true
  $Indicator/LeftClickIndicatorBottom.visible = false
  $Indicator/RightClickIndicator.visible = false
  $Indicator/SwingTarget.visible = false
  $Indicator/ThrowTarget.rotation = 3.0*PI/2.0
  throw_target_checker = TargetChecker.new($Indicator/ThrowTarget, $Indicator/Cursor)
  $CurrentTime.text = "Throwing!"

# State process functions
func idle():
  if Input.is_action_just_pressed("secondary_action"):
    start_swinging()

func swinging(delta):
  add_rotation($Torso/UpperArm/LowerArm/Wrist, -delta*swing_rpm/60*TAU)
  add_rotation($Indicator/Cursor, -delta*swing_rpm/60*TAU)

  if Input.is_action_just_pressed("secondary_action"):
    if hit_target($Indicator/SwingTarget, $Indicator/Cursor):
      # We hit it, so reset so we can use it again on the next loop.
      swing_target_checker.reset_block()
      $Indicator/ThumbsUp.show()
      $Indicator/ThumbsUp/HideTimer.start()
      swing_rpm = min(swing_rpm + 10, MAX_SWING_RPM)
      if swing_rpm == MAX_SWING_RPM:
        $CurrentTime.text = "At max speed!"
        $Indicator/Circle.color = Color.LIGHT_GREEN
        $Indicator/LeftClickIndicatorBottom.visible = true
        $Indicator/RightClickIndicator.visible = false
      else:
        $CurrentTime.text = "Speeding up!"
    else:
      show_thumbdown()
      go_idle("Right clicked too soon")
  elif Input.is_action_just_pressed("primary_action"):
    if hit_target($Indicator/SwingTarget, $Indicator/Cursor):
      start_throwing()
    else:
      show_thumbdown()
      go_idle("Left clicked too soon")
  elif swing_target_checker.missed():
    show_thumbdown()
    go_idle("Missed click in target")

func throwing(delta):
  add_rotation($Indicator/Cursor, -delta*swing_rpm/60*TAU)
  play_animation_from(throw_keyframes, current_time - throw_start_time)

  if Input.is_action_just_pressed("primary_action"):
    if throw_target_checker.hit_target():
      throw_total_inaccuracy += throw_target_checker.degrees_off()
      throw_target_checker.reset_block()
      throw_stage += 1
      add_rotation($Indicator/ThrowTarget, PI)
      $Indicator/LeftClickIndicatorTop.visible = not $Indicator/LeftClickIndicatorTop.visible
      $Indicator/LeftClickIndicatorBottom.visible = not $Indicator/LeftClickIndicatorBottom.visible
      if throw_stage >= 4:
        $Indicator/ThumbsUp.show()
        $Indicator/ThumbsUp/HideTimer.start()
        go_idle("You threw it at speed %.0f! Accuracy score is %.0f" % [swing_rpm, throw_total_inaccuracy])

    else:
      show_thumbdown()
      go_idle("Threw too early")
  elif throw_target_checker.missed():
    show_thumbdown()
    go_idle("Missed throw")

var speed_factor = 1
func _process(delta):
  var corrected_delta = delta * speed_factor
  current_time += corrected_delta

  if current_state == State.IDLE:
    idle()
  elif current_state == State.SWINGING:
    swinging(corrected_delta)
  elif current_state == State.THROWING:
    throwing(corrected_delta)

func _on_h_slider_drag_ended(value_changed):
  speed_factor = $SpeedFactorSlider.value
