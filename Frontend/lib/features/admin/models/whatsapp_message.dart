class WhatsAppMessage {
  final String id;
  final String conversationId;
  final String direction;
  final String? waMessageId;
  final String text;
  final String status;
  final DateTime createdAt;

  const WhatsAppMessage({
    required this.id,
    required this.conversationId,
    required this.direction,
    required this.waMessageId,
    required this.text,
    required this.status,
    required this.createdAt,
  });

  factory WhatsAppMessage.fromJson(Map<String, dynamic> json) {
    DateTime parseDate(dynamic value) {
      if (value == null) return DateTime.now();
      final parsed = DateTime.tryParse(value.toString());
      return parsed ?? DateTime.now();
    }

    return WhatsAppMessage(
      id: (json['id'] ?? '').toString(),
      conversationId: (json['conversationId'] ?? json['conversation_id'] ?? '').toString(),
      direction: (json['direction'] ?? 'IN').toString(),
      waMessageId: (json['waMessageId'] ?? json['wa_message_id'])?.toString(),
      text: (json['text'] ?? '').toString(),
      status: (json['status'] ?? '').toString(),
      createdAt: parseDate(json['createdAt'] ?? json['created_at']),
    );
  }
}
