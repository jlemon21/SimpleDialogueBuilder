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

func import_dialogue_text(import_text: String) -> void:
	DialogueText.text = import_text

func get_inflection() -> Array:
	return [
		InflectionType.selected,
		InflectionType.get_item_text(InflectionType.selected)
	]

func import_inflection(inflection_array: Array) -> void:
	InflectionType.selected = inflection_array[0]

func get_dialogue_options() -> Array:
	return [
		EffectButton.selected,
		EffectButton.get_item_text(EffectButton.selected),
		EffectArgument.text
	]

func import_dialogue_options(options_array: Array) -> void:
	EffectButton.selected = options_array[0]
	EffectArgument.text = options_array[2]
