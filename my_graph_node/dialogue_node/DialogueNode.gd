extends MyGraphNode
class_name DialogueNode

@onready var DialogueText: TextEdit = $DialogueText
@onready var InflectionType: OptionButton = $InflectionContainer/InflectionType
@onready var EffectButton: OptionButton = $EffectContainer/EffectButton
@onready var EffectArgument: LineEdit = $EffectContainer/EffectArgument

func _ready() -> void:
	set_slot(0, true, 0, Color.WHITE, true, 0, Color.WHITE)

func get_dialogue_text() -> String:
	return DialogueText.text

func get_inflection() -> String:
	return InflectionType.get_item_text(InflectionType.selected)

func get_dialogue_options() -> Array:
	return [
		EffectButton.get_item_text(EffectButton.selected),
		EffectArgument.text
	]
