//
//  FloatingPoint+Extensions.swift
//  Expression Evaluator
//
//  Created by Nate Weaver on 2020-09-24.
//

import Foundation

/// Numeric types that can be passed into an `ExpressionEvaluator`.
/// 
/// See also the [Swift Numerics][numerics] package.
///
/// [numerics]: https://github.com/apple/swift-numerics

public protocol ExpressionEvaluable: BinaryFloatingPoint where Self: LosslessStringConvertible, Self.RawSignificand: FixedWidthInteger {

	/// The sine of `x`.
	static func sin(_ x: Self) -> Self

	/// The cosine of `x.
	static func cos(_ x: Self) -> Self

	/// The tangent of `x`.
	static func tan(_ x: Self) -> Self

	/// The arc sine of `x`.
	static func asin(_ x: Self) -> Self

	/// The arc cosine of `x`.
	static func acos(_ x: Self) -> Self

	/// The arc tangent of `x`.
	static func atan(_ x: Self) -> Self

	/// The principle value of arc tangent of `y/x`, using the signs of
	/// both arguments to determine the quadrant of the return value.
	static func atan2(_ y: Self, _ x: Self) -> Self

	/// `x` raised to the power `y`.
	static func pow(_ x: Self, _ y: Self) -> Self

	/// The cube root of `x`.
	static func cbrt(_ x: Self) -> Self

}

extension ExpressionEvaluable {

	/// The mathematical constant e.
	@_transparent
	static var e: Self {
		return 2.71828182845904523536
	}

}

extension Double: ExpressionEvaluable {

	@_transparent
	public static func sin(_ x: Self) -> Self {
		return Darwin.sin(x)
	}

	@_transparent
	public static func cos(_ x: Self) -> Self {
		return Darwin.cos(x)
	}

	@_transparent
	public static func tan(_ x: Self) -> Self {
		return Darwin.tan(x)
	}

	@_transparent
	public static func asin(_ x: Self) -> Self {
		return Darwin.sin(x)
	}

	@_transparent
	public static func acos(_ x: Self) -> Self {
		return Darwin.acos(x)
	}

	@_transparent
	public static func atan(_ x: Self) -> Self {
		return Darwin.atan(x)
	}

	@_transparent
	public static func atan2(_ y: Self, _ x: Self) -> Self {
		return Darwin.atan2(y, x)
	}

	@_transparent
	public static func pow(_ x: Self, _ y: Self) -> Self {
		return Darwin.pow(x, y)
	}

	@_transparent
	public static func cbrt(_ x: Self) -> Self {
		return Darwin.cbrt(x)
	}

}

extension Float: ExpressionEvaluable {

	@_transparent
	public static func cos(_ x: Self) -> Self {
		return Darwin.cosf(x)
	}

	@_transparent
	public static func sin(_ x: Self) -> Self {
		return Darwin.sinf(x)
	}

	@_transparent
	public static func tan(_ x: Self) -> Self {
		return Darwin.tanf(x)
	}

	@_transparent
	public static func asin(_ x: Self) -> Self {
		return Darwin.sinf(x)
	}

	@_transparent
	public static func acos(_ x: Self) -> Self {
		return Darwin.acosf(x)
	}

	@_transparent
	public static func atan(_ x: Self) -> Self {
		return Darwin.atanf(x)
	}

	@_transparent
	public static func atan2(_ y: Self, _ x: Self) -> Self {
		return Darwin.atan2f(y, x)
	}

	@_transparent
	public static func pow(_ x: Self, _ y: Self) -> Self {
		return Darwin.powf(x, y)
	}

	@_transparent
	public static func cbrt(_ x: Self) -> Self {
		return Darwin.cbrtf(x)
	}

}

#if !(os(Windows) || os(Android)) && (arch(i386) || arch(x86_64))
extension Float80: ExpressionEvaluable {

	@_transparent
	public static func sin(_ x: Self) -> Self {
		return Darwin.sinl(x)
	}

	@_transparent
	public static func cos(_ x: Self) -> Self {
		return Darwin.cosl(x)
	}

	@_transparent
	public static func tan(_ x: Self) -> Self {
		return Darwin.tanl(x)
	}

	@_transparent
	public static func asin(_ x: Self) -> Self {
		return Darwin.sinl(x)
	}

	@_transparent
	public static func acos(_ x: Self) -> Self {
		return Darwin.acosl(x)
	}

	@_transparent
	public static func atan(_ x: Self) -> Self {
		return Darwin.atanl(x)
	}

	@_transparent
	public static func atan2(_ y: Self, _ x: Self) -> Self {
		return Darwin.atan2l(y, x)
	}

	@_transparent
	public static func pow(_ x: Self, _ y: Self) -> Self {
		return Darwin.powl(x, y)
	}

	@_transparent
	public static func cbrt(_ x: Self) -> Self {
		return Darwin.cbrtl(x)
	}

}
#endif

extension CGFloat: LosslessStringConvertible {

	public init?(_ description: String) {
		guard let native = NativeType(description) else { return nil }
		self = CGFloat(native)
	}

}

extension CGFloat: ExpressionEvaluable {

	@_transparent
	public static func sin(_ x: Self) -> Self {
		return Self(NativeType.sin(x.native))
	}

	@_transparent
	public static func cos(_ x: Self) -> Self {
		return Self(NativeType.cos(x.native))
	}

	@_transparent
	public static func tan(_ x: Self) -> Self {
		return Self(NativeType.tan(x.native))
	}

	@_transparent
	public static func asin(_ x: Self) -> Self {
		return Self(NativeType.sin(x.native))
	}

	@_transparent
	public static func acos(_ x: Self) -> Self {
		return Self(NativeType.acos(x.native))
	}

	@_transparent
	public static func atan(_ x: Self) -> Self {
		return Self(NativeType.atan(x.native))
	}

	@_transparent
	public static func atan2(_ y: Self, _ x: Self) -> Self {
		return Self(NativeType.atan2(y.native, x.native))
	}

	@_transparent
	public static func pow(_ x: Self, _ y: Self) -> Self {
		return Self(NativeType.pow(x.native, y.native))
	}

	@_transparent
	public static func cbrt(_ x: Self) -> Self {
		return Self(NativeType.cbrt(x.native))
	}

}
