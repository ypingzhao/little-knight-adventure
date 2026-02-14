class_name Player
extends CharacterBody2D

#region /// export var
# 移动速度 = 基础速度 + 技能加成
var move_speed:float:
    get:
        return float(GlobalData.player_move_speed + GlobalData.skill_speed)
    set(value):
        pass  # 只读，通过 GlobalData 控制

@export var jump_speed:float = -640

#endregion

#region /// state machinne variables

var states:Array[PlayerState]

var current_state: PlayerState : 
    get: return states.front()
var previous_state: PlayerState :
    get: return states[1]
#endregion

#region /// standard variables

var direction : Vector2 = Vector2.ZERO
var gravity : float = 980

#endregion


func _ready() -> void:
    #initialize states
    initialize_states()
    
    pass

func _unhandled_input(event: InputEvent) -> void:
    change_state(current_state.handle_input(event))
    pass

func _process(_delta: float) -> void:
    update_direction()
    change_state(current_state.process(_delta))
    pass
    
func _physics_process(_delta: float) -> void:
    velocity.y +=gravity * _delta
    move_and_slide()
    change_state(current_state.physice_process(_delta))
    
    pass

func initialize_states() -> void: 
    states = []
    #gather all the states
    for c in $States.get_children():
        if c is PlayerState:
            states.append(c)
            c.player = self
        pass
    
    if states.size() == 0:
        return
    
    #initialize all states
    for state in states:
        state.init()
    
    #set our first state
    change_state(current_state)
    #需要先call一下enter方法才能启动
    current_state.enter()
    $Label.text = current_state.name
    pass
    
    
func change_state(new_state:PlayerState) -> void:
    if new_state == null:
        return
    elif new_state == current_state:
        return
    
     #如果有新状态，就让current_state触发exit方法
    if current_state:
        current_state.exit()
    #将new_state放入到states数值第一位
    states.push_front(new_state)
    #current_state中已经是新的new_state，所以可以call enter方法
    current_state.enter()
    #避免states无限变长，只保留前三个值
    states.resize(3)
    $Label.text = current_state.name
    pass
    
func update_direction() -> void:
    #var prev_direction: Vector2 = direction
    
    #direction = Input.get_vector("left","right","up","down")
    #改为轴向获取
    var x_axis = Input.get_axis("left","right")
    var y_axis = Input.get_axis("up","down")
    direction = Vector2(x_axis,y_axis)
    
    # do some more stuff
    pass   
    
