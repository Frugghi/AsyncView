import SwiftUI

extension View {
    #if canImport(UIKit)
    typealias Window = UIWindow
    #else
    typealias Window = NSWindow
    #endif

    func addToWindow() -> Window {
        let window: Window

        #if canImport(UIKit)
        let contentViewController = UIViewController()

        window = Window(frame: UIScreen.main.bounds)
        window.rootViewController = contentViewController
        window.makeKeyAndVisible()

        let viewController = UIHostingController(rootView: self)
        #else
        let contentViewController = NSViewController()
        contentViewController.view = NSView()

        window = Window(
            contentRect: NSRect(x: 0, y: 0, width: 200, height: 200),
            styleMask: [.titled, .resizable, .closable],
            backing: .buffered,
            defer: false
        )
        window.contentViewController = contentViewController
        window.makeKeyAndOrderFront(nil)
        window.isReleasedWhenClosed = false

        let viewController = NSHostingController(rootView: self)
        #endif

        viewController.view.translatesAutoresizingMaskIntoConstraints = false
        viewController.view.frame = contentViewController.view.frame

        contentViewController.addChild(viewController)
        contentViewController.view.addSubview(viewController.view)

        NSLayoutConstraint.activate([
            viewController.view.topAnchor.constraint(equalTo: contentViewController.view.topAnchor),
            viewController.view.bottomAnchor.constraint(equalTo: contentViewController.view.bottomAnchor),
            viewController.view.leadingAnchor.constraint(equalTo: contentViewController.view.leadingAnchor),
            viewController.view.trailingAnchor.constraint(equalTo: contentViewController.view.trailingAnchor),
        ])

        #if canImport(UIKit)
        viewController.didMove(toParent: contentViewController)
        #endif

        window.layoutIfNeeded()

        return window
    }
}

#if canImport(UIKit)
extension UIWindow {
    func close() {
        self.resignKey()
        self.isHidden = true
    }
}
#endif
