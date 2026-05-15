class WhatsAppConversation {
  final String id;
  final String phone;
  final String status;
  final DateTime? lastMessageAt;
  final DateTime createdAt;
  final String? lastMessageText;
  final String? lastMessageDirection;
  final bool paused;

  const WhatsAppConversation({
    required this.id,
    required this.phone,
    required this.status,
    required this.lastMessageAt,
    required this.createdAt,
    this.lastMessageText,
    this.lastMessageDirection,
    this.paused = false,
  });

  factory WhatsAppConversation.fromJson(Map<String, dynamic> json) {
    DateTime? parseNullableDate(dynamic value) {
      if (value == null) return null;
      final asString = value.toString();
      if (asString.isEmpty) return null;
      return DateTime.tryParse(asString);
    }

    DateTime parseDate(dynamic value) {
      final parsed = parseNullableDate(value);
      return parsed ?? DateTime.now();
    }

    return WhatsAppConversation(
      id: (json['id'] ?? '').toString(),
      phone: (json['phone'] ?? '').toString(),
      status: (json['status'] ?? 'OPEN').toString(),
      lastMessageAt: parseNullableDate(json['lastMessageAt'] ?? json['last_message_at']),
      createdAt: parseDate(json['createdAt'] ?? json['created_at']),
      lastMessageText: (json['lastMessageText'] ?? json['last_message_text'])?.toString(),
      lastMessageDirection: (json['lastMessageDirection'] ?? json['last_message_direction'])?.toString(),
      paused: json['paused'] == true,
    );
  }
}
