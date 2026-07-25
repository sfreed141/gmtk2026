extends Node

signal game_over(won: bool)

@export var starter_wave: WaveDefinition
@export var wave_time := 12
@export var wave_definition: WaveDefinition
@export var wave_spawn_points_root: Node

@export var wave_count := 0

@export var split_time := 10
@export var split_node_root: Node

@onready var _wave_timer: Timer = $WaveTimer
@onready var _wave_countdown_label: Label = %WaveCountdownLabel
@onready var _wave_countdown_progress_bar: ProgressBar = %WaveCountdownProgressBar

@onready var _wave_count_label: Label = %WaveCountLabel

@onready var _split_timer: Timer = $SplitTimer
@onready var _split_countdown_label: Label = %SplitCountdownLabel
@onready var _split_countdown_progress_bar: ProgressBar = %SplitCountdownProgressBar

var _game_active = false

func reset():
	_game_active = false
	clear_enemies()
	var player = get_tree().get_first_node_in_group("player")
	player.reset()
	
	_split_timer.stop()
	_wave_timer.stop()
	_update_countdown_ui(_wave_countdown_label, _wave_countdown_progress_bar, wave_time, _wave_timer.time_left, "Wave in {0}")
	_update_countdown_ui(_split_countdown_label, _split_countdown_progress_bar, split_time, _split_timer.time_left, "Split in {0}")

	wave_count = 1;
	_update_wave_count_label()

func restart():
	reset()
	starter_wave.spawn(split_node_root, wave_spawn_points_root.get_children())
	_wave_timer.start(wave_time)
	_split_timer.start(split_time)

	_game_active = true

func clear_enemies():
	for c in split_node_root.get_children():
		split_node_root.remove_child(c)
	

func _ready() -> void:
	_wave_timer.timeout.connect(_on_wave_timeout)
	_split_timer.timeout.connect(_on_split_timeout)
	
	assert(split_node_root)
	split_node_root.child_entered_tree.connect(_split_child_entered)

func _process(_delta: float) -> void:
	if not _game_active:
		return
	
	_update_countdown_ui(_wave_countdown_label, _wave_countdown_progress_bar, wave_time, _wave_timer.time_left, "Wave in {0}")
	_update_countdown_ui(_split_countdown_label, _split_countdown_progress_bar, split_time, _split_timer.time_left, "Split in {0}")

func _update_countdown_ui(label: Label, progress_bar: ProgressBar, time_period: float, time_left: float, label_fmt: String):
	if label:
		_update_label(label, time_left, label_fmt)
	if progress_bar:
		progress_bar.value = progress_bar.max_value * time_left / time_period

func _update_label(label: Label, time_left: float, fmt: String):
	var seconds_left = floori(time_left)
	var new_text = fmt.format([seconds_left])
	if new_text == label.text:
		# no need to update label text or check for pulse if time left didn't cross integer boundary
		return
	
	label.text = fmt.format([seconds_left])
	if seconds_left <= 3:
		var anim = ControlAnimatorComponent.get_component(label)
		anim.pulse()
		
		if seconds_left == 0:
			$SFX/Countdown.stop()
			$SFX/CountdownFinal.play()
		elif not $SFX/CountdownFinal.playing and not $SFX/Countdown.playing:
			$SFX/Countdown.play()

func _on_wave_timeout():
	if wave_definition:
		assert(wave_spawn_points_root and wave_spawn_points_root.get_child_count() > 0)
		wave_definition.spawn(
			split_node_root,
			wave_spawn_points_root.get_children()
		)
		
		wave_count += 1;
		_update_wave_count_label()
		
func _update_wave_count_label():
	_wave_count_label.text = "Wave {0}".format([wave_count])
	var anim = ControlAnimatorComponent.get_component(_wave_count_label)
	anim.pulse()

func _on_split_timeout():
	var splittable = split_node_root.get_children()
	for s in splittable:
		assert(s.has_method("split"))
		s.split()
	_split_timer.start(split_time)

func _split_child_entered(n):
	n.defeated.connect(_check_game_over)

func _check_game_over():
	if _game_active:
		var all_defeated = true
		for c in split_node_root.get_children():
			if not c.is_defeated():
				all_defeated = false
				break
		if all_defeated:
			_end_game(true)

func _end_game(won: bool):
	game_over.emit(won)
	_split_timer.stop()
	_wave_timer.stop()
	
	var player = get_tree().get_first_node_in_group("player")
	player._handle_player_death()

func _on_player_defeated() -> void:
	_end_game(false)
