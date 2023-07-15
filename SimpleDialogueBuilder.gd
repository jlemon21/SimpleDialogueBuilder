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

func _add_new_graph_node(graph_node_packed: PackedScene) -> MyGraphNode:
	var new_graph_node: MyGraphNode = graph_node_packed.instantiate()
	DialogueGraph.add_child(new_graph_node)
	new_graph_node.name = new_graph_node.name.replace("@", "_")
	new_graph_node.position_offset = (Vector2(640, 360) + DialogueGraph.scroll_offset)
	if new_graph_node is CharacterKeyNode:
		_register_character_key(new_graph_node)
	new_graph_node.close_requested.connect(Callable(self, "_on_close_requested"))
	return new_graph_node

func _register_character_key(character_key_node: CharacterKeyNode) -> void:
	_character_key_dictionary[character_key_node.name] = {
		"character_key": "",
		"dialogue_triggers": {} # trigger condition array: target graph node name
	}

func _on_dialogue_graph_connection_request(from_node: StringName, from_port: int, to_node: StringName, to_port: int) -> void:
	var from_node_scene: MyGraphNode = DialogueGraph.get_node(str(from_node))
	var to_node_scene: MyGraphNode = DialogueGraph.get_node(str(to_node))
	if from_node_scene is CharacterKeyNode and !(to_node_scene is DialogueTriggerNode):
		return
	elif from_node_scene is DialogueTriggerNode and !(to_node_scene is DialogueNode):
		return
	elif from_node_scene is DialogueNode and ((to_node_scene is CharacterKeyNode) or (to_node_scene is DialogueTriggerNode)):
		return
	elif from_node_scene is ResponseBranchNode and !(to_node_scene is DialogueNode):
		return
	@warning_ignore("unused_variable")
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
	var dir_access: DirAccess = DirAccess.open(IMPORT_DIRECTORY_ROOT)
	var import_directory_files: Array = dir_access.get_files()
	if import_directory_files.is_empty():
		printerr("SimpleDialogueBuilder @ _on_import_pressed(): Import directory is empty.")
		return
		
	_free_all_graph_nodes()
	await get_tree().process_frame
	
	var file_access: FileAccess = FileAccess.open(str(IMPORT_DIRECTORY_ROOT, "/", import_directory_files[0]), FileAccess.READ)
	var import_file: Dictionary = JSON.parse_string(file_access.get_line())
	file_access.close()
	
	_reset_character_key_dictionary(import_file["character_keys"])
	_populate_graph_from_import_file(import_file["all_dialogue"])
	_restore_node_connections(import_file["all_connections"])

func _free_all_graph_nodes() -> void:
	for node in DialogueGraph.get_children():
		_handle_close_graph_node(node.name)

func _reset_character_key_dictionary(character_keys: Dictionary) -> void:
	_character_key_dictionary = character_keys

func _populate_graph_from_import_file(all_dialogue: Dictionary) -> void:
	for node_name in all_dialogue.keys():
		match all_dialogue[node_name]["node_type"]:
			"character_key":
				var character_key: CharacterKeyNode = _add_new_graph_node(character_key_node_packed)
				character_key.name = node_name
				character_key.position_offset = Vector2(
					all_dialogue[node_name]["position_offset_x"],
					all_dialogue[node_name]["position_offset_y"]
				)
				character_key.import_key(all_dialogue[node_name]["character_key"])
			"dialogue_trigger":
				var dialogue_trigger: DialogueTriggerNode = _add_new_graph_node(dialogue_trigger_node_packed)
				dialogue_trigger.name = node_name
				dialogue_trigger.position_offset = Vector2(
					all_dialogue[node_name]["position_offset_x"],
					all_dialogue[node_name]["position_offset_y"]
				)
				dialogue_trigger.import_trigger_condition(all_dialogue[node_name]["dialogue_trigger"])
			"dialogue":
				var dialogue_node: DialogueNode = _add_new_graph_node(dialogue_node_packed)
				dialogue_node.name = node_name
				dialogue_node.position_offset = Vector2(
					all_dialogue[node_name]["position_offset_x"],
					all_dialogue[node_name]["position_offset_y"]
				)
				dialogue_node.import_dialogue_text(all_dialogue[node_name]["dialogue_text"])
				dialogue_node.import_inflection(all_dialogue[node_name]["inflection"])
				dialogue_node.import_dialogue_options(all_dialogue[node_name]["dialogue_options"])
			"response_branch":
				var response_branch: ResponseBranchNode = _add_new_graph_node(response_node_packed)
				response_branch.name = node_name
				response_branch.position_offset = Vector2(
					all_dialogue[node_name]["position_offset_x"],
					all_dialogue[node_name]["position_offset_y"]
				)
				response_branch.import_response_text(all_dialogue[node_name]["response_text"])

func _restore_node_connections(all_connections: Array) -> void:
	for connection in all_connections:
		@warning_ignore("unused_variable")
		var error: Error = DialogueGraph.connect_node(connection["from"], connection["from_port"], connection["to"], connection["to_port"])

func _on_export_pressed() -> void:
	_clear_old_data()
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
		if node is CharacterKeyNode:
			_write_character_key_node(node)
		if node is DialogueTriggerNode:
			_write_dialogue_trigger_node(node)
		elif node is DialogueNode:
			_write_dialogue_node(node)
		elif node is ResponseBranchNode:
			_write_response_branch_node(node)

func _write_character_key_node(character_key_node: CharacterKeyNode) -> void:
	_all_dialogue_nodes[character_key_node.name] = {
		"node_type": "character_key",
		"position_offset_x": character_key_node.position_offset.x,
		"position_offset_y": character_key_node.position_offset.y,
		"character_key": character_key_node.get_key()
	}

func _write_dialogue_trigger_node(dialogue_trigger_node: DialogueTriggerNode) -> void:
	_all_dialogue_nodes[dialogue_trigger_node.name] = {
		"node_type": "dialogue_trigger",
		"position_offset_x": dialogue_trigger_node.position_offset.x,
		"position_offset_y": dialogue_trigger_node.position_offset.y,
		"dialogue_trigger": dialogue_trigger_node.get_trigger_condition()
	}

func _write_dialogue_node(dialogue_node: DialogueNode) -> void:
	_all_dialogue_nodes[dialogue_node.name] = {
		"node_type": "dialogue",
		"position_offset_x": dialogue_node.position_offset.x,
		"position_offset_y": dialogue_node.position_offset.y,
		"dialogue_text": dialogue_node.get_dialogue_text(),
		"inflection": dialogue_node.get_inflection(),
		"dialogue_options": dialogue_node.get_dialogue_options(),
		"next_node": _get_node_connections(dialogue_node.name)[0]["to"]
	}

func _write_response_branch_node(response_node: ResponseBranchNode) -> void:
	var connections_array: Array = []
	for i in range(4):
		var response_connection: Array = _get_node_connections(response_node.name, i)
		if !response_connection.is_empty():
			connections_array.append(response_connection[0]["to"])
		else:
			connections_array.append("")
	
	_all_dialogue_nodes[response_node.name] = {
		"node_type": "response_branch",
		"position_offset_x": response_node.position_offset.x,
		"position_offset_y": response_node.position_offset.y,
		"response_text": response_node.get_response_text(),
		"response_connections": connections_array
	}

func _write_to_export_folder() -> void:
	var dir_access: DirAccess = DirAccess.open("res://")
	if !(dir_access.dir_exists(EXPORT_DIRECTORY_ROOT)):
		dir_access.make_dir(EXPORT_DIRECTORY_ROOT)
	var master_dictionary: Dictionary = {
		"character_keys": _character_key_dictionary,
		"all_dialogue": _all_dialogue_nodes,
		"all_connections": DialogueGraph.get_connection_list()
	}
	var master_dictionary_string: String = JSON.stringify(master_dictionary)
	var system_time_string: String = Time.get_datetime_string_from_system()
	var system_time_string_replaced: String = system_time_string.replace(":", "-")
	var file_access_path: String = str(EXPORT_DIRECTORY_ROOT, "/dialogue_export_", system_time_string_replaced,".json")
	var file: FileAccess = FileAccess.open(file_access_path, FileAccess.WRITE)
	file.store_string(master_dictionary_string)
	file.close()









