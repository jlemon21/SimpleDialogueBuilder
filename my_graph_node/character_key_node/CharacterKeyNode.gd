extends MyGraphNode
class_name CharacterKeyNode

@onready var CharacterKey: LineEdit = $Key

func _ready() -> void:
	set_slot(0, false, 0, Color.WHITE, true, 0, Color.WHITE)

func get_key() -> String:
	return CharacterKey.text

func import_key(key_string: String) -> void:
	CharacterKey.text = key_string
