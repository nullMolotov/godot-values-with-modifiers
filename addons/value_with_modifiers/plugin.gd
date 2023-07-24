@tool
extends EditorPlugin

var placeholder_texture := PlaceholderTexture2D.new()

func _enter_tree():
	add_custom_type("FloatWithModifiers", "RefCounted", FloatWithModifiers, placeholder_texture)
	add_custom_type("IntWithModifiers", "RefCounted", IntWithModifiers, placeholder_texture)
	add_custom_type("ConditionEvaluator", "RefCounted", ConditionEvaluator, placeholder_texture)


func _exit_tree():
	remove_custom_type("FloatWithModifiers")
	remove_custom_type("IntWithModifiers")
	remove_custom_type("ConditionEvaluator")
