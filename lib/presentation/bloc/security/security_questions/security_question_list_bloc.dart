import 'package:bloc/bloc.dart';
import 'package:easthardware_pms/domain/enums/enums.dart';
import 'package:easthardware_pms/domain/models/security_question.dart';
import 'package:easthardware_pms/domain/repository/security_question_repository.dart';
import 'package:easthardware_pms/utils/undefined.dart';
import 'package:equatable/equatable.dart';
import 'package:flutter/foundation.dart';

part 'security_question_list_event.dart';
part 'security_question_list_state.dart';

class SecurityQuestionListBloc extends Bloc<SecurityQuestionListEvent, SecurityQuestionListState> {
  SecurityQuestionListBloc(this._repository) : super(const SecurityQuestionListState()) {
    on<FetchSecurityQuestionsEvent>(_onFetchSecurityQuestions);
    on<FilterSecurityQuestionsEvent>(_onFilterSecurityQuestions);
    on<AddSecurityQuestionEvent>(_onAddSecurityQuestion);
    on<UpdateSecurityQuestionEvent>(_onUpdateSecurityQuestion);
    on<DeleteSecurityQuestionEvent>(_onDeleteSecurityQuestion);
  }

  final SecurityQuestionRepository _repository;

  void _onFetchSecurityQuestions(
      FetchSecurityQuestionsEvent event, Emitter<SecurityQuestionListState> emit) async {
    emit(state.copyWith(status: DataStatus.loading));
    try {
      final securityQuestions = await _repository.getAllSecurityQuestions();
      emit(state.copyWith(status: DataStatus.success, securityQuestions: securityQuestions));
    } catch (e) {
      if (kDebugMode) {
        print("BLoC Error fetching security questions: $e");
      }
      emit(state.copyWith(status: DataStatus.error));
    }
  }

  void _onFilterSecurityQuestions(
      FilterSecurityQuestionsEvent event, Emitter<SecurityQuestionListState> emit) {
    final filteredQuestions =
        state.securityQuestions.where((question) => question.userId == event.userId).toList();
    emit(state.copyWith(filteredQuestions: filteredQuestions));
  }

  void _onAddSecurityQuestion(
      AddSecurityQuestionEvent event, Emitter<SecurityQuestionListState> emit) async {
    try {
      final insertedQuestion = await _repository.addSecurityQuestion(event.question);
      final updatedQuestions = List<SecurityQuestion>.from(state.securityQuestions)
        ..add(insertedQuestion);
      emit(state.copyWith(securityQuestions: updatedQuestions, status: DataStatus.success));
    } catch (e) {
      if (kDebugMode) {
        print("BLoC Error adding security question: $e");
      }
      emit(state.copyWith(status: DataStatus.error));
    }
  }

  void _onUpdateSecurityQuestion(
      UpdateSecurityQuestionEvent event, Emitter<SecurityQuestionListState> emit) async {
    try {
      final updatedQuestion = await _repository.updateSecurityQuestion(event.question);
      final updatedQuestions = state.securityQuestions.map((question) {
        return question.id == updatedQuestion.id ? updatedQuestion : question;
      }).toList();
      emit(state.copyWith(securityQuestions: updatedQuestions, status: DataStatus.success));
    } catch (e) {
      if (kDebugMode) {
        print("BLoC Error updating security question: $e");
      }
      emit(state.copyWith(status: DataStatus.error));
    }
  }

  void _onDeleteSecurityQuestion(
      DeleteSecurityQuestionEvent event, Emitter<SecurityQuestionListState> emit) async {
    try {
      await _repository.deleteSecurityQuestion(event.question.id!);
      final updatedQuestions =
          state.securityQuestions.where((question) => question.id != event.question.id).toList();
      emit(state.copyWith(securityQuestions: updatedQuestions, status: DataStatus.success));
    } catch (e) {
      if (kDebugMode) {
        print("BLoC Error deleting security question: $e");
      }
      emit(state.copyWith(status: DataStatus.error));
    }
  }
}
