# ExpressionEvaluator

A simple mathematical expression evaluator. Generic on `ExpressionEvaluable`, with conformances for `Double`, `Float`, `Float80`, and `CGFloat`.

(This is not meant to be a high-performance library.)

## Examples

One-off:

```swift
let expression = "a + b"
let variables = ["a": 2.0, "b": 3.0]
let result = ExpressionEvaluator.evaluate(expression: expression, variables: variables)
// `result` is 5.0
```

Initialize and use a reusable evaluator:

```swift
let evaluator = ExpressionEvaluator(expression: "a + b", variables: ["a": 2.0, "b": 3.0])
let result = evaluator.evaluate(expression: expression, variables: variables)
// `result` is 5.0
```

Evaluate multiple expressions:

```swift
let evaluator = ExpressionEvaluator(variables: ["a": 2.0, "b": 3.0])
let expressions = ["a + b", "a * b"]
let result = evaluator.evaluate(expressions: expressions)
// `result` is [5.0, 6.0]
```

Evaluate multiple *named* expressions:

```
let expressions = ["add": "a + b", "mult": "a * b"]
let variables = ["a": 2.0, "b": 3.0]
let result = ExpressionEvaluator.evaluate(expressions: expressions, variables: variables)
// `result` is ["add": 5.0, "mult": 6.0]
```

## Built-in functions

Implemented as static functions on `ExpressionEvaluable` types:

- `sin`
- `cos`
- `tan`
- `asin`
- `acos`
- `atan`
- `atan2`
- `pow`
- `cbrt` (cube root)
- `sqrt`

## Constants

- `pi`
- `e`
- `deg` (180 / pi)
- `rad` (pi / 180)

---

© 2020 Nate Weaver
