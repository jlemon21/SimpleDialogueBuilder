extends GraphNode

signal close_requested(self_reference: GraphNode)

func _ready():
	set_slot(0, true, 0, Color.ALICE_BLUE, true, 0, Color.ALICE_BLUE)

func _on_close_request() -> void:
	close_requested.emit(self)
