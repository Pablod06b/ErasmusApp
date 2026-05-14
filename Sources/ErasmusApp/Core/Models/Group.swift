import Foundation

enum GroupType: String, Codable, CaseIterable {
    case friends = "Amigos"
    case flatmates = "Piso"
    case erasmus = "Erasmus"
    case trip = "Viaje"
    case plan = "Plan"

    var icon: String {
        switch self {
        case .friends: return "person.3.fill"
        case .flatmates: return "house.fill"
        case .erasmus: return "graduationcap.fill"
        case .trip: return "airplane"
        case .plan: return "map.fill"
        }
    }
}

enum GroupRole: String, Codable {
    case admin = "Admin"
    case moderator = "Moderador"
    case member = "Miembro"
}

struct GroupTask: Identifiable, Codable {
    var id: String = UUID().uuidString
    var title: String
    var isDone: Bool = false
    var assignedTo: String?
    var createdAt: Date = Date()
}

struct GroupCalendarEvent: Identifiable, Codable {
    var id: String = UUID().uuidString
    var title: String
    var date: Date
    var description: String
    var createdBy: String
}

struct GroupMemberRole: Codable {
    let userId: String
    let role: GroupRole
}

struct SocialGroup: Identifiable, Codable {
    let id: String
    var name: String
    var description: String
    let city: String
    let inviteCode: String
    var imageUrl: String?
    var memberIds: [String]
    var memberRoles: [String: String]
    let createdAt: Date
    var groupType: GroupType
    var tasks: [GroupTask]
    var calendarEvents: [GroupCalendarEvent]

    init(id: String, name: String, description: String, city: String, inviteCode: String, imageUrl: String? = nil, memberIds: [String] = [], memberRoles: [String: String] = [:], createdAt: Date = Date(), groupType: GroupType = .erasmus, tasks: [GroupTask] = [], calendarEvents: [GroupCalendarEvent] = []) {
        self.id = id
        self.name = name
        self.description = description
        self.city = city
        self.inviteCode = inviteCode
        self.imageUrl = imageUrl
        self.memberIds = memberIds
        self.memberRoles = memberRoles
        self.createdAt = createdAt
        self.groupType = groupType
        self.tasks = tasks
        self.calendarEvents = calendarEvents
    }

    func role(for userId: String) -> GroupRole {
        guard let roleRaw = memberRoles[userId], let role = GroupRole(rawValue: roleRaw) else {
            return .member
        }
        return role
    }

    static let sample = SocialGroup(
        id: "group_123",
        name: "Erasmus Roma 2025",
        description: "El grupo oficial para todos los que vamos a Roma este año 🇮🇹🍕",
        city: "Roma",
        inviteCode: "ROMA25",
        memberIds: ["user_1", "user_2"],
        groupType: .erasmus
    )
}
