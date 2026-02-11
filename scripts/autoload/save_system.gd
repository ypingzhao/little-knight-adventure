# 自动加载名：SaveLoad
extends Node
# autoload 脚本不需要 class_name，会与全局单例冲突

const SAVE_PATH := "user://save_game.bin"
const SAVE_VERSION := 1             # 用于以后字段迁移

# 对外唯一接口：立即把当前 GlobalData 写盘
func save_game() -> void:
    var file := FileAccess.open(SAVE_PATH, FileAccess.WRITE)
    if file == null:
        push_error("SaveSystem: 无法打开存档文件")
        return

    var data := {
        "version"     : SAVE_VERSION,
        "coin"        : GlobalData.player_coin,
        "fruit"       : GlobalData.player_fruit
    }
    file.store_var(data, true)      # true = 压缩
    file.close()
    print("SaveSystem: 存档成功")

# 私有：首次启动或切场景时自动调用
func load_game() -> void:
    if not FileAccess.file_exists(SAVE_PATH):
        print("SaveSystem: 未发现存档，使用默认值")
        return

    var file := FileAccess.open(SAVE_PATH, FileAccess.READ)
    if file == null:
        push_error("SaveSystem: 无法读取存档")
        return

    var data : Dictionary = file.get_var(true)
    file.close()

    # 版本迁移入口
    if data.get("version", 0) != SAVE_VERSION:
        data = _migrate(data)

    GlobalData.player_coin  = data.get("coin", 0)
    GlobalData.player_fruit = data.get("fruit", 0)
    print("SaveSystem: 读档成功")

# 预留：以后字段增减时做兼容
func _migrate(old: Dictionary) -> Dictionary:
    print("SaveSystem: 迁移旧存档")
    # 示例：版本 0→1 新增 fruit 字段
    if old.get("version", 0) == 0:
        old.fruit = 0
    old.version = SAVE_VERSION
    return old

# 可选：彻底删档
func delete_save() -> void:
    var dir := DirAccess.open("user://")
    if dir.file_exists(SAVE_PATH):
        dir.remove(SAVE_PATH)
        print("SaveSystem: 删档完成")
