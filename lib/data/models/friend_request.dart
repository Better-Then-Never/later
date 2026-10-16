enum FriendRequestStatus {
  pending,
  accepted;

  static FriendRequestStatus parse(Object? value) =>
      value == 'accepted' ? accepted : pending;
}

/// `friend_requests/{fromUserId}_{toUserId}`.
class FriendRequest {
  const FriendRequest({
    required this.fromUserId,
    required this.toUserId,
    required this.status,
    this.createdAt,
  });

  final String fromUserId;
  final String toUserId;
  final FriendRequestStatus status;
  final DateTime? createdAt;

  String get id => idFor(fromUserId, toUserId);

  static String idFor(String fromUserId, String toUserId) =>
      '${fromUserId}_$toUserId';
}

/// Relationship between the signed-in user and another user, as shown on
/// profile buttons and suggestion rows.
enum FriendRelation { self, friends, requestSent, requestReceived, none }
