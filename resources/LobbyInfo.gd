extends Resource


const PlayerInfo = preload("res://resources/PlayerInfo.gd")
const RoundInfo = preload("res://resources/RoundInfo.gd")

enum LOBBY_STATUS { WAITING, HINTING, GUESSING, SCORING, STARTING, JOINING }
export (int) var status
export (Array, int) var players_ids
export (String) var game_id
var players: Dictionary
var max_size: int
var curr_players: int
var curr_round: RoundInfo
var hinter_id: int

func _init (gid: String, pid: int, hname: String):
	game_id = gid
	players_ids = [ pid ]
	players = { pid: PlayerInfo.new(hname) }
	status = LOBBY_STATUS.WAITING
	max_size = 8
	curr_players = 1
	curr_round = null

func add_player (pid: int, pname: String):
	if curr_players == max_size or players.get(pid, null) != null:
		return false

	players_ids.append(pid)
	players[pid] = PlayerInfo.new(pname)
	curr_players += 1

	return true

func remove_player (pid: int):
	if players.get(pid, null) == null:
		return false

	players_ids.erase(pid)
	players.erase(pid)
	curr_players -= 1

	return true

func start_round ():
	if curr_players == 1:
		return -1

	curr_round = RoundInfo.new(curr_players)
	hinter_id = players_ids[curr_round.hinter_idx]

	for pid in players_ids:
		if pid != hinter_id:
			players[pid].status = PlayerInfo.PLAYER_STATUS.GUESSING

		else:
			players[pid].status = PlayerInfo.PLAYER_STATUS.HINTING

	return hinter_id

func ready_hinter (score_degree: float):
	if curr_round == null:
		return false

	if players.get(hinter_id, null) == null:
		return false

	curr_round.set_score_degree(score_degree)
	players[hinter_id].status = PlayerInfo.READY

	return true

func ready_guesser (pid: int, guess_degree: float):
	if not self.is_guesser(pid):
		return false

	curr_round.set_guess_degree(pid, guess_degree)
	players[pid].status = PlayerInfo.READY

	return true

func update_score (pid: int, score: int):
	if pid == hinter_id:
		return false

	var player = players.get(pid, null)
	if player == null or player.status != PlayerInfo.READY:
		return false

	player.score += score
	player.status = PlayerInfo.PLAYER_STATUS.WAITING
	curr_round.decrement_scoring_players()

	return true

func get_players_info ():
	var players_info: Dictionary = {}
	for pid in players:
		players_info[pid] = players[pid].get_info()

	return players_info

func get_lobby_info ():
	if curr_round == null:
		return {
			"status": LOBBY_STATUS.STARTING,
			"game_id": game_id,
			"players": get_players_info(),
			"round": null
		}

	return {
		"status": LOBBY_STATUS.JOINING,
		"game_id": game_id,
		"players": get_players_info(),
		"round": {
			"hinter": hinter_id,
			"guesses": curr_round.get_guesses()
		}
	}

func is_guesser (pid: int):
	var player = players.get(pid, null)
	return player != null and player.status == PlayerInfo.PLAYER_STATUS.GUESSING

func is_empty ():
	return curr_players == 0

func all_scored ():
	return curr_round != null and curr_round.scoring_players == 0

func all_ready ():
	return curr_round != null and curr_round.guessing_players == 0
