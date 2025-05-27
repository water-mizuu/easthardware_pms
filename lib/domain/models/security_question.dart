import 'package:easthardware_pms/utils/undefined.dart';

class SecurityQuestion {

  SecurityQuestion({
    this.id,
    required this.userId,
    required this.question,
    required this.answer,
  });

  factory SecurityQuestion.fromMap(Map<String, dynamic> map) {
    return SecurityQuestion(
      id: map['id'],
      userId: map['user_id'],
      question: map['question'],
      answer: map['answer'],
    );
  }
  final int? id;
  final int userId;
  final String question;
  final String answer;

  SecurityQuestion Function({
    int? id,
    int? userId,
    String? question,
    String? answer,
  }) get copyWith {
    return ({
      Object? id = undefined,
      Object? userId = undefined,
      Object? question = undefined,
      Object? answer = undefined,
    }) {
      return SecurityQuestion(
        id: id.or(this.id),
        userId: userId.or(this.userId),
        question: question.or(this.question),
        answer: answer.or(this.answer),
      );
    };
  }

  Map<String, dynamic> toMap() {
    return {
      'user_id': userId,
      'question': question,
      'answer': answer,
    };
  }
}
