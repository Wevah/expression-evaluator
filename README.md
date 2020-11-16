# ExpressionEvaluator

A simple mathematical expression evaluator for user input. Generic on `ExpressionEvaluable`, with conformances for `Double`, `Float`, `Float80`, and `CGFloat`.

(Note: This is not meant to be a high-performance library. It might also ditch the protocol in favor of `Real` from the Numerics package.)

## Examples

One-off:

```swift
let expression = "a + b"
let variables = ["a": 2.0, "b": 3.0]
let result = try ExpressionEvaluator.evaluate(expression: expression, variables: variables)
// `result` is 5.0
```

Initialize and use a reusable evaluator:

```swift
let evaluator = ExpressionEvaluator(expression: "a + b", variables: ["a": 2.0, "b": 3.0])
let result = try evaluator.evaluate(expression: expression, variables: variables)
// `result` is 5.0
```

Evaluate multiple expressions:

```swift
let evaluator = ExpressionEvaluator(variables: ["a": 2.0, "b": 3.0])
let expressions = ["a + b", "a * b"]
let result = try evaluator.evaluate(expressions: expressions)
// `result` is [5.0, 6.0]
```

Evaluate multiple *named* expressions:

```swift
let expressions = ["add": "a + b", "mult": "a * b"]
let variables = ["a": 2.0, "b": 3.0]
let result = try ExpressionEvaluator.evaluate(expressions: expressions, variables: variables)
// `result` is ["add": 5.0, "mult": 6.0]
```

## Supported Functions

Implemented under the hood as static functions on `ExpressionEvaluable` types:

- `sin(x)`
- `cos(x)`
- `tan(x)`
- `asin(x)`
- `acos(x)`
- `atan(x)`
- `atan2(y, x)`
- `pow(x, y)`
- `sqrt(x)`
- `cbrt(x)` Cube root
- `rand()` A random number in the range `0..<1`
- `min(x, ...)`
- `max(x, ...)`

Example:

```swift
let result = ExpressionEvaluator.evaluate(expression: "sqrt(4)")
// `result` is 2
```

## Constants

- `pi`
- `e`
- `deg` (180 / pi)
- `rad` (pi / 180)

---

© 2020 Nate Weaver
