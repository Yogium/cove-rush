extends Node2D

signal cargo_collide

func _on_cargo_collision(body: Node2D) -> void:
	cargo_collide.emit()
