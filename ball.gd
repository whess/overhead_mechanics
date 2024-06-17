@tool
extends Node2D

@export var ball_radius : float = 200:
  set(value):
      ball_radius = value
      queue_redraw()
@export var color: Color = Color.BLACK:
  set(value):
      color = value
      queue_redraw()

func _draw():
  draw_circle(Vector2.ZERO, ball_radius, color)
