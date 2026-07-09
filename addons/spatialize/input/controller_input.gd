extends Node

## A node that can automatically convert input from XR controllers into standard non-XR gamepad input.
##
## Add this node to your scene, and if you didn't change the default OpenXR action map, it should
## just work! If you did change the action map, you'll need to update the exposed properties on the
## node to match.

const LEFT_HAND_TRACKER_NAME = "left_hand"
const RIGHT_HAND_TRACKER_NAME = "right_hand"

const PRESSED_THRESHOLD = 0.8
const RELEASED_THRESHOLD = 0.6

@export var thumbstick_action := "primary"
@export var trigger_action := "trigger"
@export var grip_action := "grip"
@export var ax_button_action := "ax_button"
@export var by_button_action := "by_button"
@export var menu_button_action := "menu_button"

var left_hand_tracker: XRControllerTracker
var right_hand_tracker: XRControllerTracker

class TrackerInput:
	var thumbstick: Vector2
	var trigger: float
	var grip: float
	var grip_pressed: bool
	var ax_button: bool
	var by_button: bool
	var menu_button: bool

var _tracker_input: Array[TrackerInput] = [TrackerInput.new(), TrackerInput.new()]


func _ready() -> void:
	XRServer.tracker_added.connect(_on_tracker_added)
	XRServer.tracker_removed.connect(_on_tracker_removed)

	left_hand_tracker = XRServer.get_tracker(LEFT_HAND_TRACKER_NAME)
	right_hand_tracker = XRServer.get_tracker(RIGHT_HAND_TRACKER_NAME)

	process_mode = PROCESS_MODE_ALWAYS


func _on_tracker_added(p_tracker_name: StringName, _type: int) -> void:
	if p_tracker_name == LEFT_HAND_TRACKER_NAME:
		left_hand_tracker = XRServer.get_tracker(LEFT_HAND_TRACKER_NAME)
	elif p_tracker_name == RIGHT_HAND_TRACKER_NAME:
		right_hand_tracker = XRServer.get_tracker(RIGHT_HAND_TRACKER_NAME)


func _on_tracker_removed(p_tracker_name: StringName, _type: int) -> void:
	if p_tracker_name == LEFT_HAND_TRACKER_NAME:
		left_hand_tracker = null
	elif p_tracker_name == RIGHT_HAND_TRACKER_NAME:
		right_hand_tracker = null


func _process(_delta: float) -> void:
	if left_hand_tracker:
		_process_tracker_input(left_hand_tracker, 0, _tracker_input[0])
	if right_hand_tracker:
		_process_tracker_input(right_hand_tracker, 1, _tracker_input[1])


func _tracker_get_vector2(p_tracker: XRControllerTracker, p_input_name: String) -> Vector2:
	var val = p_tracker.get_input(p_input_name)
	if val is Vector2:
		return val
	return Vector2.ZERO


func _tracker_get_float(p_tracker: XRControllerTracker, p_input_name: String) -> float:
	var val = p_tracker.get_input(p_input_name)
	if val is float:
		return val
	return 0.0


func _tracker_get_bool(p_tracker: XRControllerTracker, p_input_name: String) -> bool:
	var val = p_tracker.get_input(p_input_name)
	if val is bool:
		return val
	return false


func _process_tracker_input(p_tracker: XRTracker, p_hand_index: int, p_input: TrackerInput) -> void:
	var cur_thumbstick: Vector2 = _tracker_get_vector2(p_tracker, thumbstick_action)
	var cur_trigger: float = _tracker_get_float(p_tracker, trigger_action)
	var cur_grip: float = _tracker_get_float(p_tracker, grip_action)
	var cur_ax_button: bool = _tracker_get_bool(p_tracker, ax_button_action)
	var cur_by_button: bool = _tracker_get_bool(p_tracker, by_button_action)
	var cur_menu_button: bool = _tracker_get_bool(p_tracker, menu_button_action)

	if cur_thumbstick.x != p_input.thumbstick.x:
		var event = InputEventJoypadMotion.new()
		event.axis = JOY_AXIS_LEFT_X if p_hand_index == 0 else JOY_AXIS_RIGHT_X
		event.axis_value = cur_thumbstick.x
		Input.parse_input_event(event)
	if cur_thumbstick.y != p_input.thumbstick.y:
		var event = InputEventJoypadMotion.new()
		event.axis = JOY_AXIS_LEFT_Y if p_hand_index == 0 else JOY_AXIS_RIGHT_Y
		event.axis_value = -cur_thumbstick.y
		Input.parse_input_event(event)

	if cur_ax_button != p_input.ax_button:
		var event = InputEventJoypadButton.new()
		event.button_index = JOY_BUTTON_X if p_hand_index == 0 else JOY_BUTTON_A
		event.pressed = cur_ax_button
		Input.parse_input_event(event)
	if cur_by_button != p_input.by_button:
		var event = InputEventJoypadButton.new()
		event.button_index = JOY_BUTTON_Y if p_hand_index == 0 else JOY_BUTTON_B
		event.pressed = cur_by_button
		Input.parse_input_event(event)

	if cur_trigger != p_input.trigger:
		var event = InputEventJoypadMotion.new()
		event.axis = JOY_AXIS_TRIGGER_LEFT if p_hand_index == 0 else JOY_AXIS_TRIGGER_RIGHT
		event.axis_value = cur_trigger
		Input.parse_input_event(event)

	if cur_grip != p_input.grip:
		if p_input.grip_pressed and cur_grip < RELEASED_THRESHOLD:
			p_input.grip_pressed = false
			var event = InputEventJoypadButton.new()
			event.button_index = JOY_BUTTON_LEFT_SHOULDER if p_hand_index == 0 else JOY_BUTTON_RIGHT_SHOULDER
			event.pressed = false
			Input.parse_input_event(event)
		elif not p_input.grip_pressed and cur_grip > PRESSED_THRESHOLD:
			p_input.grip_pressed = true
			var event = InputEventJoypadButton.new()
			event.button_index = JOY_BUTTON_LEFT_SHOULDER if p_hand_index == 0 else JOY_BUTTON_RIGHT_SHOULDER
			event.pressed = true
			Input.parse_input_event(event)

	if cur_menu_button != p_input.menu_button:
		var event = InputEventJoypadButton.new()
		event.button_index = JOY_BUTTON_START if p_hand_index == 0 else JOY_BUTTON_GUIDE
		event.pressed = cur_menu_button
		Input.parse_input_event(event)

	p_input.thumbstick = cur_thumbstick
	p_input.trigger = cur_trigger
	p_input.grip = cur_grip
	p_input.ax_button = cur_ax_button
	p_input.by_button = cur_by_button
	p_input.menu_button = cur_menu_button
