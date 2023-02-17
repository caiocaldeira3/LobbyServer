extends Resource


enum { WAITING, GUESSING, HINTING, READY, SCORING }

export (String) var name
export (int) var status
export (int) var score

func _init (pname: String):
	name = pname
	status = WAITING
	score = 0

func get_info ():
	return {
		"name": name,
		"score": score
	}
