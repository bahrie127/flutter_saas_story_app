import 'dart:convert';

import 'package:dartz/dartz.dart';
import 'package:flutter_story_app/core/constants/variables.dart';
import 'package:flutter_story_app/data/models/auth_response_model.dart';
import 'package:http/http.dart' as http;

class AuthRemoteDatasource {
  Future<Either<String, AuthResponseModel>> login(
    String username,
    String password,
  ) async {
    final data = await http.post(
      Uri.parse('${Variables.baseUrl}auth/login'),
      headers: {
        'Content-Type': 'application/json',
        'Accept': 'application/json',
      },
      body: jsonEncode({'username': username, 'password': password}),
    );
    // Handle response and return Either<String, AuthResponseModel>
    if (data.statusCode == 200) {
      final authResponse = AuthResponseModel.fromJson(data.body);
      return Right(authResponse);
    } else {
      return Left('Login failed with status code: ${data.statusCode}');
    }
  }

  //register
  Future<Either<String, AuthResponseModel>> register(
    String username,
    String password,
    String email,
  ) async {
    final data = await http.post(
      Uri.parse('${Variables.baseUrl}register'),
      headers: {
        'Content-Type': 'application/json',
        'Accept': 'application/json',
      },
      body: jsonEncode({
        'name': username,
        'password': password,
        'email': email,
      }),
    );
    // Handle response and return Either<String, AuthResponseModel>
    if (data.statusCode == 201) {
      final authResponse = AuthResponseModel.fromJson(data.body);
      return Right(authResponse);
    } else {
      return Left('Registration failed with status code: ${data.statusCode}');
    }
  }
}
