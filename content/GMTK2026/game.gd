extends Node


func _ready() -> void:
	play()

func play():
	%GameOverOverlay.hide()
	%GameState.restart()

func _on_game_state_game_over(won: bool) -> void:
	%GameOverLabel.text = "YOU WON" if won else "GAME OVER"
	%GameOverOverlay.show()


func _on_game_over_restart_button_pressed() -> void:
	get_tree().reload_current_scene()


func _on_game_over_quit_button_pressed() -> void:
	pass
