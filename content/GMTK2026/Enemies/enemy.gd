extends RigidBody2D

const _MAX_SPLIT_GENERATION = 2

# Leave as null to split into itself (can't assign same PackedScene as current scene because it creates a circular ref)
@export var splits_into: PackedScene
@export var split_count := 8

@export var hp := 3
@export var speed := 1000

@export var attack_range := 150
@export var attack_telegraph_time := 0.6
@export var attack_impact_time := 0.05
@export var attack_recovery_time := 0.4
@export var attack_color := Color.DARK_ORANGE
@export var attack_damage := 1

@onready var _ui: Node2D = $UI
@onready var _hp_bar: ProgressBar = $UI/HpBar
@onready var _chase_target: Node2D = get_tree().get_first_node_in_group("player")
@onready var _attack_area: Area2D = $AttackArea
@onready var _attack_sprite: Sprite2D = $AttackArea/AttackSprite
@onready var _shaker_component: ShakerComponent2D = $ShakerComponent2D

const _BAR_SIZE_PER_HP = 32
var _max_hp
var _attacking = false
var _split_generation = 1

func is_defeated():
	return hp <= 0

func _ready():
	_max_hp = hp
	_hp_bar.max_value = hp
	_hp_bar.size.x = _BAR_SIZE_PER_HP * hp
	_hp_bar.position.x = -_hp_bar.size.x / 2
	
	_attack_sprite.hide()

func apply_hit(damage: int):
	hp -= damage
	if hp <= 0:
		$SFX/Defeated.play()
		$DeathParticles.emitting = true
		$Sprite2D.hide()
		_attack_sprite.hide()
		$UI.hide()
		$CollisionShape2D.disabled = true
		if _attack_tween:
			_attack_tween.kill()
		await $SFX/Defeated.finished
		await $DeathParticles.finished
		queue_free()
	else:
		_shaker_component.play_shake()
		$SFX/Damaged.play_sfx()

func _get_split_instance() -> RigidBody2D:
	if splits_into:
		return splits_into.instantiate()
	else:
		var instance = duplicate()
		instance.hp = _max_hp
		return instance

func split():
	if is_defeated() or _split_generation >= _MAX_SPLIT_GENERATION:
		return
	
	for i in split_count:
		var instance: RigidBody2D = _get_split_instance()
		instance.position = global_position
		instance._split_generation += 1
		add_sibling(instance)
		
		var instance_collision_mask = instance.collision_mask
		var spawn_angle = i * 2 * PI / split_count + randf_range(0, 2 * PI / split_count)
		var spawn_dist = 200 * randf_range(0.5, 2.0)
		var spawn_position = global_position + spawn_dist * Vector2.RIGHT.rotated(spawn_angle)
		var t = get_tree().create_tween()
		t.set_ease(Tween.EASE_OUT).set_trans(Tween.TRANS_EXPO)
		t.tween_callback(instance.set_deferred.bind("collision_mask", 0))
		t.tween_property(instance, "global_position", spawn_position, 0.5)
		t.tween_callback(instance.set_deferred.bind("collision_mask", instance_collision_mask))
	
	queue_free()

func _process(_delta: float) -> void:
	_ui.rotation = -rotation
	_hp_bar.value = hp

func _physics_process(_delta: float) -> void:
	if is_defeated():
		return
	
	var to_chase_target = _chase_target.global_position - global_position
	var f = to_chase_target.normalized() * speed * (0.5 if _attacking else 1.0)
	apply_central_force(f)

	if not _attacking and to_chase_target.length() < attack_range:
		_attack()

var _attack_tween: Tween
func _attack():
	assert(not _attacking)
	_attacking = true
	
	var initial_sprite_scale = _attack_sprite.scale
	_attack_sprite.modulate = attack_color
	_attack_sprite.modulate.a = 0
	_attack_sprite.show()
	
	var telegraph_color = attack_color
	telegraph_color.a = 0.4
	
	_attack_tween = create_tween()
	# telegraph
	_attack_tween.set_ease(Tween.EASE_IN).set_trans(Tween.TRANS_QUAD)
	_attack_tween.tween_property(_attack_sprite, "modulate", telegraph_color, attack_telegraph_time)
	# impact
	_attack_tween.set_ease(Tween.EASE_OUT).set_trans(Tween.TRANS_QUAD)
	_attack_tween.tween_property(_attack_sprite, "modulate", attack_color, attack_impact_time)
	_attack_tween.parallel().tween_property(_attack_sprite, "scale", initial_sprite_scale * 1.1, attack_impact_time)
	_attack_tween.tween_callback(func ():
		_shaker_component.play_shake()
		$SFX/AttackHit.play()
		var bodies = _attack_area.get_overlapping_bodies()
		for b: Node2D in bodies:
			if b.is_in_group("player"):
				b.apply_hit(attack_damage)
	)
	# recovery
	_attack_tween.tween_property(_attack_sprite, "scale", initial_sprite_scale * 0.9, attack_recovery_time)
	_attack_tween.set_ease(Tween.EASE_OUT).set_trans(Tween.TRANS_EXPO)
	_attack_tween.parallel().tween_property(_attack_sprite, "modulate", Color.TRANSPARENT, attack_recovery_time)
	_attack_tween.tween_callback(func ():
		_attack_sprite.hide()
		_attack_sprite.scale = initial_sprite_scale
		_attacking = false
	)
