import Foundation
import Combine

/// The World Clock list (iOS 6 starts with Cupertino) and the city database
/// used by "Choose a city".
final class WorldClockStore: ObservableObject {
    static let shared = WorldClockStore()

    private static let key = "OldClock.WorldClocks"

    @Published private(set) var cities: [WorldCity] = []

    /// Every city that can be added (bundled `WorldCities.json`).
    private(set) lazy var allCities: [WorldCity] = {
        guard let url = Bundle.main.url(forResource: "WorldCities", withExtension: "json"),
              let data = try? Data(contentsOf: url),
              let list = try? JSONDecoder().decode([WorldCity].self, from: data) else {
            return [.cupertino]
        }
        return list
    }()

    private init() {
        if let data = UserDefaults.standard.data(forKey: Self.key),
           let saved = try? JSONDecoder().decode([WorldCity].self, from: data) {
            cities = saved
        } else {
            cities = [.cupertino]
        }
    }

    func add(_ city: WorldCity) {
        guard !cities.contains(city) else { return }
        cities.append(city)
        save()
    }

    func remove(_ city: WorldCity) {
        cities.removeAll { $0 == city }
        save()
    }

    func move(from source: Int, to destination: Int) {
        guard cities.indices.contains(source), cities.indices.contains(destination), source != destination else { return }
        let city = cities.remove(at: source)
        cities.insert(city, at: destination)
        save()
    }

    /// iOS 6 search: cities whose name (or country) starts with the text,
    /// then those that contain it.
    func search(_ text: String) -> [WorldCity] {
        let query = text.trimmingCharacters(in: .whitespaces)
        guard !query.isEmpty else { return [] }
        let options: String.CompareOptions = [.caseInsensitive, .diacriticInsensitive]
        let prefix = allCities.filter { city in
            city.name.range(of: query, options: options.union(.anchored)) != nil
        }
        let words = allCities.filter { city in
            guard !prefix.contains(city) else { return false }
            return city.displayName.components(separatedBy: CharacterSet(charactersIn: " ,-"))
                .contains { $0.range(of: query, options: options.union(.anchored)) != nil }
        }
        return prefix + words
    }

    private func save() {
        if let data = try? JSONEncoder().encode(cities) {
            UserDefaults.standard.set(data, forKey: Self.key)
        }
    }
}
