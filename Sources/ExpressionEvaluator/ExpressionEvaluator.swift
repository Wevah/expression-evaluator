//
//  ExpressionEvaluator.swift
//  Expression Evaluator
//
//  Created by Nate Weaver on 2020-09-18.
//

import Foundation

public enum ExpressionEvaluatorError: Error, CustomStringConvertible {

	/// `pop()` was called on an empty stack.
	case zeroDepthPop

	/// A function was called with an incorrect argument count.
	case incorrectArgumentCount(_ function: String)

	/// An identifier was not recognized.
	case unknownIdentifier(_ identifier: String)

	///  A function was not recognized.
	case unknownFunction(_ function: String)

	/// A token was unexpectedly found.
	case unexpectedToken(_ token: String)

	/// The final stack has more than one element.
	case finalStackTooDeep

	/// The final stack is empty.
	case noFinalValueOnStack

	public var description: String {
		switch self {
			case .zeroDepthPop:
				return "Pop called on zero-depth stack."
			case let .incorrectArgumentCount(function):
				return #"Incorrect number of arguments for function "\#(function)"."#
			case let .unknownIdentifier(identifier):
				return #"Unknown indentifier "\#(identifier)"."#
			case let .unknownFunction(function):
				return #"Unknown function "\#(function)"."#
			case let .unexpectedToken(token):
				return #"Unexpected token "\#(token)"."#
			case .finalStackTooDeep:
				return "Final stack too deep."
			case .noFinalValueOnStack:
				return "No final value on stack."
		}
	}

}

public class ExpressionEvaluator<T> where T: ExpressionEvaluable {

	private enum TokenType {
		case unknown
		case identifier
		case number
	}

	private var expression: String
	private var variables: [String: T]

	private lazy var expressionIndex: String.Index = expression.startIndex
	private var stack = [T]()

	private var token: String = ""
	private var tokenType: TokenType = .unknown

	private lazy var constants = defaultConstants
	private lazy var functions = defaultFunctions

	/// Initializes an expression evaluator.
	///
	/// - Parameters:
	///   - expression: The initial expression to evaluate. If empty,
	///     pass an expression in the first call to `evaluate()`.
	///   - variables: A dictionary of variables to interpolate into `expression`.
	public required init(expression: String = "", variables: [String: T] = [:]) {
		self.expression = expression
		self.variables = variables
	}

	/// Evaluates an expression.
	///
	/// If `expression` and/or `variables` are `nil`, the current expression and/or variables are used.
	///
	/// Example:
	///
	/// ```
	/// let evaluator = ExpressionEvaluator(expression: "a + b", variables: ["a": 2.0, "b": 3.0])
	/// let result = evaluator.evaluate(expression: expression, variables: variables)
	/// // `result` is 5.0
	/// ```
	///
	/// - Parameters:
	///   - expression: The expression to evaluate, or `nil` to use the current expression.
	///   - variables: The new variables to interpolate, or `nil` to use the current variables.
	///
	/// - Throws: `ExpressionEvaluatorError`.
	/// - Returns: The result of the evaluation.
	public func evaluate(expression: String? = nil, variables: [String: T]? = nil) throws -> T {
		if let expression = expression {
			self.expression = expression
		}

		if let variables = variables {
			self.variables = variables
		}

		expressionIndex = self.expression.startIndex

		getNextToken()

		try parseExpression()

		if !token.isEmpty {
			switch stack.count {
				case ...0:
					throw ExpressionEvaluatorError.noFinalValueOnStack
				case 2...:
					throw ExpressionEvaluatorError.finalStackTooDeep
				default:
					return try pop()
			}
		}

		return .zero
	}

	/// Evaluates an array of expressions.
	///
	/// If `variables` is `nil`, the current variables are used.
	///
	/// Example:
	///
	/// ```
	/// let evaluator = ExpressionEvaluator(variables: ["a": 2.0, "b": 3.0])
	/// let expressions = ["a + b", "a * b"]
	/// let result = evaluator.evaluate(expressions: expressions)
	/// // `result` is [5.0, 6.0]
	/// ```
	///
	/// - Parameters:
	///   - expressions: The expressions to evaluate.
	///   - variables: If non-`nil`, the new variables to interpolate into the expressions.
	///
	/// - Throws: `ExpressionEvaluatorError`.
	/// - Returns: An array of the results of evaluating the expressions.
	public func evaluate(expressions: [String], variables: [String: T]? = nil) throws -> [T] {
		if let variables = variables {
			self.variables = variables
		}

		return try expressions.map {
			return try self.evaluate(expression: $0)
		}
	}

	/// Evaluates a dictionary of expressions.
	///
	/// If `variables` is `nil`, the current variables are used.
	///
	/// Example:
	///
	/// ```
	/// let evaluator = ExpressionEvaluator(variables: ["a": 2.0, "b": 3.0])
	/// let expressions = ["add": "a + b", "mult": "a * b"]
	/// let result = evaluator.evaluate(expressions: expressions)
	/// // `result` is ["add": 5.0, "mult": 6.0]
	/// ```
	///
	/// - Parameters:
	///   - expressions: The expressions to evaluate.
	///   - variables: If non-`nil`, the new variables to interpolate into the expressions.
	///
	/// - Throws: `ExpressionEvaluatorError`.
	/// - Returns: A dictionary of results, keyed by the same keys used in `expressions`.
	public func evaluate<K>(expressions: [K: String], variables: [String: T]? = nil) throws -> [K: T] {
		return try expressions.mapValues {
			return try self.evaluate(expression: $0)
		}
	}

	/// Evaluates a single expression.
	///
	/// Example:
	///
	/// ```
	/// let expression = "a + b"
	/// let variables = ["a": 2.0, "b": 3.0]
	/// let result = ExpressionEvaluator.evaluate(expression: expression, variables: variables)
	/// // `result` is 5.0
	/// ```
	///
	/// - Parameters:
	///   - expression: The expression to evaluate.
	///   - variables: A dictionary of variables used in the expressions.
	///
	/// - Returns: The result of evaluating the expression.
	public static func evaluate(expression: String, variables: [String: T] = [:]) throws -> T {
		return try Self(expression: expression, variables: variables).evaluate()
	}

	/// Evaluates an array of expressions.
	///
	/// Example:
	///
	/// ```
	/// let expressions = ["a + b", "a * b"]
	/// let variables = ["a": 2.0, "b": 3.0]
	/// let result = ExpressionEvaluator.evaluate(expressions: expressions, variables: variables)
	/// // `result` is [5.0, 6.0]
	/// ```
	///
	/// - Parameters:
	///   - expressions: An array of expressions to evaluate.
	///   - variables: A dictionary of variables used in the expressions.
	///
	/// - Returns: An array of results.
	public static func evaluate(expressions: [String], variables: [String: T] = [:]) throws -> [T] {
		return try Self(variables: variables).evaluate(expressions: expressions)
	}

	/// Evaluates a dictionary of expressions.
	///
	/// Example:
	///
	/// ```
	/// let expressions = ["add": "a + b", "mult": "a * b"]
	/// let variables = ["a": 2.0, "b": 3.0]
	/// let result = ExpressionEvaluator.evaluate(expressions: expressions, variables: variables)
	/// // `result` is ["add": 5.0, "mult": 6.0]
	/// ```
	///
	/// - Parameters:
	///   - expressions: A dictionary whose values are the expressions to evaluate.
	///   - variables: A dictionary of variables used in the expressions.
	///
	/// - Returns: A dictionary whose values are the results, keyed by the same keys used in `expressions`.
	public static func evaluate<K>(expressions: [K: String], variables: [String: T] = [:]) throws -> [K: T] {
		return try Self(variables: variables).evaluate(expressions: expressions)
	}

}

private extension ExpressionEvaluator {

	/// An ExpressionEvaluator function.
	enum Function {

		case arityZero(() -> T)
		case arityOne((_ x: T) -> T)
		case arityTwo((_ x: T, _ y: T) -> T)

		var numberOfArguments: Int {
			switch self {
				case .arityZero:
					return 0
				case .arityOne:
					return 1
				case .arityTwo:
					return 2
			}
		}

		init(_ function: @escaping () -> T) {
			self = .arityZero(function)
		}

		init(_ function: @escaping (_ x: T) -> T) {
			self = .arityOne(function)
		}

		init(_ function: @escaping (_ x: T, _ y: T) -> T) {
			self = .arityTwo(function)
		}

		func call(poppingWith pop: () throws -> T) rethrows -> T {
			switch self {
				case let .arityZero(function):
					return function()
				case let .arityOne(function):
					return try function(pop())
				case let .arityTwo(function):
					let y = try pop()
					let x = try pop()
					return function(x, y)
			}
		}

	}

	var defaultFunctions: [String: Function] {
		return [
			"rand": Function { .random(in: 0..<1) },
			"abs": Function { abs($0) },

			"sin": Function { .sin($0) },
			"cos": Function { .cos($0) },
			"tan": Function { .tan($0) },

			"asin": Function { .asin($0) },
			"acos": Function { .acos($0) },
			"atan": Function { .atan($0) },

			"atan2": Function { .atan2($0, $1) },

			"pow": Function { .pow($0, $1) },
			"sqrt": Function { sqrt($0) },
			"cbrt": Function { .cbrt($0) }
		]
	}

	var defaultConstants: [String: T] {
		return [
			"pi": .pi,
			"e": .e,
			"deg": 180 / .pi,
			"rad": .pi / 180
		]
	}

	func push(_ value: T) {
		stack.append(value)
	}

	func pop() throws -> T {
		guard let result = stack.popLast() else {
			throw ExpressionEvaluatorError.zeroDepthPop
		}

		return result
	}

	func value(forIdentifier identifier: String) -> T? {
		return constants[identifier] ?? variables[identifier]
	}

	func getNextToken() {
		let alpha = CharacterSet.letters
		let alnum = CharacterSet.alphanumerics
		let num = CharacterSet(charactersIn: "01234567890.")
		let white = CharacterSet.whitespaces

		guard let firstIndex = expression[expressionIndex...].unicodeScalars.firstIndex(where: { !white.contains($0) }) else {
			return
		}

		token.removeAll()

		let first = expression.unicodeScalars[firstIndex]

		token.unicodeScalars.append(first)

		expressionIndex = expression.unicodeScalars.index(after: firstIndex)

		//gotToken = true

		// FIXME: Make this better.
		if alpha.contains(first) {
			// Token is an identifier
			tokenType = .identifier

			for scalar in expression[expressionIndex...].unicodeScalars {
				guard alnum.contains(scalar) else { break }

				token.unicodeScalars.append(scalar)
				expressionIndex = expression.unicodeScalars.index(after: expressionIndex)
			}
		} else if num.contains(first) {
			// Token is a number.
			tokenType = .number

			for scalar in expression[expressionIndex...].unicodeScalars {
				guard num.contains(scalar) else { break }

				token.unicodeScalars.append(scalar)
				expressionIndex = expression.unicodeScalars.index(after: expressionIndex)
			}
		} else {
			tokenType = .unknown
		}
	}

	func parseArgList() throws -> Int {
		var numArgs = 0

		while token != ")" {
			numArgs += 1

			try parseExpression()

			if token == "," {
				getNextToken()
			}
		}

		if token != ")" {
			throw ExpressionEvaluatorError.unexpectedToken(token)
		}

		return numArgs
	}

	func parsePrimary() throws {
		var name: String

		switch tokenType {
			case .number:
				push(T(token)!)
				getNextToken()
			case .identifier:
				name = token

				getNextToken()

				if token == "(" {
					getNextToken()

					guard let function = functions[name] else {
						throw ExpressionEvaluatorError.unknownFunction(name)
					}

					guard try parseArgList() == function.numberOfArguments else {
						throw ExpressionEvaluatorError.incorrectArgumentCount(name)
					}

					try push(function.call(poppingWith: pop))

					getNextToken()
				} else {
					guard let value = value(forIdentifier: name) else {
						throw ExpressionEvaluatorError.unknownIdentifier(name)
					}

					push(value)
				}
			default:
				if !token.isEmpty {
					throw ExpressionEvaluatorError.unexpectedToken(token)
				}
		}
	}

	func parseFactor() throws {
		var unaryMinus = false

		if token == "+" {
			// Ignore unary plus
			getNextToken()
		} else if token == "-" {
			unaryMinus = true
			getNextToken()
		}

		if token == "(" {
			getNextToken()
			try parseExpression()
			getNextToken() // Discard ")"
		} else {
			try parsePrimary()
		}

		if unaryMinus {
			try push(-pop())
		}
	}

	func parseTerm() throws {
		try parseFactor()

		while token == "*" || token == "/" {
			let op = token

			getNextToken()
			try parseFactor()

			let b = try pop()
			let a = try pop()

			push(op == "*" ? a * b : a / b)
		}
	}

	func parseExpression() throws {
		try parseTerm()

		while token == "+" || token == "-" {
			let op = token

			getNextToken()
			try parseTerm()

			let b = try pop()
			let a = try pop()

			push(op == "+" ? a + b : a - b)
		}
	}
}

// Convenience functions for passing in integer variables.

public extension ExpressionEvaluator {

	static func evaluate<I: FixedWidthInteger>(expression: String, variables: [String: I]) throws -> T {
		return try evaluate(expression: expression, variables: variables.mapValues { T($0) })
	}

	static func evaluate<I: FixedWidthInteger>(expressions: [String], variables: [String: I]) throws -> [T] {
		return try evaluate(expressions: expressions, variables: variables.mapValues { T($0) })
	}

	static func evaluate<K, I: FixedWidthInteger>(expressions: [K: String], variables: [String: I]) throws -> [K: T] {
		return try evaluate(expressions: expressions, variables: variables.mapValues { T($0) })
	}

}
