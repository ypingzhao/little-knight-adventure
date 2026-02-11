extends Node2D

@onready var coin_label: Label = $CanvasLayer/CoinLabel
    
func _process(_delta: float) -> void:
    var coin:int = GlobalData.player_coin
    coin_label.text = str(coin)
