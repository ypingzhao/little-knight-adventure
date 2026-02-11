class_name PlayerStateIdle
extends PlayerState

#what happens when this state is initialized?
func init() -> void:
    
    pass
    
#what happens when we enter this state?
func enter() -> void:
    #play animation
    pass
    
#what happens when wen exit this state?
func exit() -> void:
    
    pass
    
#what happens when an input is pressed?
func handle_input(_event:InputEvent) -> PlayerState:
    #处理按键
    if Input.is_action_pressed("jump") and player.is_on_floor():
        return jump
    return next_state


#what happens each process tick in this state?
func process(_delta:float) -> PlayerState:
    if player.direction.x != 0:
        return run
    
    
    
    return next_state


#what happens each physics_process tick in this state?
func physice_process(_delta:float) -> PlayerState:
    player.velocity.x = 0
    return next_state
