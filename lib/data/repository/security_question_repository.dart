import 'package:easthardware_pms/data/database/dao/security_questions_dao.dart';
import 'package:easthardware_pms/data/database/database_helper.dart';
import 'package:easthardware_pms/domain/errors/exceptions.dart';
import 'package:easthardware_pms/domain/models/security_question.dart';
import 'package:easthardware_pms/domain/repository/security_question_repository.dart';

class SecurityQuestionRepositoryImpl implements SecurityQuestionRepository {
  SecurityQuestionRepositoryImpl(DatabaseHelper? databaseHelper)
      : securityQuestionsDao = SecurityQuestionsDao(databaseHelper);

  final SecurityQuestionsDao securityQuestionsDao;

  @override
  Future<SecurityQuestion> addSecurityQuestion(SecurityQuestion securityQuestion) async {
    try {
      return await securityQuestionsDao.insertSecurityQuestion(securityQuestion);
    } catch (e) {
      throw DatabaseException('Failed to add security question: $e');
    }
  }

  @override
  Future<void> deleteSecurityQuestion(int id) async {
    try {
      return await securityQuestionsDao.deleteSecurityQuestion(id);
    } catch (e) {
      throw DatabaseException('Failed to delete security question: $e');
    }
  }

  @override
  Future<List<SecurityQuestion>> getAllSecurityQuestions() async {
    try {
      return await securityQuestionsDao.getAllSecurityQuestions();
    } catch (e) {
      throw DatabaseException('Failed to fetch all security questions: $e');
    }
  }

  @override
  Future<SecurityQuestion?> getSecurityQuestionById(int id) async {
    try {
      return await securityQuestionsDao.getSecurityQuestionById(id);
    } catch (e) {
      throw DatabaseException('Failed to fetch security question by ID: $e');
    }
  }

  @override
  Future<List<SecurityQuestion>> getSecurityQuestionsByUserId(int userId) async {
    try {
      return await securityQuestionsDao.getSecurityQuestionsByUserId(userId);
    } catch (e) {
      throw DatabaseException('Failed to fetch security questions by user ID: $e');
    }
  }

  @override
  Future<SecurityQuestion> updateSecurityQuestion(SecurityQuestion securityQuestion) async {
    try {
      return await securityQuestionsDao.updateSecurityQuestion(securityQuestion);
    } catch (e) {
      throw DatabaseException('Failed to update security question: $e');
    }
  }
}
