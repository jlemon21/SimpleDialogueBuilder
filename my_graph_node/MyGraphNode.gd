extends GraphNode
class_name MyGraphNode

signal close_requested(self_reference: GraphNode)

func _on_close_request() -> void:
	close_requested.emit(self)
