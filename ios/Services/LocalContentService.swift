import Foundation

final class LocalContentService {
    static let shared = LocalContentService()

    private func loadJSON<T: Decodable>(_ path: String) -> T? {
        let url = URL(fileURLWithPath: path)
        guard let data = try? Data(contentsOf: url) else { return nil }
        return try? JSONDecoder().decode(T.self, from: data)
    }

    func loadPOIList() -> [POI] {
        let path = "content/poi.json"
        struct Wrapper: Decodable { let items: [POI] }
        return (loadJSON(path) as Wrapper?)?.items ?? []
    }

    func loadRoutes() -> [RoutePlan] {
        let path = "content/routes.json"
        struct Wrapper: Decodable { let items: [RoutePlan] }
        return (loadJSON(path) as Wrapper?)?.items ?? []
    }
}