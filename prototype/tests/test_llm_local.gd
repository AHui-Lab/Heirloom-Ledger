extends SceneTree

const Client = preload("res://scripts/llm_client.gd")
var server := TCPServer.new()
var peer: StreamPeerTCP
var client: DemoLLMClient
var raw := ""
var fixture: Dictionary = {}
var received: Array = []
var failures: Array[String] = []
var received_body: Dictionary = {}
var responded := false

func _initialize() -> void:
	_run.call_deferred()

func check(value: bool, label: String) -> void:
	if not value: failures.append(label)

func _run() -> void:
	var port := 19270
	while port < 19300 and server.listen(port, "127.0.0.1") != OK: port += 1
	if not server.is_listening():
		push_error("Cannot bind loopback fixture server")
		quit(1)
		return
	client = Client.new()
	root.add_child(client)
	client.response_ready.connect(func(ok, text, error): received = [ok, text, error])
	check(not Client.speaker_error("欢迎光临，我店里有几件旧物。", "npc").is_empty(), "Obvious shopkeeper voice rejected in NPC channel")
	check(Client.speaker_error("我想来看看旧物。", "npc").is_empty(), "Customer voice accepted")
	check(Client.speaker_error("我店里还有这件货，先核对。", "inner").is_empty(), "Shopkeeper inner thoughts allowed")
	var cases := [
		{"protocol": "responses", "body": {"status": "completed", "output": [{"type": "message", "content": [{"type": "output_text", "text": "本地成功"}]}]}, "ok": true},
		{"protocol": "chat_completions", "body": {"choices": [{"finish_reason": "stop", "message": {"content": "本地成功"}}]}, "ok": true},
		{"protocol": "responses", "body": {"output_text": null, "output": null}, "ok": false},
		{"protocol": "responses", "body": {"output": [{"type": "message", "content": null}]}, "ok": false},
		{"protocol": "responses", "body": {"status": "incomplete", "incomplete_details": {"reason": "max_output_tokens"}, "output_text": "不完整"}, "ok": false},
		{"protocol": "chat_completions", "body": {"choices": [{"finish_reason": "length", "message": {"content": "不完整"}}]}, "ok": false},
		{"protocol": "chat_completions", "body": {"choices": [{"message": {"content": null, "reasoning_content": "不能显示的推理"}}]}, "ok": false},
		{"protocol": "chat_completions", "body": {"choices": [{"message": {"content": [{"type": "text", "text": "本地成功"}]}}]}, "ok": true},
		{"protocol": "responses", "raw": "not-json", "ok": false},
		{"protocol": "responses", "status": 401, "body": {"error": {"message": "fixture unauthorized"}}, "ok": false},
		{"protocol": "chat_completions", "status": 503, "body": {}, "ok": false},
		{"protocol": "responses", "timeout": true, "ok": false},
		{"protocol": "responses", "body": {"output_text": "重试成功"}, "ok": true},
	]
	for index in range(cases.size()):
		fixture = cases[index]
		raw = ""
		responded = false
		received = []
		received_body = {}
		if peer != null: peer.disconnect_from_host()
		peer = null
		client.configure("local-fixture-not-a-key", "local-test", "http://127.0.0.1:%d" % port, "/fixture", fixture["protocol"], 0.7, 4096, 5)
		check(client.test_connection() == OK, "Request dispatch %d" % index)
		var deadline := Time.get_ticks_msec() + 8000
		while received.is_empty() and Time.get_ticks_msec() < deadline:
			_serve()
			await process_frame
		check(not received.is_empty(), "Bounded callback %d" % index)
		if received.is_empty(): continue
		check(received[0] == fixture["ok"], "Expected success/failure %d" % index)
		if fixture["ok"]: check(not str(received[1]).is_empty(), "Visible body %d" % index)
		check(int(received_body.get("max_output_tokens", received_body.get("max_tokens", 0))) == 4096, "Configured token budget on actual HTTP wire %d" % index)
		check(raw.begins_with("POST /fixture HTTP/1.1"), "Configured endpoint on actual HTTP wire %d" % index)
	client.cancel_pending()
	client.queue_free()
	server.stop()
	if peer != null: peer.disconnect_from_host()
	if failures.is_empty():
		print("PASS: local HTTP Responses/Chat, wire budget, malformed/null/empty/truncated, 401/503, timeout and recovery; no external API calls")
	else:
		for failure in failures: push_error(failure)
	quit(0 if failures.is_empty() else 1)

func _serve() -> void:
	if peer == null and server.is_connection_available(): peer = server.take_connection()
	if peer == null: return
	peer.poll()
	var available := peer.get_available_bytes()
	if available > 0:
		var packet := peer.get_data(available)
		raw += packet[1].get_string_from_utf8()
	var boundary := raw.find("\r\n\r\n")
	if boundary < 0 or responded: return
	var length := 0
	for header in raw.substr(0, boundary).split("\r\n"):
		if header.to_lower().begins_with("content-length:"): length = int(header.split(":", true, 1)[1])
	var payload := raw.substr(boundary + 4)
	if payload.to_utf8_buffer().size() < length: return
	var parsed = JSON.parse_string(payload)
	if parsed is Dictionary: received_body = parsed
	responded = true
	if fixture.get("timeout", false): return
	var body := str(fixture.get("raw", JSON.stringify(fixture.get("body", {}))))
	var response := "HTTP/1.1 %d Fixture\r\nContent-Type: application/json; charset=utf-8\r\nContent-Length: %d\r\nConnection: close\r\n\r\n%s" % [int(fixture.get("status", 200)), body.to_utf8_buffer().size(), body]
	peer.put_data(response.to_utf8_buffer())
