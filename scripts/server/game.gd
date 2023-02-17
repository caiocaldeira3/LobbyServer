extends Node


const LobbyInfo = preload("res://resources/LobbyInfo.gd")

remote func position_guess (pid: int, guess_degree: float):
	print("%d has positioned a guess" % pid, " at %f" % guess_degree)
	var lobby: LobbyInfo = Lobby.get_lobby(pid)
	if lobby == null or not lobby.is_guesser(pid):
		print("%d is a invalid guesser" % pid)
		return

	Lobby.syncronize_lobby(
		pid, lobby, "position_guess", { 
			"guess_degree": guess_degree, "player_id": pid
		}
	)

remote func ready_guess (pid: int, guess_degree: float):
	print("%d has finished guessing" % pid, " at %f" % guess_degree)

	var lobby: LobbyInfo = Lobby.get_lobby(pid)
	if lobby == null or not lobby.ready_guesser(pid, guess_degree):
		print("%d is a invalid guesser" % pid)
		return
	
	Lobby.syncronize_lobby(
		pid, lobby, "ready_guess", {
			"guess_degree": guess_degree, "player_id": pid
		}
	)

	if lobby.all_ready():
		print("compute scoring on players clients")
		lobby.status = LobbyInfo.SCORING
		Lobby.syncronize_lobby(
			1, lobby, "all_ready", lobby.curr_round.score_degree
		)

remote func update_score (pid: int, score: int):
	var lobby: LobbyInfo = Lobby.get_lobby(pid)
	if lobby == null or not lobby.update_score(pid, score):
		print("lobby not found or invalid scorer")
		return
		
	print("%d marked a score of " % pid, "%d on this round" % score)
	
	if lobby.all_scored():
		print("all round players have finished scoring phase")
		print("start new round")
		lobby.status = LobbyInfo.WAITING
		yield(get_tree().create_timer(5.0), "timeout")
	
		Lobby.syncronize_lobby(1, lobby.game_id, "start_round", {
			"hinter_id": lobby.start_round()
		})
