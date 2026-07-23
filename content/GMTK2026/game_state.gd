extends Node

signal game_over(won: bool)

@export var split_time := 10
@export var split_node_root: Node

@onready var _split_timer: Timer = $SplitTimer
@onready var _split_countdown_label: Label = $MarginContainer/SplitCountdownLabel

func restart():
	_split_timer.start(split_time)

func _ready() -> void:
	_split_timer.timeout.connect(_on_split_timeout)
	
	assert(split_node_root)
	split_node_root.child_exiting_tree.connect(_split_node_exiting)

func _process(delta: float) -> void:
	var seconds_left = floori(_split_timer.time_left)
	_split_countdown_label.text = str(seconds_left)

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

func _on_player_defeated() -> void:
	_end_game(false)
