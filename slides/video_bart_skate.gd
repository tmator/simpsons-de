extends MPFSlide

var LANES: PackedFloat32Array = PackedFloat32Array([300.0, 960.0, 1620.0])
const PLAYER_Y: float = 700.0
const JUMP_HEIGHT: float = 220.0
const JUMP_DUR: float = 0.65
const OBS_SPEED: float = 340.0
const SPAWN_DELAY: float = 2.5
const MAX_HITS: int = 3

var _lane: int = 1
var _jump_t: float = -1.0
var _is_jumping: bool = false
var _spawn_t: float = 1.5
var _obstacles: Array[Label] = []   # typé -> [i] retourne Label
var _hits: int = 0
var _player: Label
var _hit_label: Label
var _running: bool = false

func _ready() -> void:
	_player = Label.new()
	_player.text = "BART"
	_player.add_theme_font_size_override("font_size", 42)
	_player.add_theme_color_override("font_color", Color.YELLOW)
	_player.position = Vector2(LANES[_lane] - 30.0, PLAYER_Y)
	add_child(_player)

	_hit_label = Label.new()
	_hit_label.text = "Vies: 3"
	_hit_label.add_theme_font_size_override("font_size", 48)
	_hit_label.add_theme_color_override("font_color", Color.WHITE)
	_hit_label.position = Vector2(40.0, 620.0)
	add_child(_hit_label)

	MPF.server.add_event_handler("video_mode_left", _on_left)
	MPF.server.add_event_handler("video_mode_right", _on_right)
	MPF.server.add_event_handler("video_mode_action", _on_jump)
	_running = true

func _exit_tree() -> void:
	_running = false
	MPF.server.remove_event_handler("video_mode_left", _on_left)
	MPF.server.remove_event_handler("video_mode_right", _on_right)
	MPF.server.remove_event_handler("video_mode_action", _on_jump)

func _on_left(_p: Dictionary = {}) -> void:
	_lane = max(0, _lane - 1)
	if is_instance_valid(_player):
		_player.position.x = LANES[_lane] - 30.0

func _on_right(_p: Dictionary = {}) -> void:
	_lane = min(2, _lane + 1)
	if is_instance_valid(_player):
		_player.position.x = LANES[_lane] - 30.0

func _on_jump(_p: Dictionary = {}) -> void:
	if not _is_jumping:
		_is_jumping = true
		_jump_t = 0.0
		MPF.server.send_event("video_bart_skate_jump")

func _process(delta: float) -> void:
	if not _running:
		return

	# Arc de saut
	if _is_jumping:
		_jump_t += delta
		var progress: float = _jump_t / JUMP_DUR
		if progress >= 1.0:
			_is_jumping = false
			_jump_t = -1.0
			if is_instance_valid(_player):
				_player.position.y = PLAYER_Y
		else:
			var h: float = JUMP_HEIGHT * 4.0 * progress * (1.0 - progress)
			if is_instance_valid(_player):
				_player.position.y = PLAYER_Y - h

	# Spawn
	_spawn_t += delta
	if _spawn_t >= SPAWN_DELAY:
		_spawn_t = 0.0
		_spawn_obstacle()

	# Position Y du joueur (peut être en l'air)
	var player_y_now: float = _player.position.y if is_instance_valid(_player) else PLAYER_Y

	# Déplacement et collision (itération inverse)
	var i: int = _obstacles.size() - 1
	while i >= 0:
		var obs: Label = _obstacles[i]
		if not is_instance_valid(obs):
			_obstacles.remove_at(i)
			i -= 1
			continue
		obs.position.y += OBS_SPEED * delta
		var dx: float = absf(obs.position.x - LANES[_lane])
		var dy: float = absf(obs.position.y - player_y_now)
		if dx < 65.0 and dy < 75.0:
			_obstacles.remove_at(i)
			obs.queue_free()
			_hits += 1
			if is_instance_valid(_hit_label):
				_hit_label.text = "Vies: %d" % max(0, MAX_HITS - _hits)
			MPF.server.send_event("video_bart_skate_hit")
		elif obs.position.y > 1150.0:
			_obstacles.remove_at(i)
			obs.queue_free()
		i -= 1

func _spawn_obstacle() -> void:
	var lane: int = randi() % 3
	var obs: Label = Label.new()
	obs.text = "###"
	obs.add_theme_font_size_override("font_size", 52)
	obs.add_theme_color_override("font_color", Color.RED)
	obs.position = Vector2(LANES[lane] - 35.0, -50.0)
	add_child(obs)
	_obstacles.append(obs)
