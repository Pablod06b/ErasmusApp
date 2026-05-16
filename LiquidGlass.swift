import SwiftUI

// MARK: - Compatibility shims for iOS versions prior to 26

// Provide lightweight stand-ins to keep the API surface consistent on older OSes.
public enum _CompatGlassVariant {
    case regular
}

public enum _CompatGlassShape {
    case capsule
    case rect(cornerRadius: CGFloat)
}

extension View {
    /// Applies Liquid Glass when available, otherwise falls back to a material background.
    @ViewBuilder
    func _applyGlassEffect(_ variant: _CompatGlassVariant, shape: _CompatGlassShape) -> some View {
        if #available(iOS 26.0, *) {
            // Bridge to real types on iOS 26+
            let glass: Glass = .regular
            switch shape {
            case .capsule:
                self.glassEffect(glass, in: .capsule)
            case .rect(let radius):
                self.glassEffect(glass, in: .rect(cornerRadius: radius))
            }
        } else {
            // Fallback: approximate with a material background
            switch shape {
            case .capsule:
                self.padding(0)
                    .background(
                        Capsule().fill(.ultraThinMaterial)
                    )
            case .rect(let radius):
                self.padding(0)
                    .background(
                        RoundedRectangle(cornerRadius: radius).fill(.ultraThinMaterial)
                    )
            }
        }
    }
}

/// A compatibility wrapper around GlassEffectContainer. Falls back to a simple container on older iOS.
public struct _CompatGlassContainer<Content: View>: View {
    let spacing: CGFloat
    let content: Content

    public init(spacing: CGFloat = 8, @ViewBuilder content: () -> Content) {
        self.spacing = spacing
        self.content = content()
    }

    public var body: some View {
        if #available(iOS 26.0, *) {
            GlassEffectContainer(spacing: spacing) { content }
        } else {
            // Fallback: just render the content without special merging
            VStack(spacing: spacing) { content }
        }
    }
}

/// Compatibility button wrappers that forward to system glass styles when available.
public struct _CompatGlassButtonStyle: PrimitiveButtonStyle {
    public init() {}
    public func makeBody(configuration: Configuration) -> some View {
        if #available(iOS 26.0, *) {
            return AnyView(Button(configuration).buttonStyle(.glass))
        } else {
            return AnyView(Button(configuration)
                .buttonStyle(.bordered)
                .tint(.secondary)
                .background(.ultraThinMaterial)
                .clipShape(Capsule()))
        }
    }
}

public struct _CompatGlassProminentButtonStyle: PrimitiveButtonStyle {
    public init() {}
    public func makeBody(configuration: Configuration) -> some View {
        if #available(iOS 26.0, *) {
            return AnyView(Button(configuration).buttonStyle(.glassProminent))
        } else {
            return AnyView(Button(configuration)
                .buttonStyle(.borderedProminent)
                .tint(.accentColor)
                .background(.ultraThinMaterial)
                .clipShape(Capsule()))
        }
    }
}

/// A view modifier that applies a configurable Liquid Glass effect background.
/// Use this to style any view with a glass effect of desired variant and shape.
public struct GlassBackground: ViewModifier {
    public let variant: _CompatGlassVariant
    public let shape: _CompatGlassShape
    
    /// Creates a GlassBackground modifier.
    /// - Parameters:
    ///   - variant: The glass effect variant to apply.
    ///   - shape: The shape to clip the glass effect into.
    public init(variant: _CompatGlassVariant = .regular, shape: _CompatGlassShape = .capsule) {
        self.variant = variant
        self.shape = shape
    }
    
    public func body(content: Content) -> some View {
        content._applyGlassEffect(variant, shape: shape)
    }
}

public extension View {
    /// Applies a Liquid Glass background effect with configurable variant and shape.
    ///
    /// Example usage:
    /// ```
    /// Text("Hello")
    ///     .glassBackground(.regular, shape: .capsule)
    /// ```
    /// - Parameters:
    ///   - variant: The glass effect variant to apply (default is `.regular`).
    ///   - shape: The shape to clip the glass effect into (default is `.capsule`).
    /// - Returns: A view with the glass effect background applied.
    func glassBackground(_ variant: _CompatGlassVariant = .regular, shape: _CompatGlassShape = .capsule) -> some View {
        modifier(GlassBackground(variant: variant, shape: shape))
    }
}

/// A reusable card container that applies a rounded rectangle Liquid Glass effect background
/// with default corner radius and padding. Use to wrap content you want styled as a glass card.
///
/// Example usage:
/// ```
/// GlassCard {
///     VStack {
///         Text("Card Title")
///         Text("Card content goes here.")
///     }
/// }
/// ```
public struct GlassCard<Content: View>: View {
    private let content: Content
    
    /// Creates a GlassCard wrapping the given content.
    /// - Parameter content: A view builder closure that provides the card content.
    public init(@ViewBuilder content: () -> Content) {
        self.content = content()
    }
    
    public var body: some View {
        content
            .padding(12)
            .background(
                RoundedRectangle(cornerRadius: 16)
                    .fill(Color.clear)
                    .overlay(
                        EmptyView()._applyGlassEffect(.regular, shape: .rect(cornerRadius: 16))
                    )
            )
    }
}

/// Button style wrapping the system `.glass` style for discoverability and reuse.
///
/// Example usage:
/// ```
/// Button("Tap Me") { }
///     .buttonStyle(GlassButtonStyle())
/// ```
public struct GlassButtonStyle: PrimitiveButtonStyle {
    public init() { }
    
    public func makeBody(configuration: Configuration) -> some View {
        _CompatGlassButtonStyle().makeBody(configuration: configuration)
    }
}

/// Button style wrapping the system `.glassProminent` style for discoverability and reuse.
///
/// Example usage:
/// ```
/// Button("Tap Me") { }
///     .buttonStyle(GlassProminentButtonStyle())
/// ```
public struct GlassProminentButtonStyle: PrimitiveButtonStyle {
    public init() { }
    
    public func makeBody(configuration: Configuration) -> some View {
        _CompatGlassProminentButtonStyle().makeBody(configuration: configuration)
    }
}

/// A view rendering a menu-like section with an optional header title,
/// and a Liquid Glass styled rounded rectangle background.
///
/// Example usage:
/// ```
/// GlassMenuSection(title: "Options") {
///     Text("Option 1")
///     Text("Option 2")
/// }
/// ```
public struct GlassMenuSection<Content: View>: View {
    private let title: String?
    private let content: Content
    
    /// Creates a GlassMenuSection with optional title and content.
    /// - Parameters:
    ///   - title: Optional section header title.
    ///   - content: A view builder closure for the section content.
    public init(title: String? = nil, @ViewBuilder content: () -> Content) {
        self.title = title
        self.content = content()
    }
    
    public var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            if let title {
                Text(title)
                    .font(.headline)
            }
            VStack(alignment: .leading, spacing: 4) {
                content
            }
            .padding(12)
            .background(
                RoundedRectangle(cornerRadius: 14)
                    .fill(Color.clear)
                    .overlay(
                        EmptyView()._applyGlassEffect(.regular, shape: .rect(cornerRadius: 14))
                    )
            )
        }
    }
}

/// A container wrapper that applies `GlassEffectContainer` with configurable spacing,
/// allowing grouping of views with consistent Liquid Glass styling.
///
/// Example usage:
/// ```
/// GlassContainer(spacing: 10) {
///     Text("Child 1")
///     Text("Child 2")
/// }
/// ```
public struct GlassContainer<Content: View>: View {
    private let spacing: CGFloat
    private let content: Content
    
    /// Creates a GlassContainer wrapping the given content with specified spacing.
    /// - Parameters:
    ///   - spacing: The spacing between contained views.
    ///   - content: A view builder closure for the container content.
    public init(spacing: CGFloat = 8, @ViewBuilder content: () -> Content) {
        self.spacing = spacing
        self.content = content()
    }
    
    public var body: some View {
        _CompatGlassContainer(spacing: spacing) {
            content
        }
    }
}

#if DEBUG
struct GlassHelpers_Previews: PreviewProvider {
    static var previews: some View {
        VStack(spacing: 20) {
            Text("GlassBackground Example")
                .padding()
                .glassBackground(.regular, shape: .capsule)
            
            GlassCard {
                VStack {
                    Text("GlassCard Title")
                        .font(.headline)
                    Text("This is some card content.")
                }
            }
            
            Button("GlassButtonStyle") { }
                .buttonStyle(GlassButtonStyle())
                .padding()
            
            Button("GlassProminentButtonStyle") { }
                .buttonStyle(GlassProminentButtonStyle())
                .padding()
            
            GlassMenuSection(title: "Menu Section") {
                Text("Menu item 1")
                Text("Menu item 2")
            }
            
            GlassContainer(spacing: 16) {
                Text("Container Child 1")
                Text("Container Child 2")
            }
        }
        .padding()
        .previewLayout(.sizeThatFits)
    }
}
#endif

