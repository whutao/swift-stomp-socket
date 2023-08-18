// swift-tools-version: 5.8
import PackageDescription

let package = Package(
	name: "swift-stomp-socket",
	platforms: [
		.iOS(.v15)
	],
	products: [
		.library(name: "StompSocket", targets: ["StompSocket"])
	],
	dependencies: [
		.package(
			url: "https://github.com/Romixery/SwiftStomp",
			from: Version(1, 1, 1)
		)
	],
	targets: [
		.target(
			name: "StompSocket",
			dependencies: [
				.product(name: "SwiftStomp", package: "SwiftStomp")
			]
		),
		.testTarget(
			name: "StompSocketTests",
			dependencies: ["StompSocket"]
		)
	]
)
