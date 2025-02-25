extends CharacterBody2D

signal end_the_game
signal add_score

const SPEED_LR = 400.0
const GRAVITY = 4000

var is_new_figure = true
var complete = true
var is_rapid = false
var is_shadow = false
var position_start: int
var position_shadow: int

const START_POSITION = Vector2i(560, 40)
const LEFT_BORDER_X = 400.0
const RIGHT_BORDER_X = 760.0
const MINUS = Vector2i(15, -1)
const CHECK_END_GAME = [Vector2i(14, 0), Vector2i(15, 0), Vector2i(14, -1), Vector2i(15, -1)]

@onready var smashboy = $Smashboy
@onready var hero = $Hero
@onready var orange_ricky = $OrangeRicky
@onready var blue_ricky = $BlueRicky
@onready var teewee = $Teewee
@onready var cleveland_z = $ClevelandZ
@onready var rhode_island_z = $RhodeIslandZ

var ground: TileMapLayer
var tile_size: int

var figures = []
var actual_figure = null
var actual_figure_number: int
var f_x_min = []
var f_x_max = []
var v_x_min: Vector2
var v_x_max: Vector2

func _ready() -> void:
	connect("end_the_game", Callable(get_parent(), "_on_end_the_game"))
	connect("add_score", Callable(get_parent(), "_on_add_score"))

	ground = get_parent().get_node("Ground")
	tile_size = ground.tile_set.tile_size.x

	figures.append(orange_ricky)
	figures.append(blue_ricky)
	figures.append(hero)
	figures.append(smashboy)
	figures.append(teewee)
	figures.append(cleveland_z)
	figures.append(rhode_island_z)

	for figure in figures:
		var x_min: int
		var x_max: int
		var y_min: int
		var y_max: int
		for p in figure.polygon:
			x_min = min(x_min, p.x)
			x_max = max(x_max, p.x)
			y_min = min(y_min, p.y)
			y_max = max(y_max, p.y)
		f_x_min.append(Vector2(x_min, y_min))
		f_x_max.append(Vector2(x_max, y_max))

	create_new_figure()

func _physics_process(delta: float) -> void:
	if complete:
		return

	if not is_on_floor() and is_new_figure:
		is_new_figure = false
		velocity.y = GRAVITY * delta

	if is_on_floor() and !complete:
		complete = true
		create_new_figure()
		move_and_slide()
		return

	if Input.is_action_just_pressed("quick_down"):
		velocity.y += GRAVITY * delta * 20

	if Input.is_action_pressed("ui_down"):
		if !is_rapid and !complete:
			is_rapid = true
			velocity.y = GRAVITY * delta * 2

	if Input.is_action_just_released("ui_down"):
		if is_rapid and !complete:
			is_rapid = false
			velocity.y = GRAVITY * delta

	if Input.is_action_just_pressed("ui_up"):
		rotation_degrees += 90
		set_actual_x_and_position()

	if Input.is_action_just_released("ui_left"):
		stop_shadow_move()

	if Input.is_action_just_released("ui_right"):
		stop_shadow_move()

	if is_shadow:
		if Input.is_action_pressed("ui_left"):
			position_shadow -= round(delta * SPEED_LR)
			if position_shadow < position_start - tile_size:
				position.x = position_start - tile_size
				check_left_border()
				start_shadow_move()
		if Input.is_action_pressed("ui_right"):
			position_shadow += round(delta * SPEED_LR)
			if position_shadow > position_start + tile_size:
				position.x = position_start + tile_size
				check_right_border()
				start_shadow_move()

	if Input.is_action_just_pressed("ui_left"):
		check_left_border()
		start_shadow_move()

	if Input.is_action_just_pressed("ui_right"):
		check_right_border()
		start_shadow_move()

	move_and_slide()

func new_position_is_busy() -> bool:
	var result = false
	for coords in CHECK_END_GAME:
		if ground.get_cell_source_id(coords) != -1:
			result = true
	return result

func start_shadow_move() -> void:
	position_start = roundi(position.x)
	position_shadow = position_start
	is_shadow = true

func stop_shadow_move() -> void:
	is_shadow = false

func check_left_border() -> void:
	if position.x - tile_size < LEFT_BORDER_X - v_x_min.x:
		position.x = LEFT_BORDER_X - v_x_min.x
	else:
		position.x -= tile_size

func check_right_border() -> void:
	if position.x + tile_size > RIGHT_BORDER_X - v_x_max.x:
		position.x = RIGHT_BORDER_X - v_x_max.x
	else:
		position.x += tile_size

func create_new_figure() -> void:
	if actual_figure:
		actual_figure.disabled = true
		actual_figure.visible = false

		set_to_ground()

		if new_position_is_busy():
			velocity.y = 0
			actual_figure = null
			emit_signal("end_the_game")
			return

	remove_full_line()

	position = START_POSITION
	rotation_degrees = randi() % 4 * 90
	actual_figure_number = randi() % figures.size()
	actual_figure = figures[actual_figure_number]
	actual_figure.disabled = false
	actual_figure.visible = true
	set_actual_x_and_position()
	is_new_figure = true
	is_rapid = false
	velocity.y = 0
	if is_shadow:
		start_shadow_move()
	complete = false

func remove_full_line() -> void:
	var need_repeat = true
	while need_repeat:
		need_repeat = false
		for iy in range(15, -1, -1):
			var is_full_line = true
			for ix in range(9):
				if ground.get_cell_source_id(Vector2i(ix + 10, iy)) == -1:
					is_full_line = false
					break
			if is_full_line:
				need_repeat = true
				emit_signal("add_score")
				for iy2 in range(iy, -1, -1):
					for ix in range(9):
						var v_from = Vector2i(ix + 10, iy2 - 1)
						var v_to = Vector2i(ix + 10, iy2)
						if ground.get_cell_source_id(v_from) != -1:
							ground.set_cell(
								v_to,
								ground.get_cell_source_id(v_from),
								ground.get_cell_atlas_coords(v_from))
						else:
							ground.set_cell(v_to)

func set_actual_x_and_position() -> void:
	v_x_min = f_x_min[actual_figure_number]
	v_x_min = round(v_x_min.rotated(rotation))
	v_x_max = f_x_max[actual_figure_number]
	v_x_max = round(v_x_max.rotated(rotation))
	var x_min = v_x_min.x
	var x_max = v_x_max.x
	v_x_min = Vector2(min(x_min, x_max), 0)
	v_x_max = Vector2(max(x_min, x_max), 0)
	if position.x < LEFT_BORDER_X - v_x_min.x:
		position.x = LEFT_BORDER_X - v_x_min.x
	if position.x > RIGHT_BORDER_X - v_x_max.x:
		position.x = RIGHT_BORDER_X - v_x_max.x

func set_to_ground() -> void:
	var tile: TileMapLayer = actual_figure.get_node("Tile")
	var clicked_cell = ground.local_to_map(position)
	#print("player position: ", clicked_cell, " rotation: ", rotation_degrees)
	for coords_v2i in tile.get_used_cells():
		var atlas_coord = tile.get_cell_atlas_coords(coords_v2i)
		coords_v2i -= MINUS
		var v = Vector2(coords_v2i.x, coords_v2i.y)
		v = round(v.rotated(rotation))
		if rotation_degrees == 90.0:
			v.y += 1
		if rotation_degrees == -180.0:
			v.x -= 1
			v.y += 1
		if rotation_degrees == -90.0:
			v.x -= 1
		coords_v2i = Vector2i(v.x, v.y)
		coords_v2i += clicked_cell
		ground.set_cell(coords_v2i, 0, atlas_coord)

func _start_new_game() -> void:
	clear_ground()
	create_new_figure()

func clear_ground() -> void:
	for ix in range(roundi(LEFT_BORDER_X / tile_size) + 1, roundi(RIGHT_BORDER_X / tile_size) + 1):
		for iy in range(21):
			ground.set_cell(Vector2i(ix - 1, iy - 5))
