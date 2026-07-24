extends Node

signal game_over(won: bool)

@export var wave_time := 12
@export var wave_definition: WaveDefinition
@export var wave_spawn_points_root: Node

@export var split_time := 10
@export var split_node_root: Node


@onready var _wave_timer: Timer = $WaveTimer
@onready var _wave_countdown_label: Label = %WaveCountdownLabel

@onready var _split_timer: Timer = $SplitTimer
@onready var _split_countdown_label: Label = %SplitCountdownLabel

func restart():
	_wave_timer.start(wave_time)
	_split_timer.start(split_time)

func _ready() -> void:
	_wave_timer.timeout.connect(_on_wave_timeout)
	_split_timer.timeout.connect(_on_split_timeout)
	
	assert(split_node_root)
	split_node_root.child_exiting_tree.connect(_split_node_exiting)

func _process(_delta: float) -> void:
	_update_label(_wave_countdown_label, _wave_timer.time_left, "Wave in {0}")
	_update_label(_split_countdown_label, _split_timer.time_left, "Split in {0}")

static func _update_label(label: Label, time_left: float, fmt: String):
	var seconds_left = floori(time_left)
	label.text = fmt.format([seconds_left])

func _on_wave_timeout():
	if wave_definition:
		assert(wave_spawn_points_root and wave_spawn_points_root.get_child_count() > 0)
		wave_definition.spawn(
			split_node_root,
			wave_spawn_points_root.get_children()
		)

func _on_split_timeout():
	var splittable = split_node_root.get_children()
	for s in splittable:
		assert(s.has_method("split"))
		s.split()
	_split_timer.start(split_time)

func _split_node_exiting(_n):
	if split_node_root.get_child_count() == 1:
		_end_game(true)

func _end_game(won: bool):
	game_over.emit(won)
	_split_timer.stop()
	_wave_timer.stop()

func _on_player_defeated() -> void:
	_end_game(false)
