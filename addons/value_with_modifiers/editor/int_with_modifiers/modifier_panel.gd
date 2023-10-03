@tool
extends PanelContainer

# I suck at GUI, enjoy :)

const ICON_DICT := {
	0: preload("res://addons/value_with_modifiers/editor/plus.svg"),
	1: preload("res://addons/value_with_modifiers/editor/multiply.svg"),
	2: preload("res://addons/value_with_modifiers/editor/divide.svg")
}

var int_with_modifiers: IntWithModifiers:
	set(new):
		int_with_modifiers = new
		
		var modifiers := int_with_modifiers._modifiers
		
		for modifier_name in modifiers.keys():
			var index = get_node("HBoxContainer/ModifierList").add_item(modifier_name, ICON_DICT[modifiers[modifier_name].operation])
			get_node("HBoxContainer/ModifierList").set_item_metadata(index, modifiers[modifier_name])
			

@onready var mod_name: LineEdit = $HBoxContainer/ModifierPanel/NewModifierPanel/Name/LineEdit
@onready var mod_value: SpinBox = $HBoxContainer/ModifierPanel/NewModifierPanel/ValueAndEnabled/VBoxContainer/SpinBox
@onready var mod_operation: Button = $HBoxContainer/ModifierPanel/NewModifierPanel/ValueAndEnabled/Operation
@onready var mod_priority: SpinBox = $HBoxContainer/ModifierPanel/NewModifierPanel/OperationAndPriority/SpinBox
@onready var mod_enabled: CheckBox = $HBoxContainer/ModifierPanel/NewModifierPanel/ValueAndEnabled/EnabledCheckBox
@onready var remove_button: Button = $HBoxContainer/ModifierPanel/NewModifierPanel/Buttons/RemoveButton

var selected_modifier: StringName:
	set(new):
		selected_modifier = new
		
		if selected_modifier:
			get_node("HBoxContainer/ModifierPanel/NewModifierPanel/DeselectButton").disabled = false
			remove_button.disabled = false
		else:
			get_node("HBoxContainer/ModifierPanel/NewModifierPanel/DeselectButton").disabled = true
			remove_button.disabled = true

func _on_modifier_list_item_selected(index: int) -> void:
	var mod_list: ItemList = get_node("HBoxContainer/ModifierList")
	var metadata = mod_list.get_item_metadata(index)
	
	mod_name.text = mod_list.get_item_text(index)
	mod_name.text_changed.emit(mod_name.text)
	selected_modifier = mod_name.text
	
	remove_button.disabled = not int_with_modifiers.has_modifier(selected_modifier)
	
	mod_value.value = metadata.value
	mod_operation.selected = metadata.operation
	mod_priority.value = metadata.priority
	mod_enabled.button_pressed = metadata.enabled

func _on_set_button_pressed() -> void:
	if selected_modifier:
		int_with_modifiers.modifier_edit(
			selected_modifier,
			mod_value.value,
			mod_operation.selected,
			mod_priority.value,
			mod_enabled.button_pressed
		)
		
		int_with_modifiers.rename_modifier(selected_modifier, mod_name.text)
	else:
		if int_with_modifiers.has_modifier(mod_name.text):
			int_with_modifiers.modifier_edit(
				mod_name.text,
				mod_value.value,
				mod_operation.selected,
				mod_priority.value,
				mod_enabled.button_pressed
				)
		
		else:
			int_with_modifiers.add_modifier(
				mod_name.text,
				mod_value.value,
				mod_operation.selected,
				mod_priority.value
			)
			int_with_modifiers.set_modifier_enabled(mod_name.text, mod_enabled.button_pressed)

func _on_line_edit_text_submitted(new_text: String) -> void:
	if int_with_modifiers.has_modifier(new_text):
		remove_button.disabled = false
	else:
		remove_button.disabled = true

func _on_remove_button_pressed() -> void:
	if selected_modifier:
		int_with_modifiers.remove_modifier(selected_modifier)

func _on_deselect_button_pressed() -> void:
	get_node("HBoxContainer/ModifierList").deselect_all()
	selected_modifier = StringName()
