extends "res://scripts/presentation_qa.gd"
func run(game: Node) -> void:
	g=game;p=g.presentation
	output=ProjectSettings.globalize_path("res://qa/story_clarity") if OS.has_feature("editor") else OS.get_executable_path().get_base_dir().path_join("QA/story_clarity")
	DirAccess.make_dir_recursive_absolute(output);g.checkpoint_path=output.path_join("checkpoint.json")
	g.new_game();g.events.case_v2=false;g.events.case_v3=false;g.events.chair=true;g.stage=3;g.isolated=true
	g.report_read=true;g.brass_key=true;g.shed_read=true;g.threat.enabled=false
	check("unearned evidence ending refused",not g.finish_attendance("on_record") and not g.ended)
	g.events.memory_confirmed=true;g.isolated=false
	check("electrically live case cannot be closed",not g.finish_attendance("on_record") and not g.ended)
	g.isolated=true;g.report_read=false
	check("unknown 1998 record cannot be closed",not g.finish_attendance("on_record") and not g.ended)
	g.report_read=true
	g.events["return"]=true;g.events.threat_resolved=true
	g.player.position=Vector3(-.7,.04,5.5)
	await wait(.3);g.recount.request()
	for i in 120:
		if g.events.get("recount_complete",false) and not g.recount.active:break
		await wait(.1)
	check("real recount precedes ending layout checks",g.events.get("recount_complete",false) and not g.recount.active,"elapsed="+str(g.recount.clock))
	for size_ in [Vector2i(1920,1080),Vector2i(2560,1440),Vector2i(3440,1440)]:
		g.events.memory_confirmed=false
		render_size(size_);p.show_register();await wait(0.3)
		check("no unexplained evidence option "+str(size_),not p.buttons.has("Attach original / keep Simon's case open"))
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
		check("original ending clears footer "+str(size_),p.buttons["Quit to Desktop"].get_global_rect().end.y<p.footer.get_global_rect().position.y-8)
		await capture("ending_"+str(size_.x)+"x"+str(size_.y))
		g.ended=false
		g.events.memory_confirmed=true;p.show_register();await wait(.3)
		check("earned evidence register fits "+str(size_),p.card_body.get_global_rect().end.y<=view.y)
		await capture("earned_register_"+str(size_.x)+"x"+str(size_.y))
		p.buttons["Attach original / keep Simon's case open"].pressed.emit();await wait(.3)
		check("evidence choice reaches distinct ending "+str(size_),g.ended and g.events.get("ending","")=="on_record" and p.section=="ending")
		check("evidence ending fits "+str(size_),p.body.get_global_rect().end.y<=view.y and p.body.get_global_rect().end.x<=view.x)
		check("evidence ending clears footer "+str(size_),p.buttons["Quit to Desktop"].get_global_rect().end.y<p.footer.get_global_rect().position.y-8)
		check("evidence ending text encoding "+str(size_),verify_text(p.body))
		p.stage.clock=32;await wait(.1)
		check("no title watcher intrudes on evidence ending "+str(size_),not p.stage.shadow.visible and p.stage.porch.light_energy>.7)
		await capture("on_record_"+str(size_.x)+"x"+str(size_.y))
		g.save_game();g.ended=false;g.events.erase("ending");g.load_game();await wait(.15)
		check("evidence outcome survives completed save "+str(size_),g.ended and g.events.get("ending","")=="on_record" and p.footer.text.contains("DISPUTED"))
		g.ended=false
	g.ended=true;g.save_game();g.ended=false;g.load_game();await wait(0.3)
	check("completed schema-one save restores evidence ending",g.ended and p.section=="ending" and g.events.get("ending","")=="on_record")
	var legacy: Dictionary=g.save_data();legacy.events.erase("ending");g.ended=false;g.apply_save(legacy);await wait(.15)
	check("legacy completed save keeps original ending",g.ended and p.footer.text.contains("CORRECTED"))
	var failed:=0
	for item in checks:if not item.passed:failed+=1
	var file:=FileAccess.open(output.path_join("report.json"),FileAccess.WRITE)
	file.store_string(JSON.stringify({"passed":checks.size()-failed,"failed":failed,"checks":checks,"scope":"Focused presentation and existing choice callbacks; not a fresh full-route or human narrative playtest."},"\t"));file.close()
	print("STORY_CLARITY_COMPLETE ",checks.size()-failed," passed ",failed," failed")
	await g.qa_exit(0 if failed==0 else 1)
