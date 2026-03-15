class_name Box
extends Interactable

var _is_grabbed: bool = false
var _active_player: Node = null
var _completed: bool = false
var _locked_axis: String = ""

@onready var target_indicator: Node2D = $TargetIndicator


func _ready() -> void:
	super._ready()
	if data == null:
		data = BoxData.new()
		data.display_name = "Box"
		data.interaction_prompt = "Push [E]"

	# Reparent the target indicator to the scene so it stays fixed in world space
	var box_data := data as BoxData
	if box_data and target_indicator:
		var world_pos := box_data.target_position
		var parent := get_parent()
		remove_child(target_indicator)
		parent.add_child(target_indicator)
		target_indicator.global_position = world_pos


func _physics_process(delta: float) -> void:
	if not _is_grabbed or _active_player == null or _completed:
		return

	var box_data := data as BoxData
	var speed: float = box_data.push_speed if box_data else 30.0
	var direction := Input.get_vector("ui_left", "ui_right", "ui_up", "ui_down")

	# Restrict movement to the axis determined when the player grabbed the box
	match _locked_axis:
		"horizontal":
			direction = Vector2(direction.x, 0.0)
		"vertical":
			direction = Vector2(0.0, direction.y)

	if direction != Vector2.ZERO:
		global_position += direction * speed * delta
		_check_reached_target()


func interact(player: Node) -> void:
	if _is_grabbed and _active_player == player:
		_release(player)
	elif not _is_grabbed:
		_grab(player)


func _grab(player: Node) -> void:
	_is_grabbed = true
	_active_player = player
	player.change_state(player.State.PUSHING)
	# Match player speed to push_speed so they move in sync
	var box_data := data as BoxData
	if box_data:
		player.carry_speed_multiplier = box_data.push_speed / float(player.BASE_SPEED)
	# Lock push axis to whichever side the player approached from
	var offset: Vector2 = player.global_position - global_position
	if abs(offset.x) >= abs(offset.y):
		_locked_axis = "horizontal"
	else:
		_locked_axis = "vertical"
	player.push_axis = _locked_axis


func _release(player: Node) -> void:
	_is_grabbed = false
	_active_player = null
	_locked_axis = ""
	player.push_axis = ""
	player.change_state(player.State.IDLE)


func _check_reached_target() -> void:
	var box_data := data as BoxData
	if box_data == null:
		return
	if global_position.distance_to(box_data.target_position) <= box_data.snap_distance:
		global_position = box_data.target_position
		_completed = true
		if _active_player:
			_release(_active_player)
		task_completed.emit(self)
		if target_indicator and is_instance_valid(target_indicator):
			target_indicator.hide()


# Release if the player somehow leaves the interaction area while pushing
func _on_body_exited(body: Node) -> void:
	if body.is_in_group("player") and body == _active_player:
		_release(body)
	super._on_body_exited(body)
