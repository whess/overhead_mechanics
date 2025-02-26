extends Node
class_name MapService

@export var display_name:String

class ServiceControl:
  func EnterService(service:MapService):
    pass
  func ReturnFromService():
    pass

func _ready():
  if display_name.is_empty():
    display_name = name

func use_service(container:Control):
  pass
