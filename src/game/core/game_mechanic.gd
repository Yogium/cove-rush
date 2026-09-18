extends Node2D

#GAME STATE
var game_start: bool = false

#BOAT & CARGO
@export var boat_scene : PackedScene
@export var cargo_scene : PackedScene

#MAP SIZE
#@export var grid_length: int = 20 #map length in grid

#rectangular?
@export var grid_length_x: int = 15
@export var grid_length_y: int = 15

@export var grid_sizepx: int = 16 #px size of 1 grid

# spawnpoint middle
@export var spawnpoint = Vector2(floor(grid_length_x/2),floor(grid_length_y/2)) 
#grid coordiantes where the boat spawns

var boat: Array #store the scene holding the boat and the cargo
var cur_boat_pos: Array #store current grid coordinates for each segments
var old_boat_pos: Array #store previous snapshot of coordinates before moving

#CARGO
var floating_cargo_pos: Vector2
var regen_floating_cargo: bool = true

#MOVEMENT SYSTEM
var can_move: bool
var move_direction: Vector2

var up = Vector2(0,-1)
var down = Vector2(0,1)
var left = Vector2(-1,0)
var right = Vector2(1,0)

#BUFFER MOVERMENT
@export var boat_speed: float = 5.0
@export var time_between_move:float = 1000.0
@export var time_since_last_move:float = 0
@export var buffer_timer: float = 0.1

var buffer_queue: Array

#OTHER STUFF
var score: int #score
var boat_length: int = len(boat)-1 #store length of boat

#STARTING GAME FUNCTION
func _ready() -> void: #run new game on start
	new_game()
	
func new_game():
	get_tree().paused = false
	get_tree().call_group("cargo_segments", "queue_free")
	buffer_reset()
	$Interface.hide()
	$MoveTimer.wait_time = boat_speed
	move_direction = Vector2(0,0)
	can_move = true
	Engine.time_scale = 1
	
	#scale boat and cargo size fitting 16 px
	#---
	spawn_boat()
	move_cargo()

func start_game():#trigger Start Game
	game_start = true
	$MoveTimer.start()

func end_game():
	$MoveTimer.stop()
	game_start = false
	Engine.time_scale = 0.5
	get_tree().paused = true
	await get_tree().create_timer(1).timeout

	new_game()


func _on_game_over_menu_restart() -> void:
	new_game()

#HIGHLIGHT MAP
func _draw():
	for x in range(grid_length_x + 1):
		var startX = Vector2(x * grid_sizepx, 0)
		var endX = Vector2(x * grid_sizepx, grid_length_y * grid_sizepx)
		draw_line(startX, endX, Color.WHITE)

	for y in range(grid_length_y + 1):
		var startY = Vector2(0, y * grid_sizepx)
		var endY = Vector2(grid_length_x * grid_sizepx, y * grid_sizepx)
		draw_line(startY, endY, Color.WHITE)


#SPAWN BOAT FUNCTION
func spawn_boat():
	boat.clear()
	cur_boat_pos.clear()
	old_boat_pos.clear()
	add_boat_head(spawnpoint + Vector2(0,0))

func add_boat_head(pos):
	print("BoatHead Added")
	cur_boat_pos.append(pos)
	var BoatHead = boat_scene.instantiate()
	BoatHead.position = (pos * grid_sizepx)
	add_child(BoatHead)
	boat.append(BoatHead)	
	
	var boat_cam = BoatHead.get_node("Camera2D")
	boat_cam.limit_left = 0
	boat_cam.limit_top = 0
	boat_cam.limit_right = grid_length_x * grid_sizepx
	boat_cam.limit_bottom = grid_length_y * grid_sizepx
	
func add_cargo_segment(pos):
	print("Cargo Added")
	cur_boat_pos.append(pos)
	var CargoSegment = cargo_scene.instantiate()
	CargoSegment.position = (pos * grid_sizepx)
	add_child(CargoSegment)
	boat.append(CargoSegment)	
	boat_length = len(boat)-1 
	print("Boat Length: "+str(boat_length))

func sell_cargo_segment(amount):
	print("Selling " + str(amount) + " Cargo...")
	for i in range(amount):
		boat.pop_back()
		cur_boat_pos.pop_back()
		old_boat_pos.pop_back()

#SHOP FUNCTION
var shop_opened: bool = false
func open_shop():
	print("Open Shop")
	Engine.time_scale = 0
	shop_opened = true
	$Interface.show()

func close_shop():
	print("Close Shop")
	Engine.time_scale = 1
	shop_opened = false
	$Interface.hide()

func shop_keybind():
	if Input.is_action_just_pressed("open_shop") and not shop_opened:
		open_shop()
	elif Input.is_action_just_pressed("open_shop") and shop_opened:
		close_shop()




#BUFFER PROCESS
func add_buffer_input(input):
	if input != -move_direction:
		buffer_queue.append(input)

func get_buffer_input():
	return buffer_queue.pop_front()

func buffer_reset():
	buffer_queue.clear()

#MOVEMENT PROCESS
func _process(delta: float) -> void:
	run_boat_movement()
	shop_keybind()

func _physics_process(delta: float) -> void:
	if not game_start:
		return
		
	time_since_last_move += delta * boat_speed*1000
	if time_since_last_move >= time_between_move:
		update_boat()
		time_since_last_move = 0
		#await get_tree().create_timer(buffer_timer).timeout
		#buffer_reset()


#func _on_move_timer_timeout() -> void:
func print_direction_in_text(input):
	if input == up:
		return "up"
	elif input == down:
		return "down"
	elif input == down:
		return "left"
	elif input == down:
		return "right"

func update_boat():
	#buffer input before movement
	var buffered_input = get_buffer_input()
	print("buffered input "+str(print_direction_in_text(move_direction)))
	if buffered_input != null:
		move_direction = buffered_input
		
	can_move=true
	old_boat_pos = []+cur_boat_pos
	cur_boat_pos[0] += move_direction
	
	for i in range(len(cur_boat_pos)):
		if i>0:
			cur_boat_pos[i] = old_boat_pos[i-1]
		boat[i].position = (cur_boat_pos[i] * grid_sizepx) 

	
	print("Current boat position: ", cur_boat_pos[0])
	print("Pixel position: ", boat[0].position)
	
	check_floating_cargo_collected()
	check_self_crash()
	check_border()

func run_boat_movement():
	#movement to disallow opposite direction
	if Input.is_action_just_pressed("move_down") and move_direction != up:
		move_direction = down
		can_move = false
		add_buffer_input(move_direction)
		if not game_start:
			start_game()

	if Input.is_action_just_pressed("move_up") and move_direction != down:
		move_direction = up
		can_move = false
		add_buffer_input(move_direction)
		if not game_start:
			start_game()

	if Input.is_action_just_pressed("move_right") and move_direction != left:
		move_direction = right
		can_move = false
		add_buffer_input(move_direction)
		if not game_start:
			start_game()

	if Input.is_action_just_pressed("move_left") and move_direction != right:
		move_direction = left
		can_move = false
		add_buffer_input(move_direction)
		if not game_start:
			start_game()

#COLLECT CARGO
func check_floating_cargo_collected():
	if cur_boat_pos[0] == floating_cargo_pos:
		add_cargo_segment(old_boat_pos[-1])
		move_cargo()

func move_cargo():
	while regen_floating_cargo:
		regen_floating_cargo = false
		floating_cargo_pos = Vector2(randi_range(0, grid_length_x-1), randi_range(0,grid_length_y-1))
		for i in cur_boat_pos:
			if floating_cargo_pos == i :
				regen_floating_cargo = true
	$Floating_Cargo.position = (floating_cargo_pos * grid_sizepx)
	regen_floating_cargo = true


#GAMEOVER FUNCTION
func check_border():
	if cur_boat_pos[0].x < 0 or cur_boat_pos[0].x > grid_length_x - 1 or cur_boat_pos[0].y < 0 or cur_boat_pos[0].y > grid_length_y - 1:
		end_game()

func check_self_crash():
	for i in range(1, len(cur_boat_pos)):
		if cur_boat_pos[0] == cur_boat_pos[i]:
			end_game()
