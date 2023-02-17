extends Node


const LobbyInfo = preload("res://resources/LobbyInfo.gd")

remote func position_guess (pid: int, guess_degrees: float):
	var lobby: LobbyInfo = Lobby.get_lobby(pid)
	if lobby == null or not lobby.is_guesser(pid):
		return

	Lobby.syncronize_lobby(
		pid, lobby, "position_guess", { 
			"guess_degrees": guess_degrees, "player_id": pid
		}
	)

remote func ready_guess (pid: int, guess_degree: float):
	var lobby: LobbyInfo = Lobby.get_lobby(pid)
	if lobby == null or not lobby.ready_guesser(pid, guess_degree):
		return
	
	Lobby.syncronize_lobby(
		pid, lobby, "ready_guess", {
			"guess_degrees": guess_degree, "player_id": pid
		}
	)

	if lobby.all_ready():
		lobby.status = LobbyInfo.SCORING
		Lobby.syncronize_lobby(
			1, lobby, "all_ready", lobby.curr_round.score_degree
		)

remote func update_score (pid: int, score: int):
	var lobby: LobbyInfo = Lobby.get_lobby(pid)
	if lobby != null:
		lobby.update_score(pid, score)
		
		if lobby.all_scored():
			lobby.status = LobbyInfo.WAITING
			yield(get_tree().create_timer(5.0), "timeout")
		
			Lobby.syncronize_lobby(1, lobby.game_id, "start_round", {
				"hinter_id": lobby.start_round()
			})
