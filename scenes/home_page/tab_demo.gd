extends Control

func _ready():
	# Find the bottom tabs and connect to its signal
	var bottom_tabs = $BottomTabs
	if bottom_tabs:
		bottom_tabs.tab_changed.connect(_on_tab_changed)
		print("Tab demo ready - listening for tab changes")

func _on_tab_changed(tab_index: int, tab_name: String):
	print("Demo received tab change: ", tab_name, " (index: ", tab_index, ")")
	
	# Here you would typically switch between different page content
	# For example:
	# - Hide all page containers
	# - Show the selected page container
	# - Update navigation state
	# - Load page-specific data
	
	match tab_index:
		0: # Shop
			print("Loading Shop page...")
		1: # Cards
			print("Loading Cards page...")
		2: # Battle (default)
			print("Loading Battle page...")
		3: # Club
			print("Loading Club page...")
		4: # Leaderboard
			print("Loading Leaderboard page...")
