// AppAnalytics.swift — wrapper sobre FirebaseAnalytics para tipar los eventos clave
import Foundation
import FirebaseAnalytics

/// Catálogo central de eventos. Centralizar evita typos en nombres y
/// permite renombrar/desactivar todo desde un único sitio.
enum AppAnalytics {

    // MARK: - Auth
    static func logSignUp(method: String = "email") {
        Analytics.logEvent(AnalyticsEventSignUp, parameters: [
            AnalyticsParameterMethod: method
        ])
    }

    static func logLogin(method: String = "email") {
        Analytics.logEvent(AnalyticsEventLogin, parameters: [
            AnalyticsParameterMethod: method
        ])
    }

    static func logOnboardingCompleted() {
        Analytics.logEvent("onboarding_completed", parameters: nil)
    }

    // MARK: - Content
    static func logPostCreate(type: String, destination: String) {
        Analytics.logEvent("post_create", parameters: [
            "type": type,
            "destination": destination
        ])
    }

    static func logPostLike(postId: String, isLiked: Bool) {
        Analytics.logEvent("post_like", parameters: [
            "post_id": postId,
            "is_liked": isLiked ? 1 : 0
        ])
    }

    static func logEventCreate(category: String, destination: String) {
        Analytics.logEvent("event_create", parameters: [
            "category": category,
            "destination": destination
        ])
    }

    static func logEventJoin(eventId: String) {
        Analytics.logEvent("event_join", parameters: [
            "event_id": eventId
        ])
    }

    // MARK: - Social
    static func logProfileView(userId: String, isSelf: Bool) {
        Analytics.logEvent("profile_view", parameters: [
            "user_id": userId,
            "is_self": isSelf ? 1 : 0
        ])
    }

    static func logFollow(targetUserId: String) {
        Analytics.logEvent("user_follow", parameters: ["target_user_id": targetUserId])
    }

    static func logUserBlock(targetUserId: String) {
        Analytics.logEvent("user_block", parameters: ["target_user_id": targetUserId])
    }

    static func logFriendRequestSent(targetUserId: String) {
        Analytics.logEvent("friend_request_sent", parameters: ["target_user_id": targetUserId])
    }

    // MARK: - Messaging
    static func logMessageSend(conversationId: String, type: String) {
        Analytics.logEvent("message_send", parameters: [
            "conversation_id": conversationId,
            "message_type": type
        ])
    }

    // MARK: - Discovery / Feed
    static func logFeedSortChange(mode: String) {
        Analytics.logEvent("feed_sort_change", parameters: ["mode": mode])
    }

    static func logDestinationChange(destination: String) {
        Analytics.logEvent("destination_change", parameters: ["destination": destination])
    }

    // MARK: - Moderation
    static func logReport(targetType: String) {
        Analytics.logEvent("report_submit", parameters: ["target_type": targetType])
    }

    // MARK: - Screen view (manual override del auto-screen tracking)
    static func logScreen(_ name: String, className: String? = nil) {
        var params: [String: Any] = [AnalyticsParameterScreenName: name]
        if let className = className {
            params[AnalyticsParameterScreenClass] = className
        }
        Analytics.logEvent(AnalyticsEventScreenView, parameters: params)
    }

    // MARK: - User properties
    /// Establece propiedades del usuario para segmentación
    static func setUserProperties(destination: String?, accountType: String?) {
        Analytics.setUserProperty(destination, forName: "erasmus_destination")
        Analytics.setUserProperty(accountType, forName: "account_type")
    }
}
