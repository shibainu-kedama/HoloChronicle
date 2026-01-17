# scripts/ConditionEvaluator.gd
class_name ConditionEvaluator

static func evaluate(cond: String, stats: Dictionary) -> bool:
	if cond == "":
		return true
	var pattern = r"(\w+)\s*(>=|<=|==|>|<)\s*(\d+)"
	var re = RegEx.new()
	re.compile(pattern)
	var match = re.search(cond)
	if match:
		var key = match.get_string(1)
		var op = match.get_string(2)
		var val = int(match.get_string(3))
		var actual = stats.get(key, 0)
		match op:
			"==": return actual == val
			">=": return actual >= val
			"<=": return actual <= val
			">": return actual > val
			"<": return actual < val
	return false
