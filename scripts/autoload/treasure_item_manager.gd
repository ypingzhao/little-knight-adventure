# 自动加载名：TreasureItemManager
extends Node

enum ChestRarity {
    NORMAL,  # 普通宝箱
    RARE,   # 高级宝箱
    ROYAL    # 皇家宝箱
}

# 宝物掉落池配置
var treasure_pools := {
    ChestRarity.NORMAL: [
        {
            "type": "coin",
            "scene_path": "res://scenes/items/coin.tscn",
            "weight": 100  # 100% 掉落金币
        }
    ],
    ChestRarity.RARE: [
        {
            "type": "diamond",
            "scene_path": "res://scenes/items/diamond.tscn",
            "weight": 100  # 100% 掉落钻石
        }
    ],
    ChestRarity.ROYAL: [
        {
            "type": "health_pot",
            "scene_path": "res://scenes/items/health_pot.tscn",
            "weight": 100  # 100% 掉落血瓶
        }
    ]
}


## 从指定稀有度的宝箱中获取随机宝物数据
## 参数：
## rarity: 宝箱稀有度 (ChestRarity.NORMAL/RARE/ROYAL)
## 返回: Dictionary {
##	"type": "coin/diamond/health_pot",
##	"scene_path": "res://scenes/items/xxx.tscn"
## }
func get_random_treasure(rarity: ChestRarity) -> Dictionary:
    if not treasure_pools.has(rarity):
        push_error("TreasureItemManager: 未知的宝箱稀有度: %s" % rarity)
        return {}

    var pool = treasure_pools[rarity]

    # 权重随机选择
    var total_weight := 0
    for item in pool:
        total_weight += item.get("weight", 0)

    if total_weight == 0:
        push_error("TreasureItemManager: 宝物池总权重为0")
        return {}

    var random_value := randi() % total_weight
    var current_weight := 0

    for item in pool:
        current_weight += item.get("weight", 0)
        if random_value < current_weight:
            print("TreasureItemManager: 宝箱 [%s] 掉落 [%s]" % [rarity, item.type])
            return item

    return {}  # 不应该到达这里


## 获取宝物场景路径
## 参数：
## rarity: 宝箱稀有度
## 返回: 场景文件路径字符串
func get_treasure_scene_path(rarity: ChestRarity) -> String:
    var treasure_data = get_random_treasure(rarity)
    if treasure_data.is_empty():
        return ""

    return treasure_data.get("scene_path", "")


## 获取宝物类型名称（用于调试）
## 参数：
## rarity: 宝箱稀有度
## 返回: 类型名称字符串
func get_treasure_type_name(rarity: ChestRarity) -> String:
    var treasure_data = get_random_treasure(rarity)
    if treasure_data.is_empty():
        return "unknown"

    return treasure_data.get("type", "unknown")


## 生成宝物节点并添加到场景
## 参数：
## rarity: 宝箱稀有度
## spawn_position: 生成位置（Vector2）
## parent_node: 父节点（通常为宝箱的父节点）
## 返回: 生成的宝物节点（Node2D）
## 注：此方法已禁用，宝物生成逻辑已移到 treasure_chest.gd 中直接实现
## treasure_chest.gd 通过 @export var chest_rarity 配置，场景检查器中设置对应值
#func spawn_treasure(rarity: ChestRarity, spawn_position: Vector2, parent_node: Node) -> Node2D:
#	var treasure_path = get_treasure_scene_path(rarity)
#	if treasure_path.is_empty():
#		push_error("TreasureItemManager: 无法获取宝物场景路径")
#		return null
#
#	## 加载场景并实例化
#	var treasure_packed = load(treasure_path)
#	if not treasure_packed:
#		push_error("TreasureItemManager: 无法加载场景: %s" % treasure_path)
#		return null
#
#	var treasure_node = treasure_packed.instantiate()
#	if not treasure_node:
#		push_error("TreasureItemManager: 无法实例化宝物节点")
#		return null
#
#	## 添加到场景
#	parent_node.add_child(treasure_node)
#	treasure_node.global_position = spawn_position
#
#	print("TreasureItemManager: 已生成宝物 [%s] 于位置 %s" % [get_treasure_type_name(rarity), spawn_position])
#
#	return treasure_node
