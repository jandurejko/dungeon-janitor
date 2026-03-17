class_name Bone
extends Interactable


func _ready() -> void:
	super._ready()
	if data == null:
		data = BoneData.new()
		data.display_name = "Bone"
		data.interaction_prompt = "Pick up [E]"
		data.task_verb = "throw away"


func interact(player: Node) -> void:
	# If player is already carrying THIS bone, drop it
	if player.current_state == player.State.CARRYING and player.carried_item == self:
		_drop(player)
	# Only pick up if player has free hands
	elif player.current_state != player.State.CARRYING:
		_pickup(player)


func _pickup(player: Node) -> void:
	interaction_area.set_deferred("monitoring", false)
	player.clear_nearby_interactable(self)
	var bone_data := data as BoneData
	player.carried_item = self
	player.change_state(player.State.CARRYING)
	# Override multiplier from resource if present
	if bone_data:
		player.carry_speed_multiplier = bone_data.carry_speed_multiplier


func _drop(player: Node) -> void:
	player.carried_item = null
	player.change_state(player.State.IDLE)
	# Place slightly below the player on drop
	global_position = player.global_position + Vector2(0, 14)
	interaction_area.set_deferred("monitoring", true)
