extends Control

class TestClass:
  func _init(p_value:float):
    value = p_value
  var value:float

var control:float = 5
var test1:float = 5
var test2:TestClass = TestClass.new(5)
var test3:float = 5
var test4:TestClass = TestClass.new(5)
var test5:TestClass = test4

var dict = {"test1": test1, "test2": test2}

# Called when the node enters the scene tree for the first time.
func _ready():
  pass # Replace with function body.


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta):
  $ControlValue.text = "%.0f" % [control]
  $Test1Value.text = "%.0f" % [test1]
  $Test2Value.text =  "%.0f" % [test2.value]
  $Test3Value.text =  "%.0f" % [test3]
  $Test4Value.text =  "%.0f" % [test4.value]
  $Test5Value.text =  "%.0f" % [test5.value]

func _add_float(arg:float, value:float):
  arg += value

func _add_test_class(arg:TestClass, value:float):
  arg.value += value

func _on_increment_pressed():
  control += 1
  dict["test1"] += 1
  dict["test2"].value += 1
  _add_float(test3, 1)
  _add_test_class(test4, 1)

func _on_decrement_pressed():
  control -= 1
  dict["test1"] -= 1
  dict["test2"].value -= 1
  _add_float(test3, -1)
  _add_test_class(test4, -1)
