extends Node

@export var split_time := 10
@export var split_group_name := "split"

@onready var _split_timer: Timer = $SplitTimer
@onready var _split_countdown_label: Label = $MarginContainer/SplitCountdownLabel

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	_split_timer.timeout.connect(_on_split_timeout)
	_split_timer.start(split_time)

# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	var seconds_left = floori(_split_timer.time_left)
	_split_countdown_label.text = str(seconds_left)

func _on_split_timeout():
	var splittable = get_tree().get_nodes_in_group(split_group_name)
	for s in splittable:
		assert(s.has_method("split"))
		s.split()
	_split_timer.start(split_time)
