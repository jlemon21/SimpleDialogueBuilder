extends MyGraphNode

@onready var DialogueText: TextEdit = $DialogueText

func _ready() -> void:
	set_slot(0, true, 0, Color.WHITE, true, 0, Color.WHITE)

func get_dialogue() -> String:
	return DialogueText.text
