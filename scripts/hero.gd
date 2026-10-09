extends Node2D

@export var sprite: AnimatedSprite2D

@export var hp: int = 100

@onready var player_sfx: AudioStreamPlayer2D = $PlayerSFX

signal died
signal hurt

func play_idle_anim():
	if not sprite:
		print("⚠️ Missing AnimatedSprite2D for hero")
		return
	if sprite.sprite_frames and sprite.sprite_frames.has_animation("idle"):
		sprite.play("idle")
	else:
		print("⚠️ Missing 'idle' animation in hero SpriteFrames")

func play_attack_anim():
	if not sprite:
		print("⚠️ Missing AnimatedSprite2D for hero")
		return
	if sprite.sprite_frames and sprite.sprite_frames.has_animation("attack"):
		sprite.play("attack")
		player_sfx.play()
		await get_tree().create_timer(0.6).timeout
		player_sfx.play()
	else:
		print("⚠️ Missing 'attack' animation in hero SpriteFrames")

func play_hurt_anim():
	if sprite and sprite.sprite_frames and sprite.sprite_frames.has_animation("hurt"):
		sprite.play("hurt")

func play_death_anim():
	if sprite and sprite.sprite_frames and sprite.sprite_frames.has_animation("death"):
		sprite.play("death")
	emit_signal("died")

func take_damage(amount: int):
	hp -= amount
	if hp <= 0:
		hp = 0
		play_death_anim()
	else:
		play_hurt_anim()
	emit_signal("hurt")
