class_name Mop
extends Interactable

var is_dirty: bool = false


func _ready() -> void:
	super._ready()
	counts_as_task = false
	if data == null:
		data = MopData.new()
		data.display_name = "Mop"
		data.interaction_prompt = "Pick up [E]"


func interact(player: Node) -> void:
	if player.current_state == player.State.CARRYING and player.carried_item == self:
		_drop(player)
	elif player.current_state != player.State.CARRYING:
		_pickup(player)


func _pickup(player: Node) -> void:
	interaction_area.set_deferred("monitoring", false)
	# Clear self from nearby_interactable so the stale reference can't route
	# the next E press back to this item while it is being carried.
	player.clear_nearby_interactable(self)
	var mop_data := data as MopData
	player.carried_item = self
	player.change_state(player.State.CARRYING)
	if mop_data:
		player.carry_speed_multiplier = mop_data.carry_speed_multiplier


func _drop(player: Node) -> void:
	player.carried_item = null
	player.change_state(player.State.IDLE)
	global_position = player.global_position + Vector2(0, 14)
	interaction_area.set_deferred("monitoring", true)


func make_dirty() -> void:
	is_dirty = true
	if sprite:
		sprite.modulate = Color(0.6, 0.4, 0.2, 1.0)


func make_clean() -> void:
	is_dirty = false
	if sprite:
		sprite.modulate = Color(1.0, 1.0, 1.0, 1.0)
