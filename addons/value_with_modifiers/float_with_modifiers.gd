extends RefCounted
class_name FloatWithModifiers

## Class used to store an float base value and a list of modifiers to apply to that value.[br]
##
## Supports add and multiply operations, value clamping, modifier priorities (in ascending order).[br][br]
## [b]Some use examples may be:[/b][br][i]Decreasing player's move speed while in water.[br]Decreasing player's acceleration and friction when stepping on ice.[br]Increasing/decreasing player's critical damage chance.[/i][br]
##Usage example:
##[codeblock]
##
##signal speed_changed(new_value, previous_value)
##
##var movement : Vector2
##
##var speed = (
##    # Method chaining
##    FloatWithModifiers.new(60.0) # Constructor with base value as argument
##        .clamped(0.0, 100.0) # To clamp to a certain range
##            .signal_replaced(speed_changed) # To emit an external signal instead of the object's default signal
##)
##
##func _physics_process(delta : float) -> void:
##    movement = Input.get_vector(
##        "player_left", "player_right",
##        "player_up", "player_down"
##    )
##
##    velocity = movement.normalized * speed.modified_value
##    move_and_slide()
##    
##    if Input.is_action_just_pressed("player_run"):
##        # Name, value, operation type and priority:
##        speed.set_modifier("run", 2.0, speed.ModifierOperation.MULTIPLY, -1)
##    
##    if Input.is_action_just_released("player_run"):
##        speed.remove_modifier("run")
##[/codeblock]

## Default signal for [member base_value_changed].
signal default_modified_value_changed(new_value: float, old_value: float)

## Emitted when [member base_value] changes.
signal base_value_changed(new_value: float, old_value: float)

## Emitted when a new modifier is added.
signal modifier_added(modifier_name: StringName)
## Emitted when a modifier is changed.
signal modifier_changed(modifier_name: StringName, new_value: Dictionary, old_value: Dictionary)
## Emitted when a modifier is removed.
signal modifier_removed(modifier_name: StringName)

## Emitted when [member modified_value] changes. It can also be changed to a different external signal.
var modified_value_changed := default_modified_value_changed:
	set = set_value_changed_signal

## Base value to which all modifiers are applied.
var base_value: float:
	set = set_base_value,
	get = get_base_value

## [member base_value] with all modifiers applied.
var modified_value: float:
	set(new_value):
		var old_value := modified_value
		if new_value == old_value:
			return
		
		modified_value = new_value
		modified_value_changed.emit(new_value, old_value)

## If true, [member modified_value] will be clamped to a value between [member clamp_min] and [member clamp_max].
var clamp_value := false:
	set = set_clamp

## The minimum value for [member modified_value] if [member clamp_value] is true.
var clamp_min: float:
	set = set_clamp_min

## The maximum value for [member modified_value] if [member clamp_value] is true.
var clamp_max: float:
	set = set_clamp_max

var _modifiers := {}

enum ModifierOperation{
	ADD,
	MULTIPLY
}

func _init(initial_base_value: float) -> void:
	base_value = initial_base_value

## Returns the [member FloatWithModifiers] object with [member clamp_value] set to true.[br] Used for method chaining.
func clamped(min_value: float, max_value: float) -> FloatWithModifiers:
	clamp_min = min_value
	clamp_max = max_value
	clamp_value = true
	return self

## Returns the [member FloatWithModifiers] object with [member modified_value_changed] replaced by another external signal.[br] Used for method chaining.
func signal_replaced(new_signal: Signal) -> FloatWithModifiers:
	modified_value_changed = new_signal
	return self

## Sets [member base_value] to a new value.
func set_base_value(new_value: float) -> void:
	var old_value := get_base_value()
	if new_value == old_value:
		return
	
	base_value = new_value
	base_value_changed.emit(new_value, old_value)
	_apply_result()

## Returns [member base_value].
func get_base_value() -> float:
	return base_value

## Adds a modifier with a name, a value, a operation type and a priority level, or sets its values to different ones if it already exists.
func set_modifier(modifier_name: StringName, modifier_value: float, modifier_operation: ModifierOperation, modifier_priority: int = 0) -> void:
	var modifier_exists := has_modifier(modifier_name)
	var new_modifier := {
		value = modifier_value,
		operation_type = modifier_operation,
		priority = modifier_priority
		}
	
	if modifier_exists:
		var old_modifier := get_modifier(modifier_name)
		if new_modifier == old_modifier:
			return
		
		_modifiers[modifier_name] = new_modifier
		modifier_changed.emit(modifier_name, new_modifier, old_modifier)
	else:
		_modifiers[modifier_name] = new_modifier
		modifier_added.emit(modifier_name)
	_apply_result()

## Returns a dictionary containing the values of a modifier, or an empty dictionary if the modifier doesn't exist.
func get_modifier(modifier_name: StringName) -> Dictionary:
	return _modifiers.get(modifier_name, {})

## Removes a modifier if it exists.
func remove_modifier(modifier_name: StringName) -> void:
	if _modifiers.erase(modifier_name):
		modifier_removed.emit(modifier_name)
		_apply_result()

## Sets the priority level of a modifier.
func set_modifier_priority(modifier_name: StringName, priority: int) -> void:
	if not has_modifier(modifier_name):
		return
	
	var mod := get_modifier(modifier_name)
	
	if mod.priority == priority:
		return
	
	set_modifier(modifier_name, mod.value, mod.operation_type, priority)

## Returns true if a modifier exists.
func has_modifier(modifier_name: StringName) -> bool:
	return modifier_name in _modifiers

## Removes all modifiers.
func remove_all_modifiers() -> void:
	if _modifiers.is_empty():
		return
	_modifiers.clear()

func set_clamp(new_value : bool) -> void:
	var old_value := clamp_value
	if new_value == old_value:
		return
	
	clamp_value = new_value
	_apply_result()

func set_clamp_min(new_value : float) -> void:
	var old_value := clamp_min
	if new_value == old_value:
		return
	
	clamp_min = new_value
	
	if clamp_max < clamp_min:
		clamp_max = clamp_min
	if clamp_value:
		modified_value = clampf(modified_value, clamp_min, clamp_max)

func set_clamp_max(new_value : float) -> void:
	var old_value := clamp_max
	if new_value == old_value:
		return
	if new_value < clamp_min:
		new_value = clamp_min
	
	clamp_max = new_value
	
	if clamp_value:
		modified_value = clampf(modified_value, clamp_min, clamp_max)

func set_value_changed_signal(custom_signal : Signal) -> void:
	modified_value_changed = custom_signal

func _apply_result() -> void:
	var result := base_value
	
	var sort_method := (
		func priority_sort(modifier_a: Dictionary, modifier_b: Dictionary):
			return modifier_a.priority < modifier_b.priority
	)
	
	var modifier_values := _modifiers.values()
	
	modifier_values.sort_custom(sort_method)
	
	for mod in modifier_values:
		if mod.operation_type == ModifierOperation.ADD:
			result += mod.value
			continue
		result *= mod.value
	
	if clamp_value:
		result = clampf(result, clamp_min, clamp_max)
	
	modified_value = result