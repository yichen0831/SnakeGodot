
extends Node2D

var Block = preload("res://Subscenes/block.xml")

const block_size = 30.0												# the size of the block sprite

export var move_time = 0.3					# how fast the player will move

export var width = 20						# the width of the board
export var height = 16						# the height of the board

export var color_wall = Color(0.298312, 0.410148, 0.326675)			# the wall color
export var color_snake = Color(0.638488, 0.881216, 0.574282)		# the snake/player color
export var color_food = Color(0.879636, 0.43566, 0.409141)			# the food color


const init_length = 4						# player initial length
var init_pos = Vector2(width/2, height/2) 	# player initial position

var player_snake							# the player

var board = {}								# array for board block status
											# 0: empty block 
											# 1: player block 
											# 2: food block

var game_over = false						# is the game over
var time_counter							# time counter for moving the player
var food_block								# the food block

var moving									# if the player is moving

var player_length_text						# the label text for displaying player's length


class Player:
	var Block = preload("res://Subscenes/block.xml")						# block sprite

	var _pos = Vector2(0, 0)# player's position
	var _blocks = []		# player's block sprites
	var _dir = Vector2(0, 0)# player's moving direction
	var _color				# player color
	
	var _gameover = false	# if the player hits wall or self, game is over
	
	var _board_node 		# reference to board node for adding sprite
	var _board = {}			# reference to board
	var _board_width = 0	# reference to board width
	var _board_height = 0	# reference to board height
	
	# return player's length
	func length():
		return _blocks.size()
		
	# return player's blocks
	func blocks():
		return _blocks
	
	# return player's pos
	func pos():
		return _pos
	
	# set player's dir
	func set_dir(dir):
		if _dir.dot(dir) != 0:
			# invalid direction
			return false
		_dir = dir
		return true
	
	# return player's dir
	func dir():
		return _dir
		
	# return gameover
	func gameover():
		return _gameover
	
	# set board's Node2D reference for add_child 
	func set_board_node(board_node):
		_board_node = board_node	
		
	# set board's reference
	func set_board(board, width, height):
		_board = board
		_board_width = width
		_board_height = height
	
	# setup player
	func setup(pos, dir, length, color):
		if _blocks.size() > 0:
			for block in _blocks:
				block.queue_free()
			_blocks = []
		_pos = pos
		_dir = dir
		_color = color
		for i in range(length):
			var block = Block.instance()
			var block_pos = _pos - Vector2(1,0) * i
			block.set_modulate(_color)
			block.set_pos( block_pos * block_size)
			_board_node.add_child(block)
			_board[block_pos] = 1
			_blocks.push_back(block)
		_gameover = false
	
	# move with _dir, return can_move: 1 - hit wall or self, 2 - hit food, 0 - hit empty tile
	func move():
		var can_move = check_move(_dir)
		
		if can_move == 1:
			_gameover = true
			
		elif can_move == 2:
			_pos += _dir
			var new_block = Block.instance()
			new_block.set_modulate(_color)
			new_block.set_pos(_pos * block_size)
			_blocks.insert(0, new_block)
			_board_node.add_child(new_block)
			_board[_pos] = 1	
		else:
			var tail_block = _blocks[_blocks.size()-1]
			var tail_pos = tail_block.get_pos() / block_size
			_board[tail_pos] = 0
			_pos += _dir
			tail_block.set_pos(_pos * block_size)
			_board[_pos] = 1
			# remove the tail block and insert to head
			_blocks.resize(_blocks.size()-1)
			_blocks.insert(0, tail_block)
			
		return can_move
		
	# check if the move is avaiable
	func check_move(dir):
		# if player will hit wall or self, return 1
		# if player will eat food, return 2
		# if player will move to a empty tile, return 0
		var attemp_move = _pos+dir
		if attemp_move.x < 0 || attemp_move.x >= _board_width || attemp_move.y < 0 || attemp_move.y >= _board_height:
			return 1
		return _board[attemp_move]
		
################### end of Class Player #############################


func setup_game():
	get_node("../GameOverMessage").hide()
	setup_board()
	player_snake.set_board(board, width, height)
	player_snake.setup(init_pos, Vector2(1, 0), 4, color_snake)
	generate_food()
	
	time_counter = move_time
	moving = false
	game_over = false
	update_player_length_text()


func _ready():
	# initialize the game
	player_length_text = get_node("../PlayerLengthText")
	draw_wall()
	player_snake = Player.new()
	player_snake.set_board_node(get_node("."))
	setup_game()
	set_process(true)

################### end of _ready #############################

	
func _process(delta):
	if game_over:
		if Input.is_action_pressed("ui_accept"):
			setup_game()

	time_counter -= delta
	
	var attemp_dir = Vector2(1.0, 1.0) # the attemp direction 
	if !moving:
		if Input.is_action_pressed("ui_up"):
			attemp_dir = Vector2(0.0, -1.0)
		
		elif Input.is_action_pressed("ui_down"):
			attemp_dir = Vector2(0.0, 1.0)
			
		elif Input.is_action_pressed("ui_left"):
			attemp_dir = Vector2(-1.0, 0.0)
		
		elif Input.is_action_pressed("ui_right"):
			attemp_dir = Vector2(1.0, 0)
			
		moving = player_snake.set_dir(attemp_dir)
	
#		if player_dir != attemp_dir and player_dir.dot(attemp_dir) == 0:
#			player_dir = attemp_dir
#			moving = true
	
	if time_counter < 0:
		# move the player
		var result = player_snake.move()
		
		# player hit food
		if result == 2:
			# generate new food
			generate_food()
			update_player_length_text()
		
		# player hit wall or self
		if result == 1:
			game_over()
		
#		move_player()
		time_counter = move_time
		moving = false

################### end of _process #############################


func draw_wall():
	var wall_block
	# top and bottom walls
	for i in range(-1, width+1):
		wall_block = Block.instance()
		wall_block.set_modulate(color_wall)
		wall_block.set_pos(Vector2(i * block_size, -block_size))
		add_child(wall_block)
		
		wall_block = Block.instance()
		wall_block.set_modulate(color_wall)
		wall_block.set_pos(Vector2(i * block_size, height * block_size))
		add_child(wall_block)
	
	# left and right walls
	for i in range(0, height):
		wall_block = Block.instance()
		wall_block.set_modulate(color_wall)
		wall_block.set_pos(Vector2(-block_size, i* block_size))
		add_child(wall_block)
		
		wall_block = Block.instance()
		wall_block.set_modulate(color_wall)
		wall_block.set_pos(Vector2(width * block_size, i* block_size))
		add_child(wall_block)
	
################### end of draw_wall #############################
		

func setup_board():
	# initialize the board
	for i in range(width):
		for j in range(height):
			board[Vector2(i, j)] = 0

################### end of setup_board #############################


func check_collision(next_move):
	# if hit wall or player self, return 1
	if next_move.x < 0 || next_move.x >= width || next_move.y < 0 || next_move.y >= height:
		return 1
	
	if board[next_move] == 1:
		return 1
	
	# if hit food, return 2
	if board[next_move] == 2:
		return 2
	
	# if hit nothing, reutrn 0
	return 0

################### end of check_collision #############################

	
func generate_food():
	if food_block == null:
		# create food_block
		food_block = Block.instance()
		food_block.set_modulate(color_food)
		add_child(food_block)
	
	var position = Vector2(0, 0)
	# find a ramdon available position
	if player_snake.length() > height * width * 0.5:
		var available_blocks = []
		for key in board.keys():
			if board[key] == 0:
				available_blocks.push_back(key)
		position = available_blocks[randi() % available_blocks.size()]
	else:
		position = Vector2(randi() % width, randi() % height)
		while(board[position] == 1):
			position = Vector2(randi() % width, randi() % height)
			
	food_block.set_pos(position * block_size)
	board[position] = 2	
	
################### end of generate_food #############################


func game_over():
	for block in player_snake.blocks():
		block.set_modulate(Color(0.3, 0.3, 0,3))
	get_node("../GameOverMessage").show()
	game_over = true

################### end of game_over #############################


func update_player_length_text():
	player_length_text.set_text("Player length: " + str(player_snake.length()))
	
################### end of update_player_length_text #############################
