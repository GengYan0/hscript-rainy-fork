# RAINY-FORK

这个构建改了哪些语法、为什么改。许可与原始版权声明未做任何改动。

这是一个可用的构建，不是重写。下面每一条都存在，原因是照标准 `hscript` 写的脚本在这个
解释器上行为不同——要么静默出错，要么直接卡死。

Regression list: `test/SyntaxProbe.hx`, run with `cd test && haxe test.hxml`.
Every case is a script snippet plus the value it must produce. The two failures it reports
are deliberate and named below.

## Interpreter

### `++` / `--` on a local variable were a no-op

`Interp.increment()` put both the prefix and the postfix branch inside `if (l == null)`,
and that condition means "this name is a *global*". So:

```haxe
var i = 0;
while (i < 3) i++;   // i stays 0 -> infinite loop
```

It does not throw and it does not warn. A script written this way froze the whole game,
which is the kind of bug that gets reported as "the game hangs" rather than as a language
bug. Both branches now handle locals, and postfix still returns the old value while prefix
returns the new one - field, array and global targets were already correct.

### `switch` alternation silently never matched

`case 1 | 2:` was evaluated as a single expression, `1 | 2` = 3, so the case fired only for
the value 3. Now each candidate is matched in turn.

### `switch` binding with a guard

`case x if (x > 3):` raised `EUnknownVariable(x)`. The subject is now bound for the guard
and the body. **Only when a guard is present** - an unguarded `case x:` keeps its old
meaning of comparing against the current value of `x`, because existing scripts rely on it.

### `for (k => v in coll)`

Now supported over maps and plain objects. No AST node was added: the two names are packed
into `EFor`'s single name slot behind a `=>` separator, which no identifier can contain.
That keeps `Printer`, `Tools` and `Bytes` (including its serialization tags) untouched.

### Numeric exponent

`1e3` returned `Infinity`. `exp` holds the decimal scale and is 0 for an integer mantissa,
and the formula divided by it.

### `catch (e)` without a type

The annotation is optional now, matching Haxe 4.2+. It used to be a parse error.

### Default parameter values

`function f(a = 5)` parsed the default and then dropped it, so the body received null and
the argument stayed mandatory. The default now also marks the parameter optional.

## Strings

Single-quoted strings interpolate: `'hp=$hp'`, `'v=${n + 1}'`. `$$` is a literal `$`, and
`$` before a digit is left alone so `'cost: $5'` stays text.

The lexer only stores the segments (`{lit, code}`) on the parser; the expression side folds
them into a concatenation that starts with a literal. That detail matters: `'$a$b'` is
string concatenation, not addition, so without the leading literal two numbers would sum.
Double-quoted strings deliberately do **not** interpolate, because existing scripts pass
format strings in them.

## Not done, on purpose

| Missing | Why |
|---|---|
| `f(...args)` spread | needs a spread marker in the parameter list, on the hottest call path in the interpreter. The payoff does not justify reworking it. |
| `o!.a` null assert | it is a compile-time assertion; in an interpreter it can only be a no-op. Without position information, accepting a trailing `!` swallows the next statement's `!`. |

## Tests

```bash
cd test
haxe test.hxml
# probe: 86 passed, 2 failed (the two above)
```

`PROBE_SKIP=name` skips a case by name, which is how the pre-fix baseline was compared
against this fork: same suite, 55 -> 86 passing, nothing regressed.
