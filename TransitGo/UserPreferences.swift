import SwiftUI
import Combine

final class UserPreferences: ObservableObject {
    // Salik: include AED 4/gate toll estimate in displayed fares
    @AppStorage("includeSalik")     var includeSalik:      Bool = true
    // Subscription discounts
    @AppStorage("careemPlusActive") var careemPlusActive:  Bool = false
    @AppStorage("uberOneActive")    var uberOneActive:     Bool = false

    // Careem Plus: ~10% off Hala rides (approximate — verify current offer)
    static let careemPlusDiscount: Double = 0.10
    // Uber One: ~5% off UberX in UAE (approximate — verify)
    static let uberOneDiscount: Double    = 0.05
}
