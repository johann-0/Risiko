class_name AwaitMultiple

signal completed()

var signals: Array[bool]
var check_any: bool

func _init(_check_any: bool, _signals: Array[Signal], _arg_counts: Array[int]) -> void:
	check_any = _check_any
	for i in _signals.size():
		var sig: Signal = _signals[i]
		if _arg_counts[i] == 0:
			sig.connect(on_signal.bind(i))
		else:
			sig.connect(on_signal.bind(i).unbind(_arg_counts[i]))
		signals.append(false)

func on_signal(index: int) -> void:
	if check_any:
		completed.emit()
		return
	signals[index] = true
	check_if_all_done()

func check_if_all_done() -> void:
	for val in signals:
		if val == false:
			return
	completed.emit()
