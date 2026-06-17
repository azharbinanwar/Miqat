enum AsyncState<T> {
    case idle
    case loading
    case success(T)
    case failure(String)
}
