import 'package:bloc/bloc.dart';
import 'package:freezed_annotation/freezed_annotation.dart';

import 'package:flutter_story_app/data/datasources/auth_remote_datasource.dart';

part 'register_bloc.freezed.dart';
part 'register_event.dart';
part 'register_state.dart';

class RegisterBloc extends Bloc<RegisterEvent, RegisterState> {
  final AuthRemoteDatasource _authRemoteDatasource;
  RegisterBloc(this._authRemoteDatasource) : super(_Initial()) {
    on<_Register>((event, emit) async {
      emit(RegisterState.loading());
      try {
        final result = await _authRemoteDatasource.register(
          event.username,
          event.password,
          event.email,
        );
        result.fold(
          (failure) => emit(RegisterState.failure(failure)),
          (success) => emit(RegisterState.success()),
        );
      } catch (e) {
        emit(RegisterState.failure(e.toString()));
      }
    });
  }
}
