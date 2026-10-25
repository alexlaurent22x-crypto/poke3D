extends SceneTree
const Poker = preload("res://scripts/poker.gd")
var checks := 0
var failures := 0

func check(condition: bool, message: String) -> void:
	checks += 1
	if not condition:
		failures += 1
		printerr("FAIL: " + message)

func cards(text: String) -> Array:
	var result: Array = []
	for token in text.split(" "):
		var rank := "23456789TJQKA".find(token[0])
		var suit := "shdc".find(token[1])
		result.append(suit * 13 + rank)
	return result

func score(text: String) -> int:
	return Poker.evaluate(cards(text))

func setup_betting(stacks: Array, bets: Array, current: int, minimum: int, actor: int):
	var g = Poker.new(1)
	g.finished = false
	g.dealer = 3
	g.actor = actor
	g.current_bet = current
	g.min_raise = minimum
	g.deck = range(40)
	for i in 4:
		g.players[i].stack = stacks[i]
		g.players[i].bet = bets[i]
		g.players[i].total = bets[i]
		g.players[i].hole = [40 + i * 2, 41 + i * 2]
		g.players[i].folded = stacks[i] == 0 and bets[i] == 0
	return g

func _initialize() -> void:
	var examples := ["As Kd 9h 6c 3s", "As Ad 9h 6c 3s", "As Ad 9h 9c 3s", "As Ad Ah 6c 3s", "As 2d 3h 4c 5s", "As Js 9s 6s 3s", "As Ad Ah 6c 6s", "As Ad Ah Ac 3s", "9s Ts Js Qs Ks"]
	var last := -1
	for category in 9:
		var value := score(examples[category])
		check(value / 759375 == category, "category %d" % category)
		check(value > last, "category ordering %d" % category)
		last = value
	check(score("As 2d 3h 4c 5s") < score("2s 3d 4h 5c 6s"), "wheel below six high")
	check(score("As Ad Kc Qd 9s") > score("Ah Ac Kd Qs 8s"), "pair kicker")
	check(score("As Ks Qs Js Ts 2c 3d") == score("As Ks Qs Js Ts"), "best five of seven")
	check(score("As Ad Ah Ks Kd Kh 2c") == score("As Ad Ah Ks Kd"), "two trips make full house")
	check(score("As Ad Ks Kd Qh Qc 2c") == score("As Ad Ks Kd Qh"), "three pairs choose best two")
	check(score("As Kd Qh Jc Ts 2d 3s") == score("Ah Kc Qd Js Tc 4h 5c"), "board tie ignores suits")
	var g = Poker.new(5)
	check(g.new_hand(), "start hand")
	check(g.actor == 3, "UTG starts preflop")
	check(g.players[1].bet == 10 and g.players[2].bet == 20, "blinds")
	var all_cards: Array = []
	for p in g.players: all_cards.append_array(p.hole)
	check(all_cards.size() == 8 and g.deck.size() == 44, "dealing")
	g.act("check_call")
	g.act("check_call")
	g.act("check_call")
	check(g.actor == 2 and g.street == 0, "big blind has option")
	g.act("check_call")
	check(g.street == 1 and g.actor == 1 and g.board.size() == 3, "flop starts left of dealer")
	var before: int = g.players[g.actor].stack
	check(not g.act("raise", 1), "reject undersized non-allin bet")
	check(g.players[g.actor].stack == before, "invalid action is atomic")
	# Full raise reopens action; one short all-in does not.
	g = setup_betting([900, 50, 900, 0], [100, 100, 100, 0], 100, 100, 1)
	g.players[0].acted = true
	g.players[0].last_bet = 100
	check(g.act("raise", 150), "allow short all-in")
	check(not g.can_raise(0), "short all-in does not reopen")
	check(g.can_raise(2), "unacted player can raise")
	check(g.act("raise", 250), "full raise after short all-in")
	check(g.can_raise(0), "full raise reopens")
	g = setup_betting([900, 50, 100, 900], [100, 100, 100, 100], 100, 100, 1)
	g.players[0].last_bet = 100
	g.act("raise", 150)
	g.act("raise", 200)
	check(g.can_raise(0), "cumulative short raises reopen at full increment")
	# A short opening all-in can be completed to the minimum opening bet.
	g = setup_betting([100, 5, 100, 100], [0, 0, 0, 0], 0, 20, 1)
	g.players[0].acted = true
	g.players[0].last_bet = 0
	check(g.act("raise", 5), "short opening all-in")
	check(not g.can_raise(0), "short opener does not reopen checked player")
	check(g.minimum_target() == 20, "minimum opening completion is big blind")
	check(g.act("raise", 20), "complete short opener to big blind")
	check(g.min_raise == 20 and g.can_raise(0), "full opening bet reopens checker")
	g = setup_betting([100, 5, 100, 100], [0, 0, 0, 0], 0, 20, 1)
	g.act("raise", 5)
	g.act("raise", 50)
	check(g.min_raise == 45 and g.minimum_target() == 95, "raise increment above short opener")
	# Unequal all-ins, side pot, and uncalled surplus returned.
	g = Poker.new(1)
	g.finished = false
	g.board = cards("2s 3d 7h 8c 9s")
	var holes := ["As Ad", "Ks Kd", "Qs Qd", "Js Jd"]
	var totals := [100, 200, 300, 300]
	for i in 4:
		g.players[i].hole = cards(holes[i])
		g.players[i].total = totals[i]
		g.players[i].stack = 0
	g.players[3].folded = true
	g.showdown()
	check(g.players[0].stack == 400, "main pot best short stack")
	check(g.players[1].stack == 300, "first side pot")
	check(g.players[2].stack == 200, "second side pot includes folded chips")
	check(g.players[3].stack == 0, "folded hand never wins")
	g = Poker.new(1)
	g.finished = false
	g.board = cards("As Ks Qs Js Ts")
	g.dealer = 0
	for p in g.players:
		p.hole = cards("2d 3h")
		p.total = 1
		p.stack = 0
	g.players[3].folded = true
	g.showdown()
	check(g.players[1].stack == 2 and g.players[0].stack == 1 and g.players[2].stack == 1, "odd chip clockwise from button")
	g = Poker.new(1)
	g.players[1].stack = 0
	g.players[2].stack = 0
	g.new_hand()
	check(g.dealer == 0 and g.actor == 0 and g.players[0].bet == 10, "heads-up button small blind starts")
	g.act("check_call")
	g.act("check_call")
	check(g.actor == 3 and g.street == 1, "heads-up big blind first postflop")
	# Repeated deterministic tournaments: conservation, unique cards, termination, AI legal actions.
	var hands := 0
	for seed_value in 20:
		g = Poker.new(seed_value)
		for hand in 30:
			if not g.new_hand(): break
			hands += 1
			var actions := 0
			while not g.finished and actions < 180:
				var old_actor: int = g.actor
				var old_street: int = g.street
				if g.actor == 0:
					var roll: float = g.rng.randf()
					if roll < 0.16 and g.can_raise(0):
						g.act("raise", mini(g.current_bet + g.min_raise * 2, g.players[0].stack + g.players[0].bet))
					elif roll > 0.9 and g.to_call(0) > 0: g.act("fold")
					else: g.act("check_call")
				else: g.ai_action()
				check(g.finished or g.actor != old_actor or g.street != old_street, "action progresses")
				actions += 1
			check(g.finished, "hand terminates")
			var total := 0
			var seen := {}
			for p in g.players:
				total += p.stack
				check(p.stack >= 0, "nonnegative chips")
				for c in p.hole: seen[c] = true
			for c in g.board: seen[c] = true
			var dealt: int = g.board.size()
			for p in g.players: dealt += p.hole.size()
			check(seen.size() == dealt, "cards unique")
			check(total == 4000, "chips conserved")
	print("Poker: %d checks, %d hands, %d failures" % [checks, hands, failures])
	quit(1 if failures else 0)
