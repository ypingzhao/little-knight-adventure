extends Node

## ============================================================================
## 技能树管理器 - SkillTreeManager
## ============================================================================
## 功能：管理玩家技能升级系统
## 作者：自动生成
## 版本：1.0
##
## 使用方法：
## 1. 在编辑器中修改 SKILL_CONFIG 添加新技能
## 2. 调用 upgrade_skill(skill_id) 升级技能
## 3. 调用 get_skill_level(skill_id) 获取技能等级
## ============================================================================


## ============================================================================
## 信号定义
## ============================================================================

signal skill_upgraded(skill_id: String, new_level: int)  ## 技能升级成功
signal upgrade_failed(skill_id: String, reason: String)   ## 升级失败（金币不足等）


## ============================================================================
## 技能配置数据（静态）- 编辑这个区域来添加新技能
## ============================================================================
## 格式说明：
## - id: 技能唯一标识符（必填）
## - name: 技能显示名称（必填）
## - description: 技能描述（必填）
## - max_level: 技能最大等级（必填）
## - cost_per_level: 每级升级费用数组，从等级1开始（必填）
## - value_per_level: 每级提供的数值加成数组，从等级1开始（必填）
## - effect_type: 效果类型，用于应用技能效果（必填）
## - icon_path: 图标资源路径（可选，留空显示一个默认图标）
## - unlock_condition: 解锁条件，需要先升级的技能ID（可选，留空表示默认解锁）
## ============================================================================

const SKILL_CONFIG := {
    "health": {
        "id": "health",
        "name": "生命值",
        "description": "提升最大生命值",
        "max_level": 3,
        "cost_per_level": [100, 200, 300],           # 等级1→2: 100, 等级2→3: 200, 等级3→满级: 300
        "value_per_level": [1, 2, 3],                # 等级1: +1, 等级2: +2, 等级3: +3
        "effect_type": "increase_max_health",
        "icon_path": "",                             # TODO: 添加图标路径，如 "res://assets/ui/icons/heart.png"
        "unlock_condition": "",                      # 无前置条件，默认解锁
    },

    "attack": {
        "id": "attack",
        "name": "攻击力",
        "description": "提升攻击伤害",
        "max_level": 3,
        "cost_per_level": [150, 250, 350],
        "value_per_level": [1, 2, 3],
        "effect_type": "increase_attack",
        "icon_path": "",
        "unlock_condition": "",                      # 无前置条件，默认解锁
    },

    "speed": {
        "id": "speed",
        "name": "移动速度",
        "description": "提升移动速度",
        "max_level": 2,
        "cost_per_level": [200, 400],
        "value_per_level": [50, 100],                # 速度加成（像素/秒）
        "effect_type": "increase_speed",
        "icon_path": "",
        "unlock_condition": "health",                # 需要先升级生命值技能
    },

    # TODO: 添加更多技能...
    # 示例：
    # "critical": {
    # 	"id": "critical",
    # 	"name": "暴击率",
    # 	"description": "提升暴击几率",
    # 	"max_level": 5,
    # 	"cost_per_level": [100, 150, 200, 250, 300],
    # 	"value_per_level": [5, 10, 15, 20, 25],    # 暴击率百分比
    # 	"effect_type": "increase_critical_chance",
    # 	"icon_path": "res://assets/ui/icons/critical.png",
    # 	"unlock_condition": "attack",
    # },
}


## ============================================================================
## 运行时状态（动态）- 玩家的技能等级和解锁状态
## ============================================================================
## 格式说明：
## - current_level: 当前等级（0表示未升级）
## - unlocked: 是否已解锁（可以显示在技能树中）
## ============================================================================

var skill_states := {}


## ============================================================================
## 初始化
## ============================================================================

func _ready() -> void:
    _initialize_skill_states()
    print("SkillTreeManager 初始化完成，已加载 %d 个技能配置" % SKILL_CONFIG.size())


## 初始化所有技能的运行时状态
func _initialize_skill_states() -> void:
    for skill_id in SKILL_CONFIG:
        var skill_config = SKILL_CONFIG[skill_id]

        # 检查是否默认解锁（无前置条件）
        var is_default_unlocked = (skill_config.unlock_condition == "")

        skill_states[skill_id] = {
            "current_level": 0,
            "unlocked": is_default_unlocked,
        }


## ============================================================================
## 核心功能：技能升级逻辑
## ============================================================================

## 升级技能
## @param skill_id: 技能ID
## @return: 是否升级成功
func upgrade_skill(skill_id: String) -> bool:
    # 1. 验证技能是否存在
    if not SKILL_CONFIG.has(skill_id):
        push_error("技能不存在: %s" % skill_id)
        emit_signal("upgrade_failed", skill_id, "技能不存在")
        return false

    var skill_config = SKILL_CONFIG[skill_id]
    var current_state = skill_states[skill_id]

    # 2. 检查技能是否已解锁
    if not current_state.unlocked:
        var condition = skill_config.unlock_condition
        var reason = "需要先解锁前置技能: %s" % condition
        print("❌ 升级失败 - %s" % reason)
        emit_signal("upgrade_failed", skill_id, reason)
        return false

    # 3. 检查是否已达最大等级
    var current_level = current_state.current_level
    if current_level >= skill_config.max_level:
        var reason = "技能已达到最大等级 (%d/%d)" % [current_level, skill_config.max_level]
        print("❌ 升级失败 - %s" % reason)
        emit_signal("upgrade_failed", skill_id, reason)
        return false

    # 4. 检查金币是否足够
    var next_level = current_level + 1
    var upgrade_cost = skill_config.cost_per_level[current_level]  # 数组索引从0开始

    if GlobalData.player_coin < upgrade_cost:
        var reason = "金币不足 (需要: %d, 当前: %d)" % [upgrade_cost, GlobalData.player_coin]
        print("❌ 升级失败 - %s" % reason)
        emit_signal("upgrade_failed", skill_id, reason)
        return false

    # 5. 执行升级
    GlobalData.player_coin -= upgrade_cost
    current_state.current_level = next_level

    print("✅ 技能升级成功！%s Lv.%d (消耗金币: %d)" % [skill_config.name, next_level, upgrade_cost])
    emit_signal("skill_upgraded", skill_id, next_level)

    # 6. 应用技能效果
    _apply_skill_effect(skill_id, next_level)

    # 7. 解锁依赖此技能的其他技能
    _check_and_unlock_dependent_skills(skill_id)

    return true


## ============================================================================
## 技能效果应用（需要根据实际游戏逻辑扩展）
## ============================================================================

## 应用技能效果
## @param skill_id: 技能ID
## @param level: 技能等级
func _apply_skill_effect(skill_id: String, level: int) -> void:
    var skill_config = SKILL_CONFIG[skill_id]
    var effect_value = skill_config.value_per_level[level - 1]  # 数组索引从0开始

    match skill_config.effect_type:
        "increase_max_health":
            _increase_max_health(effect_value)
        "increase_attack":
            _increase_attack(effect_value)
        "increase_speed":
            _increase_speed(effect_value)
        _:
            push_warning("未知的技能效果类型: %s" % skill_config.effect_type)


## 增加最大生命值
func _increase_max_health(value: int) -> void:
    PlayerHealth.max_health += value
    print("💚 最大生命值 +%d (当前: %d)" % [value, PlayerHealth.max_health])


## 增加攻击力（TODO: 需要实现攻击系统）
func _increase_attack(value: int) -> void:
    # TODO: 实现攻击力增加逻辑
    # 可能需要在 GlobalData 中添加 player_attack 变量
    print("⚔️ 攻击力 +%d" % value)


## 增加移动速度（TODO: 需要实现速度系统）
func _increase_speed(value: int) -> void:
    # TODO: 实现移动速度增加逻辑
    # 可能需要在玩家脚本中读取技能加成
    print("🏃 移动速度 +%d" % value)


## ============================================================================
## 技能解锁逻辑
## ============================================================================

## 检查并解锁依赖此技能的其他技能
func _check_and_unlock_dependent_skills(unlocked_skill_id: String) -> void:
    for skill_id in SKILL_CONFIG:
        var skill_config = SKILL_CONFIG[skill_id]
        var state = skill_states[skill_id]

        # 如果此技能的解锁条件是刚升级的技能
        if skill_config.unlock_condition == unlocked_skill_id and not state.unlocked:
            state.unlocked = true
            print("🔓 解锁新技能: %s" % skill_config.name)


## ============================================================================
## 查询接口（供UI使用）
## ============================================================================

## 获取技能当前等级
func get_skill_level(skill_id: String) -> int:
    if skill_states.has(skill_id):
        return skill_states[skill_id].current_level
    return 0


## 获取技能是否已解锁
func is_skill_unlocked(skill_id: String) -> bool:
    if skill_states.has(skill_id):
        return skill_states[skill_id].unlocked
    return false


## 获取技能升级费用（下一级）
func get_upgrade_cost(skill_id: String) -> int:
    if not SKILL_CONFIG.has(skill_id):
        return 0

    var skill_config = SKILL_CONFIG[skill_id]
    var current_level = get_skill_level(skill_id)

    # 如果已达最大等级，返回0
    if current_level >= skill_config.max_level:
        return 0

    return skill_config.cost_per_level[current_level]


## 获取技能数值加成（当前等级）
func get_skill_value(skill_id: String) -> int:
    if not SKILL_CONFIG.has(skill_id):
        return 0

    var skill_config = SKILL_CONFIG[skill_id]
    var current_level = get_skill_level(skill_id)

    # 如果未升级，返回0
    if current_level == 0:
        return 0

    return skill_config.value_per_level[current_level - 1]


## 获取技能配置（供UI显示）
func get_skill_config(skill_id: String) -> Dictionary:
    return SKILL_CONFIG.get(skill_id, {})


## 获取所有已解锁的技能ID列表
func get_all_unlocked_skills() -> Array:
    var unlocked = []
    for skill_id in skill_states:
        if skill_states[skill_id].unlocked:
            unlocked.append(skill_id)
    return unlocked


## ============================================================================
## 调试工具
## ============================================================================

## 打印所有技能状态（用于调试）
func debug_print_all_skills() -> void:
    print("\n========== 技能树状态 ==========")
    for skill_id in SKILL_CONFIG:
        var config = SKILL_CONFIG[skill_id]
        var state = skill_states[skill_id]
        var status = "已解锁" if state.unlocked else "未解锁"
        print("%s (%s): Lv.%d/%d | %s" % [config.name, skill_id, state.current_level, config.max_level, status])
    print("金币: %d" % GlobalData.player_coin)
    print("================================\n")


## 重置所有技能（用于测试）
func reset_all_skills() -> void:
    _initialize_skill_states()
    print("🔄 所有技能已重置")


## ============================================================================
## 存档系统集成（TODO: 需要整合到 SaveLoad 系统）
## ============================================================================

## 获取需要保存的技能数据
func get_save_data() -> Dictionary:
    return {
        "skill_states": skill_states.duplicate(true),
    }


## 从存档加载技能数据
func load_save_data(data: Dictionary) -> void:
    if data.has("skill_states"):
        skill_states = data.skill_states
        print("✅ 技能树数据已加载")
