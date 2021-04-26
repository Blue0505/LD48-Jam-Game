extends CollisionShape2D

onready var player = get_tree().current_scene.get_node("Player")

func _physics_process(delta):
	position = Vector2(player.positionSnapped)
	print(player.positionSnapped)
