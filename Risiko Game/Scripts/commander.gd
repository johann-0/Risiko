extends Node2D

enum Commands {ProvSel, UpDown, Exec, EndTurn}

var priv_loc_queue: Array[BaseCommand] = []
var priv_glo_queue: Array[BaseCommand] = []

func add_command(command: BaseCommand):
	priv_loc_queue.append(command)
	process_command()

@rpc("any_peer","call_local")
func remote_add_command(com_arr: Array):
	print("remoted")
	var rem_command: BaseCommand = null
	match com_arr[0]:
		Commands.ProvSel:
			rem_command = ProvinceSelected.new(com_arr[1])
		Commands.UpDown:
			rem_command = UpOrDownPressed.new(com_arr[1])
		Commands.Exec:
			rem_command = ExecutePressed.new(com_arr[1])
		Commands.EndTurn:
			rem_command = EndTurnPressed.new(com_arr[1])
		_:
			pass
	priv_glo_queue.append(rem_command)
	remote_process_command()

func process_command():
	if priv_loc_queue.is_empty():
		return
	
	var command: BaseCommand = priv_loc_queue.pop_front()
	command.process()
	
	process_command()

func remote_process_command():
	if priv_glo_queue.is_empty():
		return
	
	var rem_command: BaseCommand = priv_glo_queue.pop_front()
	rem_command.remote_process()
	
	remote_process_command()
