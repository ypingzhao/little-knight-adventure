# LevelManager.gd
extends Node

var LEVEL_DB = {
    "easy"   : {"levels": ["res://scenes/coco_adventure.tscn","res://scenes/dungeon.tscn"],   "index": 0},
    "normal" : {"levels": ["res://scenes/levels/island_normal_ch_1.tscn","res://scenes/levels/dungeon_normal_ch_1.tscn"],                    "index": 0},
    "hard"   : {"levels": ["res://scenes/levels/oscar_adventure.tscn"],                              "index": 0},
    "boss"   : {"levels": ["res://scenes/levels/boss01_scene.tscn"],                                  "index": 0},
    "bonus"  : {"levels": ["res://scenes/shop.tscn"],                                          "index": 0},
    "win"    : {"levels": ["res://scenes/win_scene.tscn"],                                     "index": 0},
    "result" : {"levels": ["res://scenes/result_scene.tscn"],                                     "index": 0},
    "start"  : {"levels": ["res://scenes/start_game.tscn"],                                    "index": 0}
}

func goto_next_room(difficulty: String) -> void:
    var info = LEVEL_DB.get(difficulty)
    if not info or info.levels.is_empty():
        push_error("没有配置 %s 的关卡" % difficulty)
        return

    var pool: Array = info.levels
    var idx: int  = info.index
    var path: String = pool[idx]

    # 索引+1并写回
    idx = (idx + 1) % pool.size()
    LEVEL_DB[difficulty].index = idx

    get_tree().change_scene_to_file(path)
