extends CanvasLayer

const _TASK_FONT = preload("res://Assets/Pixelify_Sans/PixelifySans-VariableFont_wght.ttf")

@onready var timer_label: Label = $TimerLabel
@onready var task_list: VBoxContainer = $TasksPanel/TaskList
@onready var interaction_prompt: Label = $InteractionPrompt
@onready var carrying_indicator: HBoxContainer = $CarryingIndicator
@onready var item_name_label: Label = $CarryingIndicator/ItemName

# Maps task_key → Label node
var _task_labels: Dictionary = {}
var _player: Node = null


func _ready() -> void:
	var level_manager := get_tree().get_first_node_in_group("level_manager")
	if level_manager:
		level_manager.task_updated.connect(_on_task_updated)
		level_manager.timer_tick.connect(update_timer)
		level_manager.interaction_prompt_changed.connect(_on_prompt_changed)

	var players := get_tree().get_nodes_in_group("player")
	if players.size() > 0:
		_player = players[0]

	interaction_prompt.visible = false
	carrying_indicator.visible = false


func _process(_delta: float) -> void:
	if _player == null:
		return
	if _player.current_state == _player.State.CARRYING and _player.carried_item != null:
		var item = _player.carried_item
		var name_str: String = item.data.display_name if item.data else "Item"
		show_carrying(name_str)
	else:
		hide_carrying()


func update_timer(seconds_left: float) -> void:
	var minutes: int = int(seconds_left / 60.0)
	var seconds: int = int(seconds_left) % 60
	timer_label.text = "%d:%02d" % [minutes, seconds]


func add_task(task_key: String, task_label: String) -> void:
	if task_key in _task_labels:
		return
	var label := Label.new()
	label.text = "[ ] " + task_label
	label.add_theme_font_override("font", _TASK_FONT)
	label.add_theme_font_size_override("font_size", 8)
	label.clip_text = true
	task_list.add_child(label)
	_task_labels[task_key] = label


func complete_task(task_key: String) -> void:
	if task_key in _task_labels:
		var lbl: Label = _task_labels[task_key]
		# Strip "[ ] " prefix and replace with "[x] "
		lbl.text = "[x] " + lbl.text.substr(4)


func show_prompt(text: String) -> void:
	interaction_prompt.text = text
	interaction_prompt.visible = true


func hide_prompt() -> void:
	interaction_prompt.visible = false


func show_carrying(item_name: String) -> void:
	item_name_label.text = item_name
	carrying_indicator.visible = true


func hide_carrying() -> void:
	carrying_indicator.visible = false


func _on_task_updated(task_key: String, task_label: String, completed: bool) -> void:
	if task_key not in _task_labels:
		add_task(task_key, task_label)
	var lbl: Label = _task_labels[task_key]
	lbl.text = ("[x] " if completed else "[ ] ") + task_label


func _on_prompt_changed(text: String, should_show: bool) -> void:
	if should_show:
		show_prompt(text)
	else:
		hide_prompt()
