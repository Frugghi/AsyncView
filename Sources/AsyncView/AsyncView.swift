import SwiftUI

/// The current phase of the asynchronous loading operation.
///
/// When you create an ``AsyncView`` instance with the ``AsyncView/init(task:transaction:content:)`` initializer,
/// you define the appearance of the view using a `content` closure. SwiftUI calls the closure with a phase value at different points
/// during the load operation to indicate the current state. Use the phase to decide what to draw.
///
/// For example, you can render the loaded value if it exists, a view that indicates an error, or a placeholder:
///
/// ```swift
/// AsyncView { () -> String in
///     try await Task.sleep(nanoseconds: NSEC_PER_SEC)
///
///     return "Success!"
/// } content: { phase in
///     if let value = phase.value {
///         Text(value) // Displays the loaded value.
///     } else if phase.error != nil {
///         Text("Failed") // Indicates an error.
///     } else {
///         Text("Loading...") // Acts as a placeholder.
///     }
/// }
/// ```
public enum AsyncViewPhase<Value> {

    /// No image is loaded.
    case empty

    /// A value succesfully loaded.
    case success(Value)

    /// A value failed to load with an error.
    case failure(Error)

    /// The loaded value, if any.
    ///
    /// If this value isn’t `nil`, the load operation has finished, and you can use the value to update the view.
    public var value: Value? {
        guard case .success(let value) = self else { return nil }
        return value
    }

    /// The error that occurred when attempting to load a value, if any.
    ///
    /// If this value isn’t `nil`, the load operation has finished with an error.
    public var error: Error? {
        guard case .failure(let error) = self else { return nil }
        return error
    }
}

/// A view that asynchronously loads and displays its content.
///
/// Until the load operation finishes, the view displays a placeholder that fills the available space.
/// After the load completes successfully, the view updates to display the content derived from the loaded value.
/// You can specify a custom placeholder and content using ``AsyncView/init(task:content:placeholder:)``:
///
/// ```swift
/// AsyncView { () -> String in
///     try await Task.sleep(nanoseconds: NSEC_PER_SEC)
///
///     return "Success!"
/// } content: { value in
///     Text(value)
/// } placeholder: {
///     Text("Loading...")
/// }
/// ```
///
/// To gain more control over the loading process, use the ``AsyncView/init(task:transaction:content:)`` initializer,
/// which takes a `content` closure that receives an ``AsyncViewPhase`` to indicate the state of the loading operation.
/// Return a view that’s appropriate for the current phase:
///
/// ```swift
/// AsyncView { () -> String in
///     try await Task.sleep(nanoseconds: NSEC_PER_SEC)
///
///     return "Success!"
/// } content: { phase in
///     if let value = phase.value {
///         Text(value) // Displays the loaded value.
///     } else if phase.error != nil {
///         Text("Failed") // Indicates an error.
///     } else {
///         Text("Loading...") // Acts as a placeholder.
///     }
/// }
/// ```
public struct AsyncView<Value, Content>: View where Content: View {

    @State private var phase: AsyncViewPhase<Value> = .empty
    private let task: () async throws -> Value
    private let content: (AsyncViewPhase<Value>) -> Content
    private let transaction: Transaction

    /// Loads and displays the view's content in phases.
    ///
    /// Before the load operation completes, the phase is ``AsyncViewPhase/empty``. After the operation completes,
    /// the phase becomes either ``AsyncViewPhase/failure(_:)`` or ``AsyncViewPhase/success(_:)``.
    /// In the first case, the phase’s error value indicates the reason for failure. In the second case, the phase’s value property
    /// contains the loaded value.
    ///
    /// Use the phase to drive the output of the content closure, which defines the view’s appearance:
    ///
    /// ```swift
    /// AsyncView { () -> String in
    ///     try await Task.sleep(nanoseconds: NSEC_PER_SEC)
    ///
    ///     return "Success!"
    /// } content: { phase in
    ///     if let value = phase.value {
    ///         Text(value) // Displays the loaded value.
    ///     } else if phase.error != nil {
    ///         Text("Failed") // Indicates an error.
    ///     } else {
    ///         Text("Loading...") // Acts as a placeholder.
    ///     }
    /// }
    /// ```
    ///
    /// - Parameters:
    ///   - task: The asynchronous operation to load the view's content.
    ///   - transaction: The transaction to use when the phase changes.
    ///   - content: A closure that takes the load phase as an input, and returns the view to display for the specified phase.
    public init(
        task: @escaping () async throws -> Value,
        transaction: Transaction = Transaction(),
        @ViewBuilder content: @escaping (AsyncViewPhase<Value>) -> Content
    ) {
        self.task = task
        self.transaction = transaction
        self.content = content
    }

    /// Loads and displays the view's content using a custom placeholder until the load operation finishes.
    ///
    /// Until the load operation finishes, SwiftUI displays the placeholder view that you specify. When the load operation completes successfully,
    /// SwiftUI updates the view to show content that you specify, which you create using the loaded value.
    ///
    /// For example:
    ///
    /// ```swift
    /// AsyncView { () -> String in
    ///     try await Task.sleep(nanoseconds: NSEC_PER_SEC)
    ///
    ///     return "Success!"
    /// } content: { value in
    ///     Text(value)
    /// } placeholder: {
    ///     Text("Loading...")
    /// }
    /// ```
    ///
    /// If the load operation fails, SwiftUI continues to display the placeholder.
    /// To be able to display a different view on a load error, use the ``init(task:transaction:content:)`` initializer instead.
    ///
    /// - Parameters:
    ///   - task: The asynchronous operation to load the view's content.
    ///   - content: A closure that takes the loaded value as an input, and returns the view to show.
    ///   - placeholder: A closure that returns the view to show until the load operation completes successfully.
    public init<C, P>(
        task: @escaping () async throws -> Value,
        @ViewBuilder content: @escaping (Value) -> C,
        @ViewBuilder placeholder: @escaping () -> P
    ) where C: View, P: View, Content == _ConditionalContent<C, P> {
        self.init(task: task) { phase in
            if let value = phase.value {
                content(value)
            } else {
                placeholder()
            }
        }
    }

    public var body: some View {
        self.content(self.phase)
            .task {
                let phase: AsyncViewPhase<Value>
                do {
                    let result = try await self.task()

                    phase = .success(result)
                } catch {
                    phase = .failure(error)
                }

                withTransaction(self.transaction) {
                    self.phase = phase
                }
            }
    }
}
