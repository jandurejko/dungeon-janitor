class_name CleaningStation
extends Interactable


func _ready() -> void:
	super._ready()
	counts_as_task = false
	if data == null:
		data = CleaningStationData.new()
		data.display_name = "Cleaning Station"
		data.interaction_prompt = "Wash Mop [E]"


func takes_priority_over_carry() -> bool:
	return true


func interact(player: Node) -> void:
	if player.current_state != player.State.CARRYING:
		return
	var mop := player.carried_item as Mop
	if mop == null or not mop.is_dirty:
		return
	mop.make_clean()
