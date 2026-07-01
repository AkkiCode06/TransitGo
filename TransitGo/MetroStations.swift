import CoreLocation

// Dubai Metro stations — approximate coordinates [VERIFY against RTA official data]
// Red Line (Rashidiya ↔ UAE Exchange) + Green Line subset

struct MetroStation: Identifiable {
    let id = UUID()
    let name: String
    let line: MetroLine
    let coordinate: CLLocationCoordinate2D
}

enum MetroLine: String {
    case red   = "Red Line"
    case green = "Green Line"
    var color: String { self == .red ? "FF3B30" : "34C759" }
}

let dubaiMetroStations: [MetroStation] = [
    // Red Line — ordered roughly west to east
    .init(name: "UAE Exchange",       line: .red,   coordinate: .init(latitude: 25.0468, longitude: 55.1220)),
    .init(name: "Jebel Ali",          line: .red,   coordinate: .init(latitude: 25.0579, longitude: 55.1365)),
    .init(name: "Al Furjan",          line: .red,   coordinate: .init(latitude: 25.0594, longitude: 55.1528)),
    .init(name: "Discovery Gardens",  line: .red,   coordinate: .init(latitude: 25.0553, longitude: 55.1703)),
    .init(name: "Ibn Battuta",        line: .red,   coordinate: .init(latitude: 25.0537, longitude: 55.1892)),
    .init(name: "Energy",             line: .red,   coordinate: .init(latitude: 25.0594, longitude: 55.2055)),
    .init(name: "Nakheel Harbour",    line: .red,   coordinate: .init(latitude: 25.0633, longitude: 55.1381)),
    .init(name: "Jumeirah Lakes Towers", line: .red, coordinate: .init(latitude: 25.0708, longitude: 55.1444)),
    .init(name: "DMCC",               line: .red,   coordinate: .init(latitude: 25.0744, longitude: 55.1481)),
    .init(name: "Sobha Realty",       line: .red,   coordinate: .init(latitude: 25.0783, longitude: 55.1527)),
    .init(name: "GEMS Jumeirah Park", line: .red,   coordinate: .init(latitude: 25.0829, longitude: 55.1569)),
    .init(name: "Nakheel",            line: .red,   coordinate: .init(latitude: 25.0900, longitude: 55.1634)),
    .init(name: "Sharaf DG",          line: .red,   coordinate: .init(latitude: 25.1003, longitude: 55.1741)),
    .init(name: "Al Barsha",          line: .red,   coordinate: .init(latitude: 25.1156, longitude: 55.1890)),
    .init(name: "Mall of the Emirates", line: .red, coordinate: .init(latitude: 25.1175, longitude: 55.2003)),
    .init(name: "Emirates",           line: .red,   coordinate: .init(latitude: 25.1240, longitude: 55.2105)),
    .init(name: "Equiti",             line: .red,   coordinate: .init(latitude: 25.1313, longitude: 55.2144)),
    .init(name: "Onpassive",          line: .red,   coordinate: .init(latitude: 25.1509, longitude: 55.2235)),
    .init(name: "First Abu Dhabi Bank", line: .red, coordinate: .init(latitude: 25.1641, longitude: 55.2303)),
    .init(name: "ADCB",               line: .red,   coordinate: .init(latitude: 25.1808, longitude: 55.2409)),
    .init(name: "Al Jafiliya",        line: .red,   coordinate: .init(latitude: 25.1924, longitude: 55.2505)),
    .init(name: "World Trade Centre", line: .red,   coordinate: .init(latitude: 25.2019, longitude: 55.2716)),
    .init(name: "Burj Khalifa / Dubai Mall", line: .red, coordinate: .init(latitude: 25.1971, longitude: 55.2792)),
    .init(name: "Financial Centre",   line: .red,   coordinate: .init(latitude: 25.2087, longitude: 55.2733)),
    .init(name: "Emirates Towers",    line: .red,   coordinate: .init(latitude: 25.2182, longitude: 55.2822)),
    .init(name: "Al Safa",            line: .red,   coordinate: .init(latitude: 25.2297, longitude: 55.2969)),
    .init(name: "Business Bay",       line: .red,   coordinate: .init(latitude: 25.2332, longitude: 55.3024)),
    .init(name: "Noor Bank",          line: .red,   coordinate: .init(latitude: 25.2372, longitude: 55.3079)),
    .init(name: "Union",              line: .red,   coordinate: .init(latitude: 25.2676, longitude: 55.3095)),
    .init(name: "BurJuman",           line: .red,   coordinate: .init(latitude: 25.2527, longitude: 55.3077)),
    .init(name: "Al Fahidi",          line: .red,   coordinate: .init(latitude: 25.2577, longitude: 55.3024)),
    .init(name: "Abu Baker Al Siddique", line: .red, coordinate: .init(latitude: 25.2612, longitude: 55.3144)),
    .init(name: "Salah Al Din",       line: .red,   coordinate: .init(latitude: 25.2587, longitude: 55.3278)),
    .init(name: "Al Rigga",           line: .red,   coordinate: .init(latitude: 25.2589, longitude: 55.3363)),
    .init(name: "Union (Red)",        line: .red,   coordinate: .init(latitude: 25.2671, longitude: 55.3098)),
    .init(name: "Airport Terminal 1", line: .red,   coordinate: .init(latitude: 25.2532, longitude: 55.3641)),
    .init(name: "Airport Terminal 3", line: .red,   coordinate: .init(latitude: 25.2527, longitude: 55.3651)),
    .init(name: "Emirates",           line: .red,   coordinate: .init(latitude: 25.2517, longitude: 55.3733)),
    .init(name: "Rashidiya",          line: .red,   coordinate: .init(latitude: 25.2299, longitude: 55.4029)),
]

extension MetroStation {
    /// Returns stations closest to a coordinate, sorted by distance
    static func nearest(to coord: CLLocationCoordinate2D, from stations: [MetroStation] = dubaiMetroStations, max: Int = 3) -> [MetroStation] {
        let target = CLLocation(latitude: coord.latitude, longitude: coord.longitude)
        return stations
            .sorted { a, b in
                CLLocation(latitude: a.coordinate.latitude, longitude: a.coordinate.longitude).distance(from: target)
                < CLLocation(latitude: b.coordinate.latitude, longitude: b.coordinate.longitude).distance(from: target)
            }
            .prefix(max)
            .map { $0 }
    }

    var clLocation: CLLocation {
        CLLocation(latitude: coordinate.latitude, longitude: coordinate.longitude)
    }
}
