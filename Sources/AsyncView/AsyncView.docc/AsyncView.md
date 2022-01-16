# ``AsyncView``

A view that asynchronously loads and displays its content.

## Overview

``AsyncView`` asynchronously loads and displays its content and while the load operation
is in progress it displays a placeholder that fills the available space.

For example:

```swift
AsyncView { () -> String in
    try await Task.sleep(nanoseconds: NSEC_PER_SEC)

    return "Success!"
} content: { value in
    Text(value)
} placeholder: {
    Text("Loading...")
}
```

To gain more control over the loading process, you can use the ``AsyncView/init(task:transaction:content:)`` initializer,
which takes a `content` closure that receives an ``AsyncViewPhase`` to indicate the state of the loading operation:

```swift
AsyncView { () -> String in
    try await Task.sleep(nanoseconds: NSEC_PER_SEC)

    return "Success!"
} content: { phase in
    if let value = phase.value {
        Text(value) // Displays the loaded value.
    } else if phase.error != nil {
        Text("Failed") // Indicates an error.
    } else {
        Text("Loading...") // Acts as a placeholder.
    }
}
```
