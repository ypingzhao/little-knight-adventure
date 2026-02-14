# 自动加载名：SaveLoad
extends Node
# autoload 脚本不需要 class_name，会与全局单例冲突

const SAVE_PATH := "user://save_game.bin"
const SAVE_VERSION := 2             # v2: 添加技能树数据支持

# 对外唯一接口：立即把当前 GlobalData 写盘
func save_game() -> void:
    var file := FileAccess.open(SAVE_PATH, FileAccess.WRITE)
    if file == null:
        push_error("SaveSystem: 无法打开存档文件")
        return

    var skill_data = SkillTreeManager.get_save_data()
    print("SaveSystem: get_save_data() 返回类型: %s" % typeof(skill_data))
    print("SaveSystem: get_save_data() 返回内容: %s" % skill_data)

    # 再次检查是否还有嵌套结构
    if typeof(skill_data) == TYPE_DICTIONARY and skill_data.has("skill_states"):
        print("SaveSystem: ⚠️ 检测到嵌套结构，正在解包...")
        skill_data = skill_data.skill_states

    var data := {
        "version"      : SAVE_VERSION,
        "coin"         : GlobalData.player_coin,
        "fruit"        : GlobalData.player_fruit,
        "skill_states" : skill_data
    }
    file.store_var(data, true)      # true = 压缩
    file.close()
    print("SaveSystem: 存档成功（金币: %d, 技能数据已保存）" % GlobalData.player_coin)

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

    # 从存档读取金币数量，如果没有则使用默认值 80
    GlobalData.player_coin = data.get("coin", 80)
    GlobalData.player_fruit = data.get("fruit", 0)

    # 加载技能树数据（v2+）
    if data.has("skill_states"):
        print("SaveSystem: 准备加载技能数据...")
        print("  skill_states 类型: %s" % typeof(data.skill_states))
        print("  skill_states 内容: %s" % data.skill_states)
        SkillTreeManager.load_save_data(data.skill_states)

    print("SaveSystem: 读档成功（金币: %d）" % GlobalData.player_coin)

# 预留：以后字段增减时做兼容
func _migrate(old: Dictionary) -> Dictionary:
    print("SaveSystem: 迁移旧存档 (v%d → v%d)" % [old.get("version", 0), SAVE_VERSION])

    # 版本 0→1：新增 fruit 字段
    if old.get("version", 0) == 0:
        old.fruit = 0

    # 版本 1→2：新增技能树数据字段
    if old.get("version", 0) == 1:
        old.skill_states = {}
        print("SaveSystem: 添加空的技能树数据")

    old.version = SAVE_VERSION
    return old

# 可选：彻底删档
func delete_save() -> void:
    var dir := DirAccess.open("user://")
    if dir.file_exists(SAVE_PATH):
        dir.remove(SAVE_PATH)
        print("SaveSystem: 删档完成")
