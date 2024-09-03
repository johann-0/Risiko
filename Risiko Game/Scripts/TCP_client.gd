#Source for this code: https://www.bytesnsprites.com/posts/2021/creating-a-tcp-client-in-godot/
extends Node

signal connected
signal data
signal disconnected
signal error

var _status = StreamPeerTCP.STATUS_NONE
var _stream: StreamPeerTCP = StreamPeerTCP.new()

func _ready() -> void:
	_status = _stream.get_status()

func _process(_delta: float) -> void:
	_stream.poll()
	var new_status: StreamPeerTCP.Status = _stream.get_status()
	if new_status != _status:
		_status = new_status
		match _status:
			_stream.STATUS_NONE:
				print("Disconnected from host.")
				emit_signal("disconnected")
			_stream.STATUS_CONNECTING:
				print("Connecting to host.")
			_stream.STATUS_CONNECTED:
				print("Connected to host.")
				emit_signal("connected")
			_stream.STATUS_ERROR:
				print("Error with socket stream.")
				emit_signal("error")
	
	if _status == _stream.STATUS_CONNECTED:
		var available_bytes: int = _stream.get_available_bytes()
		if available_bytes > 0:
			print("available bytes: ", available_bytes)
			var _data: Array = _stream.get_partial_data(available_bytes)
			# Check for read error.
			if _data[0] != OK:
				print("Error getting data from stream: ", _data[0])
				emit_signal("error")
			else:
				emit_signal("data", _data[1])

func connect_to_host(host: String, port: int) -> void:
	print("Connecting to %s:%d..." % [host, port])
	# Reset status so we can tell if it changes to error again.
	_status = _stream.STATUS_NONE
	if _stream.connect_to_host(host, port) != OK:
		print("Error connecting to host.")
		emit_signal("error")

func disconnect_from_host():
	print("Disconnecting from %s:%d..." % [_stream.get_connected_host(), _stream.get_connected_port()])
	_stream.disconnect_from_host()

func send(_data: PackedByteArray) -> bool:
	print("Sending data... {")
	print(_data)
	print("}")
	if _status != _stream.STATUS_CONNECTED:
		print("Error: Stream is not currently connected.")
		return false
	var _error: int = _stream.put_data(_data)
	if _error != OK:
		print("Error writing to stream: ", _error)
		return false
	return true
