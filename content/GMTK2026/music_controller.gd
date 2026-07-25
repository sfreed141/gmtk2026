extends Node

@export var crossfade_duration: float = 0.5
@export var muffle_strength: float = 0.5

const VOLUME_SILENT_DB := -100.

@onready var _menu_player: AudioStreamPlayer = $MenuMusicPlayer
@onready var _battle_player: AudioStreamPlayer = $BattleMusicPlayer

func set_volume_db(volume_db: float, fade_duration: float = crossfade_duration):
	var bus_idx = AudioServer.get_bus_index("Music")
	assert(bus_idx > 0)
	var current_volume_db = AudioServer.get_bus_volume_db(bus_idx)
	
	var volume_fn = func (volume_db):
		AudioServer.set_bus_volume_db(bus_idx, volume_db)
	
	var t = create_tween()
	t.tween_method(volume_fn, current_volume_db, volume_db, fade_duration)

func play_menu(fade_duration: float = crossfade_duration):
	_play_or_fade(_battle_player, _menu_player, fade_duration)

func play_battle(fade_duration: float = crossfade_duration):
	_play_or_fade(_menu_player, _battle_player, fade_duration)

func stop():
	_menu_player.stop()
	_battle_player.stop()

func _ready():
	stop()

func _play_or_fade(from_stream: AudioStreamPlayer, to_stream: AudioStreamPlayer, fade_duration: float):
	if (from_stream.playing):
		_crossfade(from_stream, to_stream, fade_duration)
	else:
		_fade_in(to_stream, fade_duration)

func _fade_in(stream: AudioStreamPlayer, duration: float):
	stream.stop()
	stream.volume_db = VOLUME_SILENT_DB
	stream.play()
	
	var t = create_tween()
	t.tween_property(stream, "volume_db", 0, duration)

func _crossfade(from_stream: AudioStreamPlayer, to_stream: AudioStreamPlayer, duration: float):
	assert(from_stream.playing)
	assert(not to_stream.playing)
	
	to_stream.volume_db = VOLUME_SILENT_DB
	to_stream.play()
	
	var t = create_tween().set_parallel(true)
	t.tween_property(from_stream, "volume_db", VOLUME_SILENT_DB, duration)
	t.tween_property(to_stream, "volume_db", 0, duration)
	
	await t.finished
	from_stream.stop()
