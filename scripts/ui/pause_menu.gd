extends CanvasLayer


# =========================================================
# Export Variables
# =========================================================

@export_file("*.tscn") var main_menu_scene: String = "res://scenes/ui/MainMenu.tscn"


# =========================================================
# Node References
# =========================================================

@onready var control: Control = $Control
@onready var resume_button: Button = $Control/MarginContainer/VBoxContainer/ResumeButton
@onready var save_button: Button = $Control/MarginContainer/VBoxContainer/SaveButton
@onready var main_menu_button: Button = $Control/MarginContainer/VBoxContainer/MainMenuButton
@onready var exit_button: Button = $Control/MarginContainer/VBoxContainer/ExitButton


# =========================================================
# Ready
# =========================================================

func _ready() -> void:

	# ทำงานได้ตลอดเวลาแม้เกมจะ Paused
	process_mode = Node.PROCESS_MODE_ALWAYS

	# ซ่อนหน้า Pause ไว้ก่อน
	control.hide()

	# เชื่อมต่อ Signal ของปุ่มต่างๆ
	if resume_button != null:
		resume_button.pressed.connect(_on_resume_button_pressed)

	if save_button != null:
		save_button.pressed.connect(_on_save_button_pressed)

	if main_menu_button != null:
		main_menu_button.pressed.connect(_on_main_menu_button_pressed)

	if exit_button != null:
		exit_button.pressed.connect(_on_exit_button_pressed)

	# Translation
	if has_node("/root/LocaleManager"):
		var lm = get_node("/root/LocaleManager")
		lm.language_changed.connect(_on_language_changed)
		_apply_translation()

func _apply_translation() -> void:
	if not has_node("/root/LocaleManager"): return
	var lm = get_node("/root/LocaleManager")
	
	if $Control/MarginContainer/VBoxContainer/TitleLabel:
		$Control/MarginContainer/VBoxContainer/TitleLabel.text = lm.t("PAUSED")
	
	if resume_button: resume_button.text = lm.t("RESUME")
	if save_button: save_button.text = lm.t("SAVE_GAME")
	if main_menu_button: main_menu_button.text = lm.t("MAIN_MENU")
	if exit_button: exit_button.text = lm.t("EXIT_GAME")

func _on_language_changed(_lang: String) -> void:
	_apply_translation()


# =========================================================
# Input Management
# =========================================================

func _unhandled_input(event: InputEvent) -> void:

	if event.is_action_pressed("ui_cancel"): # ปุ่ม ESC
		if SceneTransition.is_transitioning:
			return
		# ห้าม toggle pause ถ้ากำลังมีบทสนทนา (DialogManager กำลังทำงาน)
		if has_node("/root/DialogManager"):
			var dm = get_node("/root/DialogManager")
			if dm.is_dialog_active:
				return
		# ห้าม toggle pause ถ้าหน้า Game Over กำลังแสดง
		var parent = get_parent()
		if parent:
			var game_over = parent.get_node_or_null("GameOverMenu")
			if game_over and game_over.has_node("Control") and game_over.get_node("Control").visible:
				return
		toggle_pause()


# =========================================================
# Pause System Logic
# =========================================================

func toggle_pause() -> void:

	get_tree().paused = not get_tree().paused

	if get_tree().paused:
		control.show()
		if resume_button != null:
			resume_button.grab_focus()
	else:
		control.hide()


# =========================================================
# Button Actions
# =========================================================

func _on_resume_button_pressed() -> void:

	toggle_pause()


func _on_save_button_pressed() -> void:

	var player := get_tree().get_first_node_in_group("player")

	if player != null and player.has_method("save_player_data"):
		player.save_player_data()
		print("========== SAVED GAME FROM PAUSE MENU ==========")


func _on_main_menu_button_pressed() -> void:

	if SceneTransition.is_transitioning:
		return

	control.hide()
	get_tree().paused = false
	SaveManager.is_respawning = false
	SceneTransition.target_spawn_id = ""
	SceneTransition.player_velocity = Vector2.ZERO

	if main_menu_scene != "" and ResourceLoader.exists(main_menu_scene):
		SceneTransition.change_scene(main_menu_scene, 0.5)
	else:
		print("PAUSE MENU ERROR: Cannot find main_menu_scene")


func _on_exit_button_pressed() -> void:

	get_tree().quit()
