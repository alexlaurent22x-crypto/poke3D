class_name PokerGame
extends RefCounted
## Offline no-limit Hold'em. Amounts are integer chips; raise targets are street totals.
signal changed
const NAMES = ["Vous", "Gabriel", "Élise", "Nora"]
const STREETS = ["Préflop", "Flop", "Turn", "River"]
const HAND_NAMES = ["Carte haute", "Paire", "Double paire", "Brelan", "Quinte", "Couleur", "Full", "Carré", "Quinte flush"]
var rng := RandomNumberGenerator.new()
var players: Array = []
var board: Array = []
var deck: Array = []
var log_lines: Array[String] = []
var dealer := -1
var actor := -1
var street := 0
var current_bet := 0
var min_raise := 20
var hand_no := 0
var finished := true
var result := ""
var revealed := false
var paid_pot := 0

func _init(seed_value: int = -1) -> void:
	if seed_value < 0: rng.randomize()
	else: rng.seed = seed_value
	for name_value in NAMES:
		players.append({"name": name_value, "stack": 1000, "hole": [], "bet": 0, "total": 0, "folded": false, "acted": false, "last_bet": -1})

func note(message: String) -> void:
	log_lines.append(message)
	if log_lines.size() > 60: log_lines.pop_front()

func live_ids() -> Array:
	var ids: Array = []
	for i in players.size():
		if not players[i].folded: ids.append(i)
	return ids

func next_funded(from: int) -> int:
	for offset in range(1, players.size() + 1):
		var i := (from + offset) % players.size()
		if players[i].stack > 0: return i
	return -1

func new_hand() -> bool:
	if not finished: return false
	var funded := 0
	for p in players:
		if p.stack > 0: funded += 1
	if funded < 2: return false
	hand_no += 1
	dealer = next_funded(dealer)
	board.clear()
	deck = range(52)
	for i in range(51, 0, -1):
		var j := rng.randi_range(0, i)
		var tmp = deck[i]
		deck[i] = deck[j]
		deck[j] = tmp
	street = 0
	current_bet = 20
	min_raise = 20
	finished = false
	revealed = false
	paid_pot = 0
	result = ""
	for p in players:
		p.hole = []
		p.bet = 0
		p.total = 0
		p.folded = p.stack == 0
		p.acted = false
		p.last_bet = -1
	for round_no in 2:
		for offset in range(1, players.size() + 1):
			var i := (dealer + offset) % players.size()
			if not players[i].folded: players[i].hole.append(deck.pop_back())
	var sb := dealer if funded == 2 else next_funded(dealer)
	var bb := next_funded(sb)
	pay(sb, 10)
	pay(bb, 20)
	note("Main %d · bouton %s · blinds 10 / 20" % [hand_no, players[dealer].name])
	actor = bb
	advance()
	changed.emit()
	return true

func pay(i: int, amount: int) -> void:
	var value: int = mini(amount, players[i].stack)
	players[i].stack -= value
	players[i].bet += value
	players[i].total += value

func pot() -> int:
	var amount := 0
	for p in players: amount += p.total
	return amount

func to_call(i: int) -> int:
	return maxi(0, current_bet - players[i].bet)

func can_raise(i: int) -> bool:
	var p = players[i]
	if p.folded or p.stack <= to_call(i): return false
	var opposition := false
	for j in players.size():
		if j != i and not players[j].folded and players[j].stack > 0: opposition = true
	return opposition and (p.last_bet < 0 or current_bet - p.last_bet >= min_raise)

func minimum_target() -> int:
	# A sub-blind opening all-in may be completed to one big blind.
	return 20 if current_bet < 20 else current_bet + min_raise

func act(action: String, target: int = 0) -> bool:
	if finished or actor < 0: return false
	var i := actor
	var p = players[i]
	var call_amount := to_call(i)
	if action == "fold":
		p.folded = true
		note("%s passe." % p.name)
	elif action == "check_call":
		var paid: int = mini(call_amount, p.stack)
		pay(i, call_amount)
		note("%s %s" % [p.name, "parole." if call_amount == 0 else "suit (%d)." % paid])
	elif action == "raise":
		if not can_raise(i): return false
		var maximum: int = p.bet + p.stack
		if target > maximum or target <= current_bet: return false
		if target < minimum_target() and target != maximum: return false
		var increase := target - current_bet
		pay(i, target - p.bet)
		if current_bet < 20 and target >= 20: min_raise = maxi(20, increase)
		elif increase >= min_raise: min_raise = increase
		current_bet = target
		note("%s mise à %d%s." % [p.name, target, " · TAPIS" if p.stack == 0 else ""])
	else: return false
	p.acted = true
	p.last_bet = current_bet
	advance()
	changed.emit()
	return true

func advance() -> void:
	var live := live_ids()
	if live.size() == 1:
		paid_pot = pot()
		players[live[0]].stack += paid_pot
		result = "%s remporte %d · tous les autres ont passé." % [players[live[0]].name, paid_pot]
		finish()
		return
	# A lone player with chips need only act if facing an outstanding bet.
	var able: Array = []
	for i in live:
		if players[i].stack > 0: able.append(i)
	for offset in range(1, players.size() + 1):
		var i := (actor + offset) % players.size()
		var p = players[i]
		if p.folded or p.stack == 0: continue
		if p.bet < current_bet or (not p.acted and able.size() > 1):
			actor = i
			return
	if street == 3:
		showdown()
		return
	street += 1
	deck.pop_back() # Burn before each community street.
	for count in (3 if street == 1 else 1): board.append(deck.pop_back())
	current_bet = 0
	min_raise = 20
	for p in players:
		p.bet = 0
		p.acted = false
		p.last_bet = -1
	note(STREETS[street] + " · " + cards_text(board))
	actor = dealer
	advance()

func showdown() -> void:
	revealed = true
	paid_pot = pot()
	var levels: Array = []
	for p in players:
		if p.total > 0 and not levels.has(p.total): levels.append(p.total)
	levels.sort()
	var previous := 0
	var winnings := [0, 0, 0, 0]
	for level in levels:
		var contributors := 0
		var eligible: Array = []
		for i in players.size():
			if players[i].total >= level:
				contributors += 1
				if not players[i].folded: eligible.append(i)
		var amount: int = (level - previous) * contributors
		previous = level
		var best := -1
		var winners: Array = []
		for i in eligible:
			var value := evaluate(players[i].hole + board)
			if value > best:
				best = value
				winners = [i]
			elif value == best: winners.append(i)
		# An unmatched contribution is returned; folded-only layers cannot arise in valid betting.
		if winners.is_empty():
			for i in players.size():
				if players[i].total >= level: winnings[i] += level - (levels[levels.find(level) - 1] if levels.find(level) > 0 else 0)
			continue
		var share: int = amount / winners.size()
		for i in winners: winnings[i] += share
		var remainder: int = amount % winners.size()
		for offset in range(1, players.size() + 1):
			var i := (dealer + offset) % players.size()
			if remainder > 0 and winners.has(i):
				winnings[i] += 1
				remainder -= 1
	var messages: Array[String] = []
	for i in players.size():
		players[i].stack += winnings[i]
		if winnings[i] > 0:
			messages.append("%s +%d (%s)" % [players[i].name, winnings[i], hand_name(evaluate(players[i].hole + board))])
	result = " · ".join(messages)
	finish()

func finish() -> void:
	finished = true
	actor = -1
	note(result)
	# Contributions stay visible until next hand; pot() is historical once finished.

func ai_action() -> void:
	if actor <= 0 or finished: return
	var p = players[actor]
	var strength: float
	if board.size() >= 3:
		strength = float(evaluate(p.hole + board) / 759375) / 8.0
	else:
		var a := rank_of(p.hole[0])
		var b := rank_of(p.hole[1])
		strength = float(a + b) / 36.0
		if a == b: strength += 0.25
		if p.hole[0] / 13 == p.hole[1] / 13: strength += 0.08
	var call_amount := to_call(actor)
	var odds := float(call_amount) / maxi(1, pot() + call_amount)
	var roll := rng.randf()
	if call_amount > 0 and strength + rng.randf_range(-0.12, 0.22) < odds + 0.12:
		act("fold")
	elif can_raise(actor) and roll < 0.10 + strength * 0.22:
		var target := current_bet + maxi(min_raise, int(pot() * 0.5))
		act("raise", mini(target, p.bet + p.stack))
	else: act("check_call")

static func rank_of(card: int) -> int:
	return card % 13 + 2

static func card_text(card: int) -> String:
	return ["2", "3", "4", "5", "6", "7", "8", "9", "10", "V", "D", "R", "A"][card % 13] + ["♠", "♥", "♦", "♣"][card / 13]

static func cards_text(cards: Array) -> String:
	var labels: Array[String] = []
	for card in cards: labels.append(card_text(card))
	return "  ".join(labels)

static func hand_name(score: int) -> String:
	return HAND_NAMES[score / 759375]

static func evaluate(cards: Array) -> int:
	assert(cards.size() >= 5 and cards.size() <= 7)
	var best := 0
	for a in range(cards.size() - 4):
		for b in range(a + 1, cards.size() - 3):
			for c in range(b + 1, cards.size() - 2):
				for d in range(c + 1, cards.size() - 1):
					for e in range(d + 1, cards.size()):
						best = maxi(best, five([cards[a], cards[b], cards[c], cards[d], cards[e]]))
	return best

static func five(cards: Array) -> int:
	var counts := {}
	var ranks: Array = []
	var flush := true
	var suit: int = cards[0] / 13
	for card in cards:
		var rank := rank_of(card)
		counts[rank] = counts.get(rank, 0) + 1
		ranks.append(rank)
		if card / 13 != suit: flush = false
	ranks.sort()
	ranks.reverse()
	var straight := 0
	if counts.size() == 5:
		if ranks[0] - ranks[4] == 4: straight = ranks[0]
		elif ranks == [14, 5, 4, 3, 2]: straight = 5
	var groups: Array = counts.keys()
	groups.sort_custom(func(a, b): return counts[a] > counts[b] if counts[a] != counts[b] else a > b)
	var category := 0
	var kickers: Array = groups.duplicate()
	if flush and straight > 0:
		category = 8
		kickers = [straight]
	elif counts[groups[0]] == 4: category = 7
	elif counts[groups[0]] == 3 and counts[groups[1]] == 2: category = 6
	elif flush:
		category = 5
		kickers = ranks
	elif straight > 0:
		category = 4
		kickers = [straight]
	elif counts[groups[0]] == 3: category = 3
	elif counts[groups[0]] == 2 and counts[groups[1]] == 2: category = 2
	elif counts[groups[0]] == 2: category = 1
	var score := category
	for i in 5: score = score * 15 + (int(kickers[i]) if i < kickers.size() else 0)
	return score
