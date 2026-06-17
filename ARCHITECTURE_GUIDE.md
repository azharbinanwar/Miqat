# Architecture Coding Guide — SwiftUI Clean Architecture + ViewModel (BLoC Equivalent)

This guide mirrors the Flutter Clean Architecture + BLoC pattern, translated to Swift/SwiftUI for macOS.

**Equivalent mapping:**
| Flutter | Swift/SwiftUI |
|---------|--------------|
| `sealed class` State | `enum` State |
| Cubit | `@Observable` ViewModel |
| `DataState<T>` | `AsyncState<T>` (custom enum) |
| `@Injectable` / `@LazySingleton` | Protocol + `ServiceLocator` |
| `BlocProvider` | `.environment()` / `.environmentObject()` |
| `BlocBuilder` | `switch viewModel.state { }` in View body |
| Entity | `struct` (pure, `Equatable`) |
| Model | `Codable struct` |

---

## Folder Structure

```
Miqat/
├── Core/
│   ├── AsyncState.swift          # DataState<T> equivalent (loading/success/failure)
│   ├── UseCase.swift             # Base UseCase protocol
│   └── ServiceLocator.swift      # Dependency injection container
│
└── Features/{FeatureName}/
    ├── Data/
    │   ├── Models/
    │   │   └── {Name}Model.swift         # Codable, maps API/storage fields
    │   ├── Services/
    │   │   ├── {Feature}Service.swift    # Abstract service protocol
    │   │   └── {Feature}ServiceImpl.swift # Concrete implementation
    │   └── Repositories/
    │       └── {Feature}RepositoryImpl.swift
    ├── Domain/
    │   ├── Entities/
    │   │   └── {Name}.swift             # Pure Swift struct, Equatable
    │   ├── Repositories/
    │   │   └── {Feature}Repository.swift # Abstract protocol
    │   └── UseCases/
    │       └── {Action}UseCase.swift
    └── Presentation/
        ├── ViewModels/
        │   ├── {Feature}ViewModel.swift  # @Observable, like Cubit
        │   └── {Feature}State.swift      # enum states, like sealed class
        ├── Views/
        │   └── {Feature}View.swift       # SwiftUI View
        └── Components/
            └── {ComponentName}.swift     # Reusable sub-views
```

---

## Data Flow

```
View → ViewModel → UseCase → Repository → Service → CoreData/UserDefaults/Adhan
         ↓           ↓           ↓            ↓
       State ← AsyncState ← AsyncState ← AsyncState
```

---

## Core Files (set up once)

### AsyncState.swift — equivalent to DataState<T>

```swift
enum AsyncState<T> {
    case idle
    case loading
    case success(T)
    case failure(String)
}
```

### UseCase.swift — base protocol

```swift
protocol UseCase {
    associatedtype Input
    associatedtype Output
    func execute(_ input: Input) async -> Output
}
```

### ServiceLocator.swift — DI container

```swift
final class ServiceLocator {
    static let shared = ServiceLocator()
    private var services: [String: Any] = [:]

    func register<T>(_ type: T.Type, factory: @escaping () -> T) {
        services[String(describing: type)] = factory
    }

    func resolve<T>(_ type: T.Type) -> T {
        guard let factory = services[String(describing: type)] as? () -> T else {
            fatalError("No registration for \(T.self)")
        }
        return factory()
    }
}
```

---

## Step-by-Step Implementation Guide

### STEP 1: Create Entity (Domain Layer)
**Path:** `Features/{Feature}/Domain/Entities/{Name}.swift`

```swift
struct PrayerRecord: Equatable {
    let id: UUID
    let prayer: Prayer      // enum: fajr, dhuhr, asr, maghrib, isha
    let date: Date
    let status: PrayerStatus // enum: prayed, missed, partial
}
```

**Key Points:**
- Pure Swift `struct`, no imports beyond Foundation
- `Equatable` for value comparison (same as Equatable in Flutter)
- No Codable here — that lives in the Model
- Use enums for typed fields, not raw strings

---

### STEP 2: Create Model (Data Layer)
**Path:** `Features/{Feature}/Data/Models/{Name}Model.swift`

```swift
struct PrayerRecordModel: Codable {
    let id: String
    let prayer: String
    let date: Date
    let status: String

    func toEntity() -> PrayerRecord {
        PrayerRecord(
            id: UUID(uuidString: id) ?? UUID(),
            prayer: Prayer(rawValue: prayer) ?? .fajr,
            date: date,
            status: PrayerStatus(rawValue: status) ?? .upcoming
        )
    }

    static func from(_ entity: PrayerRecord) -> PrayerRecordModel {
        PrayerRecordModel(
            id: entity.id.uuidString,
            prayer: entity.prayer.rawValue,
            date: entity.date,
            status: entity.status.rawValue
        )
    }
}
```

**Key Points:**
- `Codable` for storage/serialization
- `toEntity()` maps Model → Entity
- `from(_:)` maps Entity → Model
- Model knows about storage details; Entity stays pure

---

### STEP 3: Create Repository Protocol (Domain Layer)
**Path:** `Features/{Feature}/Domain/Repositories/{Feature}Repository.swift`

```swift
protocol PrayerTrackerRepository {
    func fetchRecords(for date: Date) async -> AsyncState<[PrayerRecord]>
    func saveRecord(_ record: PrayerRecord) async -> AsyncState<Void>
}
```

**Key Points:**
- `protocol` — abstract contract (same as abstract class in Flutter)
- Returns `AsyncState<T>` — never throws directly to caller
- Uses Entity types, not Models

---

### STEP 4: Create Service Protocol (Data Layer)
**Path:** `Features/{Feature}/Data/Services/{Feature}Service.swift`

```swift
protocol PrayerTrackerService {
    func fetchRecords(for date: Date) async -> AsyncState<[PrayerRecordModel]>
    func saveRecord(_ model: PrayerRecordModel) async -> AsyncState<Void>
}
```

**Key Points:**
- Same shape as Repository but uses Model types
- Abstract protocol — implementation is separate

---

### STEP 5: Create Service Implementation (Data Layer)
**Path:** `Features/{Feature}/Data/Services/{Feature}ServiceImpl.swift`

```swift
final class PrayerTrackerServiceImpl: PrayerTrackerService {

    func fetchRecords(for date: Date) async -> AsyncState<[PrayerRecordModel]> {
        do {
            let models = try CoreDataManager.shared.fetchRecords(for: date)
            return .success(models)
        } catch {
            return .failure(error.localizedDescription)
        }
    }

    func saveRecord(_ model: PrayerRecordModel) async -> AsyncState<Void> {
        do {
            try CoreDataManager.shared.save(model)
            return .success(())
        } catch {
            return .failure(error.localizedDescription)
        }
    }
}
```

**Key Points:**
- `final class` — registered as singleton in ServiceLocator
- Always `do/catch` — return `.failure(message)` never rethrow
- Works with Models, not Entities

---

### STEP 6: Create Repository Implementation (Data Layer)
**Path:** `Features/{Feature}/Data/Repositories/{Feature}RepositoryImpl.swift`

```swift
final class PrayerTrackerRepositoryImpl: PrayerTrackerRepository {
    private let service: PrayerTrackerService

    init(service: PrayerTrackerService) {
        self.service = service
    }

    func fetchRecords(for date: Date) async -> AsyncState<[PrayerRecord]> {
        let result = await service.fetchRecords(for: date)
        switch result {
        case .success(let models): return .success(models.map { $0.toEntity() })
        case .failure(let msg):    return .failure(msg)
        default:                   return .failure("Unexpected state")
        }
    }

    func saveRecord(_ record: PrayerRecord) async -> AsyncState<Void> {
        await service.saveRecord(PrayerRecordModel.from(record))
    }
}
```

**Key Points:**
- Injects `PrayerTrackerService` via `init` (constructor injection)
- Converts Models → Entities on the way out
- Delegates directly to service

---

### STEP 7: Create Use Case (Domain Layer)
**Path:** `Features/{Feature}/Domain/UseCases/{Action}UseCase.swift`

```swift
// Fetch (no params → use Void)
final class FetchPrayerRecordsUseCase {
    private let repository: PrayerTrackerRepository

    init(repository: PrayerTrackerRepository) {
        self.repository = repository
    }

    func execute(for date: Date) async -> AsyncState<[PrayerRecord]> {
        await repository.fetchRecords(for: date)
    }
}

// Save (with params)
final class SavePrayerRecordUseCase {
    private let repository: PrayerTrackerRepository

    init(repository: PrayerTrackerRepository) {
        self.repository = repository
    }

    func execute(_ record: PrayerRecord) async -> AsyncState<Void> {
        await repository.saveRecord(record)
    }
}
```

**Key Points:**
- One action per use case (same as Flutter)
- Injects Repository via `init`
- `execute()` is the single entry point — equivalent to `call()` in Flutter

---

### STEP 8: Create State (Presentation Layer)
**Path:** `Features/{Feature}/Presentation/ViewModels/{Feature}State.swift`

```swift
enum PrayerTrackerState {
    case idle
    case loading
    case loaded([PrayerRecord])
    case error(String)
}
```

**Key Points:**
- `enum` with associated values — exact equivalent of Flutter `sealed class`
- 4 standard cases: idle / loading / loaded / error
- Data lives in the `loaded` case

---

### STEP 9: Create ViewModel (Presentation Layer)
**Path:** `Features/{Feature}/Presentation/ViewModels/{Feature}ViewModel.swift`

```swift
@Observable
final class PrayerTrackerViewModel {
    var state: PrayerTrackerState = .idle

    private let fetchRecords: FetchPrayerRecordsUseCase
    private let saveRecord: SavePrayerRecordUseCase

    init(
        fetchRecords: FetchPrayerRecordsUseCase,
        saveRecord: SavePrayerRecordUseCase
    ) {
        self.fetchRecords = fetchRecords
        self.saveRecord = saveRecord
    }

    // GET — equivalent to cubit fetch method
    func loadRecords(for date: Date = .now) {
        state = .loading
        Task {
            let result = await fetchRecords.execute(for: date)
            switch result {
            case .success(let records): state = .loaded(records)
            case .failure(let msg):     state = .error(msg)
            default: break
            }
        }
    }

    // POST — equivalent to cubit action method
    func markPrayed(_ prayer: Prayer, on date: Date = .now) {
        let record = PrayerRecord(
            id: UUID(),
            prayer: prayer,
            date: date,
            status: .prayed
        )
        state = .loading
        Task {
            let result = await saveRecord.execute(record)
            switch result {
            case .success:          loadRecords(for: date)  // refresh
            case .failure(let msg): state = .error(msg)
            default: break
            }
        }
    }
}
```

**Key Points:**
- `@Observable` — Swift 5.9 equivalent of `extends Cubit<State>`
- `var state` is the single source of truth — view auto-updates when it changes
- Set `.loading` before every async call
- Use `Task { }` for async work inside sync methods
- After save → refresh list (same pattern as Flutter cubit)

---

### STEP 10: Use in View (Presentation Layer)
**Path:** `Features/{Feature}/Presentation/Views/{Feature}View.swift`

```swift
struct PrayerTrackerView: View {
    @State private var viewModel = PrayerTrackerViewModel(
        fetchRecords: ServiceLocator.shared.resolve(FetchPrayerRecordsUseCase.self),
        saveRecord: ServiceLocator.shared.resolve(SavePrayerRecordUseCase.self)
    )

    var body: some View {
        Group {
            switch viewModel.state {
            case .idle, .loading:
                ProgressView()

            case .loaded(let records):
                ForEach(records, id: \.id) { record in
                    PrayerRowView(record: record) {
                        viewModel.markPrayed(record.prayer)
                    }
                }

            case .error(let message):
                Text(message).foregroundStyle(.red)
            }
        }
        .onAppear { viewModel.loadRecords() }
    }
}
```

**Key Points:**
- `@State private var viewModel` — creates and owns the ViewModel
- `switch viewModel.state` — equivalent to `BlocBuilder` with state checks
- Handle all 4 cases
- Call fetch on `.onAppear` — equivalent to `..fetchSymptoms()` in BlocProvider
- Pass ViewModel down to child views via `environment` or direct init

---

## Dependency Injection Setup

Register all dependencies once at app startup in `MiqatApp.swift`:

```swift
func setupDI() {
    let service = PrayerTrackerServiceImpl()
    let repository = PrayerTrackerRepositoryImpl(service: service)

    ServiceLocator.shared.register(FetchPrayerRecordsUseCase.self) {
        FetchPrayerRecordsUseCase(repository: repository)
    }
    ServiceLocator.shared.register(SavePrayerRecordUseCase.self) {
        SavePrayerRecordUseCase(repository: repository)
    }
}
```

---

## Checklist for New Feature

- [ ] Create Entity in `Domain/Entities/` — pure struct, Equatable
- [ ] Create Model in `Data/Models/` — Codable, toEntity() / from()
- [ ] Create Repository protocol in `Domain/Repositories/`
- [ ] Create Service protocol in `Data/Services/`
- [ ] Create Service implementation — do/catch, return AsyncState
- [ ] Create Repository implementation — maps Model ↔ Entity
- [ ] Create Use Case(s) in `Domain/UseCases/` — one per action
- [ ] Create State enum in `Presentation/ViewModels/`
- [ ] Create ViewModel with `@Observable` — emit states, inject use cases
- [ ] Register dependencies in `ServiceLocator` setup
- [ ] Use ViewModel in View with `switch viewModel.state { }`

---

## Key Conventions

### Naming
| Layer | Flutter | Swift |
|-------|---------|-------|
| Entity | `Symptom` | `PrayerRecord` |
| Model | `SymptomModel` | `PrayerRecordModel` |
| Repository | `SymptomsRepository` | `PrayerTrackerRepository` |
| Repository Impl | `SymptomsRepositoryImpl` | `PrayerTrackerRepositoryImpl` |
| Service | `SymptomsService` | `PrayerTrackerService` |
| Service Impl | `SymptomsServiceImpl` | `PrayerTrackerServiceImpl` |
| Use Case | `FetchSymptomsListUseCase` | `FetchPrayerRecordsUseCase` |
| ViewModel | `SymptomsCubit` | `PrayerTrackerViewModel` |
| State | `SymptomsState` | `PrayerTrackerState` |

### Return Types
- Always return `AsyncState<T>` from services, repositories, use cases
- Use `.success(data)` for success
- Use `.failure(message)` for errors
- Never `throw` across layer boundaries

### Error Handling
- Always `do/catch` in service implementations
- Return `.failure(error.localizedDescription)` — never rethrow
- ViewModel maps failure → `.error(message)` state

### State Updates
- Always set `.loading` before any async call
- After a write operation — re-fetch to refresh (don't mutate state manually)
- ViewModel is the only place that mutates `state`
