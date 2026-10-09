# res://scenes/letters_container.gd
extends GridContainer

func _can_drop_data(_pos: Vector2, data) -> bool:
	# Only allow LetterTiles
	return data is Control and data.has_method("set_letter")

func _drop_data(_pos: Vector2, data) -> void:
	# Reparent tile back into this GridContainer
	if data.get_parent():
		data.get_parent().remove_child(data)
	add_child(data)

	# Reset local position (GridContainer will auto-layout)
	data.position = Vector2.ZERO
