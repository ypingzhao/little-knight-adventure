extends Node

var player_fruit:int = 0
var player_coin:int = 0

func _ready() -> void:
    SaveLoad.load_game()

func add_point():
    
    player_coin+=1
    print(player_coin)
    
func save_data(coin:int,fruit:int):
    player_coin = coin
    player_fruit = fruit
