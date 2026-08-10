enum AgentMessageRole { user, assistant }

class AgentSource {
  final String id;
  final String title;
  final String? url;

  const AgentSource({required this.id, required this.title, this.url});

  factory AgentSource.fromJson(Map<String, dynamic> json) {
    return AgentSource(
      id: json['id']?.toString() ?? '',
      title: json['title']?.toString() ?? 'Care guidance',
      url: json['url']?.toString(),
    );
  }
}

class AgentActionPreview {
  final String type;
  final String title;
  final String summary;
  final String details;
  final String patientName;

  const AgentActionPreview({
    required this.type,
    required this.title,
    required this.summary,
    required this.details,
    required this.patientName,
  });

  factory AgentActionPreview.fromJson(Map<String, dynamic> json) {
    return AgentActionPreview(
      type: json['type']?.toString() ?? '',
      title: json['title']?.toString() ?? 'Confirm action',
      summary: json['summary']?.toString() ?? '',
      details: json['details']?.toString() ?? '',
      patientName: json['patientName']?.toString() ?? 'Selected senior',
    );
  }
}

class AgentPendingAction {
  final String token;
  final AgentActionPreview preview;
  final int expiresInSeconds;

  const AgentPendingAction({
    required this.token,
    required this.preview,
    required this.expiresInSeconds,
  });

  factory AgentPendingAction.fromJson(Map<String, dynamic> json) {
    final rawPreview = json['preview'];
    return AgentPendingAction(
      token: json['token']?.toString() ?? '',
      preview: AgentActionPreview.fromJson(
        rawPreview is Map
            ? Map<String, dynamic>.from(rawPreview)
            : const <String, dynamic>{},
      ),
      expiresInSeconds: int.tryParse(json['expiresInSeconds']?.toString() ?? '') ?? 600,
    );
  }
}

class AgentChatMessage {
  final String id;
  final AgentMessageRole role;
  final String text;
  final DateTime timestamp;
  final List<AgentSource> sources;

  const AgentChatMessage({
    required this.id,
    required this.role,
    required this.text,
    required this.timestamp,
    this.sources = const [],
  });

  Map<String, String> toHistoryJson() => {
        'role': role == AgentMessageRole.user ? 'user' : 'assistant',
        'text': text,
      };
}

class AgentChatResponse {
  final String reply;
  final AgentPendingAction? action;
  final List<AgentSource> sources;
  final String model;

  const AgentChatResponse({
    required this.reply,
    required this.action,
    required this.sources,
    required this.model,
  });

  factory AgentChatResponse.fromJson(Map<String, dynamic> json) {
    final actionJson = json['action'];
    return AgentChatResponse(
      reply: json['reply']?.toString() ?? 'I could not prepare a response.',
      action: actionJson is Map
          ? AgentPendingAction.fromJson(Map<String, dynamic>.from(actionJson))
          : null,
      sources: (json['sources'] as List<dynamic>? ?? const [])
          .whereType<Map>()
          .map((item) => AgentSource.fromJson(Map<String, dynamic>.from(item)))
          .toList(),
      model: json['model']?.toString() ?? '',
    );
  }
}

class AgentActionResult {
  final String id;
  final String resourceType;
  final String message;

  const AgentActionResult({
    required this.id,
    required this.resourceType,
    required this.message,
  });

  factory AgentActionResult.fromJson(Map<String, dynamic> json) {
    return AgentActionResult(
      id: json['id']?.toString() ?? '',
      resourceType: json['resourceType']?.toString() ?? '',
      message: json['message']?.toString() ?? 'Action completed.',
    );
  }
}
