class_name PlayerState
extends Node


var player:Player
var next_state:PlayerState

#region ///state referennces
#reference to all states
@onready var idle: PlayerStateIdle = %idle
@onready var run: PlayerStateRun = %run
@onready var jump: PlayerStateJump = %jump

#endregion

#what happens when this state is initialized?
func init() -> void:
    
    pass
    
#what happens when we enter this state?
func enter() -> void:
    
    pass
    
#what happens when wen exit this state?
func exit() -> void:
    
    pass
    
#what happens when an input is pressed?
func handle_input(_event:InputEvent) -> PlayerState:
    
    return next_state


#what happens each process tick in this state?
func process(_delta:float) -> PlayerState:
    return next_state


#what happens each physics_process tick in this state?
func physice_process(_delta:float) -> PlayerState:
    return next_state
