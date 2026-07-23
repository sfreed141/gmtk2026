extends RigidBody2D

@export var split_time := 8
@export var splits_into := preload("res://content/GMTK2026/enemy_b.tscn")
@export var split_count := 8

@export var hp := 3

@onready var _split_timer: Timer = $SplitTimer

var _split_time_left: float

func _ready() -> void:
	_split_timer.timeout.connect(split)
	_split_timer.start(split_time)
	_split_time_left = split_time

func apply_hit(damage: int):
	hp -= damage
	if hp <= 0:
		queue_free()

func split():
	for i in split_count:
		var instance: RigidBody2D = splits_into.instantiate()
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
	$UI.rotation = -rotation
	
	var seconds_left = floori(_split_timer.time_left)
	$UI/Label.text = str(seconds_left)
	
	$UI/HpBar.value = hp
