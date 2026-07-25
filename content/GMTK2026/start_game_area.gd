extends Area2D

signal start()

@export var time_to_start := 3

@onready var _timer: Timer = $Timer
@onready var _start_area_ui: Control = %StartAreaUI
@onready var _start_game_countdown_label: Label = %StartGameCountdownLabel
@onready var _progress_ring: TextureProgressBar = %ProgressRing

func set_collision_enabled(enabled: bool):
	$CollisionShape2D.disabled = not enabled
	if not enabled:
		_reset()

func _ready() -> void:
	body_entered.connect(_on_body_entered)
	body_exited.connect(_on_body_exited)
	_timer.timeout.connect(_on_timeout)
	_reset()

func _process(delta: float) -> void:
	if not _timer.is_stopped():
		_progress_ring.value = _progress_ring.max_value * max(0, time_to_start - _timer.time_left) / time_to_start
		_update_label()

func _notification(what: int) -> void:
	match what:
		NOTIFICATION_VISIBILITY_CHANGED:
			if _start_area_ui:
				_start_area_ui.visible = visible

func _on_body_entered(body: Node2D):
	if body.is_in_group("player"):
		_start_game_countdown_label.show()
		_timer.start(time_to_start)
		_update_label()

func _on_body_exited(body: Node2D):
	if body.is_in_group("player"):
		_reset()

func _on_timeout():
	start.emit()

func _reset():
	_progress_ring.value = 0
	_start_game_countdown_label.text = "Enter ring to start"
	_timer.stop()

func _update_label():
	var time_left = floori(_timer.time_left)
	
	var new_text = "Start in {0}".format([time_left]) if time_left > 0 else "Start!"
	if _start_game_countdown_label.text == new_text:
		return
	
	_start_game_countdown_label.text = new_text
	var anim = ControlAnimatorComponent.get_component(_start_game_countdown_label)
	anim.pulse()
	
	if time_left == 0:
		$SFX/CountdownFinal.play()
	else:
		$SFX/Countdown.play()
