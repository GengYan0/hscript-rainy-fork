# rainy-hscript

Haxe 脚本解释器。在运行时解释 `.hx` 脚本，脚本能读写宿主变量、调用宿主函数、继承宿主类。

包名仍是 `crowplexus.iris`，`haxelib` 名仍是 `hscript-iris`，现有脚本不用改 import。

## 能力

### 语言

| 语法 | 说明 |
|---|---|
| `import` / `using` | 与 Haxe 一致 |
| `var` / `final` | `final` 赋值时报错 |
| `class` / `extends` / `implements` | 脚本里可以定义类型并让宿主 `new` |
| `function` | 支持默认参数、可变参数以外的全部参数形态 |
| `switch` | 含多值分支与守卫分支 |
| `for` / `while` / `do-while` | `break` / `continue` 可用 |
| `try` / `catch` | `catch` 的类型标注可省略 |
| 单引号字符串插值 | `'hp=$hp'`、`'v=${n + 1}'` |
| 数值指数 | `1e3`、`2.5e-4` |
| 映射遍历 | `for (k => v in map)` |

### 宿主互操作

| 能力 | 入口 |
|---|---|
| 注入变量 | `set(name, value)` |
| 注入函数 | `set(name, Reflect.makeVarArgs(fn))` |
| 调用脚本函数 | `call(name, ?args)` |
| 读脚本变量 | `get(name)` |
| 脚本报错回调 | `IrisConfig.errorHandler` |
| 预设宿主 API | `autoPreset` |

## 安装

```bash
haxelib git hscript-iris https://github.com/GengYan0/hscript-rainy-fork
```

## 快速上手

脚本 `assets/scripts/hi.hx`：

```haxe
final greeting:String = 'Hello, $name';   // name 由宿主注入

function sayHello():Void
{
	trace(greeting);
}

function countUpTo(number:Int):Void
{
	for (i in 1...number + 1)
		trace(i);
}
```

宿主：

```haxe
import crowplexus.iris.Iris;

var script = new Iris(Assets.getText('assets/scripts/hi.hx'), {
	name: 'demo',
	autoRun: true,
	autoPreset: true
});

script.set('name', 'Rainy');
script.call('sayHello');        // Hello, Rainy
script.call('countUpTo', [3]);  // 1 2 3
```

`autoRun: false` 时脚本只解析不执行，需要手动 `script.execute()`。

## 语法用法

### 局部变量自增

```haxe
var i = 0;
while (i < 3) i++;     // 正常退出
trace(i);              // 3

trace(i++);            // 3，后缀返回旧值
trace(++i);            // 5，前缀返回新值
```

### 多值分支

```haxe
switch (state)
{
	case 'idle' | 'paused':
		trace('waiting');
	case 'playing':
		trace('running');
}
```

### 守卫分支

```haxe
switch (hp)
{
	case x if (x > 50): trace('safe: $x');
	case x if (x > 0):  trace('hurt: $x');
	default:            trace('down');
}
```

没有守卫的 `case x:` 仍是「与当前 `x` 的值比较」，保持老脚本的行为。

### 映射遍历

```haxe
var stats = {score: 100, combo: 42};   // 普通对象也行
for (key => value in stats)
	trace('$key = $value');
```

### 字符串插值

只有单引号字符串插值。双引号保持原样，因为老脚本用它传格式化模板。

```haxe
var hp = 3;
trace('hp=$hp');            // hp=3
trace('next=${hp + 1}');    // next=4
trace('cost: $5');          // cost: $5，$ 后跟数字不插值
trace('literal $$hp');      // literal $hp
```

### 默认参数

```haxe
function heal(amount = 10):Void
{
	hp = Math.min(maxHp, hp + amount);
}

heal();      // 用默认值
heal(25);    // 覆盖默认值
```

### 指数

```haxe
trace(1e3);      // 1000
trace(2.5e-4);   // 0.00025
```

### 省略 catch 类型

```haxe
try
{
	doThing();
}
catch (e)
{
	trace('failed: $e');
}
```

## 注入宿主能力

```haxe
import crowplexus.iris.Iris;

var script = new Iris(source, {name: 'mod', autoPreset: true});

// 变量
script.set('score', 1200);

// 函数
script.set('addScore', Reflect.makeVarArgs(function(args:Array<Dynamic>) {
	score += Std.int(args[0]);
}));
```

脚本侧：

```haxe
addScore(50);
trace(score);
```

## 读写脚本变量

```haxe
script.set('hp', 100);
script.set('hp', 80);          // 同名覆盖
script.set('hp', 60, false);   // allowOverride = false，已存在时不覆盖

if (script.exists('hp'))
	trace(script.get('hp'));
```

脚本侧改动过的变量，宿主用 `get` 读回来即可。没有变化回调。

## 调用结果

`call()` 返回 `IrisCall`，里面有三个字段：

```haxe
var r = script.call('heal', [20]);
trace(r.funName);       // "heal"
trace(r.signature);     // 调用签名
trace(r.returnValue);   // 函数返回值
```

## 错误处理

脚本解析或执行出错时抛异常，宿主捕获：

```haxe
try
{
	script.execute();
}
catch (e:Dynamic)
{
	trace('script failed: $e');
}
```

`ErrorSeverity` 用来给错误分级，脚本内部按级别决定是否中断。

## 已知不做

| 语法 | 原因 |
|---|---|
| `f(...args)` 展开 | 要在参数表里加展开标记，落在解释器最热的调用路径上，收益不抵改动 |
| `o!.a` 非空断言 | 编译期断言在解释器里没有对应动作，且缺位置信息时会吞掉下一条语句的 `!` |

## 回归测试

```bash
cd test
haxe test.hxml
```

86 条通过，2 条失败即上表两项：逐条是「脚本片段 + 必须得到的值」，改解释器前后跑同一套。
`PROBE_SKIP=name` 按名字跳过单条。
