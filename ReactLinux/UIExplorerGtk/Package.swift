import PackageDescription

let package = Package(
  name:  "UIExplorerGtk",
  dependencies: [
    .Package(url: "https://github.com/ptmt/SwiftGtk", majorVersion: 0, minor: 2),
    .Package(url: "../../../ReactGtk", majorVersion: 0, minor: 1)
  ]
)
