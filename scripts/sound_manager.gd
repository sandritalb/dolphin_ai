extends Node
class_name SoundManager

## A utility class for playing sounds with random pitch variation.
## Usage:
##   SoundManager.play_sound(audio_stream, min_pitch, max_pitch)
##   or
##   var player = SoundManager.create_sound_player(audio_stream, min_pitch, max_pitch)
##   player.play()

## Plays a sound with a random pitch within the specified range.
## @param stream: The AudioStream to play
## @param pitch_min: Minimum pitch scale (default 0.9)
## @param pitch_max: Maximum pitch scale (default 1.1)
## @param volume_db: Volume in decibels (default 0.0)
## @param bus: Audio bus name (default "Sounds")
## @return: The AudioStreamPlayer used to play the sound
static func play_sound(stream: AudioStream, pitch_min: float = 0.9, pitch_max: float = 1.1, volume_db: float = 0.0, bus: String = "Sounds") -> AudioStreamPlayer:
	if stream == null:
		push_error("SoundManager: Cannot play null audio stream")
		return null
	
	var player = AudioStreamPlayer.new()
	player.stream = stream
	player.volume_db = volume_db
	player.bus = bus
	player.pitch_scale = randf_range(pitch_min, pitch_max)
	player.process_mode = Node.PROCESS_MODE_ALWAYS
	
	# Add to scene tree, play, and auto-remove when finished
	var tree = Engine.get_main_loop() as SceneTree
	if tree and tree.current_scene:
		tree.current_scene.add_child(player)
		player.finished.connect(player.queue_free)
		player.play()
	else:
		push_error("SoundManager: No scene tree available to play sound")
		player.queue_free()
		return null
	
	return player


## Plays a 2D positional sound with a random pitch within the specified range.
## @param stream: The AudioStream to play
## @param position: World position for the sound
## @param pitch_min: Minimum pitch scale (default 0.9)
## @param pitch_max: Maximum pitch scale (default 1.1)
## @param volume_db: Volume in decibels (default 0.0)
## @param bus: Audio bus name (default "Sounds")
## @return: The AudioStreamPlayer2D used to play the sound
static func play_sound_2d(stream: AudioStream, position: Vector2, pitch_min: float = 0.9, pitch_max: float = 1.1, volume_db: float = 0.0, bus: String = "Sounds") -> AudioStreamPlayer2D:
	if stream == null:
		push_error("SoundManager: Cannot play null audio stream")
		return null
	
	var player = AudioStreamPlayer2D.new()
	player.stream = stream
	player.volume_db = volume_db
	player.bus = bus
	player.pitch_scale = randf_range(pitch_min, pitch_max)
	player.global_position = position
	player.process_mode = Node.PROCESS_MODE_ALWAYS
	
	# Add to scene tree, play, and auto-remove when finished
	var tree = Engine.get_main_loop() as SceneTree
	if tree and tree.current_scene:
		tree.current_scene.add_child(player)
		player.finished.connect(player.queue_free)
		player.play()
	else:
		push_error("SoundManager: No scene tree available to play sound")
		player.queue_free()
		return null
	
	return player


## Creates an AudioStreamPlayer with random pitch (does not auto-play or auto-free).
## Useful when you need more control over the player.
## @param stream: The AudioStream to use
## @param pitch_min: Minimum pitch scale (default 0.9)
## @param pitch_max: Maximum pitch scale (default 1.1)
## @param volume_db: Volume in decibels (default 0.0)
## @param bus: Audio bus name (default "Sounds")
## @return: The configured AudioStreamPlayer (caller must add to scene and manage lifecycle)
static func create_sound_player(stream: AudioStream, pitch_min: float = 0.9, pitch_max: float = 1.1, volume_db: float = 0.0, bus: String = "Sounds") -> AudioStreamPlayer:
	var player = AudioStreamPlayer.new()
	player.stream = stream
	player.volume_db = volume_db
	player.bus = bus
	player.pitch_scale = randf_range(pitch_min, pitch_max)
	player.process_mode = Node.PROCESS_MODE_ALWAYS
	return player


## Randomizes the pitch of an existing AudioStreamPlayer and plays it.
## @param player: The AudioStreamPlayer to use
## @param pitch_min: Minimum pitch scale (default 0.9)
## @param pitch_max: Maximum pitch scale (default 1.1)
static func play_with_random_pitch(player: AudioStreamPlayer, pitch_min: float = 0.9, pitch_max: float = 1.1) -> void:
	if player == null:
		push_error("SoundManager: Cannot play null AudioStreamPlayer")
		return
	
	player.pitch_scale = randf_range(pitch_min, pitch_max)
	player.play()


## Randomizes the pitch of an existing AudioStreamPlayer2D and plays it.
## @param player: The AudioStreamPlayer2D to use
## @param pitch_min: Minimum pitch scale (default 0.9)
## @param pitch_max: Maximum pitch scale (default 1.1)
static func play_2d_with_random_pitch(player: AudioStreamPlayer2D, pitch_min: float = 0.9, pitch_max: float = 1.1) -> void:
	if player == null:
		push_error("SoundManager: Cannot play null AudioStreamPlayer2D")
		return
	
	player.pitch_scale = randf_range(pitch_min, pitch_max)
	player.play()
