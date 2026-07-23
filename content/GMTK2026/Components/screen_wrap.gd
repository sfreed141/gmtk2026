class_name ScreenWrap
extends Node

## Attach as a child of any Node2D to make it wrap around the viewport edges.
## Leave half_extents at (0,0) to auto-detect from a CollisionShape2D or Sprite2D child,
## or set it explicitly in the inspector to override.

@export var half_extents: Vector2 = Vector2.ZERO
@export var wrap_only_when_offscreen: bool = true

var _target: Node2D

func _ready() -> void:
	_target = get_parent() as Node2D
	if _target == null:
		push_error("ScreenWrap must be a child of a Node2D")
		set_physics_process(false)
		return

	if half_extents == Vector2.ZERO:
		half_extents = _auto_detect_half_extents(_target)
		
func _auto_detect_half_extents(node: Node2D) -> Vector2:
	for child in node.get_children():
		if child is CollisionShape2D and child.shape:
			return child.shape.get_rect().size * 0.5
		if child is Sprite2D and child.texture:
			return child.get_rect().size * 0.5
	return Vector2.ZERO

func _physics_process(_delta: float) -> void:
	_apply_screen_wrap()

func _apply_screen_wrap() -> void:
	var viewport_size = get_viewport().get_visible_rect().size
	var pos = _target.global_position
	var wrapped := false

	var margin_x = half_extents.x if wrap_only_when_offscreen else 0.0
	var margin_y = half_extents.y if wrap_only_when_offscreen else 0.0

	if pos.x < -margin_x:
		pos.x = viewport_size.x + margin_x
		wrapped = true
	elif pos.x > viewport_size.x + margin_x:
		pos.x = -margin_x
		wrapped = true

	if pos.y < -margin_y:
		pos.y = viewport_size.y + margin_y
		wrapped = true
	elif pos.y > viewport_size.y + margin_y:
		pos.y = -margin_y
		wrapped = true

	if wrapped:
		_target.global_position = pos
		_target.reset_physics_interpolation()
