extends Node
signal health_changed(old_val:int, new_val:int)
signal health_depleted()

@export var max_health:int = 3
var health:int = max_health:
    set = set_health

func set_health(value:int):
    var prev = health
    health = clampi(value, 0, max_health)
    health_changed.emit(prev, health)
    if health == 0:
        health_depleted.emit()

func take_damage(amount:int):
    set_health(health - amount)
