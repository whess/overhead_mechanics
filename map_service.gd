extends Node
class_name MapService

@export var display_name:String

func _ready():
  if display_name.is_empty():
    display_name = name
