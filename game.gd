extends Node3D
# The whole playable vertical slice, no external addons.
var player: CharacterBody3D
var camera: Camera3D
var neighbor: Node3D
var sofa: StaticBody3D
var remote: StaticBody3D
var clock_label: Label3D
var hint: Label
var objective: Label
var inventory: Label
var dialogue: PanelContainer
var speech: Label
var speaker: Label
var fade: ColorRect
var ending: PanelContainer
var pause_label: Label
var head: Node3D
var arms: Array[Node3D] = []
var step := 0 # 0 intro, 1 sofa, 2 remote, 3 clock, 4 neighbor, 5 done
var elapsed := 0.0
var talking := false
var waking := true
var paused := false
var moving_sofa := false
var lines: Array[String] = []
var after_dialogue := ""
var pitch := 0.0
var target: Node
var clock_origin := Vector3(-0.87,0.934,-1.67)
var ambiance: AudioStreamPlayer
var tv_screen: MeshInstance3D
var tv_material: Material

func b(x: float, y: float, z: float) -> Vector3:
 return Vector3(x,z,-y)

func _ready() -> void:
 randomize()
 var env := WorldEnvironment.new()
 var e := Environment.new()
 e.background_mode=Environment.BG_COLOR;e.background_color=Color("252b2d")
 e.ambient_light_source=Environment.AMBIENT_SOURCE_COLOR;e.ambient_light_color=Color("c4b396");e.ambient_light_energy=0.52
 e.tonemap_mode=Environment.TONE_MAPPER_FILMIC
 env.environment=e;add_child(env)
 var room := $Room as Node3D
 tune_materials(room)
 for spec in [[b(0,0,-.10),Vector3(6.6,.2,5.8)],[b(-3.3,0,1.55),Vector3(.2,3.1,5.8)],[b(3.3,0,1.55),Vector3(.2,3.1,5.8)],[b(0,2.9,1.55),Vector3(6.6,3.1,.2)],[b(0,-2.9,1.55),Vector3(6.6,3.1,.2)],[b(-2.15,.78,.40),Vector3(1.5,.80,2.3)],[b(.98,2.47,1.20),Vector3(3.42,2.4,.54)],[b(2.62,.63,.42),Vector3(.67,.84,1.55)],[b(1.65,.61,.44),Vector3(.50,.88,.50)],[b(.08,-1.25,.25),Vector3(1.14,.50,.67)],[b(-1.02,1.81,.39),Vector3(.65,.78,.56)],[b(-1.1,-2.28,.36),Vector3(.62,.72,.4)]]:
  body_box("Solid",spec[0],spec[1])
 add_light(b(0,.1,2.65),Color("ffd097"),1.7,5)
 add_light(b(2.9,.8,2),Color("93b9c4"),1.2,3.4)
 add_light(b(-1.07,1.81,1.08),Color("ffc276"),.85,2.0)
 add_light(b(2.7,-2.26,1.53),Color("ffb969"),.8,2.2)
 make_sofa();make_neighbor();make_remote()
 var clock := body_box("Clock",clock_origin,Vector3(.22,.30,.22));clock.collision_layer=2;clock.set_meta("action","clock")
 clock_label=Label3D.new();clock.add_child(clock_label);clock_label.position=Vector3(0,.145,.12);clock_label.pixel_size=.0012;clock_label.font_size=24;clock_label.modulate=Color("f4dca0");clock_label.no_depth_test=false
 var tv := body_box("Television",b(1.04,2.11,1.1),Vector3(1.15,.73,.08));tv.collision_layer=2;tv.set_meta("action","tv")
 player=CharacterBody3D.new();player.name="Player";add_child(player);player.position=b(-2.15,1.29,.0)
 var shape := CollisionShape3D.new();var capsule := CapsuleShape3D.new();capsule.radius=.20;capsule.height=1.55;shape.shape=capsule;shape.position.y=.80;player.add_child(shape)
 camera=Camera3D.new();player.add_child(camera);camera.position.y=1.03;camera.fov=76;camera.near=.04
 camera.look_at(b(-1.05,.82,1.43));player.rotation.y=camera.rotation.y;camera.rotation.y=0;pitch=camera.rotation.x
 make_ui();make_audio()
 Input.mouse_mode=Input.MOUSE_MODE_CAPTURED
 fade.color.a=1
 var tw := create_tween();tw.tween_property(fade,"color:a",0.,2.3)
 tw.tween_callback(func(): waking=false;start_dialogue(["СОСЕД|Проснулся? Я уже думал, до вечера проспишь.","ВЫ|Ты давно так стоишь и смотришь на меня?","СОСЕД|А что ещё делать? Телевизор хочу посмотреть. Пульт куда-то пропал.","СОСЕД|Вроде за диван свалился. Подвинь его, пожалуйста."],"intro"))
 update_task()

func tune_materials(n: Node) -> void:
 if n is MeshInstance3D:
  if str(n.name).to_lower().replace("_"," ").contains("low resolution tv picture"):
   tv_screen=n;tv_material=n.get_active_material(0);n.material_override=material("151c1b")
  for i in n.mesh.get_surface_count():
   var m = n.get_active_material(i)
   if m is BaseMaterial3D:
	m.texture_filter=BaseMaterial3D.TEXTURE_FILTER_NEAREST;m.roughness=1.;m.metallic=0.;m.specular_mode=BaseMaterial3D.SPECULAR_DISABLED
 for c in n.get_children():tune_materials(c)

func material(color: String) -> StandardMaterial3D:
 var m := StandardMaterial3D.new();m.albedo_color=Color(color);m.roughness=1.;m.specular_mode=BaseMaterial3D.SPECULAR_DISABLED;return m

func box(parent: Node3D, pos: Vector3, size: Vector3, color: String) -> MeshInstance3D:
 var o := MeshInstance3D.new();var mesh := BoxMesh.new();mesh.size=size;o.mesh=mesh;o.material_override=material(color);parent.add_child(o);o.position=pos;return o

func sphere(parent: Node3D, pos: Vector3, size: Vector3, color: String) -> MeshInstance3D:
 var o := MeshInstance3D.new();var mesh := SphereMesh.new();mesh.radial_segments=8;mesh.rings=4;mesh.radius=.5;mesh.height=1.;o.mesh=mesh;o.scale=size;o.material_override=material(color);parent.add_child(o);o.position=pos;return o

func body_box(label: String, pos: Vector3, size: Vector3) -> StaticBody3D:
 var o := StaticBody3D.new();o.name=label;add_child(o);o.position=pos
 var c := CollisionShape3D.new();var sh := BoxShape3D.new();sh.size=size;c.shape=sh;o.add_child(c);return o

func add_light(pos: Vector3, col: Color, energy: float, radius: float) -> void:
 var l := OmniLight3D.new();l.position=pos;l.light_color=col;l.light_energy=energy;l.omni_range=radius;l.shadow_enabled=true;add_child(l)

func make_sofa() -> void:
 sofa=body_box("MovableSofa",b(2.02,-1.98,0),Vector3(1.78,.96,.86));sofa.get_child(0).position.y=.48;sofa.collision_layer=3;sofa.set_meta("action","sofa")
 box(sofa,Vector3(0,.33,0),Vector3(1.78,.3,.82),"405e56")
 box(sofa,Vector3(0,.72,.31),Vector3(1.75,.76,.20),"426257")
 for x in [-.78,.78]:
  box(sofa,Vector3(x,.56,0),Vector3(.19,.40,.86),"45665a")
  box(sofa,Vector3(x,.79,0),Vector3(.20,.055,.77),"654630")
 for x in [-.37,.37]:box(sofa,Vector3(x,.53,-.06),Vector3(.67,.17,.63),"567366")
 for x in [-.68,.68]:
  for z in [-.29,.29]:box(sofa,Vector3(x,.12,z),Vector3(.08,.24,.08),"483322")
 var pillow := box(sofa,Vector3(.43,.81,.08),Vector3(.40,.37,.13),"a88145");pillow.rotation.z=-.13

func make_neighbor() -> void:
 neighbor=Node3D.new();neighbor.name="Neighbor_Misha";add_child(neighbor);neighbor.position=b(-1.07,.58,0)
 # Low-poly adult in a worn cardigan; forward = +Z.
 box(neighbor,Vector3(0,.57,0),Vector3(.31,.20,.23),"524c40")
 for x in [-.105,.105]:
  box(neighbor,Vector3(x,.28,0),Vector3(.13,.52,.15),"524c40")
  box(neighbor,Vector3(x,.055,.06),Vector3(.16,.11,.27),"392f28")
 box(neighbor,Vector3(0,1.03,0),Vector3(.43,.66,.24),"80734c")
 box(neighbor,Vector3(0,1.06,.126),Vector3(.12,.56,.018),"c2b797")
 for y in [.89,1.03,1.17]:box(neighbor,Vector3(.08,y,.14),Vector3(.018,.018,.01),"342d22")
 for x in [-.28,.28]:
  var arm := Node3D.new();neighbor.add_child(arm);arm.position=Vector3(x,1.26,0);arms.append(arm)
  box(arm,Vector3(0,-.22,0),Vector3(.135,.44,.15),"80734c");sphere(arm,Vector3(0,-.48,0),Vector3(.12,.18,.12),"b79678")
 head=Node3D.new();neighbor.add_child(head);head.position.y=1.49
 sphere(head,Vector3.ZERO,Vector3(.31,.39,.29),"b79678")
 sphere(head,Vector3(0,.125,-.045),Vector3(.32,.21,.27),"514537")
 box(head,Vector3(0,-.01,.16),Vector3(.052,.075,.057),"ac876d")
 for x in [-.071,.071]:
  box(head,Vector3(x,.043,.131),Vector3(.061,.023,.022),"302d27")
  box(head,Vector3(x,.083,.128),Vector3(.07,.015,.018),"514537")
 box(head,Vector3(0,-.092,.131),Vector3(.083,.012,.015),"614739")
 var hit := StaticBody3D.new();neighbor.add_child(hit);hit.collision_layer=3;hit.set_meta("action","neighbor")
 var cs := CollisionShape3D.new();var sh := BoxShape3D.new();sh.size=Vector3(.56,1.70,.36);cs.shape=sh;cs.position.y=.85;hit.add_child(cs)

func make_remote() -> void:
 remote=body_box("RemoteBehindSofa",b(2.03,-2.59,.07),Vector3(.24,.16,.31));remote.collision_layer=2;remote.set_meta("action","remote")
 box(remote,Vector3.ZERO,Vector3(.084,.029,.20),"292e2d")
 for i in 12:box(remote,Vector3(-.022+(i%3)*.022,.019,-.064+(i/3)*.032),Vector3(.014,.009,.017),"b2aa92" if i>0 else "9f4e36")
 remote.rotation.y=.28

func make_ui() -> void:
 var layer := CanvasLayer.new();add_child(layer)
 var ui := Control.new();ui.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT);ui.mouse_filter=Control.MOUSE_FILTER_IGNORE;layer.add_child(ui)
 objective=label(ui,Vector2(30,26),Vector2(850,80),22);inventory=label(ui,Vector2(30,108),Vector2(550,40),17);inventory.modulate=Color("cfbc91")
 var cross := Label.new();ui.add_child(cross);cross.text="·";cross.set_anchors_and_offsets_preset(Control.PRESET_CENTER);cross.add_theme_font_size_override("font_size",30)
 hint=Label.new();ui.add_child(hint);hint.set_anchors_and_offsets_preset(Control.PRESET_CENTER_BOTTOM);hint.position+=Vector2(-390,-104);hint.size=Vector2(780,70);hint.horizontal_alignment=HORIZONTAL_ALIGNMENT_CENTER;hint.add_theme_font_size_override("font_size",22)
 var help := label(ui,Vector2(30,820),Vector2(1090,28),15);help.text="WASD — движение     Мышь — взгляд     E / ЛКМ — действие, следующая реплика     Esc — пауза";help.modulate=Color("c1bba7")
 dialogue=PanelContainer.new();ui.add_child(dialogue);dialogue.position=Vector2(100,586);dialogue.size=Vector2(952,195)
 var style := StyleBoxFlat.new();style.bg_color=Color(.07,.075,.066,.97);style.border_color=Color("95815a");style.set_border_width_all(2);style.content_margin_left=24;style.content_margin_top=18;style.content_margin_right=24;style.content_margin_bottom=20;dialogue.add_theme_stylebox_override("panel",style)
 var col := VBoxContainer.new();dialogue.add_child(col);speaker=Label.new();col.add_child(speaker);speaker.add_theme_font_size_override("font_size",19);speaker.modulate=Color("d2ac6d")
 speech=Label.new();col.add_child(speech);speech.autowrap_mode=TextServer.AUTOWRAP_WORD_SMART;speech.add_theme_font_size_override("font_size",24);speech.custom_minimum_size=Vector2(900,102)
 var next := Label.new();col.add_child(next);next.text="E / ЛКМ  ·  продолжить";next.add_theme_font_size_override("font_size",16);dialogue.hide()
 ending=PanelContainer.new();ui.add_child(ending);ending.position=Vector2(230,230);ending.size=Vector2(690,335);ending.add_theme_stylebox_override("panel",style)
 var endtext := Label.new();ending.add_child(endtext);endtext.text="ПЕРВЫЙ ВЕЧЕР\n\nУровень 1 пройден\n\nПульт работает. Будильник всё ещё идёт.\n\nEnter — пройти заново";endtext.horizontal_alignment=HORIZONTAL_ALIGNMENT_CENTER;endtext.add_theme_font_size_override("font_size",25);ending.hide()
 pause_label=label(ui,Vector2(330,365),Vector2(560,100),26);pause_label.text="ПАУЗА\nEsc — продолжить";pause_label.horizontal_alignment=HORIZONTAL_ALIGNMENT_CENTER;pause_label.hide()
 fade=ColorRect.new();ui.add_child(fade);fade.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT);fade.color=Color.BLACK;fade.mouse_filter=Control.MOUSE_FILTER_IGNORE

func label(parent: Node, pos: Vector2, size: Vector2, font: int) -> Label:
 var l := Label.new();parent.add_child(l);l.position=pos;l.size=size;l.add_theme_font_size_override("font_size",font);l.add_theme_color_override("font_shadow_color",Color.BLACK);l.add_theme_constant_override("shadow_offset_x",2);l.add_theme_constant_override("shadow_offset_y",2);l.autowrap_mode=TextServer.AUTOWRAP_WORD_SMART;return l

func _unhandled_input(event: InputEvent) -> void:
 if event is InputEventKey and event.pressed and not event.echo:
  if event.keycode==KEY_ESCAPE:
   paused=not paused;pause_label.visible=paused;Input.mouse_mode=Input.MOUSE_MODE_VISIBLE if paused else Input.MOUSE_MODE_CAPTURED;return
  if event.keycode==KEY_ENTER and step==5:get_tree().reload_current_scene();return
 if paused:return
 if event is InputEventMouseMotion and not waking and not talking and step<5:
  player.rotate_y(-event.relative.x*.0026);pitch=clamp(pitch-event.relative.y*.0026,-1.22,1.22);camera.rotation.x=pitch
 var action: bool = (event is InputEventKey and event.pressed and not event.echo and event.keycode==KEY_E) or (event is InputEventMouseButton and event.pressed and event.button_index==MOUSE_BUTTON_LEFT)
 if action and not waking:
  if talking:next_line()
  elif target and step<5:interact(str(target.get_meta("action","")))

func _physics_process(delta: float) -> void:
 if not is_instance_valid(player):return
 if paused:return
 elapsed+=delta
 var remaining := maxi(0,1200-int(elapsed));clock_label.text="%02d:%02d" % [remaining/60,remaining%60]
 var to_player := player.global_position-neighbor.global_position
 if step<5:
  neighbor.rotation.y=atan2(to_player.x,to_player.z)
  head.rotation.z=sin(elapsed*.8)*.022
 for arm in arms:arm.rotation.x=sin(elapsed*1.5)*.025
 if waking or talking or step==5:hint.text="";return
 var v := Vector2(float(Input.is_physical_key_pressed(KEY_D))-float(Input.is_physical_key_pressed(KEY_A)),float(Input.is_physical_key_pressed(KEY_S))-float(Input.is_physical_key_pressed(KEY_W))).normalized()
 var direction := player.global_transform.basis * Vector3(v.x,0,v.y)
 player.velocity.x=direction.x*1.65;player.velocity.z=direction.z*1.65
 if not player.is_on_floor():player.velocity.y-=9.8*delta
 else:player.velocity.y=0
 player.move_and_slide()
 var from := camera.global_position;var to := from-camera.global_transform.basis.z*2.35
 var query := PhysicsRayQueryParameters3D.create(from,to,3,[player.get_rid()]);var hit := get_world_3d().direct_space_state.intersect_ray(query)
 target=hit.get("collider") if not hit.is_empty() else null
 hint.text=""
 if target and target.has_meta("action"):
  var a := str(target.get_meta("action"))
  match a:
   "neighbor":hint.text="E  ·  Поговорить с соседом"
   "sofa":hint.text="E  ·  Подвинуть диван" if step==1 else "Диван уже отодвинут"
   "remote":hint.text="E  ·  Подобрать пульт" if step==2 else ""
   "clock":hint.text="E  ·  Достать батарейки" if step==3 else "E  ·  Осмотреть будильник"
   "tv":hint.text="E  ·  Телевизор"
 else:target=null

func interact(action: String) -> void:
 match action:
  "sofa":
   if step==1 and not moving_sofa:
	moving_sofa=true;target=null;hint.text="";play_tone(95,.35)
	if player.position.distance_to(sofa.position)<1.6:player.position=b(.65,-.25,.03)
	var tw := create_tween();tw.set_trans(Tween.TRANS_SINE);tw.tween_property(sofa,"position",sofa.position+b(-.65,.62,0),1.35)
	tw.tween_callback(func():step=2;moving_sofa=false;update_task())
  "remote":
   if step==2:
	remote.hide();remote.collision_layer=0;step=3;play_tone(370,.10)
	start_dialogue(["ВЫ|Нашёл. Только он не работает… Внутри нет батареек.","СОСЕД|В будильнике посмотри. Там вроде такие же. Только не сбей время."],"none");update_task()
  "clock":
   if step==3:
	step=4;play_tone(210,.16);update_task()
	start_dialogue(["ВЫ|Две батарейки. Подойдут. Вставлю их в пульт.","ВЫ|Погоди… Я вынул обе. Почему будильник всё ещё идёт?"],"none")
   elif step>=4:start_dialogue(["ВЫ|Батареек нет. Но отсчёт продолжается."],"none")
   else:start_dialogue(["ВЫ|Будильник отсчитывает время. Лучше пока не трогать."],"none")
  "neighbor":
   if step==4:start_dialogue(["СОСЕД|Не смотри на часы. Они не от батареек идут.","ВЫ|А от чего?","СОСЕД|Садись. Передача уже начинается."],"finish")
   elif step==1:start_dialogue(["СОСЕД|Пульт за диваном. Подвинь диван, и увидишь."],"none")
   elif step==2:start_dialogue(["СОСЕД|Вот он, на полу у стены. Подбери."],"none")
   elif step==3:start_dialogue(["СОСЕД|Возьми батарейки из будильника возле кровати."],"none")
  "tv":start_dialogue(["ВЫ|Без рабочего пульта его не включить."],"none")

func start_dialogue(texts: Array[String], callback: String) -> void:
 lines=texts.duplicate();after_dialogue=callback;talking=true;dialogue.show();hint.text="";next_line()

func next_line() -> void:
 if not lines.is_empty():
  var parts: PackedStringArray = str(lines.pop_front()).split("|",true,1);speaker.text=parts[0];speech.text=parts[1];return
 talking=false;dialogue.hide()
 if after_dialogue=="intro":
  step=1;player.position=b(-1.14,.10,.03);camera.position.y=1.58;pitch=0.;camera.rotation.x=0.;player.rotation.y=0.;update_task()
 elif after_dialogue=="finish":
  step=5;update_task();
  if tv_screen:tv_screen.material_override=tv_material
  var direction := b(1.04,2.38,0)-neighbor.position;neighbor.rotation.y=atan2(direction.x,direction.z)
  ending.show();Input.mouse_mode=Input.MOUSE_MODE_VISIBLE;play_tone(440,.25)

func update_task() -> void:
 var tasks := ["ПЕРВЫЙ ВЕЧЕР\nВы просыпаетесь…","ПЕРВЫЙ ВЕЧЕР\nНайти пульт: подвинуть диван","ПЕРВЫЙ ВЕЧЕР\nПодобрать пульт за диваном","ПЕРВЫЙ ВЕЧЕР\nНайти батарейки — осмотреть будильник","ПЕРВЫЙ ВЕЧЕР\nСпросить соседа о будильнике","ПЕРВЫЙ ВЕЧЕР\nУровень завершён"]
 objective.text=tasks[step]
 inventory.text="" if step<3 else ("КАРМАН: пульт · без батареек" if step==3 else "КАРМАН: пульт · 2 батарейки установлены")

func make_audio() -> void:
 ambiance=AudioStreamPlayer.new();add_child(ambiance);ambiance.volume_db=-30
 var stream := AudioStreamWAV.new();stream.format=AudioStreamWAV.FORMAT_16_BITS;stream.mix_rate=22050;stream.loop_mode=AudioStreamWAV.LOOP_FORWARD;stream.loop_end=22050
 var data := PackedByteArray();data.resize(44100)
 for i in 22050:
  var sample := int((sin(float(i)*TAU*50/22050)*.22+randf_range(-.035,.035))*32767);data.encode_s16(i*2,sample)
 stream.data=data;ambiance.stream=stream;ambiance.play()

func play_tone(hz: float, duration: float) -> void:
 var audio := AudioStreamPlayer.new();add_child(audio);audio.volume_db=-23
 var wave := AudioStreamWAV.new();wave.format=AudioStreamWAV.FORMAT_16_BITS;wave.mix_rate=22050
 var count := int(duration*22050);var data := PackedByteArray();data.resize(count*2)
 for i in count:data.encode_s16(i*2,int(sin(float(i)*TAU*hz/22050)*(1.-float(i)/count)*15000))
 wave.data=data;audio.stream=wave;audio.finished.connect(audio.queue_free);audio.play()
