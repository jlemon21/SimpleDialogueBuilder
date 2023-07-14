extends MyGraphNode
class_name KeyNode

@onready var Key: LineEdit = $Key

func _ready() -> void:
	set_slot(0, false, 0, Color.WHITE, true, 0, Color.WHITE)

func get_key() -> String:
	return Key.text
