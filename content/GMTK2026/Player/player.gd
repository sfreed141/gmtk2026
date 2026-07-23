extends CharacterBody2D


@export var max_speed := 800.0
@export var acceleration := 4800.0
@export var deceleration_half_life := 0.1
@export var charge_deceleration_half_life := 0.5

@export var charge_time := 1.0
@export var boost_speed_multiplier := 3.0


@onready var _visual_pivot: Node2D = $VisualPivot
@onready var _sprite: Sprite2D = $VisualPivot/Sprite2D
@onready var _boost_particles: CPUParticles2D = $VisualPivot/BoostParticles
@onready var _charge_progress_bar: TextureProgressBar = $ChargeProgressBar
var _look_direction := Vector2.RIGHT
var _charge_tween: Tween
var _boost_tween: Tween
var _charge_start_time_ms: int
const _CHARGE_MODULATE := Color(5.0, 5.0, 5.0)
var _hit_bodies: Dictionary

func _make_charge_tween() -> Tween:
	var t = create_tween()
	t.set_ease(Tween.EASE_IN).set_trans(Tween.TRANS_LINEAR)
	t.set_parallel()
	t.tween_property(_sprite, "modulate", _CHARGE_MODULATE, charge_time)
	t.tween_property(_charge_progress_bar, "value", 100, charge_time)
	t.tween_property(_charge_progress_bar, "modulate", Color.WHITE, charge_time)
	return t

func _physics_process(delta: float) -> void:
	if Input.is_action_just_pressed("charge"):
		# Charge start
		_charge_progress_bar.modulate = Color.TRANSPARENT
		_charge_tween = _make_charge_tween()
		_charge_start_time_ms = Time.get_ticks_msec()
	elif Input.is_action_just_released("charge"):
		# Charge released
		_charge_tween.kill()
		_sprite.modulate = Color.WHITE
		
		_boost_tween = create_tween()
		_boost_tween.tween_property(_charge_progress_bar, "value", 0, 0.2)
		
		var charge_duration = (Time.get_ticks_msec() - _charge_start_time_ms) / 1000.0
		var charge_weight = charge_duration / charge_time
		
		const BOOST_SUPER_MARGIN = 0.1
		if absf(charge_weight - 1.0) < BOOST_SUPER_MARGIN:
			_charge_progress_bar.modulate = Color.FOREST_GREEN
		
		var boost_direction = _visual_pivot.global_transform.basis_xform(Vector2.RIGHT)
		var boost_speed = max_speed * boost_speed_multiplier * min(charge_weight, 1)
		velocity = boost_direction * boost_speed
		
		_boost_particles.restart()
		_hit_bodies.clear()
	
	var charging := Input.is_action_pressed("charge")
	var direction := Input.get_vector("left", "right", "up", "down")
	
	if charging:
		_apply_deceleration(delta, charge_deceleration_half_life)
		
		if direction:
			_set_look_direction(direction)
	else:
		if direction:
			var target_velocity := direction.normalized() * max_speed
			velocity = velocity.move_toward(target_velocity, acceleration * delta)
			
			_set_look_direction(velocity)
		else:
			_apply_deceleration(delta, deceleration_half_life)
	
	var impact_velocity := velocity
	move_and_slide()
	
	for i in get_slide_collision_count():
		var collision := get_slide_collision(i)
		var body := collision.get_collider() as RigidBody2D
		if body:
			var damage = 0
			if impact_velocity.length() <= max_speed + 0.01:
				body.apply_central_force(impact_velocity)
			else:
				# was boosting so apply bigger impulse
				# HACK nuke the body if super boost
				var super_boosting = _charge_progress_bar.modulate == Color.FOREST_GREEN
				var super_boost_multiplier := 4. if super_boosting else 1.
				damage = 3 if super_boosting else 1
				
				var impulse := impact_velocity * 0.8 * super_boost_multiplier
				var collision_point = collision.get_position() - body.global_position
				body.apply_impulse(impulse, collision_point)
			
			if damage > 0 and body.has_method("apply_hit"):
				var body_id = body.get_instance_id()
				if not _hit_bodies.has(body_id):
					_hit_bodies[body_id] = true
					body.apply_hit(damage)

func _process(delta: float) -> void:
	_apply_look(delta)

func _apply_look(delta: float):
	var turn_speed = 0.06
	var target_angle := _look_direction.angle()
	var turn_weight = 1.0 - exp(-log(2.0) * delta / turn_speed)
	_visual_pivot.global_rotation = lerp_angle(_visual_pivot.global_rotation, target_angle, turn_weight)

func _apply_deceleration(delta: float, half_life: float):
	var deceleration_weight := 1.0 - exp(-log(2.0) * delta / half_life)
	velocity = velocity.lerp(Vector2.ZERO, deceleration_weight)
	if velocity.length_squared() < 1.0:
		velocity = Vector2.ZERO

func _set_look_direction(direction: Vector2):
	if not direction.is_zero_approx():
		_look_direction = direction.normalized()
