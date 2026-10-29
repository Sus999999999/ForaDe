class ChatMessage {
  final String id;
  final String senderId;
  final String text;
  final DateTime sentAt;

  const ChatMessage({
    required this.id,
    required this.senderId,
    required this.text,
    required this.sentAt,
  });
}

/// Conversación temporal entre un rentero (dueño del departamento) y un
/// usuario que lo contacta (normalmente un rentador).
/// Al finalizarla se elimina por completo.
class ChatConversation {
  final String id;
  final String apartmentId;
  final String apartmentTitle; // copia, por si el departamento se elimina
  final String ownerId; // rentero
  final String renterId; // quien contacta
  final List<ChatMessage> messages;

  ChatConversation({
    required this.id,
    required this.apartmentId,
    required this.apartmentTitle,
    required this.ownerId,
    required this.renterId,
    List<ChatMessage>? messages,
  }) : messages = messages ?? [];

  bool hasParticipant(String userId) =>
      userId == ownerId || userId == renterId;

  String otherParticipantId(String userId) =>
      userId == ownerId ? renterId : ownerId;

  ChatMessage? get lastMessage => messages.isEmpty ? null : messages.last;
}
