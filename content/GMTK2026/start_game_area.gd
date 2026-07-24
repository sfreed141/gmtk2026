extends Area2D

signal start()

@export var time_to_start := 3

@onready var _timer: Timer = $Timer
@onready var _start_game_countdown_label: Label = %StartGameCountdownLabel
@onready var _sprite: Sprite2D = $Sprite2D

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
		_update_label()

func _notification(what: int) -> void:
	match what:
		NOTIFICATION_VISIBILITY_CHANGED:
			if _start_game_countdown_label:
				_start_game_countdown_label.visible = visible

func _on_body_entered(body: Node2D):
	if body.is_in_group("player"):
		_update_label()
		_start_game_countdown_label.show()
		_sprite.modulate.a = 1.
		_timer.start()

func _on_body_exited(body: Node2D):
	if body.is_in_group("player"):
		_reset()

func _on_timeout():
	start.emit()

func _reset():
	_start_game_countdown_label.text = "Enter to start"
	_sprite.modulate.a = .2
	_timer.stop()

func _update_label():
	var time_left = floori(_timer.time_left)
	
	_start_game_countdown_label.text = "Start in {0}".format([time_left]) if time_left > 0 else "Start!"
