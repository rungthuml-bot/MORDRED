extends CanvasLayer

@onready var color_rect: ColorRect = $ColorRect
var is_transitioning: bool = false
var target_spawn_id: String = ""

# ข้อมูลตัวละครสำหรับส่งข้ามด่านเพื่อให้เดินต่อเนื่อง
var player_velocity: Vector2 = Vector2.ZERO

func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	# ตั้งค่าเริ่มต้นให้จอมืดโปร่งแสงมองไม่เห็น และไม่ขัดขวางการกดปุ่ม
	color_rect.modulate.a = 0.0
	color_rect.mouse_filter = Control.MOUSE_FILTER_IGNORE


# ฟังก์ชันสลับฉากแบบ Fade Out -> เปลี่ยนฉาก -> Fade In
func change_scene(target_path: String, fade_duration: float = 0.5, spawn_id: String = "") -> void:
	if is_transitioning:
		return
	is_transitioning = true
	target_spawn_id = spawn_id
	
	# ตรวจสอบเบื้องต้นว่าฉากเป้าหมายมีอยู่จริงหรือไม่
	if target_path == "" or not ResourceLoader.exists(target_path):
		push_error("SceneTransition failed to load: " + target_path)
		target_spawn_id = ""
		player_velocity = Vector2.ZERO
		color_rect.modulate.a = 0.0
		color_rect.mouse_filter = Control.MOUSE_FILTER_IGNORE
		is_transitioning = false
		return

	# บล็อกการกดปุ่มระหว่างเปลี่ยนฉาก
	color_rect.mouse_filter = Control.MOUSE_FILTER_STOP
	
	# หยุดเพลงเมนูทันทีเมื่อเริ่มเปลี่ยนเข้าสู่ฉากด่าน
	if target_path.begins_with("res://scenes/levels/"):
		if has_node("/root/AudioManager"):
			get_node("/root/AudioManager").stop_music()

	# 1. Fade Out (จอดำค่อยๆ สว่างขึ้นมาทับ)
	var tween_out := create_tween()
	tween_out.set_pause_mode(Tween.TWEEN_PAUSE_PROCESS)
	tween_out.tween_property(color_rect, "modulate:a", 1.0, fade_duration)
	await tween_out.finished
	
	# 2. ปลด Pause ก่อนเปลี่ยนฉาก เพื่อให้ฉากใหม่เริ่มต้นอย่างถูกต้อง
	get_tree().paused = false
	
	# 3. เปลี่ยนฉาก
	var err := get_tree().change_scene_to_file(target_path)
	if err != OK:
		push_error("SceneTransition failed to load: " + target_path)
		target_spawn_id = ""
		player_velocity = Vector2.ZERO
		color_rect.modulate.a = 0.0
		color_rect.mouse_filter = Control.MOUSE_FILTER_IGNORE
		is_transitioning = false
		return
	
	# 4. Fade In (จอดำค่อยๆ จางหายไป)
	var tween_in := create_tween()
	tween_in.set_pause_mode(Tween.TWEEN_PAUSE_PROCESS)
	tween_in.tween_property(color_rect, "modulate:a", 0.0, fade_duration)
	await tween_in.finished
	
	# คืนค่าให้คลิกปุ่มต่างๆ ได้ตามปกติ
	color_rect.mouse_filter = Control.MOUSE_FILTER_IGNORE
	is_transitioning = false
