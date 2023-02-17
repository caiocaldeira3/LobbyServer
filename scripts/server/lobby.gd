extends Node


const LobbyInfo = preload("res://resources/LobbyInfo.gd")

enum { LOBBY, HINTING, GUESSING, SCORING, WAITING }
var _open_lobbies: Dictionary = {}

func signal_to_lobby (source_id: int, lobby: LobbyInfo, rpc_method: String):
	for pid in lobby.players_ids:
		if source_id != pid:
			rpc_id(pid, rpc_method)

func syncronize_lobby (
	source_id: int, lobby: LobbyInfo, rpc_method: String, data: Dictionary
):
	for pid in lobby.players_ids:
		if source_id != pid:
			rpc_id(pid, rpc_method, data)

func get_lobby (pid: int):
	var gid = Server.ONLINE_PLAYERS.get(pid, null)
	if gid == null:
		return null

	return _open_lobbies.get(gid, null)

func random_word ():
	var word: String = ""
	for _i in range(6):
		word += Server.VALID_CHARS[Server.rng.randi() % Server.ALPHA_SIZE]

	return word

remote func valid_lobby (id: int):
	print("Fetching Lobby name for %d" % id)
	Server.rng.randomize()

	var word = random_word()
	while word in _open_lobbies.keys():
		print("%s is taken" % word)
		word = random_word()

	print("chosen word is: %s" % word)
	rpc_id(id, "valid_lobby", word)

remote func create_lobby (pid: int, gid: String, pname: String):
	var success = false
	if _open_lobbies.get(gid, null) != null:
		_open_lobbies[gid] = LobbyInfo.new(gid, pid, pname)
		success = true

	rpc_id(pid, "created_lobby", success)

remote func join_lobby (pid: int, gid: String, pname: String):
	var lobby: LobbyInfo = _open_lobbies.get(gid, null)
	var success = false

	if lobby != null and lobby.add_player(pid, pname):
		signal_to_lobby(pid, lobby, "join_lobby")
		success = true

	rpc_id(pid, "joined_lobby", lobby.get_lobby_info())

	if lobby.status == LobbyInfo.WAITING:
		yield(get_tree().create_timer(5.0), "timeout")

		syncronize_lobby(1, lobby.game_id, "start_round", {
			"hinter_id": lobby.start_round()
		})

func remove_from_lobby (pid: int):
	var lobby: LobbyInfo = get_lobby(pid)

	Server.ONLINE_PLAYERS.erase(pid)
	if lobby != null and lobby.remove_player(pid):
		if lobby.is_empty():
			_open_lobbies.erase(lobby.game_id)

		else:
			syncronize_lobby(pid, lobby, "exit_lobby", { "id": pid })

remote func exit_lobby (id: int):
	remove_from_lobby(id)
	rpc_id(id, "exited_lobby", true)
