class_name BoxData
extends InteractableData

# How fast the box moves when pushed (pixels/sec, should be <= player speed)
@export var push_speed: float = 30.0
# World-space position the box must reach to complete the task
@export var target_position: Vector2 = Vector2.ZERO
# Distance threshold to consider the box "at" the target
@export var snap_distance: float = 4.0
