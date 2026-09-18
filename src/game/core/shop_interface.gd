extends Node2D

signal option1
signal option2


func _on_option_1_pressed() -> void:
	option1.emit()


func _on_option_2_pressed() -> void:
	option2.emit()
