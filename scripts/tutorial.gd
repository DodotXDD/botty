extends Control

@onready var label: Label = $Label
@onready var label_2: Label = $Label2
@onready var label_3: Label = $Label3
@onready var label_4: Label = $Label4
@onready var exit_label: Label = $ExitLabel

@onready var continue_button: Button = $ContinueButton

var tutorial_process: int = 4

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	get_tree().paused = true

# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	match tutorial_process:
		4:
			label.visible = true
			label_2.visible = false
			label_3.visible = false
			label_4.visible = false
		3:
			label.visible = false
			label_2.visible = true
			label_3.visible = false
			label_4.visible = false
		2: 
			label.visible = false
			label_2.visible = false
			label_3.visible = true
			label_4.visible = false
		1:
			label.visible = false
			label_2.visible = false
			label_3.visible = false
			label_4.visible = true
		0:
			label.visible = false
			label_2.visible = false
			label_3.visible = false
			label_4.visible = false
			exit_label.visible = true

func _on_continue_button_pressed() -> void:
	print("[DragDebug][TutorialButton] step=%d paused=%s" % [tutorial_process, get_tree().paused])
	if tutorial_process <= 1:
		tutorial_process = -1
		hide()
		get_tree().paused = false
		print("[DragDebug][TutorialDismiss] visible=%s paused=%s" % [visible, get_tree().paused])
		# Restore the battle music
		MusicController.play_stream(MusicController.music_Gameplay)
		return

	tutorial_process -= 1
