extends Node

# Global card deck manager for multiplayer games

# Available cards (1-100)
var available_cards: Array[int] = []
var used_cards: Array[int] = []

# Card texture paths mapping
var card_texture_paths: Dictionary = {}

func _ready():
	initialize_deck()
	setup_card_texture_paths()

func initialize_deck():
	# Initialize deck with cards 1-100
	available_cards.clear()
	used_cards.clear()
	
	for i in range(1, 101):
		available_cards.append(i)
	
	# Shuffle the deck
	available_cards.shuffle()
	print("Card deck initialized with 100 cards")

func setup_card_texture_paths():
	# Map card numbers to their texture paths
	card_texture_paths.clear()
	
	# Cards 1-25
	for i in range(1, 26):
		card_texture_paths[i] = "res://assets/cards/card1-25/card" + str(i) + ".jpg"
	
	# Cards 26-50
	for i in range(26, 51):
		card_texture_paths[i] = "res://assets/cards/card26-50/card" + str(i) + ".jpg"
	
	# Cards 51-75
	for i in range(51, 76):
		card_texture_paths[i] = "res://assets/cards/card51-75/card" + str(i) + ".jpg"
	
	# Cards 76-100
	for i in range(76, 101):
		card_texture_paths[i] = "res://assets/cards/card76-100/card" + str(i) + ".jpg"
	
	print("Card texture paths mapped for 100 cards")

func draw_cards(count: int) -> Array[int]:
	# Draw specified number of cards from the deck
	var drawn_cards: Array[int] = []
	
	if count > available_cards.size():
		print("Warning: Trying to draw ", count, " cards but only ", available_cards.size(), " available")
		count = available_cards.size()
	
	for i in range(count):
		if available_cards.size() > 0:
			var card_number = available_cards.pop_front()
			drawn_cards.append(card_number)
			used_cards.append(card_number)
	
	print("Drew ", drawn_cards.size(), " cards: ", drawn_cards)
	print("Remaining cards in deck: ", available_cards.size())
	
	return drawn_cards

func get_card_texture_path(card_number: int) -> String:
	if card_number in card_texture_paths:
		return card_texture_paths[card_number]
	else:
		print("Warning: No texture path found for card ", card_number)
		return ""

func return_card_to_deck(card_number: int):
	# Return a card back to the available deck (for testing/debugging)
	if card_number in used_cards:
		used_cards.erase(card_number)
		available_cards.append(card_number)
		available_cards.shuffle()
		print("Returned card ", card_number, " to deck")

func get_deck_status() -> Dictionary:
	return {
		"available_cards": available_cards.size(),
		"used_cards": used_cards.size(),
		"total_cards": available_cards.size() + used_cards.size()
	}

func reset_deck():
	# Reset the entire deck (useful for new games)
	initialize_deck()
	print("Deck reset to full 100 cards")
