@tool
extends EditorPlugin


func _enter_tree() -> void:
	add_custom_type("DubinsPathDrawer2D", "Node2D", preload("res://dubins_path_drawer_2d.gd"), preload("res://truck.png"))
	pass


func _exit_tree() -> void:
	pass
