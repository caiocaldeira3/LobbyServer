extends Node


const SERVER_IP: String = "127.0.0.1"
const SERVER_PORT: int = 3456
const MAX_PLAYERS: int = 1000
const MAX_LOBBY_SIZE: int = 8
const VALID_CHARS: String = "ABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789"
const ALPHA_SIZE: int = 36
var ONLINE_PLAYERS: Dictionary = {}
var rng = RandomNumberGenerator.new()

func _ready ():
	get_tree().connect("network_peer_connected", self, "_player_connected")
	get_tree().connect("network_peer_disconnected", self, "_player_disconnected")
	start_server()

func start_server():
	print("intializing server")

	var peer = NetworkedMultiplayerENet.new()
	var result = peer.create_server(SERVER_PORT, MAX_PLAYERS)

	if result != OK:
		print("Failed creating the server.")
		return

	print("Created the server.")
	get_tree().set_network_peer(peer)

func _player_connected(id):
	print(str(id) + " connected to server.")

func _player_disconnected(id):
	print(str(id) + " left the game.")

	Lobby.disconnect_player(id)
