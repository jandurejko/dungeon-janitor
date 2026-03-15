extends Node

signal task_updated(task_key: String, task_label: String, completed: bool)
signal timer_tick(seconds_left: float)
signal level_complete
signal level_failed
signal interaction_prompt_changed(text: String, show: bool)

@export var time_limit: float = 120.0

var _time_remaining: float = 0.0
var _tasks_total: int = 0
var _tasks_done: int = 0
var _active: bool = false


func _ready() -> void:
	add_to_group("level_manager")
	_time_remaining = time_limit
	_connect_interactables()
	_active = true


func _process(delta: float) -> void:
	if not _active:
		return
	_time_remaining = maxf(_time_remaining - delta, 0.0)
	timer_tick.emit(_time_remaining)
	if _time_remaining <= 0.0:
		_active = false
		level_failed.emit()


func _connect_interactables() -> void:
	for node in get_tree().get_nodes_in_group("interactables"):
		# Always connect player_nearby so prompts work for all interactables
		node.player_nearby.connect(_on_player_nearby.bind(node))

		if not node.counts_as_task:
			continue

		node.task_completed.connect(_on_task_completed.bind(node))
		_tasks_total += 1
		var task_label: String = node.data.display_name if node.data else node.name
		task_updated.emit(node.name, task_label, false)


func _on_task_completed(interactable: Node) -> void:
	_tasks_done += 1
	var task_label: String = interactable.data.display_name if interactable.data else interactable.name
	task_updated.emit(interactable.name, task_label, true)
	if _tasks_done >= _tasks_total and _tasks_total > 0:
		_active = false
		level_complete.emit()


func _on_player_nearby(is_near: bool, interactable: Node) -> void:
	if is_near and interactable.data:
		interaction_prompt_changed.emit(interactable.data.interaction_prompt, true)
	else:
		interaction_prompt_changed.emit("", false)
