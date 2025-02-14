extends Node
class_name PahoClient, "icon.png"


signal connected(reason_code)
signal disconnected
signal published(message_id)
signal received(topic, payload)
signal subscribed(message_id, topic)
signal unsubscribed(message_id, topic)
signal log_received(level, message)
signal error_received(message, reason_code)


export var client_id: String = "MQTTClient" 
export var clean_session: bool = true 
export var broker_address: String = "localhost"
export var broker_port: int = 1883
export var broker_keep_alive: int = 60
export var username: String = ""
export var password: String = ""

onready var _mqtt_client_class = preload("GDPaho.gdns")

onready var _mqtt_client: Object = null


func initialise() -> void:
	if not _mqtt_client_class:
		return
	_mqtt_client = _mqtt_client_class.new()
	_mqtt_client.connect("connected", self, "_on_MQTTClient_connected")
	_mqtt_client.connect("disconnected", self, "_on_MQTTClient_disconnected")
	_mqtt_client.connect("published", self, "_on_MQTTClient_published")
	_mqtt_client.connect("received", self, "_on_MQTTClient_received")
	_mqtt_client.connect("subscribed", self, "_on_MQTTClient_subscribed")
	_mqtt_client.connect("unsubscribed", self, "_on_MQTTClient_unsubscribed")
	_mqtt_client.connect("log", self, "_on_MQTTClient_log")
	_mqtt_client.connect("error", self, "_on_MQTTClient_error")
	var rc_initialise: int = _mqtt_client.initialise(client_id, broker_address, broker_port)
	if not rc_initialise:
		if username != "" and password != "":
			var rc_username_pwt: int = _mqtt_client.username_pw_set(username, password)
			if rc_username_pwt:
				printerr("[" + client_id + "] error during connect, " + _mqtt_client.reason_code_string(rc_username_pwt))
		var rc_connect: int = _mqtt_client.broker_connect(clean_session, broker_keep_alive)
		if rc_connect:
			printerr("[" + client_id + "] error during connect, " + _mqtt_client.reason_code_string(rc_connect))
	else:
		printerr("[" + client_id + "] error during initialise, " + _mqtt_client.reason_code_string(rc_initialise))


func reason_code_string(rc: int) -> String:
	return _mqtt_client.reason_code_string(rc)


func broker_connect(new_clean_session: bool = false, new_broker_keep_alive: int = 60) -> int:
	var rc_connect: int = _mqtt_client.broker_connect(new_clean_session, new_broker_keep_alive)
	if not rc_connect:
		clean_session = new_clean_session
		broker_keep_alive = new_broker_keep_alive
	return rc_connect


func broker_reconnect() -> int:
	return _mqtt_client.broker_reconnect()


func reinitialise() -> void:
	if _mqtt_client:
		if is_connected_to_broker():
			_mqtt_client.broker_disconnect()
			while is_connected_to_broker(): pass
		_mqtt_client = null
	initialise()


func is_connected_to_broker() -> int:
	return _mqtt_client.is_connected_to_broker()


func broker_disconnect() -> int:
	return _mqtt_client.broker_disconnect()


func subscribe(topic: String, qos: int = 0) -> int:
	return _mqtt_client.subscribe(topic, qos)


func unsubscribe(topic: String) -> int:
	return _mqtt_client.unsubscribe(topic)


func publish(topic: String, payload: String, qos: int = 0, retain: bool = false) -> int:
	return _mqtt_client.publish(topic, payload, qos, retain)


func _on_MQTTClient_connected(reason_code: int) -> void:
	yield(get_tree().create_timer(0.1), "timeout") # ARM bugfix (deadlock)
	emit_signal("connected", reason_code)


func _on_MQTTClient_disconnected() -> void:
	emit_signal("disconnected")


func _on_MQTTClient_published(message_id: int) -> void:
	emit_signal("published", message_id)


func _on_MQTTClient_received(topic: String, payload: String) -> void:
	emit_signal("received", topic, payload)


func _on_MQTTClient_subscribed(message_id: int, topic: String) -> void:
	emit_signal("subscribed", message_id, topic)


func _on_MQTTClient_unsubscribed(message_id: int, topic: String) -> void:
	emit_signal("unsubscribed", message_id, topic)


func _on_MQTTClient_log(level: int, message: String) -> void:
	emit_signal("log_received", level, message)


func _on_MQTTClient_error(message: String, reason_code: int) -> void:
	emit_signal("error_received", message, reason_code)

