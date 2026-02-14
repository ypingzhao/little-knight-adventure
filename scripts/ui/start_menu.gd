extends Node2D

## 技能树 UI 引用
@onready var skill_tree_ui: CanvasLayer = $SkillTreeUI

func _ready() -> void:
    PlayerHealth.health = PlayerHealth.max_health

    # 设置初始金币（用于测试）
    if GlobalData.player_coin == 0:
        GlobalData.player_coin = 500

func _on_button_play_pressed() -> void:
    # 重置本轮统计数据
    GlobalData.reset_session_data()
    LevelManager.goto_next_room("easy")

func _on_button_upgrade_pressed() -> void:
    # 打开技能树 UI
    if skill_tree_ui:
        skill_tree_ui.toggle_skill_tree()
