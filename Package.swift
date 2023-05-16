// swift-tools-version:5.5
// The swift-tools-version declares the minimum version of Swift required to build this package.

import PackageDescription

let package = Package(
    name: "Share",
    platforms: [.iOS(.v11)],
    products: [
        // Products define the executables and libraries a package produces, and make them visible to other packages.
        .library(
            name: "Share",
            targets: ["Share"]),
    ],
    dependencies: [
        // Dependencies declare other packages that this package depends on.
         .package(url: "https://github.com/ze230123/QQApi.git", from: "1.1.1"),
         .package(url: "https://github.com/ze230123/WXApi.git", from: "1.1.7"),
         .package(url: "https://github.com/ReactiveX/RxSwift.git", from: "6.5.0"),
//         .package(name: "WXApi", path: "/Users/youzy/Documents/lib_self/WXApi"),
//         .package(name: "QQApi", path: "/Users/youzy01/Github/QQApi")
    ],
    targets: [
        // Targets are the basic building blocks of a package. A target can define a module or a test suite.
        // Targets can depend on other targets in this package, and on products in packages this package depends on.
        .target(
            name: "Share",
            dependencies: ["QQApi", "WXApi", .product(name: "RxSwift", package: "RxSwift"), .product(name: "RxCocoa", package: "RxSwift")]),
    ]
)
