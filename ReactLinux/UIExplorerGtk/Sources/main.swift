import SwiftGtk
import ReactGtk
import Foundation

let app = Application(applicationId: "com.facebook.unofficial.uiexplorergtk")
app.run { window in
    window.title = "Hello World"
    window.defaultSize = Size(width: 400, height: 400)
    window.resizable = true

    let bridge = Bridge(withURL: NSURL(string: "http://localhost:8081/ReactLinux/UIExplorerQtk/UIExplorerApp.linux.bundle?platform=linux&dev=true"))

    // let button = Button(label: "Press Me")
    // button.clicked = { _ in
    //   print("")
    // }

    window.add(button)
}
