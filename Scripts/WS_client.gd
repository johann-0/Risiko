extends Node
signal connected
signal connecting
signal recieved_data(data: String)
signal disconnected
signal disconnecting
var _socket: WebSocketPeer
var _state: WebSocketPeer.State

func _ready():
	_socket = WebSocketPeer.new()
	_state = WebSocketPeer.STATE_CLOSED

func _process(_delta):
	_socket.poll()
	var newState = _socket.get_ready_state()
	if newState != _state:
		_state = newState	
		match _state:
			WebSocketPeer.STATE_CONNECTING:
				print("WS_client: Connecting")
				emit_signal("connecting")
			WebSocketPeer.STATE_OPEN: # Connected and ready to send/receive data
				print("WS_client: Connected")
				emit_signal("connected")
				#while _socket.get_available_packet_count():
					#print("Got data from server: ", _socket.get_packet().get_string_from_utf8())
			WebSocketPeer.STATE_CLOSING: # In the midst of closing
				print("WS_client: Disconnecting")
				emit_signal("disconnecting")
			WebSocketPeer.STATE_CLOSED:
				print("WS_client: Disconnected")
				emit_signal("disconnected")
				# The code will be -1 if the disconnection was not properly notified by the remote peer.
				var code = _socket.get_close_code()
				print("WebSocket disconnected with code: %d. Clean: %s" % [code, code != -1])
	
	if _state == WebSocketPeer.STATE_OPEN:
		while _socket.get_available_packet_count():
			var data: String = _socket.get_packet().get_string_from_utf8()
			print("WS_client: Recieved: %s" % [data])
			recieved_data.emit(data)

func _connect_to_url(url: String):
	print("WS_client: Connecting to %s..." % [url])
	_state = WebSocketPeer.STATE_CLOSED
	var err = _socket.connect_to_url(url)
	if err != OK:
		print("WS_client: Failed to connect, error code: %s" % str(err))

func _disconnect_from_url():
	print("WS_client: Disconnecting from %s..." % [_socket.get_requested_url()])
	_socket.close()

func _send_text(text: String):
	print("WS_client: Sending text: %s..." % [text])
	_socket.send_text(text)

func _send_dict(dict: Dictionary):
	var json_string: String = JSON.stringify(dict)
	print("WS_client: Sending dict: %s..." % [json_string])
	_socket.send_text(json_string)
