import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:flutter_dotenv/flutter_dotenv.dart';

/// A class that represents a recipient of an email
class EmailAddress {
  final String email;
  final String? name;

  EmailAddress({required this.email, this.name});

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> json = {'email': email};
    if (name != null) json['name'] = name;
    return json;
  }
}

/// A class that represents the content of an email
class EmailContent {
  final String type;
  final String value;

  EmailContent({required this.type, required this.value});

  Map<String, dynamic> toJson() {
    return {'type': type, 'value': value};
  }
}

/// A class that represents an attachment to an email
class EmailAttachment {
  final String content;
  final String filename;
  final String type;
  final String? disposition;

  EmailAttachment({
    required this.content,
    required this.filename,
    required this.type,
    this.disposition = 'attachment',
  });

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> json = {
      'content': content,
      'filename': filename,
      'type': type,
    };
    if (disposition != null) json['disposition'] = disposition;
    return json;
  }
}

/// A class representing an email message to be sent through SendGrid
class SendGridMessage {
  final List<EmailAddress> to;
  final EmailAddress from;
  final String subject;
  final List<EmailContent> content;
  final List<EmailAttachment>? attachments;
  final EmailAddress? replyTo;
  final bool? sendAt;
  final List<String>? categories;

  SendGridMessage({
    required this.to,
    required this.from,
    required this.subject,
    required this.content,
    this.attachments,
    this.replyTo,
    this.sendAt,
    this.categories,
  });

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> json = {
      'personalizations': [
        {'to': to.map((recipient) => recipient.toJson()).toList()},
      ],
      'from': from.toJson(),
      'subject': subject,
      'content': content.map((content) => content.toJson()).toList(),
    };

    if (replyTo != null) json['reply_to'] = replyTo!.toJson();
    if (attachments != null && attachments!.isNotEmpty) {
      json['attachments'] =
          attachments!.map((attachment) => attachment.toJson()).toList();
    }
    if (categories != null && categories!.isNotEmpty) {
      json['categories'] = categories;
    }

    return json;
  }
}

/// A service for sending emails through SendGrid API
class SendGridService {
  final String _apiKey;
  final String _baseUrl = 'https://api.sendgrid.com/v3/mail/send';

  SendGridService({String? apiKey})
    : _apiKey = apiKey ?? dotenv.env['SENDGRID_API_KEY'] ?? '';

  /// Creates a simple plain text email
  static SendGridMessage createTextEmail({
    required String toEmail,
    String? toName,
    required String fromEmail,
    String? fromName,
    required String subject,
    required String plainText,
  }) {
    return SendGridMessage(
      to: [EmailAddress(email: toEmail, name: toName)],
      from: EmailAddress(email: fromEmail, name: fromName),
      subject: subject,
      content: [EmailContent(type: 'text/plain', value: plainText)],
    );
  }

  /// Creates an HTML email with plain text alternative
  static SendGridMessage createHtmlEmail({
    required String toEmail,
    String? toName,
    required String fromEmail,
    String? fromName,
    required String subject,
    required String htmlContent,
    String? plainText,
  }) {
    final contents = <EmailContent>[];

    // Always include plain text version first if provided
    if (plainText != null) {
      contents.add(EmailContent(type: 'text/plain', value: plainText));
    }

    // Add HTML content
    contents.add(EmailContent(type: 'text/html', value: htmlContent));

    return SendGridMessage(
      to: [EmailAddress(email: toEmail, name: toName)],
      from: EmailAddress(email: fromEmail, name: fromName),
      subject: subject,
      content: contents,
    );
  }

  /// Sends an email through SendGrid API
  Future<http.Response> sendEmail(SendGridMessage message) async {
    if (_apiKey.isEmpty) {
      throw Exception(
        'SendGrid API key is not set. Please set SENDGRID_API_KEY in your .env file.',
      );
    }

    final response = await http.post(
      Uri.parse(_baseUrl),
      headers: {
        'Authorization': 'Bearer $_apiKey',
        'Content-Type': 'application/json',
      },
      body: jsonEncode(message.toJson()),
    );

    if (response.statusCode != 202) {
      throw Exception('Failed to send email: ${response.body}');
    }

    return response;
  }
}
