extends EditorInspectorPlugin
 

const ModifiedValueControl := preload("res://addons/value_with_modifiers/editor/int_with_modifiers/modified_value_panel.tscn")
const ModifierPanel := preload("res://addons/value_with_modifiers/editor/int_with_modifiers/modifier_panel.tscn")

func _can_handle(object: Object) -> bool:
	return object is IntWithModifiers

func _parse_begin(object: Object) -> void:
	var mod_panel_instance := ModifierPanel.instantiate()
	
	add_custom_control(mod_panel_instance)
	mod_panel_instance.int_with_modifiers = object

func _parse_property(object: Object, type: Variant.Type, name: String, hint_type: PropertyHint, hint_string: String, usage_flags: int, wide: bool) -> bool:
	if name == "clamp_value":
		var mvc_instance := ModifiedValueControl.instantiate()
		add_custom_control(mvc_instance)
		mvc_instance.int_with_modifiers = object
		return false
	return false
