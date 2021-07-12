extends Node2D

var Ball = preload("res://Ball.tscn");
var Block = preload("res://Block.tscn");
var Arrow = preload("res://Arrow.tscn");
var Trace = preload("res://Trace.tscn");


var stage;


var gameScene = null;


var state;

var level;
var ball;

var ballTexture;
var blockTexture;
var testTexture;
var aimTexture;

enum Directions{None = 0, Up = 1, Right = 2, Down = 3, Left = 4};
var SIZE = 30;
var BLOCK = 20;

var SAVE_PATH = "user://save.cfg"

var wins = 0;
var losses = 0;

var turns = 0.5;
var pathLength = 0.5;
var blocks = 0.5;
var currentLevel: = 1;
var fails: = 0;

var showTrace = false;
var trace = [];

var currentX;
var currentY;
var startX;
var startY;
var aimX;
var aimY;
var aimDirection;
var lastDirection;

var pressed_position = Vector2.ZERO
var pressed: = false

onready var menu = $CanvasLayer/Menu
onready var about = $CanvasLayer/PanelAbout

func getBlock(x:int, y:int):
	if (inBounds(x, y)):
		return level[x][y];
	else :
		return - 1;


func oppositeDirection(direction:int):
	match (direction):
		Directions.Up:
			return Directions.Down;
		Directions.Down:
			return Directions.Up;
		Directions.Left:
			return Directions.Right;
		Directions.Right:
			return Directions.Left;
	return Directions.None;


func isGoodDirection(direction:int):
	match (direction):
		Directions.Up:
			if (getBlock(currentX, currentY - 1) == 0 and (getBlock(currentX, currentY - 2) == 0)):
				return true;
		Directions.Down:
			if ((getBlock(currentX, currentY + 1) == 0) and (getBlock(currentX, currentY + 2) == 0)):
				return true;
		Directions.Left:
			if ((getBlock(currentX - 1, currentY) == 0) and (getBlock(currentX - 2, currentY) == 0)):
				return true;
		Directions.Right:
			if ((getBlock(currentX + 1, currentY) == 0) and (getBlock(currentX + 2, currentY) == 0)):
				return true;
	return false;

func blockDirection(direction:int):
	match (direction):
		Directions.Up:
			level[currentX][currentY - 1] = 1;
		Directions.Down:
			level[currentX][currentY + 1] = 1;
		Directions.Left:
			level[currentX - 1][currentY] = 1;
		Directions.Right:
			level[currentX + 1][currentY] = 1;
	

func randomDirection()->int:
	return int(floor(randf() * 4) + 1);


func fillDirection(direction:int):
	var shouldStop = true;
	level[currentX][currentY] = 2;
	if (isGoodDirection(direction)):
		match (direction):
			Directions.Up:
				currentY -= 1;
			Directions.Down:
				currentY += 1;
			Directions.Left:
				currentX -= 1;
			Directions.Right:
				currentX += 1;
		
		lastDirection = direction;
		shouldStop = false;
	
	if ( not shouldStop):
		if (randf() < pathLength):
			fillDirection(direction);

func _ready():
	var config = ConfigFile.new()
	var err = config.load(SAVE_PATH)
	if err == OK:
		currentLevel = config.get_value("game", "level", 1)
		turns = config.get_value("game", "turns", 0.5)
		blocks = config.get_value("game", "blocks", 0.5)
		fails = config.get_value("game", "fails", 0)
	updateUI()
	resetLevel();

func saveProgress():
	var config = ConfigFile.new()
	config.set_value("game", "level", currentLevel)
	config.set_value("game", "turns", turns)
	config.set_value("game", "blocks", blocks)
	config.set_value("game", "fails", fails)
	config.save(SAVE_PATH)

func updateUI():
	$CanvasLayer/LabelLevel.text = "Level: %d" % currentLevel
	$CanvasLayer/LabelIQ.text = "IQ: %d" % max(0, currentLevel * 5 - fails)

func inBounds(x:int, y:int):
	if (x >= 0 and x < SIZE and y >= 0 and y < SIZE):
		return true;
	return false;

func resetLevel():
	updateUI()
	seed(currentLevel)
	trace = [];
	if gameScene != null:
		remove_child(gameScene);
	gameScene = Node2D.new();
	add_child(gameScene);
	gameScene.position.x = BLOCK / 2;
	gameScene.position.y = BLOCK / 2;

	ball = Ball.instance();
	ball.ballDirection = Directions.None;

	level = [];
	level.resize(SIZE);
	for i in range(SIZE):
		level[i] = [];
		level[i].resize(SIZE);
		for j in range(SIZE):
			level[i][j] = 0;
		
	
	currentX = floor(randf() * (SIZE - 3)) + 2;
	currentY = floor(randf() * (SIZE - 3)) + 2;

	ball.levelX = currentX;
	ball.levelY = currentY;
	startX = currentX;
	startY = currentY;

	var d;
	while (true):
		d = randomDirection();
		if (isGoodDirection(d)):
			pathLength = 0.5 + 0.5 * randf();
			fillDirection(d);
			blockDirection(d);
		
		if (randf() > turns):
			break;
	
	aimX = currentX;
	aimY = currentY;
	aimDirection = lastDirection;
	level[aimX][aimY] = 3;

	while (true):
		var bx = floor(randf() * SIZE);
		var by = floor(randf() * SIZE);
		if (level[bx][by] == 0):
			level[bx][by] = 1;
		if (randf() > blocks):
			break;
	

	for i in range(level.size()):
		for j in range(level[i].size()):
			if (level[i][j] == 1):
				var s = Block.instance();
				gameScene.add_child(s);
				s.position.x = i * BLOCK;
				s.position.y = j * BLOCK;
			elif (level[i][j] == 2):
				var s = Trace.instance();
				gameScene.add_child(s);
				s.position.x = i * BLOCK;
				s.position.y = j * BLOCK;
				s.visible = showTrace;
				trace.push_back(s);
			elif (level[i][j] == 3):
				var s = Arrow.instance();
				
				
				s.rotation = PI / 2 * (aimDirection - 1);
				gameScene.add_child(s);
				s.position.x = i * BLOCK;
				s.position.y = j * BLOCK;
			
		

	gameScene.add_child(ball);

func _unhandled_input(event):
	if event is InputEventMouseButton or event is InputEventScreenTouch:
		if menu.visible or about.visible:
			return
		if event.is_pressed():
			pressed_position = event.position
			pressed = true
		elif pressed:
			pressed = false
			var sv = event.position - pressed_position
			if sv.length() > 20:
				var m = 0
				var e = "up"
				if sv.dot(Vector2.UP) > m:
					m = sv.dot(Vector2.UP)
					e = "up"
				if sv.dot(Vector2.DOWN) > m:
					m = sv.dot(Vector2.DOWN)
					e = "down"
				if sv.dot(Vector2.LEFT) > m:
					m = sv.dot(Vector2.LEFT)
					e = "left"
				if sv.dot(Vector2.RIGHT) > m:
					m = sv.dot(Vector2.RIGHT)
					e = "right"
				var ev = InputEventAction.new()
				ev.action = e
				ev.pressed = true
				Input.parse_input_event(ev)

func release_event(e):
	var ev = InputEventAction.new()
	ev.action = e
	ev.pressed = false
	Input.parse_input_event(ev)

func reset():
	pressed = false
	fails += 1
	ball.ballDirection = Directions.None;
	ball.levelX = startX;
	ball.levelY = startY;
	saveProgress()
	updateUI();

func _physics_process(_delta):
	if menu.visible or about.visible:
		return
	if (Input.is_action_just_pressed("trace")):
		showTrace = not showTrace;
		for i in range(trace.size()):
			trace[i].visible = showTrace;
	
	if (Input.is_action_just_pressed("reset")):
		reset()
	
	if (Input.is_action_just_pressed("new")):
		ball.visible = false;
		ball.ballDirection = Directions.None;
		resetLevel();
	
	if (inBounds(ball.levelX, ball.levelY)):
		if (ball.ballDirection == Directions.None):
			if (Input.is_action_pressed("up")):
				ball.ballDirection = Directions.Up;
				release_event("up")
			elif (Input.is_action_pressed("down")):
				ball.ballDirection = Directions.Down
				release_event("down")
			elif (Input.is_action_pressed("left")):
				ball.ballDirection = Directions.Left
				release_event("left")
			elif (Input.is_action_pressed("right")):
				ball.ballDirection = Directions.Right
				release_event("right")
		elif (ball.ballDirection == Directions.Up):
			if (ball.levelY > 0):
				if (level[ball.levelX][ball.levelY - 1] != 1):
					ball.levelY -= 1;
				else :
					ball.ballDirection = Directions.None;
			else :
				ball.levelY -= 1;
			

		elif (ball.ballDirection == Directions.Down):
			if (ball.levelY < (SIZE - 1)):
				if (level[ball.levelX][ball.levelY + 1] != 1):
					ball.levelY += 1;
				else :
					ball.ballDirection = Directions.None;
			else :
				ball.levelY += 1;
			
		elif (ball.ballDirection == Directions.Left):
			if (ball.levelX > 0):
				if (level[ball.levelX - 1][ball.levelY] != 1):
					ball.levelX -= 1;
				else :
					ball.ballDirection = Directions.None;
			else :
				ball.levelX -= 1;
			
		elif (ball.ballDirection == Directions.Right):
			if (ball.levelX < (SIZE - 1)):
				if (level[ball.levelX + 1][ball.levelY] != 1):
					ball.levelX += 1;
				else :
					ball.ballDirection = Directions.None;
			else :
				ball.levelX += 1;
			
		
		ball.position.x = ball.levelX * BLOCK;
		ball.position.y = ball.levelY * BLOCK;
		if ((ball.levelX == aimX) and (ball.levelY == aimY) and (ball.ballDirection == aimDirection)):
			ball.ballDirection = Directions.None;
			
			if (turns < 0.999):
				turns = turns + (1 - turns) / 3;
			
			
			if (blocks < 0.995):
				blocks = blocks + (1 - blocks) / 3;
			currentLevel += 1
			saveProgress()
			resetLevel();
		
	else :
		reset()



func _on_Reset_pressed() -> void:
	if menu.visible or about.visible:
		return
	reset()


func _on_LabelAbout_meta_clicked(meta) -> void:
	OS.shell_open(meta)


func _on_Back_pressed() -> void:
	about.hide()
	menu.show()


func _on_Resume_pressed() -> void:
	about.hide()
	menu.hide()


func _on_About_pressed() -> void:
	about.show()
	menu.hide()


func _on_Exit_pressed() -> void:
	get_tree().quit()


func _on_ShowMenu_pressed() -> void:
	about.hide()
	menu.show()
