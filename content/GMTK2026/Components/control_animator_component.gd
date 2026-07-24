@tool
extends Node
class_name ControlAnimatorComponent

# Animates parent control via offset transform properties

@export_tool_button("Pulse") var pulse_btn = pulse

@export var pulse_duration: float = .1
@export var pulse_fade: float = 0.05
@export var pulse_scale: float = 1.2
@export var pulse_ease := Tween.EASE_OUT
@export var pulse_trans := Tween.TRANS_SPRING

const NAME = "ControlAnimatorComponent"

var _target: Control
var _pulse_tween: Tween

static func get_component(target: Control) -> ControlAnimatorComponent:
	var comp = target.get_node(NAME)
	assert(comp)
	return comp

func pulse(
	duration: float = pulse_duration,
	fade: float = pulse_fade,
	scale: float = pulse_scale,
	ease: Tween.EaseType = pulse_ease,
	trans: Tween.TransitionType = pulse_trans
):
	cancel()
	
	_target.offset_transform_enabled = true
	_pulse_tween = create_tween()
	_pulse_tween.set_ease(ease).set_trans(trans)
	_pulse_tween.tween_property(_target, "offset_transform_scale", Vector2(scale, scale), duration)
	_pulse_tween.tween_property(_target, "offset_transform_scale", Vector2.ONE, fade)
	_pulse_tween.tween_property(_target, "offset_transform_enabled", false, 0)

# Cancel any in-flight animations. Leaves all offset transform state as-is
func cancel():
	if _pulse_tween and _pulse_tween.is_valid():
		_pulse_tween.kill()
	_pulse_tween = null

# Cancels in-flight animations and resets offset transform state to default values
func reset():
	cancel()
	
	_target.offset_transform_enabled = false
	_target.offset_transform_scale = Vector2.ONE
	_target.offset_transform_rotation = 0

func _ready() -> void:
	_target = get_parent() as Control
	assert(_target)
