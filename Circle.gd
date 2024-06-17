@tool
extends Node2D

@export var radius : float = 200:
  set(value):
      radius = value
      queue_redraw()
@export var width : float = 20:
  set(value):
      width = value
      queue_redraw()
@export_range(0, 360, 0.1, "radians_as_degrees") var arc_angle: float = TAU:
  set(value):
      arc_angle = value
      queue_redraw()
@export var color: Color = Color.BLACK:
  set(value):
      color = value
      queue_redraw()

func _draw():
  draw_arc(Vector2.ZERO, radius, -arc_angle/2, arc_angle/2, 100, color, width)
