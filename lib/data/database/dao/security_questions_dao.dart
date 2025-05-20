import 'package:easthardware_pms/data/database/dao/dao_base.dart';
import 'package:easthardware_pms/data/database/database_helper.dart';
import 'package:easthardware_pms/data/database/tables/security_questions_table.dart';
import 'package:easthardware_pms/domain/models/security_question.dart';

abstract interface class SecurityQuestionsDao {
  factory SecurityQuestionsDao(DatabaseHelper? databaseHelper) {
    return SecurityQuestionsDaoImpl._(databaseHelper);
  }
  Future<List<SecurityQuestion>> getAllSecurityQuestions();
  Future<SecurityQuestion?> getSecurityQuestionById(int id);
  Future<List<SecurityQuestion>> getSecurityQuestionsByUserId(int id);
  Future<SecurityQuestion> insertSecurityQuestion(SecurityQuestion securityQuestion);
  Future<SecurityQuestion> updateSecurityQuestion(SecurityQuestion securityQuestion);
  Future<void> deleteSecurityQuestion(int id);
}

final class SecurityQuestionsDaoImpl extends DaoBase implements SecurityQuestionsDao {
  const SecurityQuestionsDaoImpl._(super.databaseHelper);

  @override
  Future<void> deleteSecurityQuestion(int id) async {
    final database = databaseHelper.database;
    await database.delete(
      SecurityQuestionsTable.SECURITY_QUESTIONS_TABLE,
      where: '${SecurityQuestionsTable.SECURITY_QUESTIONS_ID} = ?',
      whereArgs: [id],
    );
  }

  @override
  Future<List<SecurityQuestion>> getAllSecurityQuestions() async {
    final database = databaseHelper.database;
    var queryResults = await database.query(SecurityQuestionsTable.SECURITY_QUESTIONS_TABLE);

    return queryResults.map(SecurityQuestion.fromMap).toList();
  }

  @override
  Future<SecurityQuestion?> getSecurityQuestionById(int id) async {
    final database = databaseHelper.database;
    var queryResults = await database.query(
      SecurityQuestionsTable.SECURITY_QUESTIONS_TABLE,
      where: '${SecurityQuestionsTable.SECURITY_QUESTIONS_ID} = ?',
      whereArgs: [id],
    );

    try {
      var json = queryResults.single;

      return SecurityQuestion.fromMap(json);
    } on StateError {
      return null;
    }
  }

  @override
  Future<SecurityQuestion> insertSecurityQuestion(SecurityQuestion securityQuestion) async {
    final database = databaseHelper.database;
    final id = await database.insert(
      SecurityQuestionsTable.SECURITY_QUESTIONS_TABLE,
      securityQuestion.toMap(),
    );
    return securityQuestion.copyWith(id: id);
  }

  @override
  Future<SecurityQuestion> updateSecurityQuestion(SecurityQuestion securityQuestion) async {
    final database = databaseHelper.database;
    await database.update(
      SecurityQuestionsTable.SECURITY_QUESTIONS_TABLE,
      securityQuestion.toMap(),
      where: '${SecurityQuestionsTable.SECURITY_QUESTIONS_ID} = ?',
      whereArgs: [securityQuestion.id],
    );

    return securityQuestion;
  }

  @override
  Future<List<SecurityQuestion>> getSecurityQuestionsByUserId(int id) async {
    final database = databaseHelper.database;
    var queryResults = await database.query(
      SecurityQuestionsTable.SECURITY_QUESTIONS_TABLE,
      where: '${SecurityQuestionsTable.SECURITY_QUESTIONS_USER_ID} = ?',
      whereArgs: [id],
    );
    return queryResults.map(SecurityQuestion.fromMap).toList();
  }
}
