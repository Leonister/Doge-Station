/area/dynamic // Do not use.
	name = "Area dinamica"
	icon_state = "purple"
	var/match_tag = "none"
	var/match_width = -1
	var/match_height = -1
	var/enable_lights = 0

/area/dynamic/destination // Do not use.
	name = "destino da area dinamica"

/area/dynamic/destination/lobby
	name = "Lobby de Chegada"
	match_tag = "arrivals"
	match_width = 5
	match_height = 4
	enable_lights = 1

/area/dynamic/source // Do not use.
	name = "dynamic area source"

/area/dynamic/source/lobby_bar
	name = "\improper Bar"
	match_tag = "arrivals"
	match_width = 5
	match_height = 4
	requires_power = 0

/area/dynamic/source/lobby_russian
	name = "\improper Russian Lounge"
	match_tag = "arrivals"
	match_width = 5
	match_height = 4
	requires_power = 0

/area/dynamic/source/lobby_disco
	name = "\improper Disco Lounge"
	match_tag = "arrivals"
	match_width = 5
	match_height = 4
	requires_power = 0