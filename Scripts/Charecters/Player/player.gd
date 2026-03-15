extends CharacterBody2D

enum State { IDLE, MOVING, CARRYING, CLEANING, PUSHING }

const BASE_SPEED = 50

var current_state: State = State.IDLE
var last_direction: String = "down"
var nearby_interactable: Node = null
var carried_item: Node = null
var carry_speed_multiplier: float = 1.0

@onready var animation_player: AnimationPlayer = $AnimationPlayer


func _ready() -> void:
	add_to_group("player")


func _physics_process(delta: float) -> void:
	var direction := Input.get_vector("ui_left", "ui_right", "ui_up", "ui_down")

	_handle_interact_input(delta)

	var speed = BASE_SPEED * carry_speed_multiplier
	# Block movement while cleaning
	if current_state == State.CLEANING:
		velocity = Vector2.ZERO
	else:
		velocity = direction * speed

	move_and_slide()

	_update_state(direction)
	_update_animation(direction)
	_update_carried_item()


func _handle_interact_input(delta: float) -> void:
	if nearby_interactable == null:
		return

	if Input.is_action_just_pressed("interact"):
		nearby_interactable.interact(self)

	# Pass hold-E frames to the current interactable while cleaning
	if current_state == State.CLEANING:
		if Input.is_action_pressed("interact"):
			nearby_interactable.cleaning_progress(delta)
		else:
			nearby_interactable.cleaning_cancelled()


func _update_state(direction: Vector2) -> void:
	# CARRYING, CLEANING, PUSHING states are entered/exited by interactables,
	# not by movement input — don't override them here.
	match current_state:
		State.CARRYING, State.CLEANING, State.PUSHING:
			pass
		_:
			if direction == Vector2.ZERO:
				current_state = State.IDLE
			else:
				current_state = State.MOVING


func _update_animation(direction: Vector2) -> void:
	if direction != Vector2.ZERO:
		if abs(direction.y) > abs(direction.x):
			if direction.y < 0:
				animation_player.play("player_move_up")
				last_direction = "up"
			else:
				animation_player.play("player_move_down")
				last_direction = "down"
		else:
			if direction.x < 0:
				animation_player.play("player_move_left")
				last_direction = "left"
			else:
				animation_player.play("player_move_right")
				last_direction = "right"
	else:
		animation_player.play("player_idle_" + last_direction)


func _update_carried_item() -> void:
	if carried_item:
		carried_item.global_position = global_position + Vector2(0, -10)


# Called by Interactable when the player enters its detection area
func set_nearby_interactable(interactable: Node) -> void:
	nearby_interactable = interactable


# Called by Interactable when the player leaves its detection area
func clear_nearby_interactable(interactable: Node) -> void:
	if nearby_interactable == interactable:
		nearby_interactable = null


# Called by interactable objects to switch the player's state
func change_state(new_state: State) -> void:
	current_state = new_state
	match new_state:
		State.CARRYING:
			carry_speed_multiplier = 0.7
		State.CLEANING:
			carry_speed_multiplier = 1.0
			velocity = Vector2.ZERO
		State.PUSHING:
			carry_speed_multiplier = 0.8
		_:
			carry_speed_multiplier = 1.0
