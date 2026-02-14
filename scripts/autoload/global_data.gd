extends Node

#角色初始属性
var player_health:int = 1
var player_attack:int = 1
var player_move_speed:int = 50
var player_critical:float = 1.00
var player_fruit:int = 0
var player_coin:int = 80
var player_diamond:int = 0

#技能树相关选项初始化
var skill_health:int = 0
var skill_speed:int = 0
var skill_attack:int = 0
var skill_critical:float = 0.00

# ============================================================================
## 本轮游戏统计数据（不存档，仅用于 result_scene 显示）
## ============================================================================

# 本轮收集的金币数（不含初始持有）
var session_coins_collected: int = 0

# 本轮击杀的敌人统计（按类型）
var session_enemies_killed: Dictionary = {
    "boss": 0,
    "bat": 0,
    "slime_green": 0
}

#本轮收集的钻石数
var session_diamond_collected: int = 0

func _ready() -> void:
    SaveLoad.load_game()

func add_point():

    player_coin+=1
    print(player_coin)

#增加钻石diamond
func add_diamond():
    player_diamond +=1

#改造save_data,新增diamond
func save_data(coin:int,fruit:int):
    player_coin = coin
    player_fruit = fruit
    

# ============================================================================
## 辅助函数：获取玩家总属性（基础 + 技能加成）
## ============================================================================

## 获取玩家总生命值
func get_total_health() -> int:
    return player_health + skill_health

## 获取玩家总攻击力
func get_total_attack() -> int:
    return player_attack + skill_attack

## 获取玩家总移动速度
func get_total_move_speed() -> int:
    return player_move_speed + skill_speed

## 获取玩家总暴击率（百分比）
func get_total_critical() -> float:
    return player_critical + skill_critical

# ============================================================================
## 测试辅助函数
## ============================================================================

## 增加金币（测试用）
func add_test_coins(amount:int = 100) -> void:
    player_coin += amount
    print("🧪 测试：增加 %d 金币，当前金币: %d" % [amount, player_coin])

## 设置金币数量（测试用）
func set_test_coins(amount:int = 500) -> void:
    player_coin = amount
    print("🧪 测试：设置金币为 %d" % player_coin)

## 重置所有技能（测试用）
func reset_all_skills() -> void:
    skill_health = 0
    skill_speed = 0
    skill_attack = 0
    skill_critical = 0.0
    print("🔄 测试：所有技能已重置")

# ============================================================================
## 本轮游戏统计管理（用于 result_scene）
## ============================================================================

## 增加本轮金币计数
func add_session_coin(amount: int = 1) -> void:
    session_coins_collected += amount

## 增加本轮敌人数
func add_session_enemy_killed(enemy_type: String) -> void:
    if session_enemies_killed.has(enemy_type):
        session_enemies_killed[enemy_type] += 1
    else:
        push_warning("未知敌人类型: %s" % enemy_type)

## 获取本轮总敌人数
func get_session_total_enemies() -> int:
    var total := 0
    for count in session_enemies_killed.values():
        total += count
    return total

##增加本轮钻石数
func add_session_diamond(amount: int = 1) -> void:
    session_diamond_collected += amount
    print("本轮钻石: %d" % session_diamond_collected)

## 获取本轮钻石数
func get_session_diamond_collected() -> int:
    return session_diamond_collected

## 重置本轮数据（游戏开始时调用）
func reset_session_data() -> void:
    session_coins_collected = 0
    session_diamond_collected = 0
    session_enemies_killed = {
        "boss": 0,
        "bat": 0,
        "slime_green": 0
    }
    print("🔄 本轮统计数据已重置")
