extends Node2D

signal boat_collide

func _on_boat_collision(body: Node2D) -> void:
	boat_collide.emit()
