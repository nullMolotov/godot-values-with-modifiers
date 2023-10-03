@tool
extends Button

const ICON_DICT := {
	0: preload("res://addons/value_with_modifiers/editor/plus.svg"),
	1: preload("res://addons/value_with_modifiers/editor/multiply.svg"),
	2: preload("res://addons/value_with_modifiers/editor/divide.svg")
}

enum OperationModes{
	ADD,
	MULTIPLY,
	DIVIDE
}

var selected := OperationModes.MULTIPLY:
	set(new):
		selected = new
		icon = ICON_DICT[selected]

func _on_pressed() -> void:
	selected = wrapi(selected + 1, 0, 3)
