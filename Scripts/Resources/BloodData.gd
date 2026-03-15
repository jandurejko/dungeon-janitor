class_name BloodData
extends InteractableData

# Seconds the player must hold E to fully clean this stain
@export var clean_time: float = 2.0
# Whether releasing E resets progress or just pauses it
@export var reset_on_release: bool = false
