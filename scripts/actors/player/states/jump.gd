class_name PlayerStateJump
extends PlayerState

#what happens when this state is initialized?
func init() -> void:
    
    pass
    
#what happens when we enter this state?
func enter() -> void:
    #play animation
    
    #给跳跃一个初速度
    player.velocity.y = player.jump_speed
    pass
    
#what happens when wen exit this state?
func exit() -> void:
    
    pass
    
#what happens when an input is pressed?
func handle_input(_event:InputEvent) -> PlayerState:
    
    return next_state


#what happens each process tick in this state?
func process(_delta:float) -> PlayerState:
    if player.is_on_floor():
        return idle
    return next_state


#what happens each physics_process tick in this state?
func physice_process(_delta:float) -> PlayerState:
    if not player.is_on_floor():
        player.velocity.y += player.gravity * _delta
        
    
    return next_state
