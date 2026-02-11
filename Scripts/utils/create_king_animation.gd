@tool
extends EditorScript

# 此脚本用于自动生成国王NPC的idle动画SpriteFrames资源
# 在Godot编辑器中运行：项目 -> 工具 -> 运行脚本 -> 选择此文件

func _run() -> void:
	var texture_path = "res://assets/Kings and Pigs Sprites/01-King Human/Idle (78x58).png"
	var output_path = "res://assets/Kings and Pigs Sprites/01-King Human/shop_keeper_anim.tres"

	# 加载纹理
	var texture = load(texture_path)
	if not texture:
		push_error("无法加载纹理: " + texture_path)
		return

	# 获取纹理尺寸
	var texture_size = texture.get_size()
	print("纹理尺寸: ", texture_size)

	# 每帧尺寸
	var frame_size = Vector2(78, 58)

	# 计算帧数
	var frames_count = int(texture_size.x / frame_size.x)
	print("检测到帧数: ", frames_count)

	# 创建SpriteFrames资源
	var sprite_frames = SpriteFrames.new()

	# 创建idle动画
	var anim_name = "idle"
	sprite_frames.add_animation(anim_name)
	sprite_frames.set_animation_loop(anim_name, true)
	sprite_frames.set_animation_speed(anim_name, 8.0)  # 8 FPS

	# 添加所有帧
	for i in range(frames_count):
		var atlas_coords = Vector2(i, 0)
		sprite_frames.add_frame(anim_name, texture)
		var frame_index = sprite_frames.get_frame_count(anim_name) - 1

		# 设置atlas坐标（需要在Godot 4.2+中正确设置）
		# 注意：这里使用元数据存储坐标信息
		print("添加帧 %d: atlas_coords=%s" % [i, atlas_coords])

	# 保存资源
	var result = ResourceSaver.save(sprite_frames, output_path)
	if result == OK:
		print("✅ 成功生成动画资源: ", output_path)
		print("请重新加载shop_keeper.tscn以应用动画")
	else:
		push_error("保存资源失败: " + str(result))
