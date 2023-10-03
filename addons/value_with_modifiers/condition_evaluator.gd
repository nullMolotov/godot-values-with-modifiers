@tool
extends Resource
class_name ConditionEvaluator

## Simple class used to evaluate a set of multiple boolean conditions.
##
## An dynamic way of handling with multiple [b]if[/b] statements.[br][br]
## [b]Some use examples may be:[/b][br]Disallow to move the player when frozen.[br]Disallow player to run while reloading.[br]
## Usage example:
##[codeblock]
##var can_move := ConditionEvaluator.new()
##var can_run := ConditionEvaluator.new()
##
##func _physics_process(delta : float) -> void:
##    if Input.is_action_pressed("player_run"):
##        run()
##
##func _on_player_start_reloading() -> void:
##    can_run.set_modifier("reloading", false)
##
##func _on_player_finish_reloading() -> void:
##    can_run.remove_modifier("reloading")
##[/codeblock]

## Emitted when a condition is added.
signal condition_added(condition_name : StringName)

## Emitted when a condition is changed.
signal condition_changed(condition_name : StringName, new_value : bool)

## Emitted when a condition is removed.
signal condition_removed(condition_name : StringName)

## Default signal for [member result_value_changed].
signal default_result_value_changed(new_value : bool)

## Result of checking of all conditions.
var result := true:
	set(new_value):
		if new_value == result:
			return
		
		result = new_value
		result_value_changed.emit(new_value)

var _conditions := {}

## Emitted when [member result] changes.
var result_value_changed := default_result_value_changed

## Returns [member result].
func is_enabled() -> bool:
	return result

## Returns the [ConditionEvaluator] object with [member result_value_changed] replaced by [param custom_signal].[br] Used for method chaining.
func signal_replaced(custom_signal : Signal) -> ConditionEvaluator:
	result_value_changed = custom_signal
	return self

## Adds a condition with a name and a boolean value or sets its value if it already exists.
func set_condition(condition_name : StringName, condition_value : bool) -> void:
	var condition_exists := has_condition(condition_name)
	
	if condition_exists:
		if condition_value == get_condition(condition_name):
			return
		
		_conditions[condition_name] = condition_value
		condition_changed.emit(condition_name, condition_value)
	else:
		_conditions[condition_name] = condition_value
		condition_added.emit(condition_name)
	
	_apply_result()

## Returns the value of a condition or raises an error if it doesn't exist (use [method has_condition]).
func get_condition(condition_name : StringName) -> bool:
	assert(has_condition(condition_name), "Condition named '%s' not found. Call 'has_condition' before 'get_condition'." % condition_name)
	return _conditions[condition_name]

## Returns true if a condition exists.
func has_condition(condition_name : StringName) -> bool:
	return condition_name in _conditions

## Removes a condition if it exists.
func remove_condition(condition_name : StringName) -> void:
	if _conditions.erase(condition_name):
		condition_removed.emit(condition_name)
		_apply_result()

## Toggles the value of a condition
func toggle_condition(condition_name : StringName) -> void:
	assert(has_condition(condition_name), "Condition named '%s' not found." % condition_name)
	var condition_value := _conditions[condition_name] as bool
	condition_value = not condition_value
	_conditions[condition_name] = condition_value
	
	condition_changed.emit(condition_name, condition_value)

func _apply_result() -> void:
	result = not false in _conditions.values()
