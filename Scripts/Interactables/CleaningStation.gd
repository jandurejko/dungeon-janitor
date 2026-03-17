class_name CleaningStation
extends Interactable

var _nearby_player: Node = null
var _prompt_visible: bool = false


func _ready() -> void:
	super._ready()
	counts_as_task = false
	if data == null:
		data = CleaningStationData.new()
		data.display_name = "Cleaning Station"
		data.interaction_prompt = "Wash Mop [E]"


func _process(_delta: float) -> void:
	if _nearby_player == null:
		return
	var mop := _nearby_player.carried_item as Mop
	var should_show: bool = mop != null and mop.is_dirty
	if should_show != _prompt_visible:
		_prompt_visible = should_show
		player_nearby.emit(should_show)


func _on_body_entered(body: Node) -> void:
	if body.is_in_group("player"):
		_nearby_player = body
		_player_in_range = true
		body.set_nearby_interactable(self)
		# Prompt visibility is handled by _process based on mop state


func _on_body_exited(body: Node) -> void:
	if body.is_in_group("player"):
		_nearby_player = null
		_player_in_range = false
		body.clear_nearby_interactable(self)
		if _prompt_visible:
			_prompt_visible = false
			player_nearby.emit(false)


func takes_priority_over_carry() -> bool:
	return true


func interact(player: Node) -> void:
	if player.current_state != player.State.CARRYING:
		return
	var mop := player.carried_item as Mop
	if mop == null or not mop.is_dirty:
		return
	mop.make_clean()
