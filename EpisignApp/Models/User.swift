import Foundation

struct EpisignUser: Codable {
    let login: String
    let email: String
    let firstName: String
    let lastName: String
    let uid: Int
    let gid: Int
    let groups: [Group]
    let graduationYear: Int?

    var displayName: String { "\(firstName) \(lastName)" }

    var initials: String {
        let f = firstName.first.map(String.init) ?? ""
        let l = lastName.first.map(String.init) ?? ""
        return (f + l).uppercased()
    }

    var promoLabel: String {
        guard let year = graduationYear else { return "EPITA" }
        return "EPITA · Promotion \(year)"
    }

    struct Group: Codable {
        let slug: String
        let name: String
        let gid: Int
        let kind: String
    }
}
