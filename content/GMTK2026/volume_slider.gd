extends HSlider

@export var bus_name: String

var _bus_idx: int

func _ready() -> void:
	assert(is_zero_approx(self.min_value))
	assert(bus_name)
	_bus_idx = AudioServer.get_bus_index(bus_name)
	assert(_bus_idx >= 0)
	
	self.value_changed.connect(_on_value_changed)
	_update_ui()

func _on_value_changed(value: float):
	var new_volume = value / self.max_value
	_set_volume(new_volume)

func _update_ui():
	var volume = clampf(_get_volume(), 0., 1.)
	self.value = self.max_value * volume

func _get_volume():
	return AudioServer.get_bus_volume_linear(_bus_idx)

func _set_volume(linear: float):
	AudioServer.set_bus_volume_linear(_bus_idx, linear)
