import 'package:easthardware_pms/domain/models/security_question.dart';
import 'package:easthardware_pms/utils/undefined.dart';

class FormQuestion {

  const FormQuestion({
    required this.question,
    required this.answer,
  });

  factory FormQuestion.fromSecurityQuestion(SecurityQuestion question) {
    return FormQuestion(
      question: question.question,
      answer: question.answer,
    );
  }
  final String question;
  final String answer;

  FormQuestion Function({
    String question,
    String answer,
  }) get copyWith {
    return ({
      Object? question = undefined,
      Object? answer = undefined,
    }) {
      return FormQuestion(
        question: question.or(this.question),
        answer: answer.or(this.answer),
      );
    };
  }

  SecurityQuestion toSecurityQuestion(int userId) {
    return SecurityQuestion(
      userId: userId,
      question: question,
      answer: answer,
    );
  }
}
