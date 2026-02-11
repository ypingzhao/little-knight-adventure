@tool
extends EditorScript

# 批量更新场景文件中脚本的UID引用
# 在Godot编辑器中运行：项目 -> 工具 -> 运行脚本

var updated_count = 0
var error_count = 0

func _run() -> void:
	print("开始更新场景文件的UID引用...")
	updated_count = 0
	error_count = 0

	# 递归扫描 scenes/ 目录
	_scan_directory("res://scenes/")

	print("\n✅ 更新完成！")
	print("成功更新: ", updated_count, " 个文件")
	print("错误: ", error_count, " 个文件")
	print("\n💡 提示：如果仍有警告，请在编辑器中打开对应场景并重新选择脚本")

func _scan_directory(dir_path: String) -> void:
	var dir = DirAccess.open(dir_path)
	if not dir:
		push_error("无法打开目录: " + dir_path)
		return

	dir.list_dir_begin()
	var file_name = dir.get_next()

	while file_name != "":
		if file_name == "." or file_name == "..":
			file_name = dir.get_next()
			continue

		var full_path = dir_path + file_name

		if dir.current_is_dir():
			# 递归扫描子目录
			_scan_directory(full_path + "/")
		elif file_name.ends_with(".tscn"):
			# 更新场景文件
			_update_scene_uids(full_path)

		file_name = dir.get_next()

	dir.list_dir_end()

func _update_scene_uids(file_path: String) -> void:
	var file = FileAccess.open(file_path, FileAccess.READ)
	if file == null:
		push_error("无法打开文件: " + file_path)
		error_count += 1
		return

	var content = file.get_as_text()
	file.close()

	# 检查是否包含脚本引用
	var lines = content.split("\n")
	var modified = false
	var file_updated_count = 0

	for i in range(lines.size()):
		var line = lines[i]
		if line.begins_with("[ext_resource type=\"Script\"") and line.contains(".gd\""):
			# 提取脚本路径
			var path_start = line.find("path=\"") + 6
			var path_end = line.find("\"", path_start)
			var script_path = line.substr(path_start, path_end - path_start)

			# 检查脚本是否存在
			if script_path.begins_with("res://scripts/"):
				if FileAccess.file_exists(script_path):
					# 读取.uid文件获取正确的UID
					var uid_file = script_path + ".uid"
					if FileAccess.file_exists(uid_file):
						var uid_file_obj = FileAccess.open(uid_file, FileAccess.READ)
						if uid_file_obj:
							var uid_content = uid_file_obj.get_as_text().strip_edges()
							uid_file_obj.close()

							# 更新UID
							var old_uid_start = line.find("uid://")
							if old_uid_start > 0:
								var old_uid_end = line.find("\"", old_uid_start)
								line = line.substr(0, old_uid_start) + uid_content + line.substr(old_uid_end)
								lines[i] = line
								modified = true
								file_updated_count += 1
								print("  ✓ ", script_path)
					else:
						print("  ⚠ 未找到UID文件: ", uid_file)
				else:
					print("  ⚠ 脚本文件不存在: ", script_path)

	if modified:
		var file_write = FileAccess.open(file_path, FileAccess.WRITE)
		if file_write:
			file_write.store_string("\n".join(lines))
			file_write.close()
			updated_count += file_updated_count
			print("  📄 ", file_path, " (", file_updated_count, " 个引用)")
		else:
			push_error("无法写入文件: " + file_path)
			error_count += 1
