# TradeItemList.gd - 全局商店商品列表脚本
extends Node

# 商品数据结构类
class ItemData:
    var id: int
    var name: String
    var price: int
    var icon_path: String
    var effect_type: String  # 道具效果类型
    var description: String
    var owned: bool = false  # 是否已拥有
    
    func _init(p_id: int, p_name: String, p_price: int, p_icon_path: String, p_effect_type: String, p_description: String):
        id = p_id
        name = p_name
        price = p_price
        icon_path = p_icon_path
        effect_type = p_effect_type
        description = p_description

# 全局商品列表
var item_list: Array[ItemData] = []

# 初始化商品列表
func _ready():
    _initialize_item_list()

# 初始化商品数据
func _initialize_item_list():
    # 添加示例商品到列表中
    # 注意：图标路径暂时设为空，UI会显示占位符
    item_list.append(ItemData.new(1, "生命药水", 50, "", "HEALTH_POTION", "恢复50点生命值"))
    item_list.append(ItemData.new(2, "魔法药水", 60, "", "MANA_POTION", "恢复40点魔法值"))
    item_list.append(ItemData.new(3, "速度药水", 80, "", "SPEED_BOOST", "提升移动速度20%持续10秒"))
    item_list.append(ItemData.new(4, "护盾", 120, "", "SHIELD", "获得临时护盾抵挡一次伤害"))
    item_list.append(ItemData.new(5, "双倍金币", 150, "", "DOUBLE_COIN", "获得双倍金币效果5分钟"))
    item_list.append(ItemData.new(6, "跳跃提升", 100, "", "JUMP_BOOST", "增加跳跃高度30%"))
    item_list.append(ItemData.new(7, "攻击力提升", 200, "", "ATTACK_BOOST", "增加攻击力50%持续30秒"))
    item_list.append(ItemData.new(8, "防御提升", 180, "", "DEFENSE_BOOST", "增加防御力30%持续30秒"))
    item_list.append(ItemData.new(9, "经验值加倍", 250, "", "XP_BOOST", "获得双倍经验值效果10分钟"))
    item_list.append(ItemData.new(10, "隐身药水", 300, "", "INVISIBILITY", "隐身5秒，敌人无法发现"))

# 获取随机的三个商品
func get_random_items(count: int = 3) -> Array[ItemData]:
    # 输入验证：确保数量在合理范围内
    if count <= 0:
        return []
    if count > 10:  # 设置合理上限
        count = 10

    var available_items: Array[ItemData] = []

    # 过滤掉已拥有的商品
    for item in item_list:
        if not item.owned:
            available_items.append(item)

    # 如果可用商品少于需要的数量，就返回所有可用商品
    if available_items.size() < count:
        return available_items.duplicate()

    # 随机选择指定数量的商品
    var selected_items: Array[ItemData] = []
    var temp_items: Array[ItemData] = available_items.duplicate()

    for i in range(count):
        if temp_items.size() > 0:
            var random_index = randi() % temp_items.size()
            var selected_item = temp_items[random_index]
            selected_items.append(selected_item)
            temp_items.remove_at(random_index)

    return selected_items

# 获取所有商品
func get_all_items() -> Array[ItemData]:
    return item_list.duplicate()

# 根据ID获取特定商品
func get_item_by_id(id: int) -> ItemData:
    for item in item_list:
        if item.id == id:
            return item
    return null

# 购买商品（安全版本，包含验证）
# 返回值: 成功返回 true，失败返回 false
# 参数: item_id - 商品ID, player_coins - 玩家当前金币数
func purchase_item(item_id: int, player_coins: int) -> bool:
    # 验证输入
    if item_id <= 0 or player_coins < 0:
        return false

    # 查找商品
    var item = get_item_by_id(item_id)
    if item == null:
        push_error("尝试购买不存在的商品，ID: %d" % item_id)
        return false

    # 检查是否已拥有
    if item.owned:
        push_warning("尝试购买已拥有的商品: %s" % item.name)
        return false

    # 检查金币是否足够
    if player_coins < item.price:
        push_warning("金币不足！需要: %d，当前: %d" % [item.price, player_coins])
        return false

    # 所有验证通过，标记为已拥有
    _mark_item_as_owned(item_id)
    print("成功购买商品: %s，价格: %d" % [item.name, item.price])
    return true

# 获取商品价格（用于UI显示等）
func get_item_price(item_id: int) -> int:
    var item = get_item_by_id(item_id)
    if item == null:
        return -1
    return item.price

# 私有方法：标记商品为已拥有（仅供内部使用）
func _mark_item_as_owned(item_id: int):
    for item in item_list:
        if item.id == item_id:
            item.owned = true
            break

# 标记商品为已拥有（公开版本，保留以兼容旧代码，但建议使用purchase_item）
# 注意：此方法不进行金币和价格验证，仅用于特殊场景
func mark_item_as_owned(item_id: int):
    push_warning("直接调用 mark_item_as_owned，未进行交易验证。建议使用 purchase_item()")
    _mark_item_as_owned(item_id)

# 检查商品是否已拥有
func is_item_owned(item_id: int) -> bool:
    # 输入验证
    if item_id <= 0:
        return false

    for item in item_list:
        if item.id == item_id:
            return item.owned
    return false

# 重置所有商品的拥有状态（仅用于测试/调试）
# 注意：此函数仅在调试模式下可用，生产环境会被禁用
func reset_all_ownership():
    if not OS.is_debug_build():
        push_error("reset_all_ownership 仅在调试模式下可用！")
        return

    push_warning("调试模式：重置所有商品拥有状态")
    for item in item_list:
        item.owned = false

# 获取已拥有的商品列表
func get_owned_items() -> Array[ItemData]:
    var owned_items: Array[ItemData] = []
    for item in item_list:
        if item.owned:
            owned_items.append(item)
    return owned_items

# 获取未拥有的商品列表
func get_unowned_items() -> Array[ItemData]:
    var unowned_items: Array[ItemData] = []
    for item in item_list:
        if not item.owned:
            unowned_items.append(item)
    return unowned_items

# 获取商品总数
func get_total_item_count() -> int:
    return item_list.size()

# 获取已拥有商品数量
func get_owned_item_count() -> int:
    var count = 0
    for item in item_list:
        if item.owned:
            count += 1
    return count

# 获取未拥有商品数量
func get_unowned_item_count() -> int:
    return get_total_item_count() - get_owned_item_count()
