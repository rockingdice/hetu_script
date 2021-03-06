# Hetu Script

Hetu's grammar is kind of like an abridged version of typescript, with some difference here and there. Hetu has variable('var'), function('fun') and class('class'). The semicolon in the end of the statement is optional unless there might be ambiguity(e.g. if there are expression after a empty return statement).

## Script file structure

Hetu script files has two main structure, controlled by the ParseStyle parameter in eval function of an Interpreter object.

- [ParseStyle.library]: the file contains only import statement and declarations(variable, function and class). Interpreter will call the function name given by parameter [invokeFunc]. This is like most app structure in C++, Java and Dart.

- [ParseStyle.function]: the file is a anonymous function body, contains all kinds of expression and control statement. Everything is immediately evaluated. This is like the usage of Python.

## Comments

```typescript
// This is a comment.
/* These are multi-line comments:
another line,
end here.*/
```

## Keywords

null, static, var, def, let, any, namespace, as, class, data, interface, mixin, fun, proc, construct, get, set, this, super, extends, implements, mixin, external, import, break, continue, for, in, if, else, return, while, when, is

## Operators

| Description    | Operator         | Associativity | Precedence |
| -------------- | ---------------- | ------------- | ---------- |
| Unary postfix  | e., e()          | None          | 16         |
| Unary prefix   | -e, !e           | None          | 16         |
| Multiplicative | \*, /, %         | Left          | 14         |
| Additive       | +, -             | Left          | 13         |
| Relational     | <, >, <=, >=, is | None          | 8          |
| Equality       | ==, !=           | None          | 7          |
| Logical and    | &&               | Left          | 6          |
| Logical or     | \|\|             | Left          | 5          |
| Assignment     | =                | Right         | 1          |

## Variable

Variable is declared with 'var', 'def' or 'let'. The type and initialize expression is optional.

```typescript
var person
var name = "naruto"
var year = 2020
var fineStructureConstant: num = 1 / 137
var isTimeTravelSuccessful: bool = true
var gasGiants = ["Jupiter", "Saturn"]
var skill: Map<String> = {
  tags: ["attack"],
  script: "//path/to/skill_script.ht",
}
```

If declared with 'var', variables will have a type of 'any', hence you can re-assign it with any type.

```typescript
var name = "naruto"
name = 2020 // not an error
```

If declared with 'def', variables will be given a type if it has an initialize expression. And you cannot re-assign it with another type.

```groovy
def name = "naruto"
// name = 2020 // error!
```

If declared with 'let', variables has to have an initialize expression, and it will be given a type according to the expression, and it will become immutable(in other words this is a constant).

```typescript
let name = "naruto"
// name = "sasuke" // error!
```

## Type declaration

Typename is not evaluated when declared, hence you can declare a variable with an non-exist type. However if you do this, you cannot assign it with any value.

```groovy
def i: NotAType // not an error
```

## Control statement

```typescript
if (year >= 2001) {
  print("21st century")
} else if (year >= 1901) {
  print("20th century")
} else {
  print("unkown date")
}

for (var planet in gasGiants) {
  print(planet)
}

while (year < 2040) {
  year = year + 1
}
```

## Function

Function is declared with 'fun', 'proc', 'get', 'set', 'construct'. the function name, parameter list, return type and function body are all optional. For functions with no parameters, the empty brackets are also optional.

```typescript
fun doubleIt(n: num): num {
	return n * 2
}

proc main {
  def x = doubleIt(7) // expect 14
  print(x)
}
```

For functions declared with 'fun', when no return type is provided in declaration, it will have a return type of 'any'. And it will return null if you didn't write return statement within the definition body.

For functions declared with 'proc', which means procedure, you cannot provided any return type. and you cannot use un-empty return statement to return a value. And you cannot use a proc's value within any expression.

Member functions can also be declared with 'get', 'set', 'construct', they literally means getter, setter and contructor function.

If a class have a getter or setter function. You can use 'class_name.func_name' to get or set the value hence get rid of the empty brackets.

## Class

Class is declared with 'class', 'data', 'interface'.

Data class cannot have construct, and can be use as mixins.

Variable of data class type can be assigned with anonymous data object literal.

Interface can have abstract functions(means those functions have no definition body). If do so, any class extends from this interface must have a definition of those abstract functions.

```kotlin
// class definition
class Calculator {
  // instance member
  var x: num
  var y: num

  // static private member
  static var _name = 'the calculator'

  // static get function
  static get name: String {
    // 类中的静态函数只能访问类中的静态对象
    return _name
  }

  // static set function
  static set name(new_name: String) {
    _name = new_name
  }

  // static function
  static fun greeting {
    print('hello! I\'m ' + name)
  }

  // constructor with parameters
  construct (x: num, y: num) {
    // use this to access instance members
    this.x = x
    this.y = y
  }

  // method with return type
  fun meaning: num {
    // when no shadowing, `this` keyword is omittable
    return x * y
  }
}
```
