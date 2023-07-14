extends MyGraphNode
class_name DialogueTriggerNode

@onready var TriggerType: OptionButton = $TriggerContainer/TriggerType
@onready var TriggerArgument: LineEdit = $TriggerContainer/TriggerArgument

func _ready():
	set_slot(0, true, 0, Color.WHITE, true, 0, Color.WHITE)

func get_trigger_condition() -> Array:
	return [
		TriggerType.get_item_text(TriggerType.selected),
		TriggerArgument.text
	]
