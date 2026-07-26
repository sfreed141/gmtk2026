extends Node

@export var auto_play_in_debug_build := true
@export var _paused := false

@export var pause_volume_db: float = -6

@onready var menu_overlay: Control = %MenuOverlay

func _ready() -> void:
	%StartGameArea.start.connect(_on_start)
	if auto_play_in_debug_build and OS.is_debug_build():
		play()
		
	%GameOverLabel.hide() # entering gameplay, clear game over label
	%MusicController.play_menu()
	
	if OS.has_feature("web"):
		%QuitButton.hide()

func play():
	%StartGameArea.hide()
	%StartGameArea.set_collision_enabled(false)
	
	menu_overlay.hide()
	%GameState.restart()
	%MusicController.play_battle()

func _on_start():
	play()
	
func _unhandled_input(event: InputEvent) -> void:
	if event.is_action_pressed("menu"):
		_toggle_pause()

func _toggle_pause() -> void:
	_paused = not get_tree().paused
	get_tree().paused = _paused # pauses everything in World but not in MenuOverlay
	
	menu_overlay.visible = _paused
	
	var music_volume_db = pause_volume_db if _paused else 0
	%MusicController.set_volume_db(music_volume_db)

func _on_game_state_game_over(won: bool) -> void:
	%GameOverLabel.show()
	%GameOverLabel.text = "YOU WON" if won else "GAME OVER"
	menu_overlay.show()

func _on_restart_button_pressed() -> void:
	%GameOverLabel.hide() # entering gameplay, clear game over label
	
	if _paused: _toggle_pause()
	play()

func _on_intro_level_button_pressed() -> void:
	%GameOverLabel.hide() # entering gameplay, clear game over label
	
	if _paused: _toggle_pause()
	%GameState.reset()
	%StartGameArea.show()
	%StartGameArea.set_collision_enabled(true)
	menu_overlay.hide()
	%MusicController.play_menu()
	
func _on_quit_button_pressed() -> void:
	get_tree().quit()
