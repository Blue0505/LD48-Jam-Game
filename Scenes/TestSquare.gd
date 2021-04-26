extends Node2D

var BLOCK_ID = -1

var heldItemId = -1
onready var currentScene = get_tree().current_scene
onready var player = currentScene.get_node("Player")
onready var sprite = get_node("Sprite")

func _ready():
	pass

var selectedTile
var selectedTileID
var actionPreviouslyPressed
var actionPressed
var actionJustPressed

var heldBlockID

func _physics_process(delta):
	# 
	var selectedItem = $Area2D.get_overlapping_areas()
	if !selectedItem.empty():
		selectedTile = selectedItem[0].get_parent()
		selectedTileID = selectedTile.BLOCK_ID
	else:
		selectedTileID = -1
	
	var groundCheck = $GroundCheck.get_overlapping_areas()
	
	if player.is_on_floor() and (player.heldItemID == -1 or !groundCheck.empty()):
		sprite.visible = true
	else:
		sprite.visible = false
	
	if player.heldItemID == -1:
		if selectedTileID > 0:
			sprite.set_texture(preload("res://Imports/TestSquare.png"))
		else:
			sprite.set_texture(preload("res://Imports/TestSquare4.png"))
	else:
		sprite.set_texture(preload("res://Imports/TestSquare3.png"))
