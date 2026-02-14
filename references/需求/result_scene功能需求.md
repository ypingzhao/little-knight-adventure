# Result Scene 功能需求

> **日期**: 2025-02-13
> **优先级**: 高
> **状态**: 待实现

---

## 功能概述

实现游戏结果结算场景，显示玩家本轮游戏的统计数据，并提供返回主界面的功能。

---

## 核心需求

### 1. 金币统计显示

**组件**: `CoinNumber` (Label)

**需求**:
- 显示玩家从点击"Play"按钮开始，到死亡前获得的总金币数
- 格式: 数字显示（如 "23"）
- 位置: ResultTitle 下方，offset (190, 74) 到 (297, 97)

**数据来源**:
- 需要在游戏过程中记录玩家获得的金币数量
- 从 GlobalData 读取当前金币，但需要区分"本轮获得"还是"总持有"

**实现方式**:
- 方案 A: 在游戏开始时记录初始金币数，结束时计算差值
- 方案 B: 新增一个"本轮金币"计数器，每次吃到金币时累加

**推荐**: 方案 B，更清晰独立

### 2. 敌人击杀统计显示

**组件**: `EnemyKilled` (Label)

**需求**:
- 显示本轮游戏击杀的所有敌人数量
- 统计范围: boss、bat、green slime
- 格式: 数字显示（如 "12"）
- 位置: CoinNumber 下方，offset (190, 115) 到 (297, 138)

**数据来源**:
- 需要在敌人死亡时记录击杀数
- 按敌人类型分别统计

**实现方式**:
- 在 GlobalData 新增变量:
  ```gdscript
  var enemies_killed_boss: int = 0
  var enemies_killed_bat: int = 0
  var enemies_killed_slime: int = 0
  ```
- 或使用字典:
  ```gdscript
  var enemies_killed: Dictionary = {"boss": 0, "bat": 0, "slime_green": 0}
  ```
- 敌人死亡脚本中调用计数器
- ResultScene 读取总数并显示

### 3. 场景显示触发条件

**需求**:
- 当玩家**死亡**时，显示 ResultScene
- 当玩家**穿过 win_scene 的门**时，显示 ResultScene

**实现方式**:
- 玩家死亡时切换场景到 result_scene.tscn
- 胜利到达时切换场景到 result_scene.tscn
- 需要在显示 ResultScene 前传递数据（金币数、敌人数）

**数据传递方式**:
- 方案 A: 使用 GlobalData 存储临时数据
- 方案 B: 使用场景参数 (call_deferred())
- 方案 C: 使用 autoload 单例

**推荐**: 方案 A，使用 GlobalData 添加临时变量:
```gdscript
# 临时本轮数据（不存入存档）
var session_coins_collected: int = 0
var session_enemies_killed: Dictionary = {}
```

### 4. 返回主界面功能

**组件**: `ReturnButton` (Button)

**需求**:
- 点击按钮后，返回到 start scene
- 清理本轮临时数据

**实现方式**:
- 连接 ReturnButton 的 pressed 信号
- 调用 `get_tree().change_scene_to_file("res://scenes/start_scene.tscn")`
- 重置 GlobalData 的本轮临时变量

---

## 技术实现要点

### GlobalData 新增变量

```gdscript
## ============================================================================
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

## 重置本轮数据（游戏开始时调用）
func reset_session_data() -> void:
    session_coins_collected = 0
    session_enemies_killed = {
        "boss": 0,
        "bat": 0,
        "slime_green": 0
    }
```

### ResultScene 脚本实现

```gdscript
extends Node2D

@onready var coin_number: Label = $CanvasLayer/Control/ResultTitle/CoinNumber
@onready var enemy_killed: Label = $CanvasLayer/Control/ResultTitle/EnemyKilled
@onready var return_button: Button = $CanvasLayer/ReturnButton

func _ready() -> void:
    # 显示本轮金币数
    coin_number.text = str(GlobalData.session_coins_collected)

    # 显示本轮敌人数
    var total_enemies = GlobalData.get_session_total_enemies()
    enemy_killed.text = str(total_enemies)

    # 连接返回按钮
    return_button.pressed.connect(_on_return_pressed)

func _on_return_pressed() -> void:
    # 返回主界面
    get_tree().change_scene_to_file("res://scenes/start_scene.tscn")

func _exit_tree() -> void:
    # 场景退出时清理数据
    GlobalData.reset_session_data()
```

### 修改 coin.gd

在玩家吃到金币时调用计数器：
```gdscript
func _on_body_entered(body: Node2D) -> void:
    if body.is_in_group("player"):
        animation_player.play("pick_up")
        GlobalData.add_point()
        GlobalData.add_session_coin()  # 新增：记录本轮金币
        print("金币 +1，当前: %d" % GlobalData.player_coin)
```

### 修改敌人死亡脚本

在敌人死亡时调用计数器（需要查看各个敌人脚本）

---

## UI 布局

```
┌─────────────────────────────┐
│   This Round Result      │
│                         │
│   Coins: 23             │  <- CoinNumber
│   Enemies Killed: 12      │  <- EnemyKilled
│                         │
│   [Return to Title]       │  <- ReturnButton
└─────────────────────────────┘
```

---

## 实现优先级

1. **高优先级** (必须完成)
   - [ ] GlobalData 新增本轮统计变量和方法
   - [ ] ResultScene 脚本实现（显示数据、返回功能）
   - [ ] 修改 coin.gd 记录本轮金币

2. **中优先级** (功能完善)
   - [ ] 修改敌人死亡脚本记录击杀数
   - [ ] 游戏开始时重置本轮数据
   - [ ] 死亡/胜利时切换到 ResultScene

3. **低优先级** (优化增强)
   - [ ] 添加动画效果（数字滚动）
   - [ ] 添加音效反馈
   - [ ] 优化 UI 样式

---

## 测试场景

### 测试用例 1: 金币统计
1. 启动游戏，点击 Play
2. 收集 5 个金币
3. 死亡
4. 验证: ResultScene 显示 "Coins: 5"

### 测试用例 2: 敌人击杀
1. 启动游戏，点击 Play
2. 击杀 3 个 bat，2 个 green slime
3. 死亡
4. 验证: ResultScene 显示 "Enemies Killed: 5"

### 测试用例 3: 返回功能
1. 在 ResultScene 点击 Return to Title
2. 验证: 返回到 start scene
3. 验证: 本轮数据已重置

---

## 相关文件

### 需要修改的文件
- [scripts/autoload/global_data.gd](scripts/autoload/global_data.gd) - 新增本轮统计变量
- [scripts/items/coin.gd](scripts/items/coin.gd) - 记录本轮金币
- [scripts/actors/enemies/*.gd](scripts/actors/enemies/) - 记录敌人数
- [scenes/result_scene.tscn](scenes/result_scene.tscn) - 可能需要添加脚本引用

### 需要新建的文件
- [scripts/ui/result_scene.gd](scripts/ui/result_scene.gd) - ResultScene 逻辑脚本

### 需要确认的文件
- [scenes/start_scene.tscn](scenes/start_scene.tscn) - 确认路径正确
- 玩家死亡逻辑 - 查看如何触发场景切换
