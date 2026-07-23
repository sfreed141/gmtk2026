extends RigidBody2D

# Leave as null to split into itself (can't assign same PackedScene as current scene because it creates a circular ref)
@export var splits_into: PackedScene
@export var split_count := 8

@export var hp := 3
@export var attack_range := 150
@export var speed := 1000

@onready var _ui: Node2D = $UI
@onready var _hp_bar: ProgressBar = $UI/HpBar
@onready var _chase_target: Node2D = get_tree().get_first_node_in_group("player")

const _BAR_SIZE_PER_HP = 32
var _max_hp

func _ready():
	_max_hp = hp
	_hp_bar.max_value = hp
	_hp_bar.size.x = _BAR_SIZE_PER_HP * hp
	_hp_bar.position.x = -_hp_bar.size.x / 2

func apply_hit(damage: int):
	hp -= damage
	if hp <= 0:
		queue_free()

func _get_split_instance() -> RigidBody2D:
	if splits_into:
		return splits_into.instantiate()
	else:
		var instance = duplicate()
		instance.hp = _max_hp
		return instance

func split():	
	for i in split_count:
		var instance: RigidBody2D = _get_split_instance()
		instance.position = global_position
		add_sibling(instance)
		
		var instance_collision_mask = instance.collision_mask
		var spawn_angle = i * 2 * PI / split_count
		var spawn_dist = 200
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

func _physics_process(delta: float) -> void:
	var to_chase_target = _chase_target.global_position - global_position
	if to_chase_target.length() < attack_range:
		pass
	else:
		var f = to_chase_target.normalized() * speed
		apply_central_force(f)
