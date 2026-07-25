extends CharacterBody2D

signal defeated()
signal hit()

@export var hp := 5
@export var hit_invulnerability_duration: float = 1.

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
@onready var _hp_container: HBoxContainer = %HPContainer
@onready var _boost_shaker: ShakerComponent2D = $VisualPivot/BoostShaker
@onready var _max_hp = hp
var _look_direction := Vector2.RIGHT
var _charge_tween: Tween
var _boost_tween: Tween
var _charge_start_time_ms: int
const _CHARGE_MODULATE := Color(5.0, 5.0, 5.0)
var _hit_bodies: Dictionary
var _last_hit_time_ms: int

func reset():
	hp = _max_hp
	_update_hp_ui()

	if _charge_tween and _charge_tween.is_valid():
		_charge_tween.kill()
		_charge_tween = null
	if _boost_tween and _boost_tween.is_valid():
		_boost_tween.kill()
		_boost_tween = null
	
	_boost_shaker.force_stop_shake()
	
	velocity = Vector2.ZERO
	position = Vector2.ZERO
	reset_physics_interpolation()
	
	_charge_progress_bar.modulate = Color.TRANSPARENT
	_sprite.modulate = Color.WHITE

	set_process(true)
	set_physics_process(true)

func apply_hit(damage: int):
	var hit_time_ms = Time.get_ticks_msec()
	var last_hit_time = (hit_time_ms - _last_hit_time_ms) / 1000.0
	if hp > 0 and last_hit_time > hit_invulnerability_duration:
		hp -= damage
		_last_hit_time_ms = hit_time_ms
		_update_hp_ui()
		hit.emit()
		if hp <= 0:
			defeated.emit()
			set_process(false)
			set_physics_process(false)
		else:
			# hit flash
			const _FLASH_CYCLES = 4
			const _FLASH_COLOR = Color(10, 10, 10)
			var flash_half_period = hit_invulnerability_duration / _FLASH_CYCLES
			var t = create_tween()
			t.set_loops(2)
			t.tween_property(_sprite, "modulate", _FLASH_COLOR, 0)
			t.tween_interval(flash_half_period)
			t.tween_property(_sprite, "modulate", Color.WHITE, 0)
			t.tween_interval(flash_half_period)

func _update_hp_ui():
	var hp_ui_count = _hp_container.get_child_count()
	var hp_ui_diff = hp_ui_count - hp
	if hp_ui_diff > 0:
		for i in range(hp_ui_diff):
			_hp_container.remove_child(_hp_container.get_child(0))
	elif hp_ui_diff < 0:
		var template = preload("res://content/GMTK2026/Player/player_hp_ui_chunk.tscn")
		for i in range(abs(hp_ui_diff)):
			_hp_container.add_child(template.instantiate())

func _make_charge_tween() -> Tween:
	var t = create_tween()
	t.set_ease(Tween.EASE_IN).set_trans(Tween.TRANS_LINEAR)
	t.set_parallel()
	t.tween_property(_sprite, "modulate", _CHARGE_MODULATE, charge_time)
	t.tween_property(_charge_progress_bar, "value", 100, charge_time)
	t.tween_property(_charge_progress_bar, "modulate", Color.WHITE, charge_time)
	return t
	
func _release_charge_ability():
	if _charge_tween and _charge_tween.is_valid():
		_charge_tween.kill()
		_charge_tween = null
	_sprite.modulate = Color.WHITE
	
	_boost_tween = create_tween()
	_boost_tween.tween_property(_charge_progress_bar, "value", 0, 0.2)
	
	var charge_duration = (Time.get_ticks_msec() - _charge_start_time_ms) / 1000.0
	var charge_weight = charge_duration / charge_time
	
	const BOOST_SUPER_MARGIN = 0.1
	if absf(charge_weight - 1.0) < BOOST_SUPER_MARGIN:
		_charge_progress_bar.modulate = Color.FOREST_GREEN
		_boost_shaker.intensity = 4
		_boost_shaker.play_shake()
	else:
		_boost_shaker.intensity = 1
		_boost_shaker.play_shake()
	
	var boost_direction = _visual_pivot.global_transform.basis_xform(Vector2.RIGHT)
	var boost_speed = max_speed * boost_speed_multiplier * min(charge_weight, 1)
	velocity = boost_direction * boost_speed
	
	_boost_particles.restart()
	_hit_bodies.clear()

func _ready():
	assert(hp > 0)
	_update_hp_ui()

func _physics_process(delta: float) -> void:
	if Input.is_action_just_pressed("charge"):
		# Charge start
		_charge_progress_bar.modulate = Color.TRANSPARENT
		_charge_tween = _make_charge_tween()
		_charge_start_time_ms = Time.get_ticks_msec()
	elif Input.is_action_just_released("charge"):
		# Charge released
		_release_charge_ability()
	
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
		
func _handle_player_death():
	_release_charge_ability()
