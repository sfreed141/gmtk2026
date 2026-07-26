extends Control

func _notification(what: int) -> void:
	match what:
		NOTIFICATION_VISIBILITY_CHANGED:
			if visible:
				%RestartButton.grab_focus()
