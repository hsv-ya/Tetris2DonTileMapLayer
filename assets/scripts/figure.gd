extends CharacterBody2D

const SPEED = 1000.0
const GRAVITY = 10000

var is_new_figure = true
var complete = true
var is_rapid = false

const START_POSITION = Vector2i(560, 0)

@onready var cube = $Cube
@onready var line = $Line
@onready var hook = $Hook

var figures = []
var actual_figure = null

func _ready() -> void:
	figures.append(cube)
	figures.append(line)
	figures.append(hook)

	create_new_figure()

func _physics_process(delta: float) -> void:
	if complete:
		return

	if Input.is_action_pressed("quick_down"):
		velocity.y += GRAVITY * delta * 5

	if not is_on_floor() and is_new_figure:
		is_new_figure = false
		velocity.y += GRAVITY * delta

	if is_on_floor():
		print("Need create new figure")
		create_new_figure()

	if Input.is_action_pressed("ui_down"):
		if !is_rapid and !complete:
			is_rapid = true
			velocity.y += GRAVITY * delta * 2

	if Input.is_action_just_released("ui_down"):
		if is_rapid and !complete:
			is_rapid = false
			velocity.y -= GRAVITY * delta * 2

	if Input.is_action_just_pressed("ui_up"):
		rotation_degrees += 90

	var direction := Input.get_axis("ui_left", "ui_right")
	if direction:
		position.x += delta * SPEED * direction

	move_and_slide()

func create_new_figure() -> void:
	position = START_POSITION
	if actual_figure:
		actual_figure.disabled = true
		actual_figure.visible = false
	actual_figure = figures[randi() % figures.size()]
	actual_figure.disabled = false
	actual_figure.visible = true
	is_new_figure = true
	is_rapid = false
	velocity.y = 0
	complete = false
