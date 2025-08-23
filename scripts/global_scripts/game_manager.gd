extends Node

# Singleton for managing multiplayer game state

# Game settings
const MAX_PLAYERS = 4
const TURN_TIME_LIMIT = 30
const CARDS_PER_PLAYER = 10

# Game state
var current_game_session = null
var connected_players = []
var current_turn_player = 1
var turn_time_remaining = TURN_TIME_LIMIT
var game_started = false

# Player data structure
var players_data = {
	# player_id: {
	#   "id": int,
	#   "name": String,
	#   "cards": Array[String],
	#   "is_host": bool,
	#   "is_local": bool
	# }
}

# Pile state (synchronized across all players)
var pile_cards = []
var pile_value = 0
var current_operation = "+"

# Networking
var multiplayer_peer: MultiplayerPeer
var is_host = false
var local_player_id = 1

# Signals for game events
signal game_started_signal
signal turn_changed(player_id: int)
signal player_made_move(player_id: int, move_type: String, card_id: String)
signal game_ended(winner_id: int, win_condition: String)
signal cards_distributed
signal pile_updated(new_value: int, new_operation: String)

func _ready():
	print("=== GAME MANAGER INITIALIZED ===")

# ===== GAME SESSION MANAGEMENT =====

func start_new_game_session(players: Array):
	print("=== STARTING NEW GAME SESSION ===")
	print("Players: ", players.size())
	
	# Initialize game state
	connected_players = players.duplicate()
	players_data.clear()
	current_turn_player = 1
	turn_time_remaining = TURN_TIME_LIMIT
	game_started = true
	
	# Setup players data
	for i in range(players.size()):
		var player = players[i]
		players_data[player["id"]] = {
			"id": player["id"],
			"name": player["name"],
			"cards": [],
			"is_host": player.get("is_host", false),
			"is_local": player["id"] == local_player_id
		}
	
	# Initialize pile with starting card
	initialize_game_pile()
	
	# Distribute initial cards
	distribute_initial_cards()
	
	print("Game session started with ", players.size(), " players")
	game_started_signal.emit()

func initialize_game_pile():
	print("=== INITIALIZING GAME PILE ===")
	
	if CardManager:
		# Reset CardManager deck for new game
		CardManager.reset_deck()
		
		# Draw starting card for pile
		var starting_card = CardManager.draw_starting_pile_card()
		if starting_card != "":
			pile_cards = [starting_card]
			
			# Set initial pile value and operation
			if CardManager.get_card_type(starting_card) == CardManager.CardType.NUMBER:
				pile_value = CardManager.get_card_value(starting_card)
				current_operation = "+"
			else:
				pile_value = 0
				current_operation = CardManager.get_card_value(starting_card)
			
			print("Pile initialized with: ", starting_card)
			print("Starting pile value: ", pile_value)
			print("Starting operation: ", current_operation)
			
			# Notify all clients about pile state
			if is_host:
				rpc("sync_pile_state", pile_cards, pile_value, current_operation)
		else:
			print("ERROR: Could not draw starting card for pile!")

@rpc("any_peer", "call_local")
func sync_pile_state(cards: Array, value: int, operation: String):
	pile_cards = cards
	pile_value = value
	current_operation = operation
	pile_updated.emit(pile_value, current_operation)
	print("Pile state synchronized: value=", pile_value, ", operation=", current_operation)

func distribute_initial_cards():
	print("=== DISTRIBUTING INITIAL CARDS ===")
	
	if not CardManager:
		print("ERROR: CardManager not available!")
		return
	
	if is_host:
		# Host distributes cards to all players
		for player_id in players_data.keys():
			var player_cards = CardManager.draw_cards(CARDS_PER_PLAYER)
			players_data[player_id]["cards"] = player_cards
			
			print("Distributed cards to Player ", player_id, ": ", player_cards.size(), " cards")
			
			# Send cards to client (if not local player)
			if player_id != local_player_id:
				rpc_id(player_id, "receive_initial_cards", player_cards)
		
		# Notify that cards are distributed
		cards_distributed.emit()
		rpc("on_cards_distributed")
	
	print("Initial cards distributed to all players")

@rpc("any_peer")
func receive_initial_cards(cards: Array[String]):
	print("=== RECEIVED INITIAL CARDS ===")
	print("Cards received: ", cards.size())
	players_data[local_player_id]["cards"] = cards
	cards_distributed.emit()

@rpc("any_peer", "call_local")
func on_cards_distributed():
	print("=== ALL PLAYERS RECEIVED CARDS ===")
	# Start first turn
	start_turn(current_turn_player)

# ===== TURN MANAGEMENT =====

func start_turn(player_id: int):
	print("=== STARTING TURN FOR PLAYER ", player_id, " ===")
	current_turn_player = player_id
	turn_time_remaining = TURN_TIME_LIMIT
	turn_changed.emit(player_id)
	
	# Start turn timer if this is the local player
	if player_id == local_player_id:
		print("Your turn started!")

func end_turn():
	print("=== ENDING TURN FOR PLAYER ", current_turn_player, " ===")
	
	# Move to next player
	current_turn_player = (current_turn_player % MAX_PLAYERS) + 1
	
	# Find next valid player (in case someone disconnected)
	while current_turn_player not in players_data.keys():
		current_turn_player = (current_turn_player % MAX_PLAYERS) + 1
	
	# Start next turn
	if is_host:
		rpc("start_turn", current_turn_player)

# ===== PLAYER MOVES =====

func make_move(move_type: String, card_id: String = ""):
	print("=== PLAYER MAKING MOVE ===")
	print("Player: ", local_player_id)
	print("Move type: ", move_type)
	print("Card: ", card_id)
	
	# Validate it's the player's turn
	if current_turn_player != local_player_id:
		print("ERROR: Not your turn!")
		return false
	
	# Process the move
	match move_type:
		"drop_card":
			return handle_card_drop(card_id)
		"draw_card":
			return handle_card_draw()
		"skip_turn":
			return handle_skip_turn()
		_:
			print("ERROR: Unknown move type: ", move_type)
			return false

func handle_card_drop(card_id: String) -> bool:
	print("=== HANDLING CARD DROP ===")
	print("Card: ", card_id)
	
	# Validate player has the card
	var player_cards = players_data[local_player_id]["cards"]
	if card_id not in player_cards:
		print("ERROR: Player doesn't have card: ", card_id)
		return false
	
	# Remove card from player's hand
	player_cards.erase(card_id)
	
	# Calculate new pile value
	var old_pile_value = pile_value
	var new_pile_value = calculate_pile_value_after_card(card_id)
	
	# Check win condition (card value equals pile total)
	if CardManager.get_card_type(card_id) == CardManager.CardType.NUMBER:
		var card_value = CardManager.get_card_value(card_id)
		if card_value == pile_value:
			print("=== WINNER! ===")
			print("Player ", local_player_id, " won by matching pile value!")
			
			# Notify all players of the win
			if is_host:
				rpc("declare_winner", local_player_id, "exact_match")
			
			return true
	
	# Update pile state
	pile_cards.append(card_id)
	pile_value = new_pile_value
	
	# Update operation if it's an operator card
	if CardManager.get_card_type(card_id) != CardManager.CardType.NUMBER:
		var new_operation = CardManager.get_card_value(card_id)
		if new_operation != "±":  # Plus/minus doesn't change operation
			current_operation = new_operation
	
	# Notify all players of the move
	if is_host:
		rpc("sync_player_move", local_player_id, "drop_card", card_id, pile_value, current_operation)
	
	# End turn
	end_turn()
	return true

func handle_card_draw() -> bool:
	print("=== HANDLING CARD DRAW ===")
	
	# Check if cards are available
	if CardManager and CardManager.get_deck_status()["available_cards"] > 0:
		var new_card = CardManager.draw_cards(1)
		if new_card.size() > 0:
			players_data[local_player_id]["cards"].append(new_card[0])
			print("Drew card: ", new_card[0])
			
			# Notify other players
			if is_host:
				rpc("sync_player_move", local_player_id, "draw_card", new_card[0], pile_value, current_operation)
			
			# End turn
			end_turn()
			return true
	else:
		print("No more cards available - converting to skip")
		return handle_skip_turn()
	
	return false

func handle_skip_turn() -> bool:
	print("=== HANDLING SKIP TURN ===")
	
	# Notify other players
	if is_host:
		rpc("sync_player_move", local_player_id, "skip_turn", "", pile_value, current_operation)
	
	# End turn
	end_turn()
	return true

@rpc("any_peer", "call_local")
func sync_player_move(player_id: int, move_type: String, card_id: String, new_pile_value: int, new_operation: String):
	print("=== SYNCING PLAYER MOVE ===")
	print("Player ", player_id, " made move: ", move_type)
	
	# Update pile state
	pile_value = new_pile_value
	current_operation = new_operation
	
	# Update pile cards if card was dropped
	if move_type == "drop_card" and card_id != "":
		pile_cards.append(card_id)
		
		# Remove card from player's hand
		if player_id in players_data:
			players_data[player_id]["cards"].erase(card_id)
	elif move_type == "draw_card" and card_id != "":
		# Add card to player's hand
		if player_id in players_data:
			players_data[player_id]["cards"].append(card_id)
	
	# Emit signals for UI updates
	player_made_move.emit(player_id, move_type, card_id)
	pile_updated.emit(pile_value, current_operation)

func calculate_pile_value_after_card(card_id: String) -> int:
	if not CardManager:
		return pile_value
	
	var card_type = CardManager.get_card_type(card_id)
	var card_value = CardManager.get_card_value(card_id)
	
	if card_type == CardManager.CardType.NUMBER:
		# Apply current operation to the number
		match current_operation:
			"+":
				return pile_value + card_value
			"-":
				return pile_value - card_value
			"*":
				return pile_value * card_value
			"/":
				return pile_value / card_value if card_value != 0 else pile_value
			_:
				return pile_value + card_value  # Default to addition
	elif card_value == "±":
		# Plus/minus flips the sign
		return -pile_value
	else:
		# Other operators don't change the pile value immediately
		return pile_value

# ===== WIN CONDITION CHECKS =====

@rpc("any_peer", "call_local")
func declare_winner(winner_id: int, win_condition: String):
	print("=== GAME ENDED ===")
	print("Winner: Player ", winner_id)
	print("Win condition: ", win_condition)
	
	game_ended.emit(winner_id, win_condition)

# ===== UTILITY FUNCTIONS =====

func get_local_player_cards() -> Array[String]:
	return players_data.get(local_player_id, {}).get("cards", [])

func get_current_turn_player() -> int:
	return current_turn_player

func is_local_player_turn() -> bool:
	return current_turn_player == local_player_id

func get_pile_value() -> int:
	return pile_value

func get_current_operation() -> String:
	return current_operation

func get_players_count() -> int:
	return players_data.size()

# ===== CLEANUP =====

func cleanup_game_session():
	print("=== CLEANING UP GAME SESSION ===")
	
	players_data.clear()
	pile_cards.clear()
	connected_players.clear()
	game_started = false
	current_turn_player = 1
	pile_value = 0
	current_operation = "+"
