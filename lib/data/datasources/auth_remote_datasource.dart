import 'package:dartz/dartz.dart';
import '../../core/constants/variables.dart';
import '../../core/utils/api_handler.dart';
import '../models/auth_response_model.dart';
import '../models/user_model.dart';

class AuthRemoteDatasource {
  Future<Either<String, AuthResponseModel>> register({
    required String name,
    required String email,
    required String password,
  }) async {
    final result = await ApiHandler.post(
      Variables.register,
      body: {
        'name': name,
        'email': email,
        'password': password,
      },
    );

    return result.fold(
      (error) => Left(error),
      (data) {
        final authResponse = AuthResponseModel.fromJson(data);
        ApiHandler.saveToken(authResponse.token);
        return Right(authResponse);
      },
    );
  }

  Future<Either<String, AuthResponseModel>> login({
    required String email,
    required String password,
  }) async {
    final result = await ApiHandler.post(
      Variables.login,
      body: {
        'email': email,
        'password': password,
      },
    );

    return result.fold(
      (error) => Left(error),
      (data) {
        final authResponse = AuthResponseModel.fromJson(data);
        ApiHandler.saveToken(authResponse.token);
        return Right(authResponse);
      },
    );
  }

  Future<Either<String, String>> logout() async {
    final result = await ApiHandler.post(Variables.logout);

    await ApiHandler.removeToken();

    return result.fold(
      (error) => const Right('Logout berhasil'),
      (data) => Right(data['message'] ?? 'Logout berhasil'),
    );
  }

  Future<Either<String, UserModel>> getProfile() async {
    final result = await ApiHandler.get(Variables.profile);

    return result.fold(
      (error) => Left(error),
      (data) => Right(UserModel.fromJson(data)),
    );
  }

  Future<bool> isLoggedIn() async {
    return ApiHandler.isLoggedIn();
  }
}
