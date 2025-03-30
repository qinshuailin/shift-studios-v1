import FamilyControls
import Combine

class AppBlockingModel: ObservableObject {
    static let shared = AppBlockingModel()
    
    @Published var selection = FamilyActivitySelection()
}
