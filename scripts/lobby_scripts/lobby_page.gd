extends Control

# Lobby settings
const LOBBY_TIMER_DURATION = 20
const MAX_PLAYERS = 4

# UI References
@onready var timer_label = $CenterContainer/VBoxContainer/TimerContainer/TimerLabel
@onready var players_count_label = $CenterContainer/VBoxContainer/PlayersContainer/PlayersCountLabel
@onready var player_labels = [
	$CenterContainer/VBoxContainer/PlayersList/Player1,
	$CenterContainer/VBoxContainer/PlayersList/Player2,
	$CenterContainer/VBoxContainer/PlayersList/Player3,
	$CenterContainer/VBoxContainer/PlayersList/Player4
]
@onready var leave_button = $CenterContainer/VBoxContainer/ButtonsContainer/LeaveButton
@onready var start_button = $CenterContainer/VBoxContainer/ButtonsContainer/StartButton
@onready var add_player_button = $CenterContainer/VBoxContainer/DebugContainer/AddPlayerButton
@onready var debug_container = $CenterContainer/VBoxContainer/DebugContainer
@onready var timer = $Timer

# Game state
var lobby_time_remaining = LOBBY_TIMER_DURATION
var connected_players = []
var is_host = false
var player_id = 1

# Multiplayer
var multiplayer_api: MultiplayerAPI
var peer: MultiplayerPeer

func _ready():
	print("=== LOBBY PAGE INITIALIZED ===")
	
	# Connect UI signals
	leave_button.pressed.connect(_on_leave_button_pressed)
	start_button.pressed.connect(_on_start_button_pressed)
	if add_player_button:
		add_player_button.pressed.connect(_on_add_player_button_pressed)
	timer.timeout.connect(_on_timer_timeout)
	
	# Show/hide debug controls based on debug build
	if debug_container:
		debug_container.visible = OS.is_debug_build()
	
	# Initialize as host for now (later we'll add join functionality)
	initialize_as_host()
	
	# Start lobby timer
	start_lobby_timer()
	
	print("Lobby ready, waiting for players...")

func initialize_as_host():
	print("=== INITIALIZING AS HOST ===")
	
	# Create multiplayer peer
	peer = ENetMultiplayerPeer.new()
	var port = 8910  # Default port
	var max_clients = MAX_PLAYERS - 1  # Host + 3 clients = 4 total
	
	var error = peer.create_server(port, max_clients)
	if error != OK:
		print("ERROR: Failed to create server: ", error)
		return
	
	# Set up multiplayer API
	multiplayer_api = MultiplayerAPI.create_default_interface()
	get_tree().set_multiplayer(multiplayer_api, self.get_path())
	multiplayer_api.multiplayer_peer = peer
	
	# Connect multiplayer signals
	multiplayer_api.peer_connected.connect(_on_peer_connected)
	multiplayer_api.peer_disconnected.connect(_on_peer_disconnected)
	
	# Add host as first player
	is_host = true
	player_id = 1
	connected_players.append({
		"id": 1,
		"name": "You (Host)",
		"is_host": true
	})
	
	update_players_display()
	print("Host initialized on port ", port)

func _on_peer_connected(id: int):
	print("=== PEER CONNECTED ===")
	print("Player ID: ", id)
	
	# Assign player number (2, 3, or 4)
	var player_number = connected_players.size() + 1
	if player_number <= MAX_PLAYERS:
		connected_players.append({
			"id": id,
			"name": "Player " + str(player_number),
			"is_host": false
		})
		
		print("Added player ", player_number, " (ID: ", id, ")")
		update_players_display()
		
		# Check if we have enough players to start
		if connected_players.size() >= MAX_PLAYERS:
			print("LOBBY FULL! Starting game...")
			start_game()
	else:
		print("ERROR: Lobby is full, disconnecting player ", id)
		peer.disconnect_peer(id)

func _on_peer_disconnected(id: int):
	print("=== PEER DISCONNECTED ===")
	print("Player ID: ", id)
	
	# Remove player from list
	for i in range(connected_players.size()):
		if connected_players[i]["id"] == id:
			connected_players.remove_at(i)
			break
	
	update_players_display()
	print("Player disconnected, remaining players: ", connected_players.size())

func start_lobby_timer():
	print("=== STARTING LOBBY TIMER ===")
	timer.start()
	update_timer_display()

func _on_timer_timeout():
	lobby_time_remaining -= 1
	update_timer_display()
	
	if lobby_time_remaining <= 0:
		print("=== LOBBY TIMER EXPIRED ===")
		
		# Check if we have at least 2 players to start (for testing)
		if connected_players.size() >= 2:
			print("Starting game with ", connected_players.size(), " players")
			start_game()
		else:
			print("Not enough players, returning to home")
			return_to_home()

func update_timer_display():
	if timer_label:
		timer_label.text = str(lobby_time_remaining)
		
		# Change color based on time remaining
		if lobby_time_remaining <= 5:
			timer_label.modulate = Color.RED
		elif lobby_time_remaining <= 10:
			timer_label.modulate = Color.ORANGE
		else:
			timer_label.modulate = Color(1, 0.8, 0.2)  # Yellow

func update_players_display():
	if players_count_label:
		players_count_label.text = str(connected_players.size()) + "/" + str(MAX_PLAYERS)
	
	# Update individual player labels
	for i in range(player_labels.size()):
		if i < connected_players.size():
			var player_data = connected_players[i]
			player_labels[i].text = "Player " + str(i + 1) + ": " + player_data["name"]
			player_labels[i].modulate = Color.WHITE
		else:
			player_labels[i].text = "Player " + str(i + 1) + ": Waiting..."
			player_labels[i].modulate = Color(0.6, 0.6, 0.6)
	
	# Enable start button for debugging if host and have at least 2 players
	if start_button and is_host:
		start_button.disabled = connected_players.size() < 2
		# In debug mode, always enable start button for testing
		if OS.is_debug_build():
			start_button.disabled = false
			start_button.text = "Start Game (Debug: " + str(connected_players.size()) + " players)"

func start_game():
	print("=== STARTING GAME ===")
	timer.stop()
	
	# Prepare game data
	var game_data = {
		"players": connected_players,
		"starting_player": 1
	}
	
	# Send to all clients (if any)
	if is_host and connected_players.size() > 1:
		rpc("receive_game_start", game_data)
	
	# Navigate to game area
	navigate_to_game_area(game_data)

@rpc("any_peer", "call_local")
func receive_game_start(game_data: Dictionary):
	print("=== RECEIVED GAME START ===")
	print("Game data: ", game_data)
	navigate_to_game_area(game_data)

func navigate_to_game_area(game_data: Dictionary):
	print("=== NAVIGATING TO GAME AREA ===")
	print("Players: ", game_data["players"].size())
	
	# Store game data in GameManager
	if GameManager:
		GameManager.local_player_id = player_id
		GameManager.is_host = is_host
		GameManager.multiplayer_peer = peer
		GameManager.start_new_game_session(game_data["players"])
	
	# Switch to game area scene
	get_tree().change_scene_to_file("res://scenes/game_area_page/game_area_page.tscn")

func _on_leave_button_pressed():
	print("=== LEAVING LOBBY ===")
	return_to_home()

func _on_start_button_pressed():
	print("=== FORCE START BUTTON PRESSED ===")
	if is_host:
		# In debug mode, allow starting with fewer players by adding AI/dummy players
		if OS.is_debug_build() and connected_players.size() < MAX_PLAYERS:
			add_debug_players()
		
		if connected_players.size() >= 2:
			start_game()

func add_debug_players():
	print("=== ADDING DEBUG PLAYERS ===")
	
	# Add dummy players to fill the lobby for testing
	var players_needed = MAX_PLAYERS - connected_players.size()
	
	for i in range(players_needed):
		var dummy_player_number = connected_players.size() + 1
		connected_players.append({
			"id": dummy_player_number,
			"name": "AI Player " + str(dummy_player_number),
			"is_host": false,
			"is_dummy": true  # Flag to identify debug players
		})
		print("Added debug player: Player ", dummy_player_number)
	
	update_players_display()
	print("Debug players added. Total players: ", connected_players.size())

func _on_add_player_button_pressed():
	print("=== ADD DEBUG PLAYER BUTTON PRESSED ===")
	if connected_players.size() < MAX_PLAYERS:
		var new_player_number = connected_players.size() + 1
		connected_players.append({
			"id": new_player_number,
			"name": "Debug Player " + str(new_player_number),
			"is_host": false,
			"is_dummy": true
		})
		update_players_display()
		print("Added single debug player. Total: ", connected_players.size())
	else:
		print("Lobby is already full!")

func return_to_home():
	print("=== RETURNING TO HOME ===")
	
	# Clean up multiplayer
	if peer:
		peer.close()
	
	# Navigate back to home
	get_tree().change_scene_to_file("res://scenes/home_page/home_page.tscn")

func _exit_tree():
	# Clean up when leaving the scene
	if peer:
		peer.close()
	print("Lobby cleaned up")
