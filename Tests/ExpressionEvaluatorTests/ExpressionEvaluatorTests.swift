//
//  ExpressionEvaluatorTests.swift
//  Expression Evaluator
//
//  Created by Nate Weaver on 2020-09-20.
//

import XCTest
@testable import ExpressionEvaluator

final class ExpressionEvaluatorTests: XCTestCase {

	func testExpressionEvaluator() {
		let vars = ["x": 1.0, "y": 2.0, "z": 3.0]

		try XCTAssertEqual(ExpressionEvaluator.evaluate(expression: "x + y", variables: vars), 3.0)

		try XCTAssertEqual(ExpressionEvaluator.evaluate(expression: "x + y * z", variables: vars), 7.0)

		try XCTAssertEqual(ExpressionEvaluator.evaluate(expression: "(x + y) * z", variables: vars), 9.0)
	}

	func testConstructed() throws {
		let evaluator = ExpressionEvaluator<Double>(expression: "1 + 2")

		let foo: Double = try evaluator.evaluate()

		XCTAssertEqual(foo, 3)
	}

	func testExpressionFunctions() {
		try XCTAssertEqual(ExpressionEvaluator.evaluate(expression: "sqrt(4)"), 2)
		try XCTAssertEqual(ExpressionEvaluator.evaluate(expression: "max(1,3,2)"), 3)
		try XCTAssertEqual(ExpressionEvaluator.evaluate(expression: "abs(-1)"), 1)
	}

	func testRandom() {
		guard let value: Double = try? ExpressionEvaluator.evaluate(expression: "rand()") else {
			XCTFail()
			return
		}

		XCTAssert((0.0..<1.0).contains(value))

		guard let value2: Double = try? ExpressionEvaluator.evaluate(expression: "rand()") else {
			XCTFail()
			return
		}

		XCTAssertNotEqual(value, value2)
	}

	func testBadFunctions() {
		do {
			_ = try ExpressionEvaluator<Double>.evaluate(expression: "sdafaf(4)")
		} catch ExpressionEvaluatorError.unknownFunction {
			// success
		} catch {
			XCTFail()
		}
	}

	func testBadVariables() {
		do {
			_ = try ExpressionEvaluator<Double>.evaluate(expression: "sdafaf")
		} catch ExpressionEvaluatorError.unknownIdentifier {
			// success
		} catch {
			XCTFail()
		}
	}

	func testExpressionArray() throws {
		let result: [Double] = try ExpressionEvaluator.evaluate(expressions: ["1 + 2", "3 + 4"])

		XCTAssertEqual(result, [3, 7])
	}

	func testExpressionDictionary() throws {
		let result: [String: Double] = try ExpressionEvaluator.evaluate(expressions: ["a": "1 + 2", "b": "3 + 4"])

		XCTAssertEqual(result, ["a": 3, "b": 7])
	}

	func testIntegerVariables() throws {
		let vars = ["x": 1, "y": 2, "z": 3]
		let result: Double = try ExpressionEvaluator.evaluate(expression: "1 + 2", variables: vars)
		XCTAssertEqual(result, 3)
	}

	func testEmptyExpression() throws {
		try XCTAssertEqual(ExpressionEvaluator<Double>.evaluate(expression: ""), 0)
	}

	func testSingleToken() throws {
		try XCTAssertEqual(ExpressionEvaluator<Double>.evaluate(expression: "10"), 10)
	}

	func testUnexpectedToken() throws {
		do {
			_ = try ExpressionEvaluator<Double>.evaluate(expression: "10+")
		} catch ExpressionEvaluatorError.unexpectedToken {
			// success
		} catch {
			XCTFail()
		}
	}

	func testFunctions() throws {
		try XCTAssertEqual(ExpressionEvaluator<Double>.evaluate(expression: "sqrt(4)"), 2)
		try XCTAssertEqual(ExpressionEvaluator<Double>.evaluate(expression: "cbrt(27)"), 3)

		try XCTAssertEqual(ExpressionEvaluator<Double>.evaluate(expression: "cbrt(8) + sqrt(16)"), 6)

	}

	func testRepeatedInvocations() throws {
		let evaluator = ExpressionEvaluator<Double>(expression: "1 + 2")
		try XCTAssertEqual(evaluator.evaluate(), 3)
		try XCTAssertEqual(evaluator.evaluate(), 3)
	}

	func testCustomFunction() {
		let evaluator = ExpressionEvaluator<Double>()
		evaluator.addFunction({ $0 + 1 }, withName: "addone")

		try XCTAssertEqual(evaluator.evaluate(expression: "addone(1)"), 2)
	}

	func testClamp() {
		let evaluator = ExpressionEvaluator<Double>()
		try XCTAssertEqual(evaluator.evaluate(expression: "clamp(2, 1, 3)"), 2)
		try XCTAssertEqual(evaluator.evaluate(expression: "clamp(-1, 1, 3)"), 1)
		try XCTAssertEqual(evaluator.evaluate(expression: "clamp(4, 1, 3)"), 3)

		do {
			// Swapped arguments
			try _ = evaluator.evaluate(expression: "clamp(2, 3, 1)")
		} catch ExpressionEvaluatorError.invalidArgument {
			// success
		} catch {
			XCTFail()
		}
	}

}
