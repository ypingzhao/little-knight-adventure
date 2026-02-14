extends Node
signal health_changed(old_val:int, new_val:int)
signal health_depleted()

# 最大生命值 = 基础生命值 + 技能加成
var max_health:int:
    get:
        return GlobalData.player_health + GlobalData.skill_health
    set(value):
        pass  # 只读，通过 GlobalData 控制

# 当前生命值（动态获取最大值）
var health:int:
    get:
        return _current_health
    set(value):
        set_health(value)

var _current_health:int = 0  # 内部存储当前生命值

func _ready() -> void:
    # 初始化时设置当前生命值为最大值
    _current_health = max_health

func set_health(value:int):
    var prev = _current_health
    _current_health = clampi(value, 0, max_health)
    health_changed.emit(prev, _current_health)
    if _current_health == 0:
        health_depleted.emit()

func take_damage(amount:int):
    set_health(_current_health - amount)

# 治疗生命值
func heal(amount:int) -> void:
    set_health(_current_health + amount)

# 设置为最大生命值
func set_to_max() -> void:
    _current_health = max_health
    health_changed.emit(_current_health, _current_health)
    print("💚 生命值恢复到最大值: %d" % max_health)
