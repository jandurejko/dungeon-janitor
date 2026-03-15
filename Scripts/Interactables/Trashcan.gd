class_name Trashcan
extends Interactable


func _ready() -> void:
	super._ready()
	counts_as_task = false
	if data == null:
		data = TrashcanData.new()
		data.display_name = "Trashcan"
		data.interaction_prompt = "Deposit [E]"


func takes_priority_over_carry() -> bool:
	return true


func interact(player: Node) -> void:
	if player.current_state != player.State.CARRYING:
		return
	if player.carried_item == null:
		return
	_deposit(player)


func _deposit(player: Node) -> void:
	var item: Node = player.carried_item
	player.carried_item = null
	player.change_state(player.State.IDLE)
	# Hide before emitting so any scene transition triggered by level_complete
	# doesn't briefly show the item for one frame
	item.hide()
	item.task_completed.emit(item)
