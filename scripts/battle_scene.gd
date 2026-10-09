extends Node2D

enum BattleState { PLAYER_TURN, ENEMY_TURN, ANIMATING, WON, LOST }
var state: BattleState = BattleState.PLAYER_TURN
var all_formed_words: Array = []

@onready var hero: Node2D = $Hero
@onready var hero_sprite: AnimatedSprite2D = $Hero/AnimatedSprite2D
@onready var enemy: Node2D = $Enemy
@onready var enemy_sprite: AnimatedSprite2D = $Enemy/AnimatedSprite2D
@onready var attack_button: Button = $UI/Button/AttackButton
@onready var end_turn_button: Button = $UI/Button/EndTurnButton
@onready var hero_hp_label: Label = $UI/HeroHPLabel
@onready var enemy_hp_label: Label = $UI/EnemyHPLabel
@onready var total_damage_label: Label = $UI/DamageLabel/TotalDamageLabel
@onready var feedback_label: Label = $CanvasLayer/FeedbackLabel
@onready var ui_pouch = $UIpouch
@onready var inventory_slots_container = $Inventory/SlotsContainer
@onready var inventory = $Inventory
@onready var hero_start_pos = hero.position
@onready var enemy_start_pos = enemy.position
@onready var word_recap = $WordRecap

const DictionaryLoader = preload("res://scripts/dictionary_loader.gd")
var dict_loader: Node = null

var pending_player_damage: int = 0

@export var hero_walk_speed: float = 350.0
@export var enemy_walk_speed: float = 300.0
@export var hero_attack_offset: Vector2 = Vector2(250, 40)
@export var enemy_attack_offset: Vector2 = Vector2(-380, -50)

var _grid_debounce_timer: Timer

# -----------------------------------------------------
# READY
# -----------------------------------------------------
func _ready() -> void:
	MusicController.play_stream(MusicController.music_Gameplay)
	if not attack_button.is_connected("pressed", Callable(self, "_on_attack_button_pressed")):
		attack_button.connect("pressed", Callable(self, "_on_attack_button_pressed"))
	if not end_turn_button.is_connected("pressed", Callable(self, "_on_end_turn_button_pressed")):
		end_turn_button.connect("pressed", Callable(self, "_on_end_turn_button_pressed"))

	hero_sprite.animation_finished.connect(_on_hero_anim_finished)
	enemy_sprite.animation_finished.connect(_on_enemy_anim_finished)
	hero.died.connect(_on_hero_died)
	enemy.died.connect(_on_enemy_died)
	hero.hurt.connect(_on_hero_hurt)
	enemy.hurt.connect(_on_enemy_hurt)
	
	inventory.damage_updated.connect(_on_damage_updated)

	if not has_node("WordRecap"):
		var recap_scene = preload("res://scenes/word_recap.tscn")
		word_recap = recap_scene.instantiate()
		add_child(word_recap)
	else:
		word_recap = $WordRecap
	word_recap.hide()
	
	dict_loader = DictionaryLoader.new()
	add_child(dict_loader)
	await dict_loader.load_all_chunks()
	print("✅ Dictionary loader ready")

	if ui_pouch and ui_pouch.has_method("set_dictionary_loader"):
		ui_pouch.set_dictionary_loader(dict_loader)
	if inventory and inventory.has_method("set_dictionary_loader"):
		inventory.set_dictionary_loader(dict_loader)
		print("[Battle] Passed dict_loader to Inventory")

	await get_tree().process_frame
	inventory.choose_new_enemy_targets(5)

	_grid_debounce_timer = Timer.new()
	_grid_debounce_timer.one_shot = true
	_grid_debounce_timer.wait_time = 0.15
	add_child(_grid_debounce_timer)
	_grid_debounce_timer.timeout.connect(_on_grid_debounce_timeout)

	start_player_turn()
	update_ui()
	
	inventory.check_words()

# -----------------------------------------------------
# PLAYER TURN
# -----------------------------------------------------
func start_player_turn() -> void:
	_clear_unused_tiles()
	
	state = BattleState.PLAYER_TURN
	attack_button.disabled = false
	end_turn_button.disabled = false
	feedback_label.text = "Your turn. Make a new word or pass; red slots are targeted."
	hero.play_idle_anim()
	
	if ui_pouch and ui_pouch.has_method("refresh_pouch"):
		ui_pouch.refresh_pouch(8)

func _on_attack_button_pressed() -> void:
	if state != BattleState.PLAYER_TURN: return

	var valid_word_data = inventory.check_words()
	print("📖 Player spelled data: ", valid_word_data)

	if not valid_word_data.is_empty():
		var total_damage = 0
		var new_words_found = false
		
		# Bonus logic
		var previous_word_count = all_formed_words.size()
		var bonus_damage = previous_word_count * 4

		for data in valid_word_data:
			var word = data["word"]
			var tiles = data["tiles"]
			
			if all_formed_words.has(word):
				continue 
			
			new_words_found = true
			all_formed_words.append(word)
			
			for t in tiles:
				if t.has_method("lock_tile"):
					t.lock_tile()
				t.set("turns_locked", 0)

			var word_damage = 0
			for char in word.to_upper():
				word_damage += LetterData.LETTER_POINTS.get(char, 0)
			
			total_damage += word_damage

		if not new_words_found:
			print("❌ All words on the board have already been used!")
			feedback_label.text = "Those words were already used. Find a new word or pass."
			return

		total_damage += bonus_damage
		
		inventory.played_words = all_formed_words.duplicate()
		inventory.check_words()

		pending_player_damage = total_damage
		print("⚔️ Hero attack prepared! Total damage:", pending_player_damage)
		feedback_label.text = "Attack prepared: %d damage." % pending_player_damage

		attack_button.disabled = true
		end_turn_button.disabled = true
		state = BattleState.ANIMATING
		hero_walk_to(enemy.position + hero_attack_offset)
	else:
		print("❌ No valid words were found on the grid.")
		feedback_label.text = "No new valid word. Rearrange letters or pass your turn."
		return

func _on_end_turn_button_pressed() -> void:
	if state != BattleState.PLAYER_TURN:
		return
	feedback_label.text = "You passed. The enemy is taking its turn."
	attack_button.disabled = true
	end_turn_button.disabled = true
	enemy_take_turn()

# -----------------------------------------------------
# DAMAGE LABEL UPDATE
# -----------------------------------------------------
func _on_damage_updated(new_damage: int) -> void:
	if total_damage_label:
		total_damage_label.text = "Damage: %d" % new_damage

# -----------------------------------------------------
# TILE MANAGEMENT
# -----------------------------------------------------
func _clear_unused_tiles() -> void:
	var tiles_on_board: Array = []
	for slot in inventory_slots_container.get_children():
		for child in slot.get_children():
			if child.has_method("get_letter"):
				tiles_on_board.append(child)

	for tile in tiles_on_board:
		if tile.get("is_locked"):
			if tile.get("turns_locked") >= 2:
				tile.queue_free()
			else:
				tile.set("turns_locked", tile.get("turns_locked") + 1)
		else:
			tile.queue_free()
	
	await get_tree().process_frame
	inventory.check_words()

func _on_grid_updated() -> void:
	if not _grid_debounce_timer.is_stopped():
		_grid_debounce_timer.stop()
	_grid_debounce_timer.start()

func _on_grid_debounce_timeout() -> void:
	pass

# -----------------------------------------------------
# ANIMATIONS
# -----------------------------------------------------
func hero_walk_to(target: Vector2) -> void:
	hero_sprite.play("walk")
	var tween = create_tween()
	tween.tween_property(hero, "position", target, hero.position.distance_to(target) / hero_walk_speed)
	tween.finished.connect(_on_hero_reached_enemy)

func _on_hero_reached_enemy() -> void:
	hero.play_attack_anim()

func hero_walk_back() -> void:
	var tween = create_tween()
	hero_sprite.play("walk")
	tween.tween_property(hero, "position", hero_start_pos, hero.position.distance_to(hero_start_pos) / hero_walk_speed)
	tween.finished.connect(_on_hero_back_home)

func _on_hero_back_home() -> void:
	hero.play_idle_anim()

func enemy_walk_to(target: Vector2) -> void:
	enemy_sprite.play("walk")
	var tween = create_tween()
	tween.tween_property(enemy, "position", target, enemy.position.distance_to(target) / enemy_walk_speed)
	tween.finished.connect(_on_enemy_reached_hero)

func _on_enemy_reached_hero() -> void:
	enemy.play_attack_anim()

func enemy_walk_back() -> void:
	var tween = create_tween()
	enemy_sprite.play("walk")
	tween.tween_property(enemy, "position", enemy_start_pos, enemy.position.distance_to(enemy_start_pos) / enemy_walk_speed)
	tween.finished.connect(_on_enemy_back_home)

# -----------------------------------------------------
# ENEMY TURN LOGIC (FIXED TIMING)
# -----------------------------------------------------

func _on_hero_anim_finished() -> void:
	var anim = hero_sprite.animation
	if anim == "attack":
		enemy.take_damage(pending_player_damage)
		update_ui()
		hero_walk_back()
	elif anim == "hurt":
		hero.play_idle_anim()
	elif anim == "death":
		_on_hero_died()

func _on_enemy_anim_finished() -> void:
	var anim = enemy_sprite.animation
	if anim == "hurt":
		if enemy.hp <= 0:
			enemy.play_death_anim()
		else:
			enemy.play_idle_anim()
			state = BattleState.ENEMY_TURN
			enemy_take_turn()
	elif anim == "attack":
		hero.take_damage(10)
		
		# --- 1. REPAIR OLD SLOTS FIRST (This was moved here) ---
		# We fix the old broken slots BEFORE we break the new ones.
		if inventory.has_method("repair_all_broken_slots"):
			inventory.repair_all_broken_slots()

		# --- 2. BREAK NEW TARGETS ---
		print("💥 Enemy destroyed the targeted slots!")
		if inventory.has_method("trigger_enemy_destruction"):
			inventory.trigger_enemy_destruction()
		
		update_ui()
		enemy_walk_back()
	elif anim == "death":
		_on_enemy_died()

func _on_enemy_back_home() -> void:
	enemy.play_idle_anim()
	if state == BattleState.WON or state == BattleState.LOST:
		return

	if inventory.has_method("choose_new_enemy_targets"):
		inventory.choose_new_enemy_targets(5)

	start_player_turn()

func enemy_take_turn() -> void:
	attack_button.disabled = true
	end_turn_button.disabled = true
	state = BattleState.ANIMATING
	feedback_label.text = "Enemy turn..."
	enemy_walk_to(hero.position + enemy_attack_offset)

# -----------------------------------------------------
# SIGNAL HANDLERS & RECAP
# -----------------------------------------------------
func _on_enemy_died() -> void:
	if state == BattleState.WON:
		return
	state = BattleState.WON
	attack_button.disabled = true
	end_turn_button.disabled = true
	feedback_label.hide()
	print("🏆 You win!")
	_show_recap("VICTORY")

func _on_hero_died() -> void:
	if state == BattleState.LOST or state == BattleState.WON:
		return
	state = BattleState.LOST
	attack_button.disabled = true
	end_turn_button.disabled = true
	feedback_label.hide()
	print("💀 You lose!")
	_show_recap("DEFEAT")

func _on_hero_hurt() -> void: pass
func _on_enemy_hurt() -> void: pass

func update_ui() -> void:
	hero_hp_label.text = "Hero HP: %d" % hero.hp
	enemy_hp_label.text = "Enemy HP: %d" % enemy.hp

func _show_recap(outcome: String) -> void:
	var words_for_recap: Array = []
	for w in all_formed_words:
		var lw = String(w).strip_edges().to_lower()
		if dict_loader and dict_loader.is_valid_word(lw):
			var entry: Variant = dict_loader.get_word_data(lw)
			if typeof(entry) == TYPE_DICTIONARY:
				var all_meanings: Array = []
				if entry.has("meanings") and typeof(entry["meanings"]) == TYPE_ARRAY:
					for m in entry["meanings"]:
						if typeof(m) == TYPE_DICTIONARY:
							all_meanings.append({
								"def": m.get("def", "N/A"),
								"def_tl": m.get("def_tl", ""), 
								"speech_part": m.get("speech_part", "N/A"),
								"example": m.get("example", ""),
								"synonyms": m.get("synonyms", [])
							})
				else:
					all_meanings.append({
						"def": entry.get("def", entry.get("meaning", "N/A")),
						"def_tl": entry.get("def_tl", ""),
						"speech_part": entry.get("speech_part", entry.get("part_of_speech", "N/A")),
						"synonyms": entry.get("synonyms", [])
					})
				words_for_recap.append({
					"word": lw,
					"meanings": all_meanings
				})
	if word_recap and word_recap.has_method("show_recap"):
		word_recap.show_recap(words_for_recap, outcome)
		word_recap.visible = true
	else:
		print("⚠️ Word recap missing or invalid")
