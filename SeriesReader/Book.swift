import Foundation

struct Book: Decodable, Identifiable {
    var id: UUID
    var number: Int
}
