extends MyGraphNode
class_name ResponseBranchNode

@onready var _responses: Array = get_children()

func _ready() -> void:
	set_slot(0, true, 0, Color.WHITE, true, 0, Color.WHITE)
	set_slot(1, false, 0, Color.WHITE, true, 0, Color.WHITE)
	set_slot(2, false, 0, Color.WHITE, true, 0, Color.WHITE)
	set_slot(3, false, 0, Color.WHITE, true, 0, Color.WHITE)

func get_response_text() -> Array[String]:
	var response_array: Array[String] = []
	for line_edit in _responses:
		response_array.append(line_edit.text)
	return response_array

func import_response_text(import_array: Array) -> void:
	for i in range(4):
		_responses[i].text = import_array[i]
