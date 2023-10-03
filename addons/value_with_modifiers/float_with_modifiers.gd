@tool
extends Resource
class_name FloatWithModifiers

## Class used to store an float base value and a list of modifiers to apply to that value.[br]
##
## Supports add and multiply operations, value clamping, modifier enabling/disabling and modifier priorities (in ascending order).[br][br]
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
##    FloatWithModifiers.create(60.0) # Constructor with base value as argument
##        .clamped(0.0, 100.0) # To clamp to a certain range
##            .signal_replaced(speed_changed) # To emit an external signal instead of the object's default signal
##)
##
##func _ready() -> void:
##    # Name, value, operation type and priority:
##    speed.add_modifier("run", 2.0, speed.MODIFIER_MULTIPLY, -1)
##
##func _physics_process(delta : float) -> void:
##    movement = Input.get_vector(
##        "player_left", "player_right",
##        "player_up", "player_down"
##    )
##    
##    if Input.is_action_just_pressed("player_run"):
##        # Modifier "run" is enabled.
##        speed.modifier_on("run")
##    
##    if Input.is_action_just_released("player_run"):
##        # Modifier "run" is disabled.
##        speed.modifier_off("run")
##    
##    velocity = movement.normalized * speed.modified_value
##    move_and_slide()
##[/codeblock]

## Default signal for [member base_value_changed].
signal default_modified_value_changed(value: float, old_value: float)

## Emitted when [member base_value] changes.
signal base_value_changed(value: float, old_value: float)

## Emitted when a new modifier is added.
signal modifier_added(name: StringName)
## Emitted when a modifier is changed.
signal modifier_changed(name: StringName, value: Dictionary, old_value: Dictionary)
## Emitted when a modifier is removed.
signal modifier_removed(name: StringName)

const MODIFIER_ADD = 0 ## Add operation.
const MODIFIER_MULTIPLY = 1 ## Multiply operation.
const MODIFIER_DIVIDE = 2 ## Divide operation, carefully avoid divisions by 0 to avoid NaN values.

## Base value to which all modifiers are applied.
@export var base_value: float = 1:
	set = set_base_value,
	get = get_base_value

## If true, [member modified_value] will be clamped to a value between [member clamp_min] and [member clamp_max].
@export var clamp_value := false:
	set = set_clamp

## The minimum value for [member modified_value] if [member clamp_value] is true.
var clamp_min: float = 0:
	set = set_clamp_min

## The maximum value for [member modified_value] if [member clamp_value] is true.
var clamp_max: float = 100:
	set = set_clamp_max

## Emitted when [member modified_value] changes. It can also be changed to a different external signal.
var modified_value_changed: Signal = default_modified_value_changed:
	set = set_value_changed_signal

## [member base_value] with all modifiers applied.
var modified_value: float:
	set(new_value):
		var old_value := modified_value
		if new_value == old_value:
			return
		
		modified_value = new_value
		modified_value_changed.emit(new_value, old_value)

var _modifiers := {}

func _init() -> void:
	_calculate_result()

func _get_property_list() -> Array[Dictionary]:
	var show_clamp_min_max := clamp_value
	
	var clamp_min_max_usage := PROPERTY_USAGE_NO_EDITOR
	
	if show_clamp_min_max:
		clamp_min_max_usage = PROPERTY_USAGE_DEFAULT
	
	var properties : Array[Dictionary]
	
	properties.append({
		name = "clamp_min",
		type = TYPE_INT,
		usage = clamp_min_max_usage
	})
	
	properties.append({
		name = "clamp_max",
		type = TYPE_INT,
		usage = clamp_min_max_usage
	})
	
	properties.append({
		name = "_modifiers",
		type = TYPE_DICTIONARY,
		usage = PROPERTY_USAGE_NO_EDITOR
	})
	
	# modifiers dont get applied at editor startup so instead this must be serialized too.
	properties.append({
		name = "modified_value",
		type = TYPE_FLOAT,
		usage = PROPERTY_USAGE_NO_EDITOR
	})
	
	return properties

## Returns a new [FloatWithModifiers] objectwith parameter [param base_value] as [member base_value].
static func create(base_value: float) -> FloatWithModifiers:
	var new_instance := FloatWithModifiers.new()
	new_instance.base_value = base_value
	return new_instance

## Returns the [member FloatWithModifiers] object with [member clamp_value] set to true.[br] Used for method chaining.
func clamped(min_value: float, max_value: float) -> FloatWithModifiers:
	clamp_min = min_value
	clamp_max = max_value
	clamp_value = true
	return self

## Returns the [member FloatWithModifiers] object with [member modified_value_changed] replaced by another external signal.[br] Used for method chaining.
func signal_replaced(custom_signal: Signal) -> FloatWithModifiers:
	modified_value_changed = custom_signal
	return self

## Sets [member base_value] to a new value.
func set_base_value(value: float) -> void:
	var old_value: float = get_base_value()
	if value == old_value:
		return
	
	base_value = value
	
	base_value_changed.emit(value, old_value)
	_calculate_result()

## Returns [member base_value].
func get_base_value() -> float:
	return base_value

func set_clamp(value: bool) -> void:
	var old_value: bool = clamp_value
	if value == old_value:
		return
	
	clamp_value = value
	_calculate_result()

func set_clamp_min(value: float) -> void:
	var old_value: float = clamp_min
	if value == old_value:
		return
	
	clamp_min = value
	
	if clamp_max < clamp_min:
		clamp_max = clamp_min
	
	
	if clamp_value:
		_calculate_result()
	else:
		notify_property_list_changed()

func set_clamp_max(value: float) -> void:
	var old_value: float = clamp_max
	if value == old_value:
		return
	
	if value < clamp_min:
		value = clamp_min
	
	clamp_max = value
	
	if clamp_value:
		_calculate_result()
	else:
		notify_property_list_changed()

## Adds a modifier with a name, a value, an operation type ([member MODIFIER_ADD] or [member MODIFIER_MULTIPLY]) and a optional priority level (in ascending order).[br]
## New modifiers are disabled by default, enable them when they are needed using [method set_modifier_enabled] or [method modifier_on].
func add_modifier(name: StringName, value: float, operation: int, priority: int = 0) -> void:
	assert(not has_modifier(name),
			"Tried to add modifier '%s' when already exists." % name
	)
	
	_modifiers[name] = {
		value = value,
		operation = operation,
		priority = priority,
		enabled = false
	}
	notify_property_list_changed()

## Renames a modifier
func rename_modifier(name: StringName, new_name: StringName) -> void:
	_assert_modifier_exists(name)
	
	if name == new_name:
		return
	
	_modifiers[new_name] = _modifiers[name]
	_modifiers.erase(name)
	notify_property_list_changed()

## Edits a modifier's values.
func modifier_edit(name: StringName, value: float, operation: int, priority: int, enabled: bool) -> void:
	_assert_modifier_exists(name)
	
	var modifier := get_modifier(name)
	
	var new_modifier := {
		value = value,
		operation = operation,
		priority = priority,
		enabled = enabled
	}
	
	if new_modifier == modifier:
		return
		
	var enabled_changed := false
	
	if new_modifier.enabled != modifier.enabled:
		enabled_changed = true
	
	_modifiers[name] = new_modifier
	
	if enabled_changed:
		_calculate_result()
	else:
		if modifier.enabled:
			_calculate_result()
		else:
			notify_property_list_changed()

## Sets a modifier's value.
func set_modifier(name: StringName, value: float) -> void:
	_assert_modifier_exists(name)
	
	var modifier: Dictionary = get_modifier(name)
	
	if modifier.value == value:
		return
	
	var old_modifier: Dictionary = modifier.duplicate(true)
	
	modifier.value = value
	
	modifier_changed.emit(name, modifier, old_modifier)
	
	if modifier.enabled:
		_calculate_result()
	else:
		notify_property_list_changed()

## Returns a dictionary containing the values of a modifier.
func get_modifier(name: StringName) -> Dictionary:
	_assert_modifier_exists(name)
	return _modifiers.get(name)

## Removes a modifier if it exists.
func remove_modifier(name: StringName) -> void:
	if not has_modifier(name):
		return
	
	var mod_enabled : bool = get_modifier(name).enabled
	
	if _modifiers.erase(name):
		modifier_removed.emit(name)
		if mod_enabled:
			_calculate_result()
		else:
			notify_property_list_changed()

## Enables or disables a modifier.
func set_modifier_enabled(name: StringName, enabled: bool) -> void:
	_assert_modifier_exists(name)
	
	var modifier: Dictionary = get_modifier(name)
	
	if enabled == modifier.enabled:
		return
	
	var old_modifier: Dictionary = modifier.duplicate(true)
	
	modifier.enabled = enabled
	
	modifier_changed.emit(name, modifier, old_modifier)
	
	_calculate_result()

## Disables a modifier.
func modifier_off(name: StringName) -> void:
	_assert_modifier_exists(name)
	
	set_modifier_enabled(name, false)

## Enables a modifier.
func modifier_on(name: StringName) -> void:
	_assert_modifier_exists(name)
	
	set_modifier_enabled(name, true)

## Sets a modifier's priority level (priorities work in ascending order).
func set_modifier_priority(name: StringName, priority: int) -> void:
	_assert_modifier_exists(name)
	
	var modifier: Dictionary = get_modifier(name)
	
	if modifier.priority == priority:
		return
	
	var old_modifier: Dictionary = modifier.duplicate(true)
	
	modifier.priority = priority
	
	modifier_changed.emit(name, modifier, old_modifier)
	
	if modifier.enabled:
		_calculate_result()
	else:
		notify_property_list_changed()

## Sets a modifier's operation type, [param operation] must be either [member MODIFIER_ADD] or [member MODIFIER_MULTIPLY].
func set_modifier_operation(name: StringName, operation: int) -> void:
	_assert_modifier_exists(name)
	assert(operation in [MODIFIER_ADD, MODIFIER_MULTIPLY], "Modifier operation must be either MODIFIER_ADD (0) or MODIFIER_MULTIPLY (1).")
	
	var modifier: Dictionary = get_modifier(name)
	
	if modifier.operation == operation:
		return
	
	var old_modifier: Dictionary = modifier.duplicate(true)
	
	modifier.operation = operation
	
	modifier_changed.emit(name, modifier, old_modifier)
	
	if modifier.enabled:
		_calculate_result()
	else:
		notify_property_list_changed()

## Returns true if a modifier exists.
func has_modifier(name: StringName) -> bool:
	return name in _modifiers

## Removes all modifiers.
func remove_all_modifiers() -> void:
	if _modifiers.is_empty():
		return
	
	_modifiers.clear()
	_calculate_result()

func set_value_changed_signal(custom_signal: Signal) -> void:
	modified_value_changed = custom_signal

func _assert_modifier_exists(name: StringName) -> void:
	assert(has_modifier(name), "Modifier '%s' doesn't exist, consider using has_modifier() first." % name)

func _calculate_result() -> void:
	var result: float = base_value
	
	var sort_method := (
		func priority_sort(modifier_a: Dictionary, modifier_b: Dictionary):
			return modifier_a.priority < modifier_b.priority
	)
	
	var modifier_values := _modifiers.values()
	
	modifier_values.sort_custom(sort_method)
	
	for mod in modifier_values:
		if not mod.enabled:
			continue
		
		match mod.operation:
			MODIFIER_ADD:
				result += mod.value
			MODIFIER_MULTIPLY:
				result *= mod.value
			_:
				result /= mod.value
	
	if clamp_value:
		result = clampf(result, clamp_min, clamp_max)
	
	modified_value = result
	notify_property_list_changed()
