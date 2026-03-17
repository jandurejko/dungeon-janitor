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
# Grouped tasks: display_name -> {total, done}
var _task_groups: Dictionary = {}


func _ready() -> void:
	add_to_group("level_manager")
	_time_remaining = time_limit
	# Deferred so HUD._ready has run and connected to our signals first
	_connect_interactables.call_deferred()
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
		node.player_nearby.connect(_on_player_nearby.bind(node))

		if not node.counts_as_task or not node.data:
			continue

		# task_completed already emits the interactable — do NOT use .bind() here
		node.task_completed.connect(_on_task_completed)
		_tasks_total += 1

		var verb: String = node.data.task_verb
		if verb != "":
			var key: String = node.data.display_name
			if key not in _task_groups:
				_task_groups[key] = {"total": 0, "done": 0}
			_task_groups[key]["total"] += 1

	# Emit one grouped entry per type
	for key in _task_groups:
		var g: Dictionary = _task_groups[key]
		task_updated.emit(key, _group_label(key, 0, g["total"]), false)

	# Emit individual entries for non-grouped tasks
	for node in get_tree().get_nodes_in_group("interactables"):
		if not node.counts_as_task or not node.data:
			continue
		if node.data.task_verb == "":
			task_updated.emit(node.name, node.data.display_name, false)


func _on_task_completed(interactable: Node) -> void:
	_tasks_done += 1

	if interactable.data and interactable.data.task_verb != "":
		var key: String = interactable.data.display_name
		if key in _task_groups:
			_task_groups[key]["done"] += 1
			var done: int = _task_groups[key]["done"]
			var total: int = _task_groups[key]["total"]
			task_updated.emit(key, _group_label(key, done, total), done >= total)
	else:
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


func _group_label(display_name: String, done: int, total: int) -> String:
	var label: String = display_name + ("s" if total > 1 else "")
	return label + " (" + str(done) + "/" + str(total) + ")"
