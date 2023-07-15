extends MyGraphNode
class_name DialogueTriggerNode

@onready var TriggerType: OptionButton = $TriggerContainer/TriggerType
@onready var TriggerArgument: LineEdit = $TriggerContainer/TriggerArgument

func _ready():
	set_slot(0, true, 0, Color.WHITE, true, 0, Color.WHITE)

func get_trigger_condition() -> Array:
	return [
		TriggerType.selected,
		TriggerType.get_item_text(TriggerType.selected),
		TriggerArgument.text
	]

# Intended purely to be used when importing a dialogue file.
# Assumes set_array of structure identical to that returned
# by above function.
func import_trigger_condition(trigger_array: Array) -> void:
	TriggerType.selected = trigger_array[0]
	TriggerArgument.text = trigger_array[2]
