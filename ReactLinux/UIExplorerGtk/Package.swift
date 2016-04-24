import PackageDescription


let package = Package(
    name: "UIExplorerGtk",
    dependencies: [
      .Package(url: "https://github.com/ptmt/SwiftGtk", majorVersion: 0, minor: 4)
    ]
)

// import PackageDescription
//
//
// let package = Package(
//     // The name of the package (defaults to source root directory name).
//     name: "ReactGtk",
//     dependencies: [
//       .Package(url: "https://github.com/ptmt/SwiftGtk", majorVersion: 0, minor: 4),
//     ],
//     // The list of targets in the package.
//     targets: [
//         // Declares the main application.
//         Target(
//             name: "UIExplorerGtk"
//             // Declare the type of application.
//             //type: .Tool,
//
//             // Declare that this target is a published product of the package
//             // (as opposed to an internal library or tool).
//             //published: true
//           ),
//
//         // Add information on a support library "CoreFoo" (as found by the
//         // convention based system in CoreFoo/**/*.swift).
//         Target(
//             name: "CoreReactGtk"
//
//             // depends: [
//             //     // The library always depends on the "Utils" target.
//             //     "Utils",
//             //
//             //     // This library depends on "AccessibilityUtils" on Linux.
//             //     .Conditional(name: "AccessibilityUtils", platforms: [.Linux])
//             // ]
//             ),
//
//         Target(
//             /** Runs package tests */
//             name: "swift-test",
//             dependencies: ["CoreReactGtk"])
//
//         // NOTE: There is a "Utils" target inferred by the convention based
//         // system, but we don't need to modify it at all because the defaults
//         // were fine.
//
//         // Declare that the "AccessibilityUtils" target is Linux-specific.
//         //Target(name: "AccessibilityUtils", platforms: [.Linux])
//     ])
