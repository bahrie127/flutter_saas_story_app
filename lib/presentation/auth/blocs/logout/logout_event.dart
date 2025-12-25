part of 'logout_bloc.dart';

@freezed
sealed class LogoutEvent with _$LogoutEvent {
  const factory LogoutEvent.logout() = _Logout;
}
