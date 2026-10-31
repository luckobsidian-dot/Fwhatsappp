extends Control
## Fwhatsapp - seznam chatu + chat ve stylu WhatsApp (dark), Godot 4.3

const SAVE_PATH := "user://fwhatsapp.json"

const C_BG := Color("0b141a")
const C_HEADER := Color("202c33")
const C_IN := Color("202c33")
const C_OUT := Color("005c4b")
const C_TEXT := Color("e9edef")
const C_SUB := Color("8696a0")
const C_FIELD := Color("2a3942")
const C_GREEN := Color("00a884")
const PALETTE := ["6b7c85", "d4545c", "5a8f4e", "c9822b", "4f7fd1", "9b59b6", "1f9e9e"]

var contacts: Array = []
var cur := -1
var edit_idx := 0

var list_screen: Control
var chat_screen: Control
var list_box: VBoxContainer
var msg_list: VBoxContainer
var scroll: ScrollContainer
var name_label: Label
var status_label: Label
var avatar: Avatar
var input: LineEdit
var editor: Control

var f_contact: OptionButton
var f_name: LineEdit
var f_status: LineEdit
var f_color: ColorPickerButton
var f_unread: SpinBox
var f_text: LineEdit
var f_time: LineEdit
var f_dir: OptionButton
var f_state: OptionButton


# ───────────── male kreslici tridy ─────────────

class Ticks extends Control:
	var state := 2 # 0 odeslano, 1 doruceno, 2 prečteno
	func _init(s: int = 2) -> void:
		state = s
		custom_minimum_size = Vector2(18, 14)
		mouse_filter = Control.MOUSE_FILTER_IGNORE
	func _draw() -> void:
		var col := Color("53bdeb") if state == 2 else Color("8696a0")
		if state >= 1:
			draw_polyline(PackedVector2Array([Vector2(0, 8), Vector2(4, 12), Vector2(12, 3)]), col, 1.6, true)
		draw_polyline(PackedVector2Array([Vector2(4, 8), Vector2(8, 12), Vector2(16, 3)]), col, 1.6, true)


class Avatar extends Control:
	var col := Color("6b7c85")
	var letter := "M"
	func _init() -> void:
		custom_minimum_size = Vector2(40, 40)
		mouse_filter = Control.MOUSE_FILTER_IGNORE
	func set_info(c: Color, name_text: String) -> void:
		col = c
		letter = name_text.substr(0, 1).to_upper() if name_text != "" else "?"
		queue_redraw()
	func _draw() -> void:
		var c := size / 2.0
		draw_circle(c, minf(size.x, size.y) / 2.0, col)
		var f := ThemeDB.fallback_font
		var fs := int(minf(size.x, size.y) * 0.5)
		var w := f.get_string_size(letter, HORIZONTAL_ALIGNMENT_LEFT, -1, fs)
		draw_string(f, Vector2(c.x - w.x / 2.0, c.y + fs * 0.35), letter, HORIZONTAL_ALIGNMENT_LEFT, -1, fs, Color.WHITE)


class HeaderIcons extends Control:
	func _init() -> void:
		custom_minimum_size = Vector2(80, 40)
		mouse_filter = Control.MOUSE_FILTER_IGNORE
	func _draw() -> void:
		var col := Color("aebac1")
		draw_rect(Rect2(8, 13, 16, 14), col, false, 2.0)
		draw_colored_polygon(PackedVector2Array([Vector2(25, 18), Vector2(33, 13), Vector2(33, 27), Vector2(25, 22)]), col)
		for i in 3:
			draw_circle(Vector2(62, 12 + i * 8), 2.2, col)


class SendIcon extends Control:
	func _init() -> void:
		mouse_filter = Control.MOUSE_FILTER_IGNORE
		set_anchors_preset(Control.PRESET_FULL_RECT)
	func _draw() -> void:
		var c := size / 2.0
		draw_colored_polygon(PackedVector2Array([
			c + Vector2(-9, -10), c + Vector2(11, 0), c + Vector2(-9, 10), c + Vector2(-5, 0)
		]), Color.WHITE)


class PlusIcon extends Control:
	func _init() -> void:
		mouse_filter = Control.MOUSE_FILTER_IGNORE
		set_anchors_preset(Control.PRESET_FULL_RECT)
	func _draw() -> void:
		var c := size / 2.0
		draw_line(c + Vector2(-9, 0), c + Vector2(9, 0), Color("0b141a"), 3.0, true)
		draw_line(c + Vector2(0, -9), c + Vector2(0, 9), Color("0b141a"), 3.0, true)


class Wallpaper extends Control:
	func _init() -> void:
		mouse_filter = Control.MOUSE_FILTER_IGNORE
		set_anchors_preset(Control.PRESET_FULL_RECT)
		resized.connect(queue_redraw)
	func _draw() -> void:
		var col := Color("17222a")
		var rng := RandomNumberGenerator.new()
		rng.seed = 20241
		var step := 58.0
		var y := 20.0
		var row := 0
		while y < size.y + step:
			var x := 20.0 + (step / 2.0 if row % 2 == 1 else 0.0)
			while x < size.x + step:
				var kind := rng.randi() % 7
				var rot := rng.randf() * TAU
				var p := Vector2(x + rng.randf_range(-8.0, 8.0), y + rng.randf_range(-8.0, 8.0))
				draw_set_transform(p, rot, Vector2.ONE)
				_shape(kind, col)
				x += step
			y += step
			row += 1
		draw_set_transform(Vector2.ZERO, 0.0, Vector2.ONE)
	func _shape(kind: int, col: Color) -> void:
		match kind:
			0:
				draw_arc(Vector2.ZERO, 8.0, 0.0, TAU, 20, col, 1.6, true)
			1:
				draw_line(Vector2(-8, 0), Vector2(8, 0), col, 1.6, true)
				draw_line(Vector2(0, -8), Vector2(0, 8), col, 1.6, true)
			2:
				var pts := PackedVector2Array()
				for i in 6:
					var a := -PI / 2.0 + i * 4.0 * PI / 5.0
					pts.append(Vector2(cos(a), sin(a)) * 10.0)
				draw_polyline(pts, col, 1.6, true)
			3:
				draw_polyline(PackedVector2Array([Vector2(-9, 7), Vector2(9, 7), Vector2(0, -8), Vector2(-9, 7)]), col, 1.6, true)
			4:
				var w := PackedVector2Array()
				for i in 13:
					w.append(Vector2(-12 + i * 2, sin(i * 0.9) * 4.0))
				draw_polyline(w, col, 1.6, true)
			5:
				draw_rect(Rect2(-8, -6, 16, 12), col, false, 1.6)
			6:
				draw_rect(Rect2(-9, -7, 18, 12), col, false, 1.6)
				draw_polyline(PackedVector2Array([Vector2(-4, 5), Vector2(-6, 10), Vector2(1, 5)]), col, 1.6, true)


# ───────────── start ─────────────

func _ready() -> void:
	set_anchors_preset(Control.PRESET_FULL_RECT)
	_build_list_screen()
	_build_chat_screen()
	_build_secret_button()
	_build_editor()
	if not _load():
		_demo()
	_show_list()


func _notification(what: int) -> void:
	if what == NOTIFICATION_WM_GO_BACK_REQUEST:
		if editor != null and editor.visible:
			editor.visible = false
		elif cur >= 0:
			_show_list()
		else:
			get_tree().quit()


func _mk_msg(t: String, time: String, out: bool, state: int = 0) -> Dictionary:
	return {"text": t, "time": time, "out": out, "state": state}


func _mk_contact(n: String, st: String, col: String, unread: int, msgs: Array) -> Dictionary:
	return {"name": n, "status": st, "color": col, "unread": unread, "messages": msgs}


func _demo() -> void:
	contacts = [
		_mk_contact("Máma", "online", "d4545c", 0, [
			_mk_msg("Ahoj, už jsi doma?", "20:41", false),
			_mk_msg("Jo, před chvílí jsem dorazil", "20:43", true, 2),
			_mk_msg("Fajn, tak ať se ti dobře spí", "20:44", false),
			_mk_msg("Díky, dobrou noc!", "20:45", true, 2),
		]),
		_mk_contact("Tomáš", "naposledy online dnes v 19:20", "4f7fd1", 1, [
			_mk_msg("Kámo jdeš dneska na trénink?", "19:12", false),
			_mk_msg("Jo, v 18 tam budu", "19:15", true, 2),
			_mk_msg("Super, vezmi míč", "19:16", false),
		]),
		_mk_contact("Kačka", "online", "9b59b6", 2, [
			_mk_msg("Poslala jsem ti ty poznámky", "18:03", false),
			_mk_msg("Jsou v mailu", "18:03", false),
		]),
		_mk_contact("Dominik", "naposledy online dnes v 17:41", "5a8f4e", 0, [
			_mk_msg("Zítra v 10 u mě?", "17:22", false),
			_mk_msg("Tak zítra", "17:30", true, 1),
		]),
		_mk_contact("Babička", "naposledy online včera", "c9822b", 0, [
			_mk_msg("Dobrou noc, broučku", "22:10", false),
			_mk_msg("Dobrou noc, babi", "22:12", true, 2),
		]),
	]


# ───────────── pomocne UI ─────────────

func _flat(col: Color, radius: int, ml := 0, mt := 0, mr := 0, mb := 0) -> StyleBoxFlat:
	var sb := StyleBoxFlat.new()
	sb.bg_color = col
	sb.set_corner_radius_all(radius)
	sb.content_margin_left = ml
	sb.content_margin_top = mt
	sb.content_margin_right = mr
	sb.content_margin_bottom = mb
	return sb


func _label(t: String, size_px: int, col: Color) -> Label:
	var l := Label.new()
	l.text = t
	l.add_theme_font_size_override("font_size", size_px)
	l.add_theme_color_override("font_color", col)
	return l


func _full(c: Control) -> void:
	c.set_anchors_preset(Control.PRESET_FULL_RECT)


# ───────────── obrazovka: seznam chatu ─────────────

func _build_list_screen() -> void:
	list_screen = Control.new()
	_full(list_screen)
	add_child(list_screen)

	var bg := ColorRect.new()
	bg.color = C_BG
	_full(bg)
	list_screen.add_child(bg)

	var root := VBoxContainer.new()
	_full(root)
	root.add_theme_constant_override("separation", 0)
	list_screen.add_child(root)

	var hm := MarginContainer.new()
	hm.add_theme_constant_override("margin_left", 16)
	hm.add_theme_constant_override("margin_right", 8)
	hm.add_theme_constant_override("margin_top", 34)
	hm.add_theme_constant_override("margin_bottom", 6)
	root.add_child(hm)
	var hb := HBoxContainer.new()
	hm.add_child(hb)
	var title := _label("WhatsApp", 26, C_TEXT)
	title.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	title.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	hb.add_child(title)
	hb.add_child(HeaderIcons.new())

	var sm := MarginContainer.new()
	sm.add_theme_constant_override("margin_left", 12)
	sm.add_theme_constant_override("margin_right", 12)
	sm.add_theme_constant_override("margin_top", 4)
	sm.add_theme_constant_override("margin_bottom", 8)
	root.add_child(sm)
	var sp := PanelContainer.new()
	sp.add_theme_stylebox_override("panel", _flat(C_FIELD, 24, 18, 11, 18, 11))
	sp.add_child(_label("Hledat", 16, C_SUB))
	sm.add_child(sp)

	var sc := ScrollContainer.new()
	sc.size_flags_vertical = Control.SIZE_EXPAND_FILL
	sc.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	sc.scroll_deadzone = 10
	root.add_child(sc)
	list_box = VBoxContainer.new()
	list_box.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	list_box.add_theme_constant_override("separation", 0)
	sc.add_child(list_box)

	var nav := PanelContainer.new()
	nav.add_theme_stylebox_override("panel", _flat(Color("111b21"), 0, 0, 12, 0, 16))
	root.add_child(nav)
	var nh := HBoxContainer.new()
	nav.add_child(nh)
	var tabs := ["Chaty", "Aktuality", "Komunity", "Hovory"]
	for i in tabs.size():
		var tl := _label(tabs[i], 13, C_TEXT if i == 0 else C_SUB)
		tl.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		tl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		nh.add_child(tl)

	var fab := Button.new()
	fab.focus_mode = Control.FOCUS_NONE
	for s in ["normal", "hover", "pressed", "focus"]:
		fab.add_theme_stylebox_override(s, _flat(C_GREEN, 16))
	fab.anchor_left = 1.0
	fab.anchor_right = 1.0
	fab.anchor_top = 1.0
	fab.anchor_bottom = 1.0
	fab.offset_left = -78
	fab.offset_right = -20
	fab.offset_top = -150
	fab.offset_bottom = -92
	fab.add_child(PlusIcon.new())
	list_screen.add_child(fab)


func _rebuild_list() -> void:
	for ch in list_box.get_children():
		list_box.remove_child(ch)
		ch.queue_free()
	for i in contacts.size():
		list_box.add_child(_make_row(i))


func _make_row(i: int) -> Control:
	var c: Dictionary = contacts[i]
	var msgs: Array = c["messages"]
	var has_msg := msgs.size() > 0
	var last: Dictionary = msgs[msgs.size() - 1] if has_msg else {}
	var unread := int(c["unread"])

	var btn := Button.new()
	btn.custom_minimum_size = Vector2(0, 76)
	btn.focus_mode = Control.FOCUS_NONE
	btn.add_theme_stylebox_override("normal", StyleBoxEmpty.new())
	btn.add_theme_stylebox_override("hover", StyleBoxEmpty.new())
	btn.add_theme_stylebox_override("focus", StyleBoxEmpty.new())
	btn.add_theme_stylebox_override("pressed", _flat(Color("182229"), 0))
	btn.pressed.connect(_open_chat.bind(i))

	var mc := MarginContainer.new()
	_full(mc)
	mc.mouse_filter = Control.MOUSE_FILTER_IGNORE
	mc.add_theme_constant_override("margin_left", 16)
	mc.add_theme_constant_override("margin_right", 16)
	mc.add_theme_constant_override("margin_top", 8)
	mc.add_theme_constant_override("margin_bottom", 8)
	btn.add_child(mc)

	var hb := HBoxContainer.new()
	hb.mouse_filter = Control.MOUSE_FILTER_IGNORE
	hb.add_theme_constant_override("separation", 14)
	mc.add_child(hb)

	var av := Avatar.new()
	av.custom_minimum_size = Vector2(54, 54)
	av.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	av.set_info(Color(str(c["color"])), str(c["name"]))
	hb.add_child(av)

	var vb := VBoxContainer.new()
	vb.mouse_filter = Control.MOUSE_FILTER_IGNORE
	vb.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	vb.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	vb.add_theme_constant_override("separation", 2)
	hb.add_child(vb)

	var top := HBoxContainer.new()
	top.mouse_filter = Control.MOUSE_FILTER_IGNORE
	vb.add_child(top)
	var nl := _label(str(c["name"]), 17, C_TEXT)
	nl.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	nl.clip_text = true
	top.add_child(nl)
	var tcol := C_GREEN if unread > 0 else C_SUB
	top.add_child(_label(str(last["time"]) if has_msg else "", 12, tcol))

	var bottom := HBoxContainer.new()
	bottom.mouse_filter = Control.MOUSE_FILTER_IGNORE
	bottom.add_theme_constant_override("separation", 4)
	vb.add_child(bottom)
	if has_msg and bool(last["out"]):
		var tk := Ticks.new(int(last["state"]))
		tk.size_flags_vertical = Control.SIZE_SHRINK_CENTER
		bottom.add_child(tk)
	var pl := _label(str(last["text"]) if has_msg else "", 15, C_SUB)
	pl.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	pl.clip_text = true
	pl.text_overrun_behavior = TextServer.OVERRUN_TRIM_ELLIPSIS
	bottom.add_child(pl)
	if unread > 0:
		var badge := PanelContainer.new()
		badge.mouse_filter = Control.MOUSE_FILTER_IGNORE
		badge.add_theme_stylebox_override("panel", _flat(C_GREEN, 12, 7, 1, 7, 1))
		badge.add_child(_label(str(unread), 12, C_BG))
		bottom.add_child(badge)
	return btn


# ───────────── obrazovka: chat ─────────────

func _build_chat_screen() -> void:
	chat_screen = Control.new()
	_full(chat_screen)
	add_child(chat_screen)

	var bg := ColorRect.new()
	bg.color = C_BG
	_full(bg)
	chat_screen.add_child(bg)
	chat_screen.add_child(Wallpaper.new())

	var root := VBoxContainer.new()
	_full(root)
	root.add_theme_constant_override("separation", 0)
	chat_screen.add_child(root)

	var header := PanelContainer.new()
	header.add_theme_stylebox_override("panel", _flat(C_HEADER, 0, 6, 30, 10, 8))
	root.add_child(header)
	var hb := HBoxContainer.new()
	hb.add_theme_constant_override("separation", 8)
	header.add_child(hb)

	var back := Button.new()
	back.text = "←"
	back.flat = true
	back.focus_mode = Control.FOCUS_NONE
	back.custom_minimum_size = Vector2(40, 40)
	back.add_theme_font_size_override("font_size", 26)
	for s in ["normal", "hover", "pressed", "focus"]:
		back.add_theme_stylebox_override(s, StyleBoxEmpty.new())
	for s in ["font_color", "font_hover_color", "font_pressed_color", "font_focus_color"]:
		back.add_theme_color_override(s, C_TEXT)
	back.pressed.connect(_show_list)
	hb.add_child(back)

	avatar = Avatar.new()
	hb.add_child(avatar)
	var vb := VBoxContainer.new()
	vb.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	vb.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	vb.add_theme_constant_override("separation", -2)
	hb.add_child(vb)
	name_label = _label("", 18, C_TEXT)
	status_label = _label("", 13, C_SUB)
	vb.add_child(name_label)
	vb.add_child(status_label)
	hb.add_child(HeaderIcons.new())

	scroll = ScrollContainer.new()
	scroll.size_flags_vertical = Control.SIZE_EXPAND_FILL
	scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	root.add_child(scroll)
	msg_list = VBoxContainer.new()
	msg_list.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	msg_list.add_theme_constant_override("separation", 3)
	scroll.add_child(msg_list)

	var bar := MarginContainer.new()
	for s in ["left", "right", "top", "bottom"]:
		bar.add_theme_constant_override("margin_" + s, 6)
	root.add_child(bar)
	var ib := HBoxContainer.new()
	ib.add_theme_constant_override("separation", 6)
	bar.add_child(ib)
	var field := PanelContainer.new()
	field.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	field.add_theme_stylebox_override("panel", _flat(C_FIELD, 24, 14, 4, 14, 4))
	ib.add_child(field)
	input = LineEdit.new()
	input.placeholder_text = "Napsat zprávu"
	input.add_theme_stylebox_override("normal", StyleBoxEmpty.new())
	input.add_theme_stylebox_override("focus", StyleBoxEmpty.new())
	input.add_theme_color_override("font_color", C_TEXT)
	input.add_theme_color_override("font_placeholder_color", C_SUB)
	input.add_theme_font_size_override("font_size", 17)
	input.text_submitted.connect(_send)
	field.add_child(input)
	var send := Button.new()
	send.custom_minimum_size = Vector2(48, 48)
	send.focus_mode = Control.FOCUS_NONE
	for s in ["normal", "hover", "pressed", "focus"]:
		send.add_theme_stylebox_override(s, _flat(C_GREEN, 24))
	send.add_child(SendIcon.new())
	send.pressed.connect(_send)
	ib.add_child(send)


func _build_secret_button() -> void:
	var secret := Button.new()
	secret.flat = true
	secret.focus_mode = Control.FOCUS_NONE
	for s in ["normal", "hover", "pressed", "focus"]:
		secret.add_theme_stylebox_override(s, StyleBoxEmpty.new())
	secret.anchor_left = 1.0
	secret.anchor_right = 1.0
	secret.anchor_top = 0.0
	secret.anchor_bottom = 0.0
	secret.offset_left = -80
	secret.offset_right = 0
	secret.offset_top = 0
	secret.offset_bottom = 75
	secret.pressed.connect(_open_editor)
	add_child(secret)


# ───────────── navigace ─────────────

func _show_list() -> void:
	cur = -1
	chat_screen.visible = false
	list_screen.visible = true
	_rebuild_list()


func _open_chat(i: int) -> void:
	if i < 0 or i >= contacts.size():
		return
	cur = i
	contacts[i]["unread"] = 0
	list_screen.visible = false
	chat_screen.visible = true
	_refresh_header()
	_rebuild()
	_save()


func _refresh_header() -> void:
	if cur < 0 or cur >= contacts.size():
		return
	var c: Dictionary = contacts[cur]
	name_label.text = str(c["name"])
	status_label.text = str(c["status"])
	status_label.visible = str(c["status"]) != ""
	avatar.set_info(Color(str(c["color"])), str(c["name"]))


func _refresh_all() -> void:
	_rebuild_list()
	if cur >= 0:
		_rebuild()


# ───────────── zpravy ─────────────

func _now() -> String:
	var t := Time.get_time_dict_from_system()
	return "%02d:%02d" % [t.hour, t.minute]


func _inc_time(s: String) -> String:
	var p := s.split(":")
	if p.size() != 2 or not p[0].is_valid_int() or not p[1].is_valid_int():
		return s
	var total := (int(p[0]) * 60 + int(p[1]) + 1) % 1440
	return "%02d:%02d" % [total / 60, total % 60]


func _send(_t: String = "") -> void:
	if cur < 0:
		return
	var t := input.text.strip_edges()
	if t == "":
		return
	input.text = ""
	var m := {"text": t, "time": _now(), "out": true, "state": 0}
	var c: Dictionary = contacts[cur]
	c["messages"].append(m)
	contacts.remove_at(cur)
	contacts.push_front(c)
	cur = 0
	_rebuild()
	get_tree().create_timer(0.8).timeout.connect(func(): m["state"] = 1; _refresh_all())
	get_tree().create_timer(2.0).timeout.connect(func(): m["state"] = 2; _refresh_all(); _save())
	_save()


func _rebuild() -> void:
	if cur < 0 or cur >= contacts.size():
		return
	for c in msg_list.get_children():
		msg_list.remove_child(c)
		c.queue_free()
	msg_list.add_child(_date_chip("DNES"))
	for m in contacts[cur]["messages"]:
		msg_list.add_child(_make_bubble(m))
	await get_tree().process_frame
	await get_tree().process_frame
	scroll.scroll_vertical = int(scroll.get_v_scroll_bar().max_value)


func _date_chip(t: String) -> Control:
	var cc := CenterContainer.new()
	var pc := PanelContainer.new()
	pc.add_theme_stylebox_override("panel", _flat(Color("182229"), 8, 10, 4, 10, 4))
	pc.add_child(_label(t, 12, C_SUB))
	cc.add_child(pc)
	return cc


func _make_bubble(m: Dictionary) -> Control:
	var out: bool = m["out"]
	var txt: String = m["text"]
	var time_txt: String = m["time"]

	var outer := MarginContainer.new()
	outer.add_theme_constant_override("margin_left", 8)
	outer.add_theme_constant_override("margin_right", 8)
	var row := HBoxContainer.new()
	outer.add_child(row)

	var pc := PanelContainer.new()
	pc.size_flags_horizontal = Control.SIZE_EXPAND | (Control.SIZE_SHRINK_END if out else Control.SIZE_SHRINK_BEGIN)
	var sb := _flat(C_OUT if out else C_IN, 10, 9, 5, 9, 4)
	if out:
		sb.corner_radius_top_right = 2
	else:
		sb.corner_radius_top_left = 2
	pc.add_theme_stylebox_override("panel", sb)
	row.add_child(pc)

	var vb := VBoxContainer.new()
	vb.add_theme_constant_override("separation", -2)
	pc.add_child(vb)

	var fs := 16
	var font := ThemeDB.fallback_font
	var max_w := get_viewport_rect().size.x * 0.76 - 18.0
	var ts := font.get_multiline_string_size(txt, HORIZONTAL_ALIGNMENT_LEFT, max_w, fs)
	var tw := font.get_string_size(time_txt, HORIZONTAL_ALIGNMENT_LEFT, -1, 12).x + (24.0 if out else 0.0) + 6.0

	var lbl := _label(txt, fs, C_TEXT)
	lbl.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	lbl.custom_minimum_size.x = clampf(maxf(ts.x + 2.0, tw), 10.0, max_w)
	vb.add_child(lbl)

	var meta := HBoxContainer.new()
	meta.size_flags_horizontal = Control.SIZE_SHRINK_END
	meta.add_theme_constant_override("separation", 4)
	meta.add_child(_label(time_txt, 12, C_SUB))
	if out:
		var tk := Ticks.new(int(m["state"]))
		tk.size_flags_vertical = Control.SIZE_SHRINK_CENTER
		meta.add_child(tk)
	vb.add_child(meta)
	return outer


# ───────────── tajny editor ─────────────

func _build_editor() -> void:
	editor = ColorRect.new()
	(editor as ColorRect).color = Color(0, 0, 0, 0.7)
	_full(editor)
	editor.visible = false
	add_child(editor)

	var margin := MarginContainer.new()
	_full(margin)
	margin.add_theme_constant_override("margin_left", 14)
	margin.add_theme_constant_override("margin_right", 14)
	margin.add_theme_constant_override("margin_top", 50)
	margin.add_theme_constant_override("margin_bottom", 30)
	editor.add_child(margin)

	var panel := PanelContainer.new()
	panel.add_theme_stylebox_override("panel", _flat(C_HEADER, 16, 14, 14, 14, 14))
	margin.add_child(panel)
	var sc := ScrollContainer.new()
	sc.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	panel.add_child(sc)
	var vb := VBoxContainer.new()
	vb.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	vb.add_theme_constant_override("separation", 6)
	sc.add_child(vb)

	vb.add_child(_label("Editor chatů", 20, C_TEXT))

	f_contact = OptionButton.new()
	f_contact.item_selected.connect(_on_contact_selected)
	_row(vb, "Kontakt", f_contact)

	var b_new := Button.new()
	b_new.text = "Nový kontakt"
	b_new.pressed.connect(_new_contact)
	vb.add_child(b_new)
	var b_top := Button.new()
	b_top.text = "Dát kontakt na začátek seznamu"
	b_top.pressed.connect(_contact_to_top)
	vb.add_child(b_top)
	var b_del := Button.new()
	b_del.text = "Smazat kontakt"
	b_del.pressed.connect(_delete_contact)
	vb.add_child(b_del)

	vb.add_child(HSeparator.new())

	f_name = LineEdit.new()
	f_name.text_changed.connect(_on_name)
	_row(vb, "Jméno", f_name)

	f_status = LineEdit.new()
	f_status.text_changed.connect(_on_status)
	_row(vb, "Stav (online / píše… / naposledy online dnes v 21:14)", f_status)

	f_color = ColorPickerButton.new()
	f_color.custom_minimum_size = Vector2(0, 36)
	f_color.color_changed.connect(_on_color)
	_row(vb, "Barva avataru", f_color)

	f_unread = SpinBox.new()
	f_unread.min_value = 0
	f_unread.max_value = 99
	f_unread.value_changed.connect(_on_unread)
	_row(vb, "Nepřečtené zprávy (zelený puntík)", f_unread)

	vb.add_child(HSeparator.new())

	f_text = LineEdit.new()
	f_text.placeholder_text = "Text zprávy"
	_row(vb, "Nová zpráva", f_text)

	f_time = LineEdit.new()
	f_time.text = _now()
	_row(vb, "Čas (HH:MM)", f_time)

	f_dir = OptionButton.new()
	f_dir.add_item("Příchozí (od kontaktu)")
	f_dir.add_item("Odchozí (moje)")
	_row(vb, "Směr", f_dir)

	f_state = OptionButton.new()
	f_state.add_item("Odesláno (1 šedá fajfka)")
	f_state.add_item("Doručeno (2 šedé)")
	f_state.add_item("Přečteno (2 modré)")
	f_state.select(2)
	_row(vb, "Stav odchozí zprávy", f_state)

	var add := Button.new()
	add.text = "Přidat zprávu"
	add.custom_minimum_size = Vector2(0, 44)
	add.pressed.connect(_on_add)
	vb.add_child(add)

	var del_last := Button.new()
	del_last.text = "Smazat poslední zprávu"
	del_last.pressed.connect(_del_last_msg)
	vb.add_child(del_last)

	var clear := Button.new()
	clear.text = "Smazat všechny zprávy kontaktu"
	clear.pressed.connect(_clear_msgs)
	vb.add_child(clear)

	var close := Button.new()
	close.text = "Zavřít"
	close.custom_minimum_size = Vector2(0, 44)
	close.pressed.connect(func(): editor.visible = false)
	vb.add_child(close)


func _row(parent: Node, label_text: String, ctrl: Control) -> void:
	parent.add_child(_label(label_text, 13, C_SUB))
	parent.add_child(ctrl)


func _ec():
	if edit_idx >= 0 and edit_idx < contacts.size():
		return contacts[edit_idx]
	return null


func _open_editor() -> void:
	if cur >= 0:
		edit_idx = cur
	_populate_editor()
	editor.visible = true


func _populate_editor() -> void:
	f_contact.clear()
	for c in contacts:
		var n := str(c["name"])
		f_contact.add_item(n if n != "" else "(bez jména)")
	if contacts.is_empty():
		edit_idx = -1
	else:
		edit_idx = clampi(edit_idx, 0, contacts.size() - 1)
		f_contact.select(edit_idx)
	_load_fields()


func _load_fields() -> void:
	var c = _ec()
	if c == null:
		f_name.text = ""
		f_status.text = ""
		f_unread.set_value_no_signal(0)
		return
	f_name.text = str(c["name"])
	f_status.text = str(c["status"])
	f_color.color = Color(str(c["color"]))
	f_unread.set_value_no_signal(int(c["unread"]))


func _after_edit() -> void:
	_save()
	_refresh_all()
	if cur >= 0:
		_refresh_header()


func _on_contact_selected(i: int) -> void:
	edit_idx = i
	_load_fields()


func _on_name(t: String) -> void:
	var c = _ec()
	if c == null:
		return
	c["name"] = t
	f_contact.set_item_text(edit_idx, t if t != "" else "(bez jména)")
	_after_edit()


func _on_status(t: String) -> void:
	var c = _ec()
	if c == null:
		return
	c["status"] = t
	_after_edit()


func _on_color(col: Color) -> void:
	var c = _ec()
	if c == null:
		return
	c["color"] = col.to_html(false)
	_after_edit()


func _on_unread(v: float) -> void:
	var c = _ec()
	if c == null:
		return
	c["unread"] = int(v)
	_after_edit()


func _new_contact() -> void:
	contacts.append(_mk_contact("Nový kontakt", "online", PALETTE[contacts.size() % PALETTE.size()], 0, []))
	edit_idx = contacts.size() - 1
	_populate_editor()
	_after_edit()


func _contact_to_top() -> void:
	var c = _ec()
	if c == null:
		return
	contacts.remove_at(edit_idx)
	contacts.push_front(c)
	if cur >= 0:
		cur = 0
	edit_idx = 0
	_populate_editor()
	_after_edit()


func _delete_contact() -> void:
	if _ec() == null:
		return
	contacts.remove_at(edit_idx)
	if cur >= 0:
		_show_list()
	_populate_editor()
	_after_edit()


func _on_add() -> void:
	var c = _ec()
	if c == null:
		return
	var t := f_text.text.strip_edges()
	if t == "":
		return
	var incoming := f_dir.selected == 0
	c["messages"].append({"text": t, "time": f_time.text, "out": not incoming, "state": f_state.selected})
	if incoming and cur != edit_idx:
		c["unread"] = int(c["unread"]) + 1
		f_unread.set_value_no_signal(int(c["unread"]))
	f_text.text = ""
	f_time.text = _inc_time(f_time.text)
	_after_edit()


func _del_last_msg() -> void:
	var c = _ec()
	if c == null or c["messages"].is_empty():
		return
	c["messages"].pop_back()
	_after_edit()


func _clear_msgs() -> void:
	var c = _ec()
	if c == null:
		return
	c["messages"].clear()
	_after_edit()


# ───────────── ukladani ─────────────

func _save() -> void:
	var f := FileAccess.open(SAVE_PATH, FileAccess.WRITE)
	if f == null:
		return
	f.store_string(JSON.stringify({"contacts": contacts}))


func _load() -> bool:
	if not FileAccess.file_exists(SAVE_PATH):
		return false
	var d = JSON.parse_string(FileAccess.get_file_as_string(SAVE_PATH))
	if typeof(d) != TYPE_DICTIONARY or not d.has("contacts") or typeof(d["contacts"]) != TYPE_ARRAY:
		return false
	contacts = d["contacts"]
	for c in contacts:
		c["name"] = str(c.get("name", ""))
		c["status"] = str(c.get("status", ""))
		c["color"] = str(c.get("color", "6b7c85"))
		c["unread"] = int(c.get("unread", 0))
		if typeof(c.get("messages")) != TYPE_ARRAY:
			c["messages"] = []
	return true
