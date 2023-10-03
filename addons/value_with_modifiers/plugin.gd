@tool
extends EditorPlugin

const fwm_icon := preload("res://addons/value_with_modifiers/float_with_modifiers.svg")
const iwm_icon := preload("res://addons/value_with_modifiers/int_with_modifiers.svg")
const ce_icon := preload("res://addons/value_with_modifiers/condition_evaluator.svg")

var iwm_inspector_plugin := preload("res://addons/value_with_modifiers/editor/int_with_modifiers/int_with_modifiers_inspector_plugin.gd").new()
var fwm_inspector_plugin := preload("res://addons/value_with_modifiers/editor/float_with_modifiers/float_with_modifiers_inspector_plugin.gd").new()

func _enter_tree():
	add_custom_type("FloatWithModifiers", "Resource", FloatWithModifiers, fwm_icon)
	add_custom_type("IntWithModifiers", "Resource", IntWithModifiers, iwm_icon)
	add_custom_type("ConditionEvaluator", "Resource", ConditionEvaluator, ce_icon)
	add_inspector_plugin(iwm_inspector_plugin)
	add_inspector_plugin(fwm_inspector_plugin)

func _exit_tree():
	remove_custom_type("FloatWithModifiers")
	remove_custom_type("IntWithModifiers")
	remove_custom_type("ConditionEvaluator")
	remove_inspector_plugin(iwm_inspector_plugin)
	remove_inspector_plugin(fwm_inspector_plugin)
