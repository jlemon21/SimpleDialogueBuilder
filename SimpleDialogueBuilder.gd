extends Control
class_name DialogueBuilder

@onready var DialogueGraph: GraphEdit = $DialogueGraph

@onready var key_node_packed: PackedScene = preload("res://my_graph_node/key_node/KeyNode.tscn")
@onready var dialogue_node_packed: PackedScene = preload("res://my_graph_node/dialogue_node/DialogueNode.tscn")
@onready var response_node_packed: PackedScene = preload("res://my_graph_node/response_branch_node/ResponseBranchNode.tscn")

var _key_nodes: Array = []
var node_index: int = 0

func _on_new_key_pressed() -> void:
	_add_new_graph_node(key_node_packed)

func _on_new_dialogue_pressed() -> void:
	_add_new_graph_node(dialogue_node_packed)

func _on_new_response_branch_pressed() -> void:
	_add_new_graph_node(response_node_packed)

func _add_new_graph_node(graph_node_packed: PackedScene) -> void:
	var new_graph_node: MyGraphNode = graph_node_packed.instantiate()
	if new_graph_node is KeyNode:
		_key_nodes.append(new_graph_node)
	DialogueGraph.add_child(new_graph_node)
	new_graph_node.close_requested.connect(Callable(self, "_on_close_requested"))

func _on_dialogue_graph_connection_request(from_node: StringName, from_port: int, to_node: StringName, to_port: int) -> void:
	var error: Error = DialogueGraph.connect_node(from_node, from_port, to_node, to_port)

func _on_close_requested(graph_node: GraphNode) -> void:
	_handle_close_graph_node(graph_node.name)

func _on_dialogue_graph_delete_nodes_request(nodes: Array) -> void:
	for node in nodes:
		_handle_close_graph_node(node)

func _handle_close_graph_node(graph_node_name: StringName) -> void:
	var connection_list: Array = DialogueGraph.get_connection_list()
	for connection in connection_list:
		if connection["from"] == graph_node_name:
			DialogueGraph.disconnect_node(connection["from"], connection["from_port"], connection["to"], connection["to_port"])
		if connection["to"] == graph_node_name:
			DialogueGraph.disconnect_node(connection["from"], connection["from_port"], connection["to"], connection["to_port"])
	var selected_graph_node: GraphNode = DialogueGraph.get_node(NodePath(graph_node_name))
	if selected_graph_node is KeyNode:
		_key_nodes.erase(selected_graph_node)
	selected_graph_node.queue_free()

func _on_export_pressed() -> void:
	print(DialogueGraph.get_connection_list())







