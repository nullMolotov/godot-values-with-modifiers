@tool
extends PanelContainer

var int_with_modifiers : IntWithModifiers:
	set(new):
		int_with_modifiers = new
		get_node("HBoxContainer/LineEdit").text = str(int_with_modifiers.modified_value)
