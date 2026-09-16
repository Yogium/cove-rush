extends Node2D

#map constants
const MAP_HEIGHT = 8
const MAP_LENGTH = 10



#initiate 
var rng = RandomNumberGenerator.new()

func create_island(width: int, height: int, pattern_id) -> void:
	var coord = Vector2i(rng.randi_range(0, MAP_LENGTH), rng.randi_range(0, MAP_HEIGHT))
	
	#check if cell already has an island
	while %Islands.get_cell_source_id(coord) != -1:
		coord = Vector2i(rng.randi_range(0, MAP_LENGTH), rng.randi_range(1, MAP_HEIGHT+1))
	
	%Islands.set_pattern(coord, pattern_id)

# Called when the node enters the scene tree for the firsfor loop gdscriptt time.
func _ready() -> void:
	#clear islands
	%Islands.clear()
	
	for i in range(5):
		create_island(1, 1, %Islands.tile_set.get_pattern(0))

	#Testing map bounds
	#%Islands.set_pattern(Vector2i(0,0), %Islands.tile_set.get_pattern(1))
	#%Islands.set_pattern(Vector2i(10,8), %Islands.tile_set.get_pattern(1))

# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	pass
