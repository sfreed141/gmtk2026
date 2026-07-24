extends Node

@export var auto_play_in_debug_build := true

func _ready() -> void:
	%StartGameArea.start.connect(_on_start)
	if auto_play_in_debug_build and OS.is_debug_build():
		play()

func play():
	%StartGameArea.hide()
	%StartGameArea.set_collision_enabled(false)
	
	%GameOverOverlay.hide()
	%GameState.restart()

func _on_start():
	play()

func _on_game_state_game_over(won: bool) -> void:
	%GameOverLabel.text = "YOU WON" if won else "GAME OVER"
	%GameOverOverlay.show()


func _on_game_over_restart_button_pressed() -> void:
	play()

func _on_game_over_quit_button_pressed() -> void:
	%GameState.reset()
	%StartGameArea.show()
	%StartGameArea.set_collision_enabled(true)
	%GameOverOverlay.hide()
