import 'package:firebase_messaging/firebase_messaging.dart';

enum PushAuthorizationStatus { notDetermined, granted, denied, provisional }

class PushMessage {
  const PushMessage({required this.data, this.messageId});
  final Map<String, dynamic> data;
  final String? messageId;
}

abstract interface class PushMessagingGateway {
  Stream<PushMessage> get foregroundMessages;
  Stream<PushMessage> get openedMessages;
  Stream<String> get tokenRefreshes;

  Future<PushMessage?> getInitialMessage();
  Future<PushAuthorizationStatus> authorizationStatus();
  Future<PushAuthorizationStatus> requestPermission();
  Future<String?> getToken();
  Future<void> deleteToken();
}

class FirebasePushMessagingGateway implements PushMessagingGateway {
  FirebasePushMessagingGateway(this._messaging);

  final FirebaseMessaging _messaging;

  PushMessage _message(RemoteMessage message) =>
      PushMessage(data: message.data, messageId: message.messageId);

  @override
  Stream<PushMessage> get foregroundMessages =>
      FirebaseMessaging.onMessage.map(_message);

  @override
  Stream<PushMessage> get openedMessages =>
      FirebaseMessaging.onMessageOpenedApp.map(_message);

  @override
  Stream<String> get tokenRefreshes => _messaging.onTokenRefresh;

  @override
  Future<PushMessage?> getInitialMessage() async {
    final message = await _messaging.getInitialMessage();
    return message == null ? null : _message(message);
  }

  @override
  Future<PushAuthorizationStatus> authorizationStatus() async =>
      _status((await _messaging.getNotificationSettings()).authorizationStatus);

  @override
  Future<PushAuthorizationStatus> requestPermission() async => _status(
    (await _messaging.requestPermission(
      alert: true,
      badge: true,
      sound: true,
      provisional: false,
    )).authorizationStatus,
  );

  PushAuthorizationStatus _status(
    AuthorizationStatus status,
  ) => switch (status) {
    AuthorizationStatus.authorized => PushAuthorizationStatus.granted,
    AuthorizationStatus.provisional => PushAuthorizationStatus.provisional,
    AuthorizationStatus.denied => PushAuthorizationStatus.denied,
    AuthorizationStatus.notDetermined => PushAuthorizationStatus.notDetermined,
  };

  @override
  Future<String?> getToken() => _messaging.getToken();

  @override
  Future<void> deleteToken() => _messaging.deleteToken();
}
