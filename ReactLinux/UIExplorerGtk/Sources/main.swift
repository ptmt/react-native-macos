import SwiftGtk
import Foundation

let app = Application(applicationId: "com.facebook.unofficial.uiexplorergtk")
app.run { window in
    window.title = "Hello World"
    window.defaultSize = Size(width: 400, height: 400)
    window.resizable = true

    let bundle = "http://localhost:8081/ReactLinux/UIExplorerApp.osx.bundle?platform=osx&dev=true"
    if let bundleURL = NSURL(string: bundle) {
      let bridge = Bridge(withURL: bundleURL)
    }

    let button = Button(label: "Press Me")
    button.clicked = { _ in
      print("clicked")
    }

    window.add(widget: button)
}
