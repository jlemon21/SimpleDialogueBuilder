extends MyGraphNode
class_name ResponseBranchNode

@onready var _responses: Array = get_children()

func _ready() -> void:
	set_slot(0, true, 0, Color.WHITE, true, 0, Color.WHITE)
	set_slot(1, false, 0, Color.WHITE, true, 0, Color.WHITE)
	set_slot(2, false, 0, Color.WHITE, true, 0, Color.WHITE)
	set_slot(3, false, 0, Color.WHITE, true, 0, Color.WHITE)

func get_response(response_index: int) -> String:
	var index: int = clamp(response_index, 0, _responses.size() - 1)
	return _responses[index].text
