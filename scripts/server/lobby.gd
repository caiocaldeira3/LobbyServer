extends Node


const LobbyInfo = preload("res://resources/LobbyInfo.gd")

enum { LOBBY, HINTING, GUESSING, SCORING, WAITING }
var _open_lobbies: Dictionary = {}

func signal_to_lobby (source_id: int, lobby: LobbyInfo, rpc_method: String):
	print(
		"signalling %d call " % source_id, rpc_method, " over lobby ", lobby.game_id
	)
	for pid in lobby.players_ids:
		if source_id != pid:
			print("signaling %d about " % pid, rpc_method)
			rpc_id(pid, rpc_method)

func synchronize_lobby (
	source_id: int, lobby: LobbyInfo, rpc_method: String, data: Dictionary
):
	print(
		"synchronizing %d call " % source_id, rpc_method, " over lobby ", lobby.game_id
	)
	for pid in lobby.players_ids:
		if source_id != pid:
			print("synchronizing %d about " % pid, rpc_method)
			rpc_id(pid, rpc_method, data)

func get_lobby (pid: int):
	var gid = Server.ONLINE_PLAYERS.get(pid, null)
	if gid == null:
		print("lobby not found")
		return null

	return _open_lobbies.get(gid, null)

func random_word ():
	var word: String = ""
	for _i in range(6):
		word += Server.VALID_CHARS[Server.rng.randi() % Server.ALPHA_SIZE]

	return word

func valid_lobby ():
	Server.rng.randomize()
	print("randomizing lobby id")

	var word = random_word()
	while _open_lobbies.get(word, null) != null:
		print("%s is taken" % word)
		word = random_word()

	print("chosen word is: %s" % word)
	return word

remote func create_lobby (pid: int, pname: String):
	print("%d is creating a lobby" % pid)
	var gid = valid_lobby()

	_open_lobbies[gid] = LobbyInfo.new(gid, pid, pname)
	rpc_id(pid, "created_lobby", gid)

remote func join_lobby (pid: int, gid: String, pname: String):
	print("%d wants to join lobby " % pid, gid)
	var lobby: LobbyInfo = _open_lobbies.get(gid, null)

	if lobby == null or not lobby.add_player(pid, pname):
		print("lobby non-existent or full")

		rpc_id(pid, "join_lobby", { "status": "error" })
		return

	signal_to_lobby(pid, lobby, "join_lobby")
	rpc_id(pid, "joined_lobby", lobby.get_lobby_info())

	if lobby.status == LobbyInfo.WAITING:
		print("initializing game if it is the first player")
		yield(get_tree().create_timer(5.0), "timeout")

		synchronize_lobby(1, lobby.game_id, "start_round", {
			"hinter_id": lobby.start_round()
		})

func remove_from_lobby (pid: int):
	var lobby: LobbyInfo = get_lobby(pid)
	print("remove %d from lobby " % pid, lobby.game_id)

	Server.ONLINE_PLAYERS.erase(pid)
	if lobby != null and lobby.remove_player(pid):
		print("%d removed" % pid)
		if lobby.is_empty():
			print("deleting %s empty lobby")
			_open_lobbies.erase(lobby.game_id)

		else:
			print(
				"synchronize with online players that %d left the lobby" % pid
			)
			synchronize_lobby(pid, lobby, "exit_lobby", { "id": pid })

remote func exit_lobby (id: int):
	remove_from_lobby(id)
	rpc_id(id, "exited_lobby")
