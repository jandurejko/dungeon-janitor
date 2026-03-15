class_name Interactable
extends Node2D

signal task_completed(interactable: Node)
signal player_nearby(is_near: bool)

@export var data: InteractableData
@export var counts_as_task: bool = true

@onready var sprite: Sprite2D = $Sprite2D
@onready var interaction_area: Area2D = $InteractionArea

var _player_in_range: bool = false


func _ready() -> void:
	add_to_group("interactables")
	interaction_area.body_entered.connect(_on_body_entered)
	interaction_area.body_exited.connect(_on_body_exited)


# Override in child classes to define interaction behaviour
func interact(player: Node) -> void:
	pass


# Override to return true if this interactable should receive E press even
# when the player is currently carrying an item (e.g. Blood requires Mop).
func takes_priority_over_carry() -> bool:
	return false


# Called each frame by the player while CLEANING state is active
func cleaning_progress(_delta: float) -> void:
	pass


# Called when the player releases E mid-clean
func cleaning_cancelled() -> void:
	pass


func _on_body_entered(body: Node) -> void:
	if body.is_in_group("player"):
		_player_in_range = true
		body.set_nearby_interactable(self)
		player_nearby.emit(true)


func _on_body_exited(body: Node) -> void:
	if body.is_in_group("player"):
		_player_in_range = false
		body.clear_nearby_interactable(self)
		player_nearby.emit(false)
