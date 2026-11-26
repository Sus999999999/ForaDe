class ChatMessage {
  final String id;
  final String conversationId;
  final String senderId;
  final String text;
  final DateTime sentAt;

  const ChatMessage({
    required this.id,
    this.conversationId = '',
    required this.senderId,
    required this.text,
    required this.sentAt,
  });

  factory ChatMessage.fromMap(Map<String, dynamic> map) {
    return ChatMessage(
      id: map['id']?.toString() ?? '',
      conversationId: map['conversation_id']?.toString() ?? '',
      senderId: map['sender_id']?.toString() ?? '',
      text: (map['text'] as String?) ?? '',
      sentAt: map['created_at'] != null
          ? DateTime.tryParse(map['created_at'].toString())?.toLocal() ?? DateTime.now()
          : (map['sent_at'] != null
              ? DateTime.tryParse(map['sent_at'].toString())?.toLocal() ?? DateTime.now()
              : DateTime.now()),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      if (conversationId.isNotEmpty) 'conversation_id': conversationId,
      'sender_id': senderId,
      'text': text,
      'created_at': sentAt.toUtc().toIso8601String(),
    };
  }
}

/// Conversación entre un rentero (dueño del departamento) y un
/// rentador que lo contacta. Sincronizada con Supabase y WebSockets.
class ChatConversation {
  final String id;
  final String apartmentId;
  final String apartmentTitle;
  final String ownerId;
  final String renterId;
  final String ownerName;
  final String renterName;
  final String ownerAvatarUrl;
  final String renterAvatarUrl;
  final DateTime createdAt;
  final DateTime updatedAt;
  final List<ChatMessage> messages;

  ChatConversation({
    required this.id,
    required this.apartmentId,
    required this.apartmentTitle,
    required this.ownerId,
    required this.renterId,
    this.ownerName = 'Propietario',
    this.renterName = 'Rentador',
    this.ownerAvatarUrl = '',
    this.renterAvatarUrl = '',
    DateTime? createdAt,
    DateTime? updatedAt,
    List<ChatMessage>? messages,
  })  : createdAt = createdAt ?? DateTime.now(),
        updatedAt = updatedAt ?? DateTime.now(),
        messages = messages ?? [];

  bool hasParticipant(String userId) =>
      userId == ownerId || userId == renterId;

  String otherParticipantId(String userId) =>
      userId == ownerId ? renterId : ownerId;

  String otherParticipantName(String userId) =>
      userId == ownerId ? renterName : ownerName;

  String otherParticipantAvatar(String userId) =>
      userId == ownerId ? renterAvatarUrl : ownerAvatarUrl;

  ChatMessage? get lastMessage => messages.isEmpty ? null : messages.last;

  ChatConversation copyWith({
    String? id,
    String? apartmentId,
    String? apartmentTitle,
    String? ownerId,
    String? renterId,
    String? ownerName,
    String? renterName,
    String? ownerAvatarUrl,
    String? renterAvatarUrl,
    DateTime? createdAt,
    DateTime? updatedAt,
    List<ChatMessage>? messages,
  }) {
    return ChatConversation(
      id: id ?? this.id,
      apartmentId: apartmentId ?? this.apartmentId,
      apartmentTitle: apartmentTitle ?? this.apartmentTitle,
      ownerId: ownerId ?? this.ownerId,
      renterId: renterId ?? this.renterId,
      ownerName: ownerName ?? this.ownerName,
      renterName: renterName ?? this.renterName,
      ownerAvatarUrl: ownerAvatarUrl ?? this.ownerAvatarUrl,
      renterAvatarUrl: renterAvatarUrl ?? this.renterAvatarUrl,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      messages: messages ?? List.from(this.messages),
    );
  }

  factory ChatConversation.fromMap(
    Map<String, dynamic> map, {
    List<ChatMessage>? messages,
  }) {
    final ownerData = map['owner'] as Map<String, dynamic>?;
    final renterData = map['renter'] as Map<String, dynamic>?;

    return ChatConversation(
      id: map['id']?.toString() ?? '',
      apartmentId: map['apartment_id']?.toString() ?? '',
      apartmentTitle: (map['apartment_title'] as String?) ?? 'Departamento',
      ownerId: map['owner_id']?.toString() ?? '',
      renterId: map['renter_id']?.toString() ?? '',
      ownerName: (ownerData?['name'] as String?) ?? 'Propietario',
      renterName: (renterData?['name'] as String?) ?? 'Rentador',
      ownerAvatarUrl: (ownerData?['avatar_url'] as String?) ?? '',
      renterAvatarUrl: (renterData?['avatar_url'] as String?) ?? '',
      createdAt: map['created_at'] != null
          ? DateTime.tryParse(map['created_at'].toString())?.toLocal() ?? DateTime.now()
          : DateTime.now(),
      updatedAt: map['updated_at'] != null
          ? DateTime.tryParse(map['updated_at'].toString())?.toLocal() ?? DateTime.now()
          : DateTime.now(),
      messages: messages ?? [],
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'apartment_id': apartmentId,
      'apartment_title': apartmentTitle,
      'owner_id': ownerId,
      'renter_id': renterId,
      'created_at': createdAt.toUtc().toIso8601String(),
      'updated_at': updatedAt.toUtc().toIso8601String(),
    };
  }
}
