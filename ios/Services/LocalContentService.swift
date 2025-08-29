import Foundation

class LocalContentService {
    static let shared = LocalContentService()
    
    private init() {}
    
    func loadPOIs() -> [POI] {
        guard let url = Bundle.main.url(forResource: "poi", withExtension: "json", subdirectory: "content"),
              let data = try? Data(contentsOf: url) else {
            return []
        }
        
        struct Wrapper: Decodable { let items: [POI] }
        return (try? JSONDecoder().decode(Wrapper.self, from: data))?.items ?? []
    }
    
    func loadRoutes() -> [Route] {
        guard let url = Bundle.main.url(forResource: "routes", withExtension: "json", subdirectory: "content"),
              let data = try? Data(contentsOf: url) else {
            return []
        }
        
        struct Wrapper: Decodable { let items: [Route] }
        return (try? JSONDecoder().decode(Wrapper.self, from: data))?.items ?? []
    }
}