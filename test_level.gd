extends SceneTree
func _initialize() -> void:
 call_deferred("run")
func run() -> void:
 var game = load("res://main.tscn").instantiate()
 root.add_child(game)
 await create_timer(2.7).timeout
 assert(game.talking,"Intro not started")
 while game.talking:game.next_line()
 assert(game.step==1,"Intro transition")
 game.interact("clock")
 while game.talking:game.next_line()
 assert(game.step==1,"Clock prematurely advanced puzzle")
 game.interact("sofa")
 await create_timer(1.5).timeout
 assert(game.step==2,"Sofa failed")
 game.interact("remote")
 while game.talking:game.next_line()
 assert(game.step==3 and game.remote.collision_layer==0,"Remote pickup failed")
 var before = game.elapsed
 game.interact("clock")
 while game.talking:game.next_line()
 await create_timer(1.1).timeout
 assert(game.elapsed>before+1 and game.step==4,"Clock stopped")
 game.interact("neighbor")
 while game.talking:game.next_line()
 assert(game.step==5 and game.ending.visible,"Completion failed")
 print("LEVEL_TEST_PASS: intro > sofa > remote > batteries > ticking clock > neighbor > completed")
 quit()
