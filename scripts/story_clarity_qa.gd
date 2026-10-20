extends "res://scripts/presentation_qa.gd"
func run(game: Node) -> void:
	g=game;p=g.presentation
	output=ProjectSettings.globalize_path("res://qa/story_clarity") if OS.has_feature("editor") else OS.get_executable_path().get_base_dir().path_join("QA/story_clarity")
	DirAccess.make_dir_recursive_absolute(output);g.checkpoint_path=output.path_join("checkpoint.json")
	g.new_game();g.events.chair=true;g.stage=3;g.isolated=true
	g.report_read=true;g.brass_key=true;g.shed_read=true;g.threat.enabled=false
	for size_ in [Vector2i(1920,1080),Vector2i(2560,1440),Vector2i(3440,1440)]:
		render_size(size_);p.show_register();await wait(0.3)
		var view:=g.get_viewport().get_visible_rect().size
		check("1998 register fits "+str(size_),p.card.get_global_rect().end.y<=view.y and p.card_body.get_global_rect().end.y<=view.y)
		await capture("register_"+str(size_.x)+"x"+str(size_.y))
		p.buttons["Eli Ward / PRESENT"].pressed.emit();await wait(0.2)
		check("Eli choice remains recoverable "+str(size_),not g.ended and g.player.active and p.section=="game")
		p.show_register();p.buttons["Simon Ward / PRESENT"].pressed.emit();await wait(0.3)
		check("Simon acknowledgement reaches ending "+str(size_),g.ended and p.section=="ending")
		check("ending fits "+str(size_),p.body.get_global_rect().end.y<=view.y and p.body.get_global_rect().end.x<=view.x)
		var separated:=true;var children: Array=p.body.get_children()
		for i in children.size():
			for j in range(i+1,children.size()):
				if children[i] is Control and children[j] is Control and children[i].get_global_rect().intersects(children[j].get_global_rect()):separated=false
		check("ending blocks do not overlap "+str(size_),separated)
		await capture("ending_"+str(size_.x)+"x"+str(size_.y))
		g.ended=false
	g.ended=true;g.save_game();g.ended=false;g.load_game();await wait(0.3)
	check("completed schema-one save restores clarified ending",g.ended and p.section=="ending")
	var failed:=0
	for item in checks:if not item.passed:failed+=1
	var file:=FileAccess.open(output.path_join("report.json"),FileAccess.WRITE)
	file.store_string(JSON.stringify({"passed":checks.size()-failed,"failed":failed,"checks":checks,"scope":"Focused presentation and existing choice callbacks; not a fresh full-route or human narrative playtest."},"\t"));file.close()
	print("STORY_CLARITY_COMPLETE ",checks.size()-failed," passed ",failed," failed")
	await g.qa_exit(0 if failed==0 else 1)
