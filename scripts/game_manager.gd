extends Node

var score = 0 
@onready var score_label = $ScoreLabel

var starting_level = 0

var current_level = 0
var area_path = "res://scenes/levels/"

var energy_cells = 0 
var area_container : Node2D
var player : PlayerController
var hud : HUD

func _ready() -> void:
	hud = get_tree().get_first_node_in_group("hud")
	area_container = get_tree().get_first_node_in_group("area_container")
	player = get_tree().get_first_node_in_group("player")
	load_level(starting_level)	
	
func add_point():
	score += 1
	print(score)
	score_label.text = "You collected " + str(score) + " coins."

func next_level():
	#increment the level count
	current_level += 1
	load_level(current_level)


func load_level(_level_number):
	#move to the next area
	#Checking the new scene path
	var full_path = area_path + "level_" + str(current_level) + ".tscn"
	#get_tree().change_scene_to_file(full_path)
	#print(full_path)
	
	
	#load next scene 
	var scene = load(full_path) as PackedScene
	if !scene:
		return 
	
	#remove the previous scene
	for child in area_container.get_children():
		child.queue_free()
		await child.tree_exited
		
	#Setting up the new scene 
	var instance = scene.instantiate()
	area_container.add_child(instance)
	reset_energy_cells()
	
	#Moving the player to the start position of the new scene
	var player_start_position = get_tree().get_first_node_in_group("player_start_position") as Node2D
	print("Spawn position", player_start_position.global_position)
	player.teleport_to_location(player_start_position.position)


#Redundant
#func set_up_level():
	#reset_energy_cells()
	
func add_energy_cell():
	energy_cells += 1
	hud.update_energy_cell_label(energy_cells)
	if energy_cells >= 1:
		#portal opens
		var portal = get_tree().get_first_node_in_group("area_exits") as AreaExit
		portal.open()
		hud.portal_opened()
		
func reset_energy_cells():
	energy_cells = 0
	hud.update_energy_cell_label(energy_cells)
	hud.portal_closed()
	
