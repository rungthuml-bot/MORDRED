extends Node2D
class_name BaseLevel

func _ready() -> void:
	var player = get_node_or_null("Player")
	if not player:
		return
	
	var spawn_id = SceneTransition.target_spawn_id
	var spawn_node = null
	
	if spawn_id != "":
		spawn_node = find_child(spawn_id, true, false)
		
	if spawn_node != null:
		player.global_position = spawn_node.global_position
		player.global_position.y += 50
		
		if spawn_node.global_position.x < 600:
			player.global_position.x += 40
		else:
			player.global_position.x -= 40
			
		player.velocity = SceneTransition.player_velocity
		SceneTransition.player_velocity = Vector2.ZERO
	elif spawn_id == "":
		var current_scene_path := scene_file_path
		var checkpoint_scene = SaveManager.save_data.get("checkpoint_scene", "")
		var saved_current_scene = SaveManager.save_data.get("current_scene", "")
		var is_checkpoint_valid: bool = (checkpoint_scene is String and checkpoint_scene != "" and checkpoint_scene == current_scene_path)
		var is_saved_pos_valid: bool = (saved_current_scene is String and saved_current_scene != "" and saved_current_scene == current_scene_path)
		
		if is_checkpoint_valid and _has_valid_coords(SaveManager.save_data, "checkpoint_pos_x", "checkpoint_pos_y"):
			player.global_position = Vector2(float(SaveManager.save_data["checkpoint_pos_x"]), float(SaveManager.save_data["checkpoint_pos_y"]))
		elif is_saved_pos_valid and _has_valid_coords(SaveManager.save_data, "pos_x", "pos_y"):
			player.global_position = Vector2(float(SaveManager.save_data["pos_x"]), float(SaveManager.save_data["pos_y"]))

static func _has_valid_coords(data: Dictionary, key_x: String, key_y: String) -> bool:
	if not data.has(key_x) or not data.has(key_y):
		return false
	var vx = data[key_x]
	var vy = data[key_y]
	if not (vx is int or vx is float) or not (vy is int or vy is float):
		return false
	var fx := float(vx)
	var fy := float(vy)
	return is_finite(fx) and is_finite(fy)
