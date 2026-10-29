class SyntaxProbe
{
	static var pass:Int = 0;
	static var fail:Array<String> = [];

	public static function main()
	{
		t('compound add', 'var x = 1; x += 2; x', '3');
		t('compound sub', 'var x = 5; x -= 2; x', '3');
		t('compound mul', 'var x = 3; x *= 2; x', '6');
		t('compound div', 'var x = 8; x /= 2; x', '4');
		t('compound mod', 'var x = 7; x %= 4; x', '3');
		t('compound shift', 'var x = 1; x <<= 3; x', '8');
		t('compound or', 'var x = 1; x |= 4; x', '5');
		t('compound and', 'var x = 7; x &= 5; x', '5');
		t('compound xor', 'var x = 7; x ^= 3; x', '4');
		t('null coalesce assign', 'var x = null; x ??= 9; x', '9');
		t('null coalesce keeps', 'var x = 2; x ??= 9; x', '2');
		t('post increment', 'var x = 1; x++; x', '2');
		t('pre increment', 'var x = 1; ++x; x', '2');
		t('post decrement', 'var x = 3; x--; x', '2');
		t('pre decrement', 'var x = 3; --x; x', '2');
		t('post increment value', 'var x = 1; var y = x++; y + "-" + x', '1-2');
		t('field increment', 'var o = {n:1}; o.n++; o.n', '2');
		t('array element increment', 'var a = [5]; a[0]++; a[0]', '6');

		// Literals
		t('ternary', 'true ? 1 : 2', '1');
		t('null coalesce', 'null ?? 7', '7');
		t('string interpolation bare', "var n = 4; 'v=$n'", 'v=4');
		t('string interpolation expr', "var n = 4; 'v=${n + 1}'", 'v=5');
		t('string interpolation nested quote', "var n = 2; 'v=${n * 3}'", 'v=6');
		t('array comprehension', '[for (i in 0...3) i * 2]', '[0,2,4]');
		t('object literal', 'var o = {a: 1, b: 2}; o.a + o.b', '3');
		t('nested object literal', 'var o = {a: {b: 3}}; o.a.b', '3');
		t('map literal', 'var m = ["k" => 5]; m["k"]', '5');
		t('string escapes', "'a\\tb'.length", '3');
		t('hex int', '0x10', '16');
		t('float exponent', '1e3', '1000');
		t('negative literal', '-5 + 2', '-3');

		t('arrow single arg', 'var f = x -> x * 2; f(3)', '6');
		t('arrow parenthesized', 'var f = (a, b) -> a + b; f(1, 2)', '3');
		t('arrow block body', 'var f = (a) -> { return a + 1; }; f(1)', '2');
		t('function expression', 'var f = function(a) return a * 2; f(2)', '4');
		t('default argument', 'function f(a = 5) return a; f()', '5');
		t('named argument list', 'function f(a, b) return a - b; f(9, 4)', '5');

		t('if expression', 'var v = if (true) 1 else 2; v', '1');
		t('while loop', 'var i = 0; while (i < 3) i++; i', '3');
		t('do while loop', 'var i = 0; do { i++; } while (i < 3); i', '3');
		t('range exclusive', 'var s = 0; for (i in 0...4) s += i; s', '6');
		t('for over array', 'var s = 0; for (v in [1,2,3]) s += v; s', '6');
		t('key value iteration', 'var s = ""; for (k => v in ["a" => 1]) s += k; s', 'a');
		t('break', 'var i = 0; while (true) { i++; if (i > 2) break; } i', '3');
		t('continue', 'var s = 0; for (i in 0...5) { if (i % 2 == 0) continue; s += i; } s', '4');
		t('switch value', "switch (2) { case 1: 'a'; case 2: 'b'; default: 'c'; }", 'b');
		t('switch pattern or', "switch (2) { case 1 | 2: 'hit'; default: 'miss'; }", 'hit');
		t('switch default', "switch (9) { case 1: 'a'; default: 'z'; }", 'z');
		t('switch guard', 'var n = 5; switch (n) { case x if (x > 3): "big"; default: "small"; }', 'big');
		t('try catch', 'var r = "none"; try { throw "boom"; } catch (e) { r = e; } r', 'boom');
		t('try catch typed', 'var r = "none"; try { throw "boom"; } catch (e:Dynamic) { r = e; } r', 'boom');

		t('typed var', 'var x:Int = 5; x', '5');
		t('final', 'final x = 3; x', '3');
		t('block scoped var', 'var x = 1; { var x = 2; } x', '1');

		t('method call chain', '"abc".toUpperCase()', 'ABC');
		t('array map with arrow', '[1,2,3].map(x -> x + 1)', '[2,3,4]');
		t('array filter with arrow', '[1,2,3].filter(x -> x > 1)', '[2,3]');
		t('array length', '[1,2,3].length', '3');
		t('array push', 'var a = []; a.push(1); a.length', '1');
		t('string concat mixed', '"n=" + 5', 'n=5');
		t('Math static', 'Math.max(2, 7)', '7');
		t('Reflect call', 'var o = {f: 3}; Reflect.field(o, "f")', '3');
		t('null safe field read', 'var o = null; o == null', 'true');
		t('typeof via Type', 'Type.typeof(1)', 'TInt');

		t('dollar before digit stays literal', "var n = 1; 'cost: $5'", 'cost: $5');
		t('double dollar is literal', "var n = 1; 'a$$n'", "a$n");
		t('interpolation then dot', "var o = {a: 1}; var n = 'x'; '$n.b'", 'x.b');
		t('interpolation of field', "var o = {a: 7}; 'v=${o.a}'", 'v=7');
		t('interpolation nested string', "var n = 'q'; 'v=${'$n!'}'", 'v=q!');
		t('interpolation brace in string', "var s = '}'; 'v=${s}'", 'v=}');
		t('interpolation two vars', "var a = 1; var b = 2; '$a$b'", '12');
		t('interpolation call result', "var f = x -> x + 1; 'v=${f(1)}'", 'v=2');
		t('double quoted no interpolation', "var n = 4; \"v=$n\"", "v=$n");
		t('guard falls through', 'var n = 1; switch (n) { case x if (x > 5): "big"; case x if (x > 0): "small"; default: "none"; }', 'small');
		t('guard no match uses default', 'var n = 0; switch (n) { case x if (x > 5): "big"; default: "none"; }', 'none');
		t('guard does not leak', 'var x = 9; var n = 1; switch (n) { case x if (x > 5): 1; } x', '9');
		t('unguarded ident still compares', 'var target = "b"; switch ("b") { case target: "same"; default: "diff"; }', 'same');
		t('key value over object', 'var s = ""; for (k => v in {a: 1, b: 2}) s += k + v; s', 'a1b2');
		t('key value break', 'var s = 0; for (k => v in {a: 1, b: 2}) { s += v; break; } s', '1');
		t('default arg used', 'function f(a, b = 10) return a + b; f(1)', '11');
		t('default arg overridden', 'function f(a, b = 10) return a + b; f(1, 2)', '3');
		t('catch without type', 'var r = ""; try { throw "x"; } catch (e) { r = e; } r', 'x');
		t('exponent value', '1.5e3', '1500');
		t('negative exponent', '2e-3', '0.002');
		t('increment in nested function', 'var c = 0; var f = function() { c++; return c; }; f(); f(); c', '2');

		t('optional chaining', 'var o = null; o?.a', 'null');
		t('spread call', 'function f(a, b) return a + b; var v = [1, 2]; f(...v)', '3');
		t('postfix null assert', 'var o = {a: 1}; o!.a', '1');

		report();
	}

	static function t(name:String, code:String, expected:String):Void
	{
		if (Sys.getEnv('PROBE_TRACE') != null)
			Sys.println('... ' + name);
		var got:String = null;
		var err:String = null;
		try
		{
			var parser = new crowplexus.hscript.Parser();
			parser.allowTypes = true;
			var expr = parser.parseString(code, name);
			var interp = new crowplexus.hscript.Interp();
			interp.variables.set('Math', Math);
			interp.variables.set('Reflect', Reflect);
			interp.variables.set('Type', Type);
			interp.variables.set('Std', Std);
			interp.variables.set('StringTools', StringTools);
			got = Std.string(interp.execute(expr));
		}
		catch (e:Dynamic)
		{
			err = Std.string(e);
		}

		if (err == null && got == expected)
		{
			pass++;
			return;
		}

		var reason:String = err != null ? 'threw: ' + err : 'got ' + got + ', want ' + expected;
		fail.push(name + '  ->  ' + reason);
	}

	static function report():Void
	{
		Sys.println('');
		Sys.println('probe: ' + pass + ' pass, ' + fail.length + ' fail');
		if (fail.length > 0)
		{
			Sys.println('');
			for (f in fail)
				Sys.println('  FAIL  ' + f);
		}
	}
}
