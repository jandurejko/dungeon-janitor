class_name Blood
extends Interactable

var clean_progress: float = 0.0
var _active_player: Node = null

@onready var progress_bar: ProgressBar = $ProgressBar

const BLOOD_TEXTURES: Array[String] = [
	"res://Assets/NEw pack blood/1/1_5.png",
	"res://Assets/NEw pack blood/1/1_7.png",
	"res://Assets/NEw pack blood/1/1_10.png",
	"res://Assets/NEw pack blood/2/1_5.png",
	"res://Assets/NEw pack blood/2/1_7.png",
	"res://Assets/NEw pack blood/2/1_10.png",
	"res://Assets/NEw pack blood/3/1_5.png",
	"res://Assets/NEw pack blood/3/1_7.png",
	"res://Assets/NEw pack blood/3/1_10.png",
]


func _ready() -> void:
	super._ready()
	if data == null:
		data = BloodData.new()
		data.display_name = "Blood Stain"
		data.interaction_prompt = "Clean [Hold E]"
	sprite.texture = load(BLOOD_TEXTURES[randi() % BLOOD_TEXTURES.size()])
	progress_bar.visible = false
	progress_bar.min_value = 0.0
	progress_bar.max_value = 1.0
	progress_bar.value = 0.0


# Blood takes priority so the player can clean while holding the mop
func takes_priority_over_carry() -> bool:
	return true


func interact(player: Node) -> void:
	if player.current_state == player.State.CLEANING and _active_player == player:
		_stop_cleaning(player)
	elif _can_clean(player):
		_start_cleaning(player)


func _can_clean(player: Node) -> bool:
	if player.current_state != player.State.CARRYING:
		return false
	var item: Node = player.carried_item
	if item == null or not item.has_method("make_dirty"):
		return false
	return not item.get("is_dirty")


func cleaning_progress(delta: float) -> void:
	var blood_data := data as BloodData
	var clean_time: float = blood_data.clean_time if blood_data else 2.0
	clean_progress = minf(clean_progress + delta / clean_time, 1.0)
	progress_bar.value = clean_progress
	if clean_progress >= 1.0:
		_finish_cleaning()


func cleaning_cancelled() -> void:
	var blood_data := data as BloodData
	if blood_data and blood_data.reset_on_release:
		clean_progress = 0.0
		progress_bar.value = 0.0
	if _active_player:
		_active_player.change_state(_active_player.State.CARRYING)
		_active_player = null
	progress_bar.visible = false


func _start_cleaning(player: Node) -> void:
	_active_player = player
	player.change_state(player.State.CLEANING)
	progress_bar.visible = true


func _stop_cleaning(player: Node) -> void:
	player.change_state(player.State.CARRYING)
	_active_player = null
	var blood_data := data as BloodData
	if blood_data and blood_data.reset_on_release:
		clean_progress = 0.0
		progress_bar.value = 0.0
	progress_bar.visible = false


func _finish_cleaning() -> void:
	# Dirty the mop that was used
	if _active_player and _active_player.carried_item != null \
			and _active_player.carried_item.has_method("make_dirty"):
		_active_player.carried_item.make_dirty()

	if _active_player:
		# Player still holds the (now dirty) mop — return to CARRYING, not IDLE
		_active_player.change_state(_active_player.State.CARRYING)
		_active_player = null

	task_completed.emit(self)
	hide()


# Player walked away mid-clean — cancel gracefully
func _on_body_exited(body: Node) -> void:
	if body.is_in_group("player") and body == _active_player:
		cleaning_cancelled()
	super._on_body_exited(body)
