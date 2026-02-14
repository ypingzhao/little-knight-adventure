extends CanvasLayer

@onready var health_bar: ProgressBar = %HealthBar
@onready var boss_health_bar: ProgressBar = %BossHealthBar
@onready var boss_label: Label = $BossLabel
@onready var coin_label: Label = $CoinLabel

var tween: Tween

func _ready():
    # 添加到 hud 组以便其他节点可以找到
    add_to_group("hud")

    # 监听全局事件
    PlayerHealth.health_changed.connect(_on_health_changed)
    PlayerHealth.health_depleted.connect(_on_health_depleted)

    # 初始值
    health_bar.max_value = PlayerHealth.max_health
    health_bar.value     = PlayerHealth.health

    # 初始隐藏boss血条
    if boss_health_bar:
        boss_health_bar.visible = false
    if boss_label:
        boss_label.visible = false

func _on_boss_health_changed(current_hp: int) -> void:
    if boss_health_bar and boss_health_bar.visible:
        if tween and tween.is_valid():
            tween.kill()
        tween = create_tween().set_trans(Tween.TRANS_LINEAR).set_ease(Tween.EASE_IN_OUT)
        tween.tween_property(boss_health_bar, "value", current_hp, 0.5)


func _process(_delta: float) -> void:
    var coin:int = GlobalData.player_coin
    coin_label.text = str(coin)


func _on_health_changed(_old: int, new_val: int):
    #health_bar.value = new_val 这行代码致了错误！ 答案在这里：health_changed.emit(prev, health)
    # 如果旧 Tween 还在跑，先杀掉
    if tween and tween.is_valid():
        tween.kill()

    tween = create_tween().set_trans(Tween.TRANS_LINEAR).set_ease(Tween.EASE_IN_OUT)
    tween.tween_property(health_bar, "value", new_val, 0.5)   # 0.25 秒完成过渡

func _on_health_depleted() -> void:
    # 玩家生命值耗尽，可以在这里添加死亡相关逻辑
    pass


## 显示boss血条

func show_boss_health_bar(max_hp: int) -> void:
    if boss_health_bar:
        boss_health_bar.visible = true
        boss_health_bar.max_value = max_hp
        boss_health_bar.value = max_hp

    if boss_label:
        boss_label.visible = true

    print("HUD: Boss health bar shown, max_hp=", max_hp)
