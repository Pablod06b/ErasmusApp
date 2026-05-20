// UserProfileCodableTests.swift
// Regresión del hotfix #12: añadir `blockedUserIds` rompía perfiles antiguos.
import XCTest
@testable import Erasmus_App

final class UserProfileCodableTests: XCTestCase {

    func test_decode_profile_without_blockedUserIds_succeeds() throws {
        // JSON simulando un perfil "antiguo" creado antes de añadir blockedUserIds
        let json = """
        {
          "id": "abc123",
          "email": "pablo@test.com",
          "displayName": "Pablo",
          "username": "pablo",
          "createdAt": 770000000.0,
          "lastLogin": 770000000.0,
          "interests": [],
          "destination": "Salamanca",
          "photoURL": "",
          "bio": "",
          "onboardingCompleted": true,
          "postsCount": 0,
          "eventsCount": 0,
          "connectionsCount": 0,
          "university": "USAL",
          "career": "Informática",
          "erasmusStatus": "actual",
          "languages": [],
          "permissions": {
            "location": false,
            "notifications": false,
            "camera": false,
            "isPrivateAccount": false,
            "showOnlineStatus": true,
            "allowNotifications": true
          },
          "followerIds": [],
          "followingIds": [],
          "friendIds": [],
          "pendingFriendRequestIds": [],
          "savedPostIds": [],
          "savedEventIds": [],
          "savedCityNames": [],
          "savedUserIds": [],
          "originCountry": "España",
          "originCity": "",
          "accountType": "student"
        }
        """.data(using: .utf8)!

        let decoder = JSONDecoder()
        decoder.dateDecodingStrategy = .secondsSince1970
        let profile = try decoder.decode(UserProfile.self, from: json)

        XCTAssertEqual(profile.id, "abc123")
        XCTAssertEqual(profile.displayName, "Pablo")
        XCTAssertNil(profile.blockedUserIds, "Si no está en el JSON debe quedar nil, no fallar")
    }

    func test_decode_profile_with_blockedUserIds_succeeds() throws {
        let json = """
        {
          "id": "abc",
          "email": "a@a.com",
          "displayName": "A",
          "username": "a",
          "createdAt": 770000000.0,
          "lastLogin": 770000000.0,
          "interests": [],
          "destination": "",
          "photoURL": "",
          "bio": "",
          "onboardingCompleted": true,
          "postsCount": 0,
          "eventsCount": 0,
          "connectionsCount": 0,
          "university": "",
          "career": "",
          "erasmusStatus": "",
          "languages": [],
          "permissions": {
            "location": false, "notifications": false, "camera": false,
            "isPrivateAccount": false, "showOnlineStatus": true, "allowNotifications": true
          },
          "followerIds": [], "followingIds": [], "friendIds": [],
          "pendingFriendRequestIds": [], "savedPostIds": [], "savedEventIds": [],
          "savedCityNames": [], "savedUserIds": [],
          "blockedUserIds": ["user1", "user2"],
          "originCountry": "España", "originCity": "", "accountType": "student"
        }
        """.data(using: .utf8)!

        let decoder = JSONDecoder()
        decoder.dateDecodingStrategy = .secondsSince1970
        let profile = try decoder.decode(UserProfile.self, from: json)
        XCTAssertEqual(profile.blockedUserIds?.count, 2)
    }
}
