protocol UseCase {
    associatedtype Input
    associatedtype Output
    func execute(_ input: Input) async -> Output
}
