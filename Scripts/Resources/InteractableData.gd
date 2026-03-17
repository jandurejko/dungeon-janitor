class_name InteractableData
extends Resource

@export var display_name: String = "Object"
@export var interaction_prompt: String = "Interact [E]"
# When non-empty, this interactable is grouped in the task list by display_name.
# The verb appears in the label: "3 Blood Stains to mop up"
@export var task_verb: String = ""
