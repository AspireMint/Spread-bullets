extends Node

var bullets_list: Spatial
var bullet: Spatial

func _ready():
	bullets_list = get_tree().get_root().find_node("Bullets", true, false)
	bullet = get_tree().get_root().find_node("Bullet", true, false)
