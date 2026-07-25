@tool
extends AudioStreamPlayer2D

@export_tool_button("Play SFX") var play_sfx_btn = play_sfx

@export var end_time: float = -1

func play_sfx():
	play()
	if end_time > 0:
		await get_tree().create_timer(end_time).timeout
		stop()
