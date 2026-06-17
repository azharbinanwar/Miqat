import Foundation

final class ServiceLocator {
    static let shared = ServiceLocator()
    private var registry: [String: Any] = [:]

    private init() {}

    func register<T>(_ type: T.Type, factory: @escaping () -> T) {
        registry[key(type)] = factory
    }

    func resolve<T>(_ type: T.Type) -> T {
        guard let factory = registry[key(type)] as? () -> T else {
            fatalError("ServiceLocator: no registration for \(T.self)")
        }
        return factory()
    }

    private func key<T>(_ type: T.Type) -> String {
        String(describing: type)
    }
}
