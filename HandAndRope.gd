extends Node2D

@export var rope_end: Vector2 = Vector2(200, 0):
  set(value):
    $Rope.set_point_position(1, value)

#func _draw():
