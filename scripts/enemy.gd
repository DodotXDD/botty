extends Node2D

@onready var sprite: AnimatedSprite2D = $AnimatedSprite2D

@export var hp: int = 100

@onready var enemy_sfx: AudioStreamPlayer2D = $EnemySFX
@onready var victory: AudioStreamPlayer2D = $Victory

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
		await get_tree().create_timer(1).timeout
		enemy_sfx.play()
	else:
		print("⚠️ Missing 'attack' animation in hero SpriteFrames")

func play_hurt_anim():
	if sprite and sprite.sprite_frames and sprite.sprite_frames.has_animation("hurt"):
		sprite.play("hurt")

func play_death_anim():
	if sprite and sprite.sprite_frames and sprite.sprite_frames.has_animation("death"):
		sprite.play("death")
	emit_signal("died")
	await get_tree().create_timer(0.3).timeout
	victory.play()

func take_damage(amount: int):
	hp -= amount
	if hp <= 0:
		hp = 0
		play_death_anim()
	else:
		play_hurt_anim()
	emit_signal("hurt")
