import SwiftData
import SwiftUI
import Combine

class DataManager: ObservableObject {
    static let shared = DataManager()
    
    let localContainer: ModelContainer
    @Published var cloudContainer: ModelContainer?
    
    private init() {
        self.localContainer = Self.createLocalContainer()
    }
    
    private static func createLocalContainer() -> ModelContainer {
        let schema = Schema([Expense.self, Income.self])
        let config = ModelConfiguration(schema: schema, isStoredInMemoryOnly: false)
        
        do {
            return try ModelContainer(for: schema, configurations: [config])
        } catch {
            print("❌ Failed to load local container, deleting old store and retrying: \(error)")
            
            // Delete old store
            let url = config.url
            if FileManager.default.fileExists(atPath: url.path) {
                try? FileManager.default.removeItem(at: url)
            }
            
            // Retry
            do {
                return try ModelContainer(for: schema, configurations: [config])
            } catch {
                fatalError("❌ Could not initialize local container even after reset: \(error)")
            }
        }
    }
    
    func setupCloudContainer(forUser isAuthenticated: Bool) {
        // Only enable cloud container if user is authenticated AND iCloud sync is enabled
        let shouldEnableCloud = isAuthenticated && UserDefaults.standard.bool(forKey: "iCloudSyncEnabled")
        
        guard shouldEnableCloud else {
            // Ensure cloud container is nil when not authenticated
            if cloudContainer != nil {
                cloudContainer = nil
                print("☁️ iCloud sync disabled — using local data only.")
            }
            return
        }
        
        // Only create cloud container if it doesn't exist
        guard cloudContainer == nil else { return }
        
        let schema = Schema([Expense.self, Income.self])
        let cloudConfig = ModelConfiguration(
            "iCloud.com.piggyflowlabs.PiggyFlow",
            schema: schema,
            isStoredInMemoryOnly: false
        )
        
        do {
            cloudContainer = try ModelContainer(for: schema, configurations: [cloudConfig])
            print("✅ iCloud container initialized.")
        } catch {
            print("❌ Failed to create CloudKit container: \(error)")
            cloudContainer = nil
        }
    }
    
    // Method to completely disable cloud sync
    func disableCloudSync() {
        cloudContainer = nil
        UserDefaults.standard.set(false, forKey: "iCloudSyncEnabled")
        print("🔴 Cloud sync completely disabled")
    }
}
