@tool
extends PanelContainer

var float_with_modifiers : FloatWithModifiers:
	set(new):
		float_with_modifiers = new
		get_node("HBoxContainer/LineEdit").text = str(float_with_modifiers.modified_value)
