extends CanvasLayer

@onready var health_bar: ProgressBar = %HealthBar
@onready var coin_label: Label = $CoinLabel

var tween: Tween 

func _ready():
    # 监听全局事件
    PlayerHealth.health_changed.connect(_on_health_changed)
    PlayerHealth.health_depleted.connect(_on_health_depleted)
    

    # 初始值
    health_bar.max_value = PlayerHealth.max_health
    health_bar.value     = PlayerHealth.health

func _process(_delta: float) -> void:
    var coin:int = GlobalData.player_coin
    coin_label.text = str(coin)

func _on_health_changed(_old: int, new_val: int):
    #health_bar.value = new_val 这行代码致了错误！ 答案在这里：health_changed.emit(prev, health)
     # 如果旧 Tween 还在跑，先杀掉
    if tween and tween.is_valid():
        tween.kill()
        
    tween = create_tween().set_trans(Tween.TRANS_LINEAR).set_ease(Tween.EASE_OUT_IN)
    tween.tween_property(health_bar, "value", new_val, 0.5)   # 0.25 秒完成过渡
    

func _on_health_depleted():
    # 可以在这里统一做死亡 UI 淡入等
    pass

func _on_coin_changed(_new_coins: int):
    pass
