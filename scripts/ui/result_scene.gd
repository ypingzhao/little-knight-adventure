extends Node2D

## ============================================================================
## 结果结算场景 - ResultScene
## ============================================================================
## 功能：显示玩家本轮游戏的统计数据
## 作者：自动生成
## 版本：1.0
##
## 使用方法：
## 1. 场景加载时自动显示本轮统计
## 2. 点击 Return to Title 返回主界面
## ============================================================================


## ============================================================================
## 节点引用
## ============================================================================

@onready var coin_number: Label = $CanvasLayer/Control/ResultTitle/CoinNumber
@onready var enemy_killed: Label = $CanvasLayer/Control/ResultTitle/EnemyKilled
@onready var return_button: Button = $CanvasLayer/ReturnButton


## ============================================================================
## 初始化
## ============================================================================

func _ready() -> void:
    # 显示本轮金币数
    coin_number.text = str(GlobalData.session_coins_collected)

    # 显示本轮敌人数
    var total_enemies = GlobalData.get_session_total_enemies()
    enemy_killed.text = str(total_enemies)

    print("📊 本轮结果 - 金币: %d, 敌人: %d" % [
        GlobalData.session_coins_collected, total_enemies
    ])

    # 连接返回按钮
    if return_button:
        return_button.pressed.connect(_on_return_pressed)


## ============================================================================
## 事件处理
## ============================================================================

## 返回按钮点击事件
func _on_return_pressed() -> void:
    print("🔙 返回主界面")
    get_tree().change_scene_to_file("res://scenes/start_game.tscn")


## 场景退出时清理数据
func _exit_tree() -> void:
    # 清理本轮数据，避免影响下一轮
    GlobalData.reset_session_data()
