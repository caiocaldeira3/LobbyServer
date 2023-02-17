extends Resource


export (float) var score_degree
export (int) var guessing_players
export (int) var scoring_players
export (int) var hinter_idx
var guesses_degrees: Dictionary

func _init (curr_players: int):
	Server.rng.randomize()

	hinter_idx = Server.rng.randi() % curr_players
	guessing_players = curr_players - 1
	scoring_players = curr_players - 1
	guesses_degrees = {}
	score_degree = null

func decrement_scoring_players ():
	scoring_players -= 1

func set_score_degree (_score_degree: float):
	score_degree = _score_degree

func set_guess_degree (pid: int, guess_degree: float):
	guessing_players -= 1
	guesses_degrees[pid] = guess_degree

func get_guesses ():
	return guesses_degrees
