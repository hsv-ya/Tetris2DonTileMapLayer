extends Node2D

signal start_new_game

var is_game_over = false
var score = 0

@onready var label_game_over = $LabelGameOver
@onready var label_paused = $LabelPaused
@onready var label_score = $LabelScore

func _ready() -> void:
	label_game_over.visible = false
	get_tree().paused = true
	label_paused.visible = get_tree().paused

	connect("start_new_game", Callable($Figure, "_start_new_game"))

func _input(event: InputEvent) -> void:
	if event.is_action_pressed("quit"):
		get_tree().quit()

func _process(_delta: float) -> void:
	if Input.is_action_just_pressed("paused"):
		get_tree().paused = !get_tree().paused
		label_paused.visible = get_tree().paused

	if is_game_over:
		if Input.is_action_just_pressed("new_game"):
			_start_new_game()

func _start_new_game() -> void:
	score = 0
	label_game_over.visible = false
	emit_signal("start_new_game")
	get_tree().paused = false
	is_game_over = false

func _on_end_the_game() -> void:
	label_game_over.visible = true
	get_tree().paused = true
	is_game_over = true

func _on_add_score() -> void:
	score += 1
	label_score.text = str(score)
