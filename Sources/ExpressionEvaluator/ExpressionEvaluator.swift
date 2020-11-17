//
//  ExpressionEvaluator.swift
//  Expression Evaluator
//
//  Created by Nate Weaver on 2020-09-18.
//

//  Parsing logic originally adapted for Obejctive-C from a file named "eval4.cpp" in 2005,
//  whose source I can't seem to track down (it has no copyright information in the source).
//  If anyone has any pointers, I'd be grateful!

import Foundation

public enum ExpressionEvaluatorError: Error, CustomStringConvertible {

	/// Attempted to add an element to the stack when it already has `maxStackDepth` values.
	case stackOverflow(_ maxCount: Int)

	/// `pop()` was called on an empty stack.
	case zeroDepthPop

	/// A function was called with an incorrect argument count.
	case incorrectArgumentCount(function: String, expectedCount: Int?)

	/// An invalid argument was passed to a function,
	/// for example swapping the last two arguments of "clamp".
	case invalidArgument(function: String, message: String)

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
			case let .stackOverflow(maxCount):
				return "Stack overflow: max stack count is \(maxCount)"
			case .zeroDepthPop:
				return "Pop called on zero-depth stack."
			case let .incorrectArgumentCount(function, expectedCount):
				if let expectedCount = expectedCount {
					return #"Incorrect number of arguments for function "\#(function)"; expects exactly \#(expectedCount) arguments."#
				} else {
					return #"Incorrect number of arguments for function "\#(function)"; expects at least one argument."#
				}
			case let .invalidArgument(function, message):
				return #"Error calling function "\#(function)": \#(message)"#
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

/// An expression evaluator.
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

	/// The maximum stack depth.
	///
	/// Default is 100.
	public var maxStackDepth = 100

	private var token: String = ""
	private var tokenType: TokenType = .unknown

	/// Defined constants.
	public private(set) lazy var constants = Self.defaultConstants

	/// Defined functions.
	public private(set) lazy var functions = Self.defaultFunctions


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
	/// let result = try evaluator.evaluate(expression: expression, variables: variables)
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
	/// let result = try evaluator.evaluate(expressions: expressions)
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
	/// let result = try evaluator.evaluate(expressions: expressions)
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
	/// let result = try ExpressionEvaluator.evaluate(expression: expression, variables: variables)
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
	/// let result = try ExpressionEvaluator.evaluate(expressions: expressions, variables: variables)
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
	/// let result = try ExpressionEvaluator.evaluate(expressions: expressions, variables: variables)
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

public extension ExpressionEvaluator {

	/// An ExpressionEvaluator function.
	enum Function {

		case arityZero(() throws -> T)
		case arityOne((_ x: T) throws -> T)
		case arityTwo((_ x: T, _ y: T) throws -> T)
		case arityThree((_ x: T, _ y: T, _ z: T) throws -> T)
		case arityFour((_ x: T, _ y: T, _ z: T, _ w: T) throws -> T)
		case arityAny((_ values: [T]) throws -> T)

		/// The number of arguments a the function accepts.
		/// If `nil`, the function accepts one or more arguments.
		public var argumentCount: Int? {
			switch self {
				case .arityZero:
					return 0
				case .arityOne:
					return 1
				case .arityTwo:
					return 2
				case .arityThree:
					return 3
				case .arityFour:
					return 4
				case .arityAny:
					return nil
			}
		}

		public init(_ function: @escaping () throws -> T) {
			self = .arityZero(function)
		}

		public init(_ function: @escaping (_ x: T) throws -> T) {
			self = .arityOne(function)
		}

		public init(_ function: @escaping (_ x: T, _ y: T) throws -> T) {
			self = .arityTwo(function)
		}

		public init(_ function: @escaping (_ x: T, _ y: T, _ z: T) throws -> T) {
			self = .arityThree(function)
		}

		public init(_ function: @escaping (_ values: [T]) throws -> T) {
			self = .arityAny(function)
		}

		fileprivate func call(poppingWith pop: () throws -> T, count: Int) throws -> T {
			switch self {
				case let .arityZero(function):
					return try function()
				case let .arityOne(function):
					return try function(pop())
				case let .arityTwo(function):
					let (y, x) = try (pop(), pop())
					return try function(x, y)
				case let .arityThree(function):
					let (z, y, x) = try (pop(), pop(), pop())
					return try function(x, y, z)
				case let .arityFour(function):
					let (w, z, y, x) = try (pop(), pop(), pop(), pop())
					return try function(x, y, z, w)
				case let .arityAny(function):
					var array = [T]()

					for _ in 0..<count {
						try array.insert(pop(), at: 0)
					}

					return try function(array)
			}
		}

	}

	func addFunction(_ function: @escaping () throws -> T, withName name: String) {
		functions[name] = Function(function)
	}

	func addFunction(_ function: @escaping (_ x: T) throws -> T, withName name: String) {
		functions[name] = Function(function)
	}

	func addFunction(_ function: @escaping (_ x: T, _ y: T) throws -> T, withName name: String) {
		functions[name] = Function(function)
	}

	func addFunction(_ function: @escaping (_ x: T, _ y: T, _ z: T) throws -> T, withName name: String) {
		functions[name] = Function(function)
	}

	func addFunction(_ function: @escaping (_ values: [T]) throws -> T, withName name: String) {
		functions[name] = Function(function)
	}

	func removeFunction(named name: String) {
		functions[name] = nil
	}

	static var defaultFunctions: [String: Function] {
		return [
			"rand": Function { .random(in: 0..<1) },
			"abs": Function(abs),

			"sin": Function(T.sin),
			"cos": Function(T.cos),
			"tan": Function(T.tan),

			"asin": Function(T.asin),
			"acos": Function(T.acos),
			"atan": Function(T.atan),

			"atan2": Function(T.atan2),

			"pow": Function(T.pow),
			"sqrt": Function(T.sqrt),
			"cbrt": Function(T.cbrt),

			"max": Function { $0.max() ?? 0 },
			"min": Function { $0.min() ?? 0 },

			"clamp": Function {
				if $1 > $2 {
					throw ExpressionEvaluatorError.invalidArgument(function: "clamp", message: "Argument 2 must be less than argument 3.")
				}
				if $0 < $1 {
					return $1
				} else if $0 > $2 {
					return $2
				}

				return $0
			}
		]
	}

	static var defaultConstants: [String: T] {
		return [
			"pi": .pi,
			"e": .e,
			"deg": 180 / .pi,
			"rad": .pi / 180
		]
	}

}

private extension ExpressionEvaluator {

	func push(_ value: T) throws {
		guard stack.count < maxStackDepth else {
			throw ExpressionEvaluatorError.stackOverflow(maxStackDepth)
		}

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
				try push(T(token)!)
				getNextToken()
			case .identifier:
				name = token

				getNextToken()

				if token == "(" {
					getNextToken()

					guard let function = functions[name] else {
						throw ExpressionEvaluatorError.unknownFunction(name)
					}

					let argumentCount = try parseArgList()

					guard  argumentCount == function.argumentCount || (function.argumentCount == nil && argumentCount > 0) else {
						throw ExpressionEvaluatorError.incorrectArgumentCount(function: name, expectedCount: function.argumentCount)
					}

					try push(function.call(poppingWith: pop, count: argumentCount))

					getNextToken()
				} else {
					guard let value = value(forIdentifier: name) else {
						throw ExpressionEvaluatorError.unknownIdentifier(name)
					}

					try push(value)
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

			try push(op == "*" ? a * b : a / b)
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

			try push(op == "+" ? a + b : a - b)
		}
	}
}

/// Convenience functions for passing in integer variables.
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
