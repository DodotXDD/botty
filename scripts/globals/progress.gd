extends Node

var highest_unlocked := 1  # set to 5 for testing, change to 1 later
var current_level := 1
var stars := {}

func is_unlocked(id: int) -> bool:
	return id <= highest_unlocked

func complete_level(id: int, star_count: int) -> void:
	stars[id] = maxi(stars.get(id, 0), star_count)
	highest_unlocked = maxi(highest_unlocked, id + 1)
