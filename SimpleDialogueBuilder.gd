extends Control
class_name DialogueBuilder

@onready var DialogueGraph: GraphEdit = $DialogueGraph

@onready var character_key_node_packed: PackedScene = preload("res://my_graph_node/character_key_node/CharacterKeyNode.tscn")
@onready var dialogue_trigger_node_packed: PackedScene = preload("res://my_graph_node/dialogue_trigger_node/DialogueTriggerNode.tscn")
@onready var dialogue_node_packed: PackedScene = preload("res://my_graph_node/dialogue_node/DialogueNode.tscn")
@onready var response_node_packed: PackedScene = preload("res://my_graph_node/response_branch_node/ResponseBranchNode.tscn")

const IMPORT_DIRECTORY_ROOT: String = "res://import/"
const EXPORT_DIRECTORY_ROOT: String = "res://export/"

var _character_key_dictionary: Dictionary = {}
var _all_dialogue_nodes: Dictionary = {}
var node_index: int = 0

func _on_new_character_pressed() -> void:
	_add_new_graph_node(character_key_node_packed)

func _on_new_dialogue_trigger_pressed() -> void:
	_add_new_graph_node(dialogue_trigger_node_packed)

func _on_new_dialogue_pressed() -> void:
	_add_new_graph_node(dialogue_node_packed)

func _on_new_response_branch_pressed() -> void:
	_add_new_graph_node(response_node_packed)

func _add_new_graph_node(graph_node_packed: PackedScene) -> void:
	var new_graph_node: MyGraphNode = graph_node_packed.instantiate()
	DialogueGraph.add_child(new_graph_node)
	if new_graph_node is CharacterKeyNode:
		_register_character_key(new_graph_node)
	new_graph_node.close_requested.connect(Callable(self, "_on_close_requested"))

func _register_character_key(character_key_node: CharacterKeyNode) -> void:
	_character_key_dictionary[character_key_node.name] = {
		"character_key": "",
		"dialogue_triggers": {} # trigger condition array: target graph node name
	}

func _on_dialogue_graph_connection_request(from_node: StringName, from_port: int, to_node: StringName, to_port: int) -> void:
	@warning_ignore("unused_variable")
	var error: Error = DialogueGraph.connect_node(from_node, from_port, to_node, to_port)
	
	# Write this connection data to the MyGraphNode scene?
	# Update when nodes are disconnected as well, use custom _connect_node(), _disconnect_node() functions to handle this change. 
	# Make traversal from Key nodes through trees to export to JSON easier, potentially.

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
	if selected_graph_node is CharacterKeyNode:
		_character_key_dictionary.erase(selected_graph_node.name)
	selected_graph_node.queue_free()

func _get_node_connections(node_name: StringName, from_port: int = -1) -> Array[Dictionary]:
	var connection_list: Array[Dictionary] = DialogueGraph.get_connection_list()
	var return_array: Array[Dictionary] = []
	for connection in connection_list:
		if connection["to"] == node_name or connection["from"] == node_name:
			if from_port == -1:
				return_array.append(connection)
			elif connection["from_port"] == from_port:
				return_array.append(connection)
	return return_array

func _on_import_pressed() -> void:
	print("import attempted")

func _on_export_pressed() -> void:
	_clear_old_data()
	#_write_graph_node_configuration() #??
	_write_character_dialogue_triggers()
	_write_all_dialogue_connections()
	_write_to_export_folder()

func _clear_old_data() -> void:
	_all_dialogue_nodes = {}

func _write_character_dialogue_triggers() -> void:
	for key_node_name in _character_key_dictionary.keys():
		var key_node: CharacterKeyNode = DialogueGraph.get_node(str(key_node_name))
		_character_key_dictionary[key_node_name]["character_key"] = key_node.get_key()
		var trigger_connections: Array[Dictionary] = _get_node_connections(key_node_name)
		for connection in trigger_connections:
			# key nodes only have right slot, all connections will be FROM this key
			var trigger_node: DialogueTriggerNode = DialogueGraph.get_node(str(connection["to"]))
			_character_key_dictionary[key_node_name]["dialogue_triggers"][trigger_node.get_trigger_condition()] = trigger_node.name

func _write_all_dialogue_connections() -> void:
	for node in DialogueGraph.get_children():
		if node is DialogueNode:
			_write_dialogue_node(node)
		elif node is ResponseBranchNode:
			_write_response_branch_node(node)

func _write_dialogue_node(dialogue_node: DialogueNode) -> void:
	_all_dialogue_nodes[dialogue_node.name] = {
		"node_type": "dialogue",
		"dialogue_text": dialogue_node.get_dialogue_text(),
		"inflection": dialogue_node.get_inflection(),
		"dialogue_options": dialogue_node.get_dialogue_options(),
		"next_node": _get_node_connections(dialogue_node.name)[0]["to"]
	}

func _write_response_branch_node(response_node: ResponseBranchNode) -> void:
	var response_dictionary: Dictionary = {}
	for i in range(4):
		var response_connection: Array = _get_node_connections(response_node.name, i)
		if !response_connection.is_empty():
			response_dictionary[response_node.get_response(i)] = response_connection[0]["to"]
	
	_all_dialogue_nodes[response_node.name] = {
		"node_type": "response_branch",
		"responses": response_dictionary
	}

func _write_to_export_folder() -> void:
	var dir_access: DirAccess = DirAccess.open("res://")
	if !(dir_access.dir_exists(EXPORT_DIRECTORY_ROOT)):
		dir_access.make_dir(EXPORT_DIRECTORY_ROOT)
	var master_dictionary: Dictionary = {
		"character_keys": _character_key_dictionary,
		"all_dialogue": _all_dialogue_nodes
	}
	var master_dictionary_string: String = JSON.stringify(master_dictionary)
	var file_access_directory: String = str(EXPORT_DIRECTORY_ROOT, "/dialogue_export.json")
	var file: FileAccess = FileAccess.open(file_access_directory, FileAccess.WRITE)
	file.store_string(master_dictionary_string)
	file.close()









