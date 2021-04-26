extends KinematicBody2D

var SCREENSHOTS_ENABLED = true
export var NONE = 0
export var JUMP_VELOCITY = 0
export var ACCELERATION = 0
export var RUN_SPEED_MAX = 0
export var GRAVITY = 0
export var MAX_GRAVITY = 0
export var CLIMB_SPEED = 0

var screenshotNumber = 0

var leftIsPressed = false
var rightIsPressed = false
var keyX = 0
var upIsPressed = 0
var downIsPressed = 0
var keyY = 0

var jumpPressed = false
var jumpPreviouslyPressed = false
var jumpJustPressed = false

var actionPressed = false
var actionPreviouslyPressed = false
var actionJustPressed = false

var directionFacing = "right"

var isOnLadder
var overlapping
var overlappingTile

export(Array, PackedScene) var blockList = []

var heldItemID = -1

var velocity = Vector2(0, 0)

onready var currentScene = get_tree().current_scene
onready var cursor = currentScene.get_node("Cursor")

onready var animatedSprite = get_node("AnimatedSprite")

# Take the player's inputs
func takeInputs():
	# Check if left is pressed
	leftIsPressed = int(Input.is_key_pressed(KEY_LEFT) or Input.is_key_pressed(KEY_A))
	# Check if right is pressed
	rightIsPressed = int(Input.is_key_pressed(KEY_RIGHT) or Input.is_key_pressed(KEY_D))
	# Combine left and right inputs
	keyX = rightIsPressed - leftIsPressed
	
	# Check if down is pressed
	downIsPressed = int(Input.is_key_pressed(KEY_DOWN) or Input.is_key_pressed(KEY_S))
	# Check if up is pressed
	upIsPressed = int(Input.is_key_pressed(KEY_UP) or Input.is_key_pressed(KEY_W))
	# Combine left and right inputs
	keyY = downIsPressed - upIsPressed
	
	actionPreviouslyPressed = actionPressed
	actionPressed = max(int(Input.is_key_pressed(KEY_E)), int(Input.is_key_pressed(KEY_X)))
	if !actionPreviouslyPressed and actionPressed:
		actionJustPressed = true
	else:
		actionJustPressed = false
	
	jumpPreviouslyPressed = jumpPressed
	jumpPressed = max(int(Input.is_key_pressed(KEY_SPACE)), int(Input.is_key_pressed(KEY_Z)))
	if !jumpPreviouslyPressed and jumpPressed:
		jumpJustPressed = true
	else:
		jumpJustPressed = false

func changeItemSprite():
	var itemSprite = currentScene.get_node("Control").get_node("Sprite")
	if heldItemID == -1:
		itemSprite.set_texture(preload("res://Imports/SlotEmpty.png"))
	elif heldItemID == 0:
		itemSprite.set_texture(preload("res://Imports/Tile.png"))
	elif heldItemID == 1:
		itemSprite.set_texture(preload("res://Imports/DirtBlock.png"))
	elif heldItemID == 2:
		itemSprite.set_texture(preload("res://Imports/SlimeBlock.png"))

func findDirection():
	if keyX != 0:
		if keyX == 1:
			directionFacing = "right"
		else:
			directionFacing = "left"

# breakBlock(): Changes the held item ID of the player depending on the tile
# Selected by the cursor, then destroys the tile (Tile ID must be 1 or greater)
func breakBlock():
	if cursor.selectedTileID > 0:
		heldItemID = cursor.selectedTileID
		
		if cursor.selectedTileID == 1:
			$Audio/Dirt.play()
		elif cursor.selectedTileID == 2:
			$Audio/Slime.play()
		
		cursor.selectedTile.queue_free()

# placeBlock(): Places the held item at the player's current grid position
# And moves the player above it
func placeBlock():
	if $HeadCheck.get_overlapping_areas().empty():
		position.y -= 16
		
		var placedBlock = blockList[heldItemID].instance()
		currentScene.add_child(placedBlock)
		placedBlock.position = cursor.position
		
		if heldItemID == 1:
			$Audio/Dirt.play()
		elif heldItemID == 2:
			$Audio/Slime.play()
		
		heldItemID = -1

func _ready():
	pass

func _physics_process(delta):
	# 
	overlapping = $Area2D.get_overlapping_areas()
	if !overlapping.empty() and overlapping[0].get_parent().BLOCK_ID != null:
		overlappingTile = overlapping[0].get_parent().BLOCK_ID
	else:
		overlappingTile = -1
	if overlappingTile == -2:
		isOnLadder = true
	else:
		isOnLadder = false
	
	takeInputs() # Take inputs
	if keyX != 0:
		velocity.x += keyX * ACCELERATION # Accelerate the player left or right
	if keyX != sign(velocity.x) and velocity.x != 0: 
		velocity.x -= sign(velocity.x) * ACCELERATION # Friction
	
	velocity.x = clamp(velocity.x, -RUN_SPEED_MAX, RUN_SPEED_MAX)
	if !isOnLadder:
		velocity.y = min(velocity.y + GRAVITY, MAX_GRAVITY)
	
	if jumpJustPressed and is_on_floor():
		velocity.y = -JUMP_VELOCITY
	
	var isOnSlimeBlock = false
	var bounceVelocity = 0
	
	if velocity.y >= 280:
		bounceVelocity = -280 - GRAVITY
	elif velocity.y >= 240:
		bounceVelocity = -240 - GRAVITY
	
	var previousVelocityY = velocity.y
	
	velocity = move_and_slide(velocity, Vector2.UP)
	
	if previousVelocityY > GRAVITY and velocity.y == 0:
		$Audio/Land.play()
	
	if overlappingTile == 2 and velocity.y == 0 and bounceVelocity != 0:
		velocity.y = bounceVelocity
	
	# Find the player direction and display
	findDirection()
	
	# Find the players position on a grid
	var positionSnapped = Vector2(position.x, position.y)
	var spaceFromGrid = Vector2(int(position.x) % 16, int(position.y) % 16)
	if spaceFromGrid.x < 8:
		positionSnapped.x = int(position.x) - spaceFromGrid.x
	else:
		positionSnapped.x = int(position.x) + 16 - spaceFromGrid.x
	if spaceFromGrid.y < 8:
		positionSnapped.y = int(position.y) - spaceFromGrid.y
	else:
		positionSnapped.y = int(position.y) + 16 - spaceFromGrid.y
	
	if heldItemID == -1:
		if directionFacing == "right":
			cursor.position = Vector2(positionSnapped.x + 16, positionSnapped.y)
			#if spaceFromGrid.x < 8:
				#cursor.position.x += 16
		elif directionFacing == "left":
			cursor.position = Vector2(positionSnapped.x - 16, positionSnapped.y)
			#if spaceFromGrid.x > 7:
				#cursor.position.x -= 16
	else:
		cursor.position = Vector2(positionSnapped.x, positionSnapped.y)
	
	if actionJustPressed and is_on_floor() and cursor.sprite.visible:
		if heldItemID == -1:
			breakBlock()
		else:
			var groundCheck = cursor.get_node("GroundCheck").get_overlapping_areas()
			if !groundCheck.empty():
				placeBlock()
	
	if isOnLadder:
		velocity.y = keyY * CLIMB_SPEED
	
	changeItemSprite()
	
	# Animation
	if velocity.x > 0:
		animatedSprite.flip_h = false
	elif velocity.x < 0:
		animatedSprite.flip_h = true
	if is_on_floor():
		if velocity.x == 0:
			animatedSprite.play("Idle")
		else:
			animatedSprite.play("Run")
	else:
		if velocity.y > 0:
			animatedSprite.play("Fall")
		elif velocity.y < 0:
			animatedSprite.play("Jump")
	
	if isOnLadder:
		if velocity == Vector2(0, 0):
			animatedSprite.play("Ladder")
		else:
			animatedSprite.play("Climb")
	
	# Go to next level when exitting the bottom of the screen
	if position.y > 190:
		roomNext()
	
	if Input.is_action_just_pressed("ui_home"):
		get_tree().reload_current_scene()
	
	

func roomNext():
	var currentLevelScene = get_tree().get_current_scene().get_name()
	if currentLevelScene == "Level":
		get_tree().change_scene("res://Scenes/Level1.tscn")
	elif currentLevelScene == "Level1":
		get_tree().change_scene("res://Scenes/Level2.tscn")
	elif currentLevelScene == "Level2":
		get_tree().change_scene("res://Scenes/Level3.tscn")
	elif currentLevelScene == "Level3":
		get_tree().change_scene("res://Scenes/Level4.tscn")
	elif currentLevelScene == "Level4":
		get_tree().change_scene("res://Scenes/Level5.tscn")
	elif currentLevelScene == "Level5":
		get_tree().change_scene("res://Scenes/Level6.tscn")
	elif currentLevelScene == "Level6":
		get_tree().change_scene("res://Scenes/Level7.tscn")
	elif currentLevelScene == "Level7":
		get_tree().change_scene("res://Scenes/Level8.tscn")
	elif currentLevelScene == "Level8":
		get_tree().change_scene("res://Scenes/Level9.tscn")
	elif currentLevelScene == "Level9":
		get_tree().change_scene("res://Scenes/Level10.tscn")
	elif currentLevelScene == "Level10":
		get_tree().change_scene("res://Scenes/Level11.tscn")
	elif currentLevelScene == "Level11":
		get_tree().change_scene("res://Scenes/Level12.tscn")
	elif currentLevelScene == "Level12":
		get_tree().change_scene("res://Scenes/Level13.tscn")
	elif currentLevelScene == "Level13":
		get_tree().change_scene("res://Scenes/Level14.tscn")
	elif currentLevelScene == "Level14":
		get_tree().change_scene("res://Scenes/LevelEnd.tscn")
	
	


func _on_AnimatedSprite_animation_finished():
	if animatedSprite.animation == "Run":
		$Audio/Walk.play()
