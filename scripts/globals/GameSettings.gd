extends Node

var sound_enabled: bool = true
var target_language: String = "English"

func set_sound(enabled: bool) -> void:
	sound_enabled = enabled
	# Mutes the Master Audio Bus (Index 0)
	var bus_index = AudioServer.get_bus_index("Master")
	AudioServer.set_bus_mute(bus_index, not enabled)

func set_language(lang: String) -> void:
	target_language = lang
	print("Global Language set to: ", lang)
