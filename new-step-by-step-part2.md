# Flutter Story App - Step by Step Livecode (Part 2)
## JagoFlutter Academy 2026
### Datasources, BLoCs, dan Pages

---

# PART 4: DATA LAYER - DATASOURCES

## Step 14: Auth Local Datasource

Buat file `lib/data/datasources/auth_local_datasource.dart`:

```dart
import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/auth_response_model.dart';
import '../models/user_model.dart';

class AuthLocalDatasource {
  static const String _authKey = 'auth_data';
  static const String _userKey = 'user_data';

  /// Simpan data auth (user + token)
  Future<void> saveAuth(AuthResponseModel auth) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_authKey, jsonEncode(auth.toJson()));
  }

  /// Ambil data auth
  Future<AuthResponseModel?> getAuth() async {
    final prefs = await SharedPreferences.getInstance();
    final data = prefs.getString(_authKey);
    if (data != null) {
      return AuthResponseModel.fromJson(jsonDecode(data));
    }
    return null;
  }

  /// Simpan data user saja
  Future<void> saveUser(UserModel user) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_userKey, jsonEncode(user.toJson()));
  }

  /// Ambil data user
  Future<UserModel?> getUser() async {
    final prefs = await SharedPreferences.getInstance();
    final data = prefs.getString(_userKey);
    if (data != null) {
      return UserModel.fromJson(jsonDecode(data));
    }
    return null;
  }

  /// Hapus semua data auth
  Future<void> clearAuth() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_authKey);
    await prefs.remove(_userKey);
  }

  /// Cek apakah user sudah login
  Future<bool> isLoggedIn() async {
    final auth = await getAuth();
    return auth != null;
  }
}
```

## Step 15: Auth Remote Datasource

Buat file `lib/data/datasources/auth_remote_datasource.dart`:

```dart
import 'package:dartz/dartz.dart';
import '../../core/constants/variables.dart';
import '../../core/utils/api_handler.dart';
import '../models/auth_response_model.dart';
import '../models/user_model.dart';

class AuthRemoteDatasource {
  /// Register user baru
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
        // Simpan token
        ApiHandler.saveToken(authResponse.token);
        return Right(authResponse);
      },
    );
  }

  /// Login user
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
        // Simpan token
        ApiHandler.saveToken(authResponse.token);
        return Right(authResponse);
      },
    );
  }

  /// Logout user
  Future<Either<String, String>> logout() async {
    final result = await ApiHandler.post(Variables.logout);

    // Hapus token terlepas dari hasil
    await ApiHandler.removeToken();

    return result.fold(
      (error) => const Right('Logout berhasil'),
      (data) => Right(data['message'] ?? 'Logout berhasil'),
    );
  }

  /// Get profile user
  Future<Either<String, UserModel>> getProfile() async {
    final result = await ApiHandler.get(Variables.profile);

    return result.fold(
      (error) => Left(error),
      (data) => Right(UserModel.fromJson(data)),
    );
  }

  /// Cek apakah user sudah login
  Future<bool> isLoggedIn() async {
    return ApiHandler.isLoggedIn();
  }
}
```

## Step 16: Story Remote Datasource

Buat file `lib/data/datasources/story_remote_datasource.dart`:

```dart
import 'dart:io';
import 'package:dartz/dartz.dart';
import '../../core/constants/variables.dart';
import '../../core/utils/api_handler.dart';
import '../models/stories_response_model.dart';
import '../models/story_model.dart';

class StoryRemoteDatasource {
  /// Get my stories (paginated)
  Future<Either<String, StoriesResponseModel>> getMyStories({
    int page = 1,
  }) async {
    final result = await ApiHandler.get(
      '${Variables.myStories}?page=$page',
    );

    return result.fold(
      (error) => Left(error),
      (data) => Right(StoriesResponseModel.fromJson(data)),
    );
  }

  /// Create new story
  Future<Either<String, StoryModel>> createStory({
    required String title,
    required String content,
    File? image,
  }) async {
    final result = await ApiHandler.postMultipart(
      Variables.stories,
      fields: {
        'title': title,
        'content': content,
      },
      file: image,
      fileField: 'image',
    );

    return result.fold(
      (error) => Left(error),
      (data) {
        final storyData = data['data'] as Map<String, dynamic>;
        return Right(StoryModel.fromJson(storyData));
      },
    );
  }

  /// Update story
  Future<Either<String, StoryModel>> updateStory({
    required int id,
    required String title,
    required String content,
    File? image,
  }) async {
    final result = await ApiHandler.postMultipart(
      Variables.storyById(id),
      fields: {
        '_method': 'PUT',
        'title': title,
        'content': content,
      },
      file: image,
      fileField: 'image',
    );

    return result.fold(
      (error) => Left(error),
      (data) {
        final storyData = data['data'] as Map<String, dynamic>;
        return Right(StoryModel.fromJson(storyData));
      },
    );
  }

  /// Delete story
  Future<Either<String, String>> deleteStory(int id) async {
    final result = await ApiHandler.delete(Variables.storyById(id));

    return result.fold(
      (error) => Left(error),
      (data) => Right(data['message'] ?? 'Cerita berhasil dihapus'),
    );
  }
}
```

---

# PART 5: PRESENTATION LAYER - AUTH BLOCS

## Step 17: Login Event (Freezed)

Buat file `lib/presentation/auth/blocs/login/login_event.dart`:

```dart
import 'package:freezed_annotation/freezed_annotation.dart';

part 'login_event.freezed.dart';

@freezed
class LoginEvent with _$LoginEvent {
  const factory LoginEvent.login({
    required String email,
    required String password,
  }) = _Login;
}
```

## Step 18: Login State (Freezed)

Buat file `lib/presentation/auth/blocs/login/login_state.dart`:

```dart
import 'package:freezed_annotation/freezed_annotation.dart';
import '../../../../data/models/auth_response_model.dart';

part 'login_state.freezed.dart';

@freezed
class LoginState with _$LoginState {
  const factory LoginState.initial() = _Initial;
  const factory LoginState.loading() = _Loading;
  const factory LoginState.success(AuthResponseModel data) = _Success;
  const factory LoginState.error(String message) = _Error;
}
```

## Step 19: Login BLoC

Buat file `lib/presentation/auth/blocs/login/login_bloc.dart`:

```dart
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../../data/datasources/auth_remote_datasource.dart';
import 'login_event.dart';
import 'login_state.dart';

class LoginBloc extends Bloc<LoginEvent, LoginState> {
  final AuthRemoteDatasource _datasource;

  LoginBloc(this._datasource) : super(const LoginState.initial()) {
    on<_Login>(_onLogin);
  }

  Future<void> _onLogin(_Login event, Emitter<LoginState> emit) async {
    emit(const LoginState.loading());

    final result = await _datasource.login(
      email: event.email,
      password: event.password,
    );

    result.fold(
      (error) => emit(LoginState.error(error)),
      (data) => emit(LoginState.success(data)),
    );
  }
}
```

## Step 20: Register Event (Freezed)

Buat file `lib/presentation/auth/blocs/register/register_event.dart`:

```dart
import 'package:freezed_annotation/freezed_annotation.dart';

part 'register_event.freezed.dart';

@freezed
class RegisterEvent with _$RegisterEvent {
  const factory RegisterEvent.register({
    required String name,
    required String email,
    required String password,
  }) = _Register;
}
```

## Step 21: Register State (Freezed)

Buat file `lib/presentation/auth/blocs/register/register_state.dart`:

```dart
import 'package:freezed_annotation/freezed_annotation.dart';
import '../../../../data/models/auth_response_model.dart';

part 'register_state.freezed.dart';

@freezed
class RegisterState with _$RegisterState {
  const factory RegisterState.initial() = _Initial;
  const factory RegisterState.loading() = _Loading;
  const factory RegisterState.success(AuthResponseModel data) = _Success;
  const factory RegisterState.error(String message) = _Error;
}
```

## Step 22: Register BLoC

Buat file `lib/presentation/auth/blocs/register/register_bloc.dart`:

```dart
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../../data/datasources/auth_remote_datasource.dart';
import 'register_event.dart';
import 'register_state.dart';

class RegisterBloc extends Bloc<RegisterEvent, RegisterState> {
  final AuthRemoteDatasource _datasource;

  RegisterBloc(this._datasource) : super(const RegisterState.initial()) {
    on<_Register>(_onRegister);
  }

  Future<void> _onRegister(_Register event, Emitter<RegisterState> emit) async {
    emit(const RegisterState.loading());

    final result = await _datasource.register(
      name: event.name,
      email: event.email,
      password: event.password,
    );

    result.fold(
      (error) => emit(RegisterState.error(error)),
      (data) => emit(RegisterState.success(data)),
    );
  }
}
```

## Step 23: Logout Event & State

Buat file `lib/presentation/auth/blocs/logout/logout_event.dart`:

```dart
import 'package:freezed_annotation/freezed_annotation.dart';

part 'logout_event.freezed.dart';

@freezed
class LogoutEvent with _$LogoutEvent {
  const factory LogoutEvent.logout() = _Logout;
}
```

Buat file `lib/presentation/auth/blocs/logout/logout_state.dart`:

```dart
import 'package:freezed_annotation/freezed_annotation.dart';

part 'logout_state.freezed.dart';

@freezed
class LogoutState with _$LogoutState {
  const factory LogoutState.initial() = _Initial;
  const factory LogoutState.loading() = _Loading;
  const factory LogoutState.success() = _Success;
  const factory LogoutState.error(String message) = _Error;
}
```

Buat file `lib/presentation/auth/blocs/logout/logout_bloc.dart`:

```dart
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../../data/datasources/auth_remote_datasource.dart';
import 'logout_event.dart';
import 'logout_state.dart';

class LogoutBloc extends Bloc<LogoutEvent, LogoutState> {
  final AuthRemoteDatasource _datasource;

  LogoutBloc(this._datasource) : super(const LogoutState.initial()) {
    on<_Logout>(_onLogout);
  }

  Future<void> _onLogout(_Logout event, Emitter<LogoutState> emit) async {
    emit(const LogoutState.loading());

    final result = await _datasource.logout();

    result.fold(
      (error) => emit(LogoutState.error(error)),
      (_) => emit(const LogoutState.success()),
    );
  }
}
```

---

# PART 6: PRESENTATION LAYER - STORY BLOCS

## Step 24: Get Stories Event & State

Buat file `lib/presentation/story/blocs/get_stories/get_stories_event.dart`:

```dart
import 'package:freezed_annotation/freezed_annotation.dart';

part 'get_stories_event.freezed.dart';

@freezed
class GetStoriesEvent with _$GetStoriesEvent {
  const factory GetStoriesEvent.getMyStories({
    @Default(1) int page,
    @Default(false) bool refresh,
  }) = _GetMyStories;

  const factory GetStoriesEvent.loadMore() = _LoadMore;
}
```

Buat file `lib/presentation/story/blocs/get_stories/get_stories_state.dart`:

```dart
import 'package:freezed_annotation/freezed_annotation.dart';
import '../../../../data/models/story_model.dart';

part 'get_stories_state.freezed.dart';

@freezed
class GetStoriesState with _$GetStoriesState {
  const factory GetStoriesState.initial() = _Initial;
  const factory GetStoriesState.loading() = _Loading;
  const factory GetStoriesState.success({
    required List<StoryModel> stories,
    required int currentPage,
    required int lastPage,
    required bool hasMore,
    @Default(false) bool isLoadingMore,
  }) = _Success;
  const factory GetStoriesState.error(String message) = _Error;
}
```

Buat file `lib/presentation/story/blocs/get_stories/get_stories_bloc.dart`:

```dart
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../../data/datasources/story_remote_datasource.dart';
import '../../../../data/models/story_model.dart';
import 'get_stories_event.dart';
import 'get_stories_state.dart';

class GetStoriesBloc extends Bloc<GetStoriesEvent, GetStoriesState> {
  final StoryRemoteDatasource _datasource;

  GetStoriesBloc(this._datasource) : super(const GetStoriesState.initial()) {
    on<_GetMyStories>(_onGetMyStories);
    on<_LoadMore>(_onLoadMore);
  }

  Future<void> _onGetMyStories(
    _GetMyStories event,
    Emitter<GetStoriesState> emit,
  ) async {
    if (event.refresh || state is _Initial || state is _Error) {
      emit(const GetStoriesState.loading());
    }

    final result = await _datasource.getMyStories(page: event.page);

    result.fold(
      (error) => emit(GetStoriesState.error(error)),
      (response) {
        List<StoryModel> stories = response.data;

        // Jika load more, append ke list yang ada
        if (!event.refresh && state is _Success && event.page > 1) {
          final currentState = state as _Success;
          stories = [...currentState.stories, ...response.data];
        }

        emit(GetStoriesState.success(
          stories: stories,
          currentPage: response.currentPage,
          lastPage: response.lastPage,
          hasMore: response.hasMore,
        ));
      },
    );
  }

  Future<void> _onLoadMore(_LoadMore event, Emitter<GetStoriesState> emit) async {
    final currentState = state;
    if (currentState is! _Success || !currentState.hasMore || currentState.isLoadingMore) {
      return;
    }

    emit(currentState.copyWith(isLoadingMore: true));

    final nextPage = currentState.currentPage + 1;
    final result = await _datasource.getMyStories(page: nextPage);

    result.fold(
      (error) => emit(currentState.copyWith(isLoadingMore: false)),
      (response) {
        final updatedStories = [...currentState.stories, ...response.data];
        emit(GetStoriesState.success(
          stories: updatedStories,
          currentPage: response.currentPage,
          lastPage: response.lastPage,
          hasMore: response.hasMore,
          isLoadingMore: false,
        ));
      },
    );
  }
}
```

## Step 25: Create Story Event & State

Buat file `lib/presentation/story/blocs/create_story/create_story_event.dart`:

```dart
import 'dart:io';
import 'package:freezed_annotation/freezed_annotation.dart';

part 'create_story_event.freezed.dart';

@freezed
class CreateStoryEvent with _$CreateStoryEvent {
  const factory CreateStoryEvent.create({
    required String title,
    required String content,
    File? image,
  }) = _Create;
}
```

Buat file `lib/presentation/story/blocs/create_story/create_story_state.dart`:

```dart
import 'package:freezed_annotation/freezed_annotation.dart';
import '../../../../data/models/story_model.dart';

part 'create_story_state.freezed.dart';

@freezed
class CreateStoryState with _$CreateStoryState {
  const factory CreateStoryState.initial() = _Initial;
  const factory CreateStoryState.loading() = _Loading;
  const factory CreateStoryState.success(StoryModel story) = _Success;
  const factory CreateStoryState.error(String message) = _Error;
}
```

Buat file `lib/presentation/story/blocs/create_story/create_story_bloc.dart`:

```dart
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../../data/datasources/story_remote_datasource.dart';
import 'create_story_event.dart';
import 'create_story_state.dart';

class CreateStoryBloc extends Bloc<CreateStoryEvent, CreateStoryState> {
  final StoryRemoteDatasource _datasource;

  CreateStoryBloc(this._datasource) : super(const CreateStoryState.initial()) {
    on<_Create>(_onCreate);
  }

  Future<void> _onCreate(_Create event, Emitter<CreateStoryState> emit) async {
    emit(const CreateStoryState.loading());

    final result = await _datasource.createStory(
      title: event.title,
      content: event.content,
      image: event.image,
    );

    result.fold(
      (error) => emit(CreateStoryState.error(error)),
      (story) => emit(CreateStoryState.success(story)),
    );
  }
}
```

## Step 26: Update Story Event & State

Buat file `lib/presentation/story/blocs/update_story/update_story_event.dart`:

```dart
import 'dart:io';
import 'package:freezed_annotation/freezed_annotation.dart';

part 'update_story_event.freezed.dart';

@freezed
class UpdateStoryEvent with _$UpdateStoryEvent {
  const factory UpdateStoryEvent.update({
    required int id,
    required String title,
    required String content,
    File? image,
  }) = _Update;
}
```

Buat file `lib/presentation/story/blocs/update_story/update_story_state.dart`:

```dart
import 'package:freezed_annotation/freezed_annotation.dart';
import '../../../../data/models/story_model.dart';

part 'update_story_state.freezed.dart';

@freezed
class UpdateStoryState with _$UpdateStoryState {
  const factory UpdateStoryState.initial() = _Initial;
  const factory UpdateStoryState.loading() = _Loading;
  const factory UpdateStoryState.success(StoryModel story) = _Success;
  const factory UpdateStoryState.error(String message) = _Error;
}
```

Buat file `lib/presentation/story/blocs/update_story/update_story_bloc.dart`:

```dart
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../../data/datasources/story_remote_datasource.dart';
import 'update_story_event.dart';
import 'update_story_state.dart';

class UpdateStoryBloc extends Bloc<UpdateStoryEvent, UpdateStoryState> {
  final StoryRemoteDatasource _datasource;

  UpdateStoryBloc(this._datasource) : super(const UpdateStoryState.initial()) {
    on<_Update>(_onUpdate);
  }

  Future<void> _onUpdate(_Update event, Emitter<UpdateStoryState> emit) async {
    emit(const UpdateStoryState.loading());

    final result = await _datasource.updateStory(
      id: event.id,
      title: event.title,
      content: event.content,
      image: event.image,
    );

    result.fold(
      (error) => emit(UpdateStoryState.error(error)),
      (story) => emit(UpdateStoryState.success(story)),
    );
  }
}
```

## Step 27: Delete Story Event & State

Buat file `lib/presentation/story/blocs/delete_story/delete_story_event.dart`:

```dart
import 'package:freezed_annotation/freezed_annotation.dart';

part 'delete_story_event.freezed.dart';

@freezed
class DeleteStoryEvent with _$DeleteStoryEvent {
  const factory DeleteStoryEvent.delete(int id) = _Delete;
}
```

Buat file `lib/presentation/story/blocs/delete_story/delete_story_state.dart`:

```dart
import 'package:freezed_annotation/freezed_annotation.dart';

part 'delete_story_state.freezed.dart';

@freezed
class DeleteStoryState with _$DeleteStoryState {
  const factory DeleteStoryState.initial() = _Initial;
  const factory DeleteStoryState.loading() = _Loading;
  const factory DeleteStoryState.success(String message) = _Success;
  const factory DeleteStoryState.error(String message) = _Error;
}
```

Buat file `lib/presentation/story/blocs/delete_story/delete_story_bloc.dart`:

```dart
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../../data/datasources/story_remote_datasource.dart';
import 'delete_story_event.dart';
import 'delete_story_state.dart';

class DeleteStoryBloc extends Bloc<DeleteStoryEvent, DeleteStoryState> {
  final StoryRemoteDatasource _datasource;

  DeleteStoryBloc(this._datasource) : super(const DeleteStoryState.initial()) {
    on<_Delete>(_onDelete);
  }

  Future<void> _onDelete(_Delete event, Emitter<DeleteStoryState> emit) async {
    emit(const DeleteStoryState.loading());

    final result = await _datasource.deleteStory(event.id);

    result.fold(
      (error) => emit(DeleteStoryState.error(error)),
      (message) => emit(DeleteStoryState.success(message)),
    );
  }
}
```

---

# PART 7: PROFILE BLOC

## Step 28: Profile Event & State

Buat file `lib/presentation/profile/blocs/profile/profile_event.dart`:

```dart
import 'package:freezed_annotation/freezed_annotation.dart';

part 'profile_event.freezed.dart';

@freezed
class ProfileEvent with _$ProfileEvent {
  const factory ProfileEvent.getProfile() = _GetProfile;
}
```

Buat file `lib/presentation/profile/blocs/profile/profile_state.dart`:

```dart
import 'package:freezed_annotation/freezed_annotation.dart';
import '../../../../data/models/user_model.dart';

part 'profile_state.freezed.dart';

@freezed
class ProfileState with _$ProfileState {
  const factory ProfileState.initial() = _Initial;
  const factory ProfileState.loading() = _Loading;
  const factory ProfileState.success(UserModel user) = _Success;
  const factory ProfileState.error(String message) = _Error;
}
```

Buat file `lib/presentation/profile/blocs/profile/profile_bloc.dart`:

```dart
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../../data/datasources/auth_remote_datasource.dart';
import 'profile_event.dart';
import 'profile_state.dart';

class ProfileBloc extends Bloc<ProfileEvent, ProfileState> {
  final AuthRemoteDatasource _datasource;

  ProfileBloc(this._datasource) : super(const ProfileState.initial()) {
    on<_GetProfile>(_onGetProfile);
  }

  Future<void> _onGetProfile(
    _GetProfile event,
    Emitter<ProfileState> emit,
  ) async {
    emit(const ProfileState.loading());

    final result = await _datasource.getProfile();

    result.fold(
      (error) => emit(ProfileState.error(error)),
      (user) => emit(ProfileState.success(user)),
    );
  }
}
```

---

# PART 8: BLOC PROVIDERS (SERVICE LOCATOR)

## Step 29: Bloc Providers

Buat file `lib/bloc_providers.dart`:

```dart
import 'package:flutter_bloc/flutter_bloc.dart';
import 'data/datasources/auth_remote_datasource.dart';
import 'data/datasources/story_remote_datasource.dart';
import 'presentation/auth/blocs/login/login_bloc.dart';
import 'presentation/auth/blocs/logout/logout_bloc.dart';
import 'presentation/auth/blocs/register/register_bloc.dart';
import 'presentation/profile/blocs/profile/profile_bloc.dart';
import 'presentation/story/blocs/create_story/create_story_bloc.dart';
import 'presentation/story/blocs/delete_story/delete_story_bloc.dart';
import 'presentation/story/blocs/get_stories/get_stories_bloc.dart';
import 'presentation/story/blocs/update_story/update_story_bloc.dart';

// ═══════════════════════════════════════════════════════════════
// DATASOURCES (Singleton)
// ═══════════════════════════════════════════════════════════════

final AuthRemoteDatasource _authDatasource = AuthRemoteDatasource();
final StoryRemoteDatasource _storyDatasource = StoryRemoteDatasource();

// ═══════════════════════════════════════════════════════════════
// BLOC PROVIDERS
// ═══════════════════════════════════════════════════════════════

List<BlocProvider> get blocProviders => [
      // Auth BLoCs
      BlocProvider<LoginBloc>(
        create: (_) => LoginBloc(_authDatasource),
      ),
      BlocProvider<RegisterBloc>(
        create: (_) => RegisterBloc(_authDatasource),
      ),
      BlocProvider<LogoutBloc>(
        create: (_) => LogoutBloc(_authDatasource),
      ),

      // Profile BLoC
      BlocProvider<ProfileBloc>(
        create: (_) => ProfileBloc(_authDatasource),
      ),

      // Story BLoCs
      BlocProvider<GetStoriesBloc>(
        create: (_) => GetStoriesBloc(_storyDatasource),
      ),
      BlocProvider<CreateStoryBloc>(
        create: (_) => CreateStoryBloc(_storyDatasource),
      ),
      BlocProvider<UpdateStoryBloc>(
        create: (_) => UpdateStoryBloc(_storyDatasource),
      ),
      BlocProvider<DeleteStoryBloc>(
        create: (_) => DeleteStoryBloc(_storyDatasource),
      ),
    ];

// ═══════════════════════════════════════════════════════════════
// HELPER FUNCTIONS
// ═══════════════════════════════════════════════════════════════

AuthRemoteDatasource get authDatasource => _authDatasource;
StoryRemoteDatasource get storyDatasource => _storyDatasource;
```

---

# PART 9: PRESENTATION LAYER - PAGES

## Step 30: Splash Page

Buat file `lib/presentation/splash/pages/splash_page.dart`:

```dart
import 'package:flutter/material.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_sizes.dart';
import '../../../core/extensions/build_context_ext.dart';
import '../../../core/utils/api_handler.dart';
import '../../auth/pages/login_page.dart';
import '../../story/pages/home_page.dart';

class SplashPage extends StatefulWidget {
  const SplashPage({super.key});

  @override
  State<SplashPage> createState() => _SplashPageState();
}

class _SplashPageState extends State<SplashPage> with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _fadeAnimation;
  late Animation<double> _scaleAnimation;

  @override
  void initState() {
    super.initState();
    _setupAnimations();
    _checkAuthStatus();
  }

  void _setupAnimations() {
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1500),
    );

    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _controller,
        curve: const Interval(0.0, 0.5, curve: Curves.easeIn),
      ),
    );

    _scaleAnimation = Tween<double>(begin: 0.5, end: 1.0).animate(
      CurvedAnimation(
        parent: _controller,
        curve: const Interval(0.0, 0.5, curve: Curves.easeOutBack),
      ),
    );

    _controller.forward();
  }

  Future<void> _checkAuthStatus() async {
    await Future.delayed(const Duration(seconds: 2));

    if (!mounted) return;

    final isLoggedIn = await ApiHandler.isLoggedIn();

    if (mounted) {
      if (isLoggedIn) {
        context.pushAndRemoveUntil(const HomePage(), (route) => false);
      } else {
        context.pushAndRemoveUntil(const LoginPage(), (route) => false);
      }
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: Center(
        child: AnimatedBuilder(
          animation: _controller,
          builder: (context, child) {
            return FadeTransition(
              opacity: _fadeAnimation,
              child: ScaleTransition(
                scale: _scaleAnimation,
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    // Logo Container
                    Container(
                      padding: const EdgeInsets.all(AppSizes.xl),
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          colors: [
                            AppColors.primary,
                            AppColors.primary.withOpacity(0.8),
                          ],
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                        ),
                        shape: BoxShape.circle,
                        boxShadow: [
                          BoxShadow(
                            color: AppColors.primary.withOpacity(0.3),
                            blurRadius: 30,
                            spreadRadius: 5,
                          ),
                        ],
                      ),
                      child: const Icon(
                        Icons.auto_stories_rounded,
                        size: 80,
                        color: AppColors.onPrimary,
                      ),
                    ),
                    const SizedBox(height: AppSizes.xl),

                    // App Name
                    const Text(
                      'Story App',
                      style: TextStyle(
                        fontSize: AppSizes.fontDisplay,
                        fontWeight: FontWeight.bold,
                        color: AppColors.onBackground,
                        letterSpacing: 1.2,
                      ),
                    ),
                    const SizedBox(height: AppSizes.sm),

                    // Tagline
                    Text(
                      'Share your stories with the world',
                      style: TextStyle(
                        fontSize: AppSizes.fontLg,
                        color: AppColors.onSurfaceVariant,
                        letterSpacing: 0.5,
                      ),
                    ),
                    const SizedBox(height: AppSizes.xxl),

                    // Loading Indicator
                    SizedBox(
                      width: 40,
                      height: 40,
                      child: CircularProgressIndicator(
                        strokeWidth: 3,
                        valueColor: AlwaysStoppedAnimation<Color>(
                          AppColors.primary,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            );
          },
        ),
      ),
    );
  }
}
```

## Step 31: Login Page (Design Profesional)

Buat file `lib/presentation/auth/pages/login_page.dart`:

```dart
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../core/components/app_button.dart';
import '../../../core/components/app_text_field.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_sizes.dart';
import '../../../core/extensions/build_context_ext.dart';
import '../../story/pages/home_page.dart';
import '../blocs/login/login_bloc.dart';
import '../blocs/login/login_event.dart';
import '../blocs/login/login_state.dart';
import 'register_page.dart';

class LoginPage extends StatefulWidget {
  const LoginPage({super.key});

  @override
  State<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _emailFocusNode = FocusNode();
  final _passwordFocusNode = FocusNode();
  bool _obscurePassword = true;

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    _emailFocusNode.dispose();
    _passwordFocusNode.dispose();
    super.dispose();
  }

  void _login() {
    if (_formKey.currentState!.validate()) {
      context.read<LoginBloc>().add(
            LoginEvent.login(
              email: _emailController.text.trim(),
              password: _passwordController.text,
            ),
          );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: BlocConsumer<LoginBloc, LoginState>(
        listener: (context, state) {
          state.maybeWhen(
            success: (data) {
              context.showSuccess('Selamat datang, ${data.user.name}!');
              context.pushAndRemoveUntil(const HomePage(), (route) => false);
            },
            error: (message) {
              context.showError(message);
            },
            orElse: () {},
          );
        },
        builder: (context, state) {
          final isLoading = state.maybeWhen(
            loading: () => true,
            orElse: () => false,
          );

          return SafeArea(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(AppSizes.lg),
              child: Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    const SizedBox(height: AppSizes.xxl),

                    // ═══════════════════════════════════════════
                    // HEADER
                    // ═══════════════════════════════════════════
                    _buildHeader(),

                    const SizedBox(height: AppSizes.xxl),

                    // ═══════════════════════════════════════════
                    // FORM
                    // ═══════════════════════════════════════════
                    _buildLoginForm(isLoading),

                    const SizedBox(height: AppSizes.lg),

                    // ═══════════════════════════════════════════
                    // LOGIN BUTTON
                    // ═══════════════════════════════════════════
                    AppButton(
                      text: 'Masuk',
                      onPressed: isLoading ? null : _login,
                      isLoading: isLoading,
                    ),

                    const SizedBox(height: AppSizes.lg),

                    // ═══════════════════════════════════════════
                    // DIVIDER
                    // ═══════════════════════════════════════════
                    _buildDivider(),

                    const SizedBox(height: AppSizes.lg),

                    // ═══════════════════════════════════════════
                    // REGISTER LINK
                    // ═══════════════════════════════════════════
                    _buildRegisterLink(),
                  ],
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildHeader() {
    return Column(
      children: [
        // Logo
        Container(
          padding: const EdgeInsets.all(AppSizes.lg),
          decoration: BoxDecoration(
            color: AppColors.primaryContainer,
            shape: BoxShape.circle,
          ),
          child: Icon(
            Icons.auto_stories_rounded,
            size: AppSizes.iconXl * 1.5,
            color: AppColors.primary,
          ),
        ),
        const SizedBox(height: AppSizes.lg),

        // Title
        const Text(
          'Selamat Datang!',
          style: TextStyle(
            fontSize: AppSizes.fontXxl,
            fontWeight: FontWeight.bold,
            color: AppColors.onBackground,
          ),
        ),
        const SizedBox(height: AppSizes.sm),

        // Subtitle
        Text(
          'Masuk untuk melanjutkan ke Story App',
          style: TextStyle(
            fontSize: AppSizes.fontMd,
            color: AppColors.onSurfaceVariant,
          ),
          textAlign: TextAlign.center,
        ),
      ],
    );
  }

  Widget _buildLoginForm(bool isLoading) {
    return Column(
      children: [
        // Email Field
        AppTextField(
          controller: _emailController,
          label: 'Email',
          hint: 'Masukkan email anda',
          prefixIcon: Icons.email_outlined,
          keyboardType: TextInputType.emailAddress,
          textInputAction: TextInputAction.next,
          focusNode: _emailFocusNode,
          enabled: !isLoading,
          onSubmitted: (_) {
            FocusScope.of(context).requestFocus(_passwordFocusNode);
          },
          validator: (value) {
            if (value == null || value.isEmpty) {
              return 'Email tidak boleh kosong';
            }
            if (!RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$').hasMatch(value)) {
              return 'Format email tidak valid';
            }
            return null;
          },
        ),
        const SizedBox(height: AppSizes.md),

        // Password Field
        AppTextField(
          controller: _passwordController,
          label: 'Password',
          hint: 'Masukkan password anda',
          prefixIcon: Icons.lock_outline,
          obscureText: _obscurePassword,
          textInputAction: TextInputAction.done,
          focusNode: _passwordFocusNode,
          enabled: !isLoading,
          onSubmitted: (_) => _login(),
          suffixIcon: IconButton(
            icon: Icon(
              _obscurePassword ? Icons.visibility_off : Icons.visibility,
              color: AppColors.onSurfaceVariant,
            ),
            onPressed: () {
              setState(() {
                _obscurePassword = !_obscurePassword;
              });
            },
          ),
          validator: (value) {
            if (value == null || value.isEmpty) {
              return 'Password tidak boleh kosong';
            }
            return null;
          },
        ),
      ],
    );
  }

  Widget _buildDivider() {
    return Row(
      children: [
        Expanded(child: Divider(color: AppColors.divider)),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: AppSizes.md),
          child: Text(
            'atau',
            style: TextStyle(
              color: AppColors.onSurfaceVariant,
              fontSize: AppSizes.fontSm,
            ),
          ),
        ),
        Expanded(child: Divider(color: AppColors.divider)),
      ],
    );
  }

  Widget _buildRegisterLink() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Text(
          'Belum punya akun? ',
          style: TextStyle(
            color: AppColors.onSurfaceVariant,
            fontSize: AppSizes.fontMd,
          ),
        ),
        TextButton(
          onPressed: () {
            context.push(const RegisterPage());
          },
          child: const Text(
            'Daftar Sekarang',
            style: TextStyle(
              fontWeight: FontWeight.bold,
              fontSize: AppSizes.fontMd,
            ),
          ),
        ),
      ],
    );
  }
}
```

## Step 32: Register Page (Design Profesional)

Buat file `lib/presentation/auth/pages/register_page.dart`:

```dart
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../core/components/app_button.dart';
import '../../../core/components/app_text_field.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_sizes.dart';
import '../../../core/extensions/build_context_ext.dart';
import '../../story/pages/home_page.dart';
import '../blocs/register/register_bloc.dart';
import '../blocs/register/register_event.dart';
import '../blocs/register/register_state.dart';

class RegisterPage extends StatefulWidget {
  const RegisterPage({super.key});

  @override
  State<RegisterPage> createState() => _RegisterPageState();
}

class _RegisterPageState extends State<RegisterPage> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();
  bool _obscurePassword = true;
  bool _obscureConfirmPassword = true;

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }

  void _register() {
    if (_formKey.currentState!.validate()) {
      context.read<RegisterBloc>().add(
            RegisterEvent.register(
              name: _nameController.text.trim(),
              email: _emailController.text.trim(),
              password: _passwordController.text,
            ),
          );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: AppColors.onBackground),
          onPressed: () => context.pop(),
        ),
      ),
      body: BlocConsumer<RegisterBloc, RegisterState>(
        listener: (context, state) {
          state.maybeWhen(
            success: (data) {
              context.showSuccess('Registrasi berhasil! Selamat datang, ${data.user.name}!');
              context.pushAndRemoveUntil(const HomePage(), (route) => false);
            },
            error: (message) {
              context.showError(message);
            },
            orElse: () {},
          );
        },
        builder: (context, state) {
          final isLoading = state.maybeWhen(
            loading: () => true,
            orElse: () => false,
          );

          return SafeArea(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(AppSizes.lg),
              child: Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    // ═══════════════════════════════════════════
                    // HEADER
                    // ═══════════════════════════════════════════
                    _buildHeader(),

                    const SizedBox(height: AppSizes.xl),

                    // ═══════════════════════════════════════════
                    // FORM
                    // ═══════════════════════════════════════════
                    _buildRegisterForm(isLoading),

                    const SizedBox(height: AppSizes.lg),

                    // ═══════════════════════════════════════════
                    // REGISTER BUTTON
                    // ═══════════════════════════════════════════
                    AppButton(
                      text: 'Daftar',
                      onPressed: isLoading ? null : _register,
                      isLoading: isLoading,
                    ),

                    const SizedBox(height: AppSizes.lg),

                    // ═══════════════════════════════════════════
                    // LOGIN LINK
                    // ═══════════════════════════════════════════
                    _buildLoginLink(),
                  ],
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildHeader() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Buat Akun Baru',
          style: TextStyle(
            fontSize: AppSizes.fontXxl,
            fontWeight: FontWeight.bold,
            color: AppColors.onBackground,
          ),
        ),
        const SizedBox(height: AppSizes.sm),
        Text(
          'Isi form berikut untuk mendaftar',
          style: TextStyle(
            fontSize: AppSizes.fontMd,
            color: AppColors.onSurfaceVariant,
          ),
        ),
      ],
    );
  }

  Widget _buildRegisterForm(bool isLoading) {
    return Column(
      children: [
        // Name Field
        AppTextField(
          controller: _nameController,
          label: 'Nama Lengkap',
          hint: 'Masukkan nama lengkap anda',
          prefixIcon: Icons.person_outline,
          textInputAction: TextInputAction.next,
          enabled: !isLoading,
          validator: (value) {
            if (value == null || value.isEmpty) {
              return 'Nama tidak boleh kosong';
            }
            if (value.length < 3) {
              return 'Nama minimal 3 karakter';
            }
            return null;
          },
        ),
        const SizedBox(height: AppSizes.md),

        // Email Field
        AppTextField(
          controller: _emailController,
          label: 'Email',
          hint: 'Masukkan email anda',
          prefixIcon: Icons.email_outlined,
          keyboardType: TextInputType.emailAddress,
          textInputAction: TextInputAction.next,
          enabled: !isLoading,
          validator: (value) {
            if (value == null || value.isEmpty) {
              return 'Email tidak boleh kosong';
            }
            if (!RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$').hasMatch(value)) {
              return 'Format email tidak valid';
            }
            return null;
          },
        ),
        const SizedBox(height: AppSizes.md),

        // Password Field
        AppTextField(
          controller: _passwordController,
          label: 'Password',
          hint: 'Minimal 8 karakter',
          prefixIcon: Icons.lock_outline,
          obscureText: _obscurePassword,
          textInputAction: TextInputAction.next,
          enabled: !isLoading,
          suffixIcon: IconButton(
            icon: Icon(
              _obscurePassword ? Icons.visibility_off : Icons.visibility,
              color: AppColors.onSurfaceVariant,
            ),
            onPressed: () {
              setState(() {
                _obscurePassword = !_obscurePassword;
              });
            },
          ),
          validator: (value) {
            if (value == null || value.isEmpty) {
              return 'Password tidak boleh kosong';
            }
            if (value.length < 8) {
              return 'Password minimal 8 karakter';
            }
            return null;
          },
        ),
        const SizedBox(height: AppSizes.md),

        // Confirm Password Field
        AppTextField(
          controller: _confirmPasswordController,
          label: 'Konfirmasi Password',
          hint: 'Ulangi password anda',
          prefixIcon: Icons.lock_outline,
          obscureText: _obscureConfirmPassword,
          textInputAction: TextInputAction.done,
          enabled: !isLoading,
          onSubmitted: (_) => _register(),
          suffixIcon: IconButton(
            icon: Icon(
              _obscureConfirmPassword ? Icons.visibility_off : Icons.visibility,
              color: AppColors.onSurfaceVariant,
            ),
            onPressed: () {
              setState(() {
                _obscureConfirmPassword = !_obscureConfirmPassword;
              });
            },
          ),
          validator: (value) {
            if (value == null || value.isEmpty) {
              return 'Konfirmasi password tidak boleh kosong';
            }
            if (value != _passwordController.text) {
              return 'Password tidak cocok';
            }
            return null;
          },
        ),
      ],
    );
  }

  Widget _buildLoginLink() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Text(
          'Sudah punya akun? ',
          style: TextStyle(
            color: AppColors.onSurfaceVariant,
            fontSize: AppSizes.fontMd,
          ),
        ),
        TextButton(
          onPressed: () => context.pop(),
          child: const Text(
            'Masuk',
            style: TextStyle(
              fontWeight: FontWeight.bold,
              fontSize: AppSizes.fontMd,
            ),
          ),
        ),
      ],
    );
  }
}
```

## Step 33: Home Page (Design Profesional)

Buat file `lib/presentation/story/pages/home_page.dart`:

```dart
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../core/components/empty_state.dart';
import '../../../core/components/error_state.dart';
import '../../../core/components/loading_indicator.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_sizes.dart';
import '../../../core/extensions/build_context_ext.dart';
import '../../auth/blocs/logout/logout_bloc.dart';
import '../../auth/blocs/logout/logout_event.dart';
import '../../auth/blocs/logout/logout_state.dart';
import '../../auth/pages/login_page.dart';
import '../../profile/pages/profile_page.dart';
import '../blocs/delete_story/delete_story_bloc.dart';
import '../blocs/delete_story/delete_story_state.dart';
import '../blocs/get_stories/get_stories_bloc.dart';
import '../blocs/get_stories/get_stories_event.dart';
import '../blocs/get_stories/get_stories_state.dart';
import '../widgets/story_card.dart';
import 'add_story_page.dart';

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  final ScrollController _scrollController = ScrollController();

  @override
  void initState() {
    super.initState();
    _loadStories();
    _scrollController.addListener(_onScroll);
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  void _loadStories() {
    context.read<GetStoriesBloc>().add(
          const GetStoriesEvent.getMyStories(refresh: true),
        );
  }

  void _onScroll() {
    if (_isBottom) {
      context.read<GetStoriesBloc>().add(const GetStoriesEvent.loadMore());
    }
  }

  bool get _isBottom {
    if (!_scrollController.hasClients) return false;
    final maxScroll = _scrollController.position.maxScrollExtent;
    final currentScroll = _scrollController.offset;
    return currentScroll >= (maxScroll * 0.9);
  }

  Future<void> _confirmLogout() async {
    final confirm = await context.showConfirmDialog(
      title: 'Logout',
      message: 'Apakah anda yakin ingin keluar?',
      confirmText: 'Logout',
      confirmColor: AppColors.error,
    );

    if (confirm == true && mounted) {
      context.read<LogoutBloc>().add(const LogoutEvent.logout());
    }
  }

  @override
  Widget build(BuildContext context) {
    return MultiBlocListener(
      listeners: [
        // Logout Listener
        BlocListener<LogoutBloc, LogoutState>(
          listener: (context, state) {
            state.maybeWhen(
              success: () {
                context.pushAndRemoveUntil(const LoginPage(), (route) => false);
              },
              error: (message) {
                context.showError(message);
              },
              orElse: () {},
            );
          },
        ),
        // Delete Story Listener
        BlocListener<DeleteStoryBloc, DeleteStoryState>(
          listener: (context, state) {
            state.maybeWhen(
              success: (message) {
                context.showSuccess(message);
                _loadStories();
              },
              error: (message) {
                context.showError(message);
              },
              orElse: () {},
            );
          },
        ),
      ],
      child: Scaffold(
        backgroundColor: AppColors.background,
        appBar: _buildAppBar(),
        body: _buildBody(),
        floatingActionButton: _buildFAB(),
      ),
    );
  }

  PreferredSizeWidget _buildAppBar() {
    return AppBar(
      backgroundColor: AppColors.surface,
      elevation: 0,
      title: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(AppSizes.sm),
            decoration: BoxDecoration(
              color: AppColors.primaryContainer,
              borderRadius: BorderRadius.circular(AppSizes.radiusSm),
            ),
            child: const Icon(
              Icons.auto_stories_rounded,
              color: AppColors.primary,
              size: AppSizes.iconMd,
            ),
          ),
          const SizedBox(width: AppSizes.sm),
          const Text(
            'Story App',
            style: TextStyle(
              color: AppColors.onSurface,
              fontWeight: FontWeight.bold,
              fontSize: AppSizes.fontXl,
            ),
          ),
        ],
      ),
      actions: [
        // Profile Button
        IconButton(
          icon: const Icon(Icons.person_outline, color: AppColors.onSurface),
          onPressed: () {
            context.push(const ProfilePage());
          },
          tooltip: 'Profile',
        ),
        // Logout Button
        BlocBuilder<LogoutBloc, LogoutState>(
          builder: (context, state) {
            final isLoading = state.maybeWhen(
              loading: () => true,
              orElse: () => false,
            );

            return IconButton(
              icon: isLoading
                  ? const SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : const Icon(Icons.logout, color: AppColors.onSurface),
              onPressed: isLoading ? null : _confirmLogout,
              tooltip: 'Logout',
            );
          },
        ),
      ],
    );
  }

  Widget _buildBody() {
    return BlocBuilder<GetStoriesBloc, GetStoriesState>(
      builder: (context, state) {
        return state.when(
          initial: () => const LoadingIndicator(),
          loading: () => const LoadingIndicator(message: 'Memuat cerita...'),
          success: (stories, currentPage, lastPage, hasMore, isLoadingMore) {
            if (stories.isEmpty) {
              return EmptyState(
                icon: Icons.article_outlined,
                title: 'Belum Ada Cerita',
                subtitle: 'Mulai bagikan cerita pertamamu!',
                buttonText: 'Buat Cerita',
                onButtonPressed: () async {
                  final result = await context.push(const AddStoryPage());
                  if (result == true) {
                    _loadStories();
                  }
                },
              );
            }

            return RefreshIndicator(
              onRefresh: () async {
                _loadStories();
              },
              child: ListView.builder(
                controller: _scrollController,
                padding: const EdgeInsets.all(AppSizes.md),
                itemCount: stories.length + (hasMore ? 1 : 0),
                itemBuilder: (context, index) {
                  if (index >= stories.length) {
                    return const Padding(
                      padding: EdgeInsets.all(AppSizes.md),
                      child: Center(
                        child: CircularProgressIndicator(),
                      ),
                    );
                  }

                  final story = stories[index];
                  return Padding(
                    padding: const EdgeInsets.only(bottom: AppSizes.md),
                    child: StoryCard(
                      story: story,
                      onRefresh: _loadStories,
                    ),
                  );
                },
              ),
            );
          },
          error: (message) => ErrorState(
            message: message,
            onRetry: _loadStories,
          ),
        );
      },
    );
  }

  Widget _buildFAB() {
    return FloatingActionButton.extended(
      onPressed: () async {
        final result = await context.push(const AddStoryPage());
        if (result == true) {
          _loadStories();
        }
      },
      backgroundColor: AppColors.primary,
      foregroundColor: AppColors.onPrimary,
      icon: const Icon(Icons.add),
      label: const Text('Cerita Baru'),
    );
  }
}
```

## Step 34: Story Card Widget

Buat file `lib/presentation/story/widgets/story_card.dart`:

```dart
import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_sizes.dart';
import '../../../core/extensions/build_context_ext.dart';
import '../../../data/models/story_model.dart';
import '../blocs/delete_story/delete_story_bloc.dart';
import '../blocs/delete_story/delete_story_event.dart';
import '../pages/edit_story_page.dart';
import '../pages/story_detail_page.dart';

class StoryCard extends StatelessWidget {
  final StoryModel story;
  final VoidCallback? onRefresh;

  const StoryCard({
    super.key,
    required this.story,
    this.onRefresh,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AppSizes.radiusLg),
        side: BorderSide(color: AppColors.outlineVariant),
      ),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: () async {
          final result = await context.push(StoryDetailPage(story: story));
          if (result == true) {
            onRefresh?.call();
          }
        },
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Image Section
            if (story.imageUrl != null) _buildImage(),

            // Content Section
            Padding(
              padding: const EdgeInsets.all(AppSizes.md),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Title
                  Text(
                    story.title,
                    style: const TextStyle(
                      fontSize: AppSizes.fontLg,
                      fontWeight: FontWeight.bold,
                      color: AppColors.onSurface,
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: AppSizes.sm),

                  // Content Preview
                  Text(
                    story.content,
                    style: const TextStyle(
                      fontSize: AppSizes.fontMd,
                      color: AppColors.onSurfaceVariant,
                      height: 1.5,
                    ),
                    maxLines: 3,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: AppSizes.md),

                  // Footer
                  Row(
                    children: [
                      // Author & Date
                      Expanded(
                        child: Row(
                          children: [
                            CircleAvatar(
                              radius: 14,
                              backgroundColor: AppColors.primaryContainer,
                              child: Text(
                                (story.user?.name ?? 'U').substring(0, 1).toUpperCase(),
                                style: const TextStyle(
                                  fontSize: AppSizes.fontSm,
                                  fontWeight: FontWeight.bold,
                                  color: AppColors.primary,
                                ),
                              ),
                            ),
                            const SizedBox(width: AppSizes.sm),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    story.user?.name ?? 'Unknown',
                                    style: const TextStyle(
                                      fontSize: AppSizes.fontSm,
                                      fontWeight: FontWeight.w500,
                                      color: AppColors.onSurface,
                                    ),
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                  Text(
                                    story.formattedDate,
                                    style: const TextStyle(
                                      fontSize: AppSizes.fontXs,
                                      color: AppColors.onSurfaceVariant,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),

                      // Action Buttons
                      _buildActionButtons(context),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildImage() {
    return AspectRatio(
      aspectRatio: 16 / 9,
      child: CachedNetworkImage(
        imageUrl: story.imageUrl!,
        fit: BoxFit.cover,
        placeholder: (context, url) => Container(
          color: AppColors.surfaceVariant,
          child: const Center(
            child: CircularProgressIndicator(strokeWidth: 2),
          ),
        ),
        errorWidget: (context, url, error) => Container(
          color: AppColors.surfaceVariant,
          child: const Center(
            child: Icon(
              Icons.broken_image_outlined,
              color: AppColors.onSurfaceVariant,
              size: 48,
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildActionButtons(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        // Edit Button
        IconButton(
          icon: const Icon(Icons.edit_outlined),
          iconSize: AppSizes.iconSm,
          color: AppColors.primary,
          onPressed: () async {
            final result = await context.push(EditStoryPage(story: story));
            if (result == true) {
              onRefresh?.call();
            }
          },
          tooltip: 'Edit',
        ),

        // Delete Button
        IconButton(
          icon: const Icon(Icons.delete_outline),
          iconSize: AppSizes.iconSm,
          color: AppColors.error,
          onPressed: () async {
            final confirm = await context.showConfirmDialog(
              title: 'Hapus Cerita',
              message: 'Apakah anda yakin ingin menghapus cerita ini?',
              confirmText: 'Hapus',
              confirmColor: AppColors.error,
            );

            if (confirm == true && context.mounted) {
              context.read<DeleteStoryBloc>().add(
                    DeleteStoryEvent.delete(story.id),
                  );
            }
          },
          tooltip: 'Hapus',
        ),
      ],
    );
  }
}
```

## Step 35: Add Story Page

Buat file `lib/presentation/story/pages/add_story_page.dart`:

```dart
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:image_picker/image_picker.dart';
import '../../../core/components/app_button.dart';
import '../../../core/components/app_text_field.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_sizes.dart';
import '../../../core/extensions/build_context_ext.dart';
import '../blocs/create_story/create_story_bloc.dart';
import '../blocs/create_story/create_story_event.dart';
import '../blocs/create_story/create_story_state.dart';

class AddStoryPage extends StatefulWidget {
  const AddStoryPage({super.key});

  @override
  State<AddStoryPage> createState() => _AddStoryPageState();
}

class _AddStoryPageState extends State<AddStoryPage> {
  final _formKey = GlobalKey<FormState>();
  final _titleController = TextEditingController();
  final _contentController = TextEditingController();
  File? _selectedImage;
  final _imagePicker = ImagePicker();

  @override
  void dispose() {
    _titleController.dispose();
    _contentController.dispose();
    super.dispose();
  }

  Future<void> _pickImage(ImageSource source) async {
    try {
      final pickedFile = await _imagePicker.pickImage(
        source: source,
        maxWidth: 1024,
        maxHeight: 1024,
        imageQuality: 80,
      );

      if (pickedFile != null) {
        setState(() {
          _selectedImage = File(pickedFile.path);
        });
      }
    } catch (e) {
      context.showError('Gagal memilih gambar');
    }
  }

  void _showImageSourceDialog() {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(
          top: Radius.circular(AppSizes.radiusLg),
        ),
      ),
      builder: (context) {
        return SafeArea(
          child: Padding(
            padding: const EdgeInsets.all(AppSizes.md),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // Handle bar
                Container(
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                    color: AppColors.outlineVariant,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
                const SizedBox(height: AppSizes.lg),
                const Text(
                  'Pilih Sumber Gambar',
                  style: TextStyle(
                    fontSize: AppSizes.fontLg,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: AppSizes.lg),
                ListTile(
                  leading: Container(
                    padding: const EdgeInsets.all(AppSizes.sm),
                    decoration: BoxDecoration(
                      color: AppColors.primaryContainer,
                      borderRadius: BorderRadius.circular(AppSizes.radiusSm),
                    ),
                    child: const Icon(Icons.camera_alt, color: AppColors.primary),
                  ),
                  title: const Text('Kamera'),
                  subtitle: const Text('Ambil foto baru'),
                  onTap: () {
                    Navigator.pop(context);
                    _pickImage(ImageSource.camera);
                  },
                ),
                ListTile(
                  leading: Container(
                    padding: const EdgeInsets.all(AppSizes.sm),
                    decoration: BoxDecoration(
                      color: AppColors.secondaryContainer,
                      borderRadius: BorderRadius.circular(AppSizes.radiusSm),
                    ),
                    child: const Icon(Icons.photo_library, color: AppColors.secondary),
                  ),
                  title: const Text('Galeri'),
                  subtitle: const Text('Pilih dari galeri'),
                  onTap: () {
                    Navigator.pop(context);
                    _pickImage(ImageSource.gallery);
                  },
                ),
                const SizedBox(height: AppSizes.md),
              ],
            ),
          ),
        );
      },
    );
  }

  void _submit() {
    if (_formKey.currentState!.validate()) {
      context.read<CreateStoryBloc>().add(
            CreateStoryEvent.create(
              title: _titleController.text.trim(),
              content: _contentController.text.trim(),
              image: _selectedImage,
            ),
          );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.surface,
        elevation: 0,
        title: const Text(
          'Buat Cerita Baru',
          style: TextStyle(
            color: AppColors.onSurface,
            fontWeight: FontWeight.bold,
          ),
        ),
        leading: IconButton(
          icon: const Icon(Icons.close, color: AppColors.onSurface),
          onPressed: () => context.pop(),
        ),
      ),
      body: BlocConsumer<CreateStoryBloc, CreateStoryState>(
        listener: (context, state) {
          state.maybeWhen(
            success: (story) {
              context.showSuccess('Cerita berhasil dibuat!');
              context.pop(true);
            },
            error: (message) {
              context.showError(message);
            },
            orElse: () {},
          );
        },
        builder: (context, state) {
          final isLoading = state.maybeWhen(
            loading: () => true,
            orElse: () => false,
          );

          return SingleChildScrollView(
            padding: const EdgeInsets.all(AppSizes.md),
            child: Form(
              key: _formKey,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  // Image Picker
                  _buildImagePicker(),
                  const SizedBox(height: AppSizes.lg),

                  // Title Field
                  AppTextField(
                    controller: _titleController,
                    label: 'Judul Cerita',
                    hint: 'Masukkan judul cerita yang menarik',
                    prefixIcon: Icons.title,
                    enabled: !isLoading,
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return 'Judul tidak boleh kosong';
                      }
                      if (value.length < 5) {
                        return 'Judul minimal 5 karakter';
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: AppSizes.md),

                  // Content Field
                  AppTextField(
                    controller: _contentController,
                    label: 'Isi Cerita',
                    hint: 'Tulis cerita anda di sini...',
                    maxLines: 8,
                    enabled: !isLoading,
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return 'Isi cerita tidak boleh kosong';
                      }
                      if (value.length < 20) {
                        return 'Isi cerita minimal 20 karakter';
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: AppSizes.lg),

                  // Submit Button
                  AppButton(
                    text: 'Publikasikan',
                    onPressed: isLoading ? null : _submit,
                    isLoading: isLoading,
                    icon: Icons.send,
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildImagePicker() {
    return GestureDetector(
      onTap: _showImageSourceDialog,
      child: Container(
        height: 200,
        decoration: BoxDecoration(
          color: AppColors.surfaceVariant,
          borderRadius: BorderRadius.circular(AppSizes.radiusLg),
          border: Border.all(
            color: AppColors.outlineVariant,
            width: 2,
            style: BorderStyle.solid,
          ),
          image: _selectedImage != null
              ? DecorationImage(
                  image: FileImage(_selectedImage!),
                  fit: BoxFit.cover,
                )
              : null,
        ),
        child: _selectedImage == null
            ? Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.add_photo_alternate_outlined,
                    size: 48,
                    color: AppColors.onSurfaceVariant,
                  ),
                  const SizedBox(height: AppSizes.sm),
                  Text(
                    'Tambahkan Gambar',
                    style: TextStyle(
                      color: AppColors.onSurfaceVariant,
                      fontSize: AppSizes.fontMd,
                    ),
                  ),
                  const SizedBox(height: AppSizes.xs),
                  Text(
                    '(Opsional)',
                    style: TextStyle(
                      color: AppColors.onSurfaceVariant.withOpacity(0.7),
                      fontSize: AppSizes.fontSm,
                    ),
                  ),
                ],
              )
            : Stack(
                children: [
                  Positioned(
                    top: AppSizes.sm,
                    right: AppSizes.sm,
                    child: CircleAvatar(
                      backgroundColor: Colors.black54,
                      radius: 18,
                      child: IconButton(
                        icon: const Icon(Icons.close, size: 18),
                        color: Colors.white,
                        onPressed: () {
                          setState(() {
                            _selectedImage = null;
                          });
                        },
                      ),
                    ),
                  ),
                ],
              ),
      ),
    );
  }
}
```

## Step 36: Story Detail Page

Buat file `lib/presentation/story/pages/story_detail_page.dart`:

```dart
import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_sizes.dart';
import '../../../core/extensions/build_context_ext.dart';
import '../../../data/models/story_model.dart';
import '../blocs/delete_story/delete_story_bloc.dart';
import '../blocs/delete_story/delete_story_event.dart';
import '../blocs/delete_story/delete_story_state.dart';
import 'edit_story_page.dart';

class StoryDetailPage extends StatelessWidget {
  final StoryModel story;

  const StoryDetailPage({super.key, required this.story});

  @override
  Widget build(BuildContext context) {
    return BlocListener<DeleteStoryBloc, DeleteStoryState>(
      listener: (context, state) {
        state.maybeWhen(
          success: (message) {
            context.showSuccess(message);
            context.pop(true);
          },
          error: (message) {
            context.showError(message);
          },
          orElse: () {},
        );
      },
      child: Scaffold(
        backgroundColor: AppColors.background,
        body: CustomScrollView(
          slivers: [
            // App Bar with Image
            _buildSliverAppBar(context),

            // Content
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.all(AppSizes.md),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Title
                    Text(
                      story.title,
                      style: const TextStyle(
                        fontSize: AppSizes.fontXxl,
                        fontWeight: FontWeight.bold,
                        color: AppColors.onSurface,
                        height: 1.3,
                      ),
                    ),
                    const SizedBox(height: AppSizes.md),

                    // Author Info
                    _buildAuthorInfo(),
                    const SizedBox(height: AppSizes.lg),

                    // Divider
                    Divider(color: AppColors.divider),
                    const SizedBox(height: AppSizes.lg),

                    // Content
                    Text(
                      story.content,
                      style: const TextStyle(
                        fontSize: AppSizes.fontLg,
                        color: AppColors.onSurface,
                        height: 1.8,
                      ),
                    ),
                    const SizedBox(height: AppSizes.xxl),
                  ],
                ),
              ),
            ),
          ],
        ),
        bottomNavigationBar: _buildBottomBar(context),
      ),
    );
  }

  Widget _buildSliverAppBar(BuildContext context) {
    return SliverAppBar(
      expandedHeight: story.imageUrl != null ? 300 : 0,
      pinned: true,
      backgroundColor: AppColors.surface,
      foregroundColor: AppColors.onSurface,
      flexibleSpace: story.imageUrl != null
          ? FlexibleSpaceBar(
              background: CachedNetworkImage(
                imageUrl: story.imageUrl!,
                fit: BoxFit.cover,
                placeholder: (context, url) => Container(
                  color: AppColors.surfaceVariant,
                  child: const Center(
                    child: CircularProgressIndicator(),
                  ),
                ),
                errorWidget: (context, url, error) => Container(
                  color: AppColors.surfaceVariant,
                  child: const Icon(
                    Icons.broken_image,
                    size: 64,
                    color: AppColors.onSurfaceVariant,
                  ),
                ),
              ),
            )
          : null,
    );
  }

  Widget _buildAuthorInfo() {
    return Row(
      children: [
        CircleAvatar(
          radius: 24,
          backgroundColor: AppColors.primaryContainer,
          child: Text(
            (story.user?.name ?? 'U').substring(0, 1).toUpperCase(),
            style: const TextStyle(
              fontSize: AppSizes.fontXl,
              fontWeight: FontWeight.bold,
              color: AppColors.primary,
            ),
          ),
        ),
        const SizedBox(width: AppSizes.md),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                story.user?.name ?? 'Unknown',
                style: const TextStyle(
                  fontSize: AppSizes.fontLg,
                  fontWeight: FontWeight.w600,
                  color: AppColors.onSurface,
                ),
              ),
              const SizedBox(height: AppSizes.xs),
              Text(
                story.formattedDate,
                style: const TextStyle(
                  fontSize: AppSizes.fontMd,
                  color: AppColors.onSurfaceVariant,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildBottomBar(BuildContext context) {
    return Container(
      padding: EdgeInsets.only(
        left: AppSizes.md,
        right: AppSizes.md,
        bottom: context.padding.bottom + AppSizes.md,
        top: AppSizes.md,
      ),
      decoration: BoxDecoration(
        color: AppColors.surface,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, -5),
          ),
        ],
      ),
      child: Row(
        children: [
          // Edit Button
          Expanded(
            child: OutlinedButton.icon(
              onPressed: () async {
                final result = await context.push(EditStoryPage(story: story));
                if (result == true && context.mounted) {
                  context.pop(true);
                }
              },
              icon: const Icon(Icons.edit_outlined),
              label: const Text('Edit'),
              style: OutlinedButton.styleFrom(
                padding: const EdgeInsets.symmetric(vertical: AppSizes.md),
                side: const BorderSide(color: AppColors.primary),
              ),
            ),
          ),
          const SizedBox(width: AppSizes.md),

          // Delete Button
          Expanded(
            child: BlocBuilder<DeleteStoryBloc, DeleteStoryState>(
              builder: (context, state) {
                final isLoading = state.maybeWhen(
                  loading: () => true,
                  orElse: () => false,
                );

                return FilledButton.icon(
                  onPressed: isLoading
                      ? null
                      : () async {
                          final confirm = await context.showConfirmDialog(
                            title: 'Hapus Cerita',
                            message: 'Apakah anda yakin ingin menghapus cerita ini?',
                            confirmText: 'Hapus',
                            confirmColor: AppColors.error,
                          );

                          if (confirm == true && context.mounted) {
                            context.read<DeleteStoryBloc>().add(
                                  DeleteStoryEvent.delete(story.id),
                                );
                          }
                        },
                  icon: isLoading
                      ? const SizedBox(
                          width: 16,
                          height: 16,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: Colors.white,
                          ),
                        )
                      : const Icon(Icons.delete_outline),
                  label: const Text('Hapus'),
                  style: FilledButton.styleFrom(
                    backgroundColor: AppColors.error,
                    padding: const EdgeInsets.symmetric(vertical: AppSizes.md),
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}
```

## Step 37: Edit Story Page

Buat file `lib/presentation/story/pages/edit_story_page.dart`:

```dart
import 'dart:io';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:image_picker/image_picker.dart';
import '../../../core/components/app_button.dart';
import '../../../core/components/app_text_field.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_sizes.dart';
import '../../../core/extensions/build_context_ext.dart';
import '../../../data/models/story_model.dart';
import '../blocs/update_story/update_story_bloc.dart';
import '../blocs/update_story/update_story_event.dart';
import '../blocs/update_story/update_story_state.dart';

class EditStoryPage extends StatefulWidget {
  final StoryModel story;

  const EditStoryPage({super.key, required this.story});

  @override
  State<EditStoryPage> createState() => _EditStoryPageState();
}

class _EditStoryPageState extends State<EditStoryPage> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _titleController;
  late final TextEditingController _contentController;
  File? _selectedImage;
  bool _imageChanged = false;
  final _imagePicker = ImagePicker();

  @override
  void initState() {
    super.initState();
    _titleController = TextEditingController(text: widget.story.title);
    _contentController = TextEditingController(text: widget.story.content);
  }

  @override
  void dispose() {
    _titleController.dispose();
    _contentController.dispose();
    super.dispose();
  }

  Future<void> _pickImage(ImageSource source) async {
    try {
      final pickedFile = await _imagePicker.pickImage(
        source: source,
        maxWidth: 1024,
        maxHeight: 1024,
        imageQuality: 80,
      );

      if (pickedFile != null) {
        setState(() {
          _selectedImage = File(pickedFile.path);
          _imageChanged = true;
        });
      }
    } catch (e) {
      context.showError('Gagal memilih gambar');
    }
  }

  void _showImageSourceDialog() {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(
          top: Radius.circular(AppSizes.radiusLg),
        ),
      ),
      builder: (context) {
        return SafeArea(
          child: Padding(
            padding: const EdgeInsets.all(AppSizes.md),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                    color: AppColors.outlineVariant,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
                const SizedBox(height: AppSizes.lg),
                const Text(
                  'Ubah Gambar',
                  style: TextStyle(
                    fontSize: AppSizes.fontLg,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: AppSizes.lg),
                ListTile(
                  leading: Container(
                    padding: const EdgeInsets.all(AppSizes.sm),
                    decoration: BoxDecoration(
                      color: AppColors.primaryContainer,
                      borderRadius: BorderRadius.circular(AppSizes.radiusSm),
                    ),
                    child: const Icon(Icons.camera_alt, color: AppColors.primary),
                  ),
                  title: const Text('Kamera'),
                  onTap: () {
                    Navigator.pop(context);
                    _pickImage(ImageSource.camera);
                  },
                ),
                ListTile(
                  leading: Container(
                    padding: const EdgeInsets.all(AppSizes.sm),
                    decoration: BoxDecoration(
                      color: AppColors.secondaryContainer,
                      borderRadius: BorderRadius.circular(AppSizes.radiusSm),
                    ),
                    child: const Icon(Icons.photo_library, color: AppColors.secondary),
                  ),
                  title: const Text('Galeri'),
                  onTap: () {
                    Navigator.pop(context);
                    _pickImage(ImageSource.gallery);
                  },
                ),
                const SizedBox(height: AppSizes.md),
              ],
            ),
          ),
        );
      },
    );
  }

  void _submit() {
    if (_formKey.currentState!.validate()) {
      context.read<UpdateStoryBloc>().add(
            UpdateStoryEvent.update(
              id: widget.story.id,
              title: _titleController.text.trim(),
              content: _contentController.text.trim(),
              image: _imageChanged ? _selectedImage : null,
            ),
          );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.surface,
        elevation: 0,
        title: const Text(
          'Edit Cerita',
          style: TextStyle(
            color: AppColors.onSurface,
            fontWeight: FontWeight.bold,
          ),
        ),
        leading: IconButton(
          icon: const Icon(Icons.close, color: AppColors.onSurface),
          onPressed: () => context.pop(),
        ),
      ),
      body: BlocConsumer<UpdateStoryBloc, UpdateStoryState>(
        listener: (context, state) {
          state.maybeWhen(
            success: (story) {
              context.showSuccess('Cerita berhasil diperbarui!');
              context.pop(true);
            },
            error: (message) {
              context.showError(message);
            },
            orElse: () {},
          );
        },
        builder: (context, state) {
          final isLoading = state.maybeWhen(
            loading: () => true,
            orElse: () => false,
          );

          return SingleChildScrollView(
            padding: const EdgeInsets.all(AppSizes.md),
            child: Form(
              key: _formKey,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  // Image Picker
                  _buildImagePicker(),
                  const SizedBox(height: AppSizes.lg),

                  // Title Field
                  AppTextField(
                    controller: _titleController,
                    label: 'Judul Cerita',
                    hint: 'Masukkan judul cerita',
                    prefixIcon: Icons.title,
                    enabled: !isLoading,
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return 'Judul tidak boleh kosong';
                      }
                      if (value.length < 5) {
                        return 'Judul minimal 5 karakter';
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: AppSizes.md),

                  // Content Field
                  AppTextField(
                    controller: _contentController,
                    label: 'Isi Cerita',
                    hint: 'Tulis cerita anda di sini...',
                    maxLines: 8,
                    enabled: !isLoading,
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return 'Isi cerita tidak boleh kosong';
                      }
                      if (value.length < 20) {
                        return 'Isi cerita minimal 20 karakter';
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: AppSizes.lg),

                  // Submit Button
                  AppButton(
                    text: 'Simpan Perubahan',
                    onPressed: isLoading ? null : _submit,
                    isLoading: isLoading,
                    icon: Icons.save,
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildImagePicker() {
    final hasExistingImage = widget.story.imageUrl != null && !_imageChanged;
    final hasNewImage = _selectedImage != null;

    return GestureDetector(
      onTap: _showImageSourceDialog,
      child: Container(
        height: 200,
        decoration: BoxDecoration(
          color: AppColors.surfaceVariant,
          borderRadius: BorderRadius.circular(AppSizes.radiusLg),
          border: Border.all(color: AppColors.outlineVariant, width: 2),
        ),
        clipBehavior: Clip.antiAlias,
        child: Stack(
          fit: StackFit.expand,
          children: [
            if (hasExistingImage)
              CachedNetworkImage(
                imageUrl: widget.story.imageUrl!,
                fit: BoxFit.cover,
              )
            else if (hasNewImage)
              Image.file(_selectedImage!, fit: BoxFit.cover)
            else
              Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.add_photo_alternate_outlined,
                    size: 48,
                    color: AppColors.onSurfaceVariant,
                  ),
                  const SizedBox(height: AppSizes.sm),
                  Text(
                    'Tambahkan Gambar',
                    style: TextStyle(
                      color: AppColors.onSurfaceVariant,
                      fontSize: AppSizes.fontMd,
                    ),
                  ),
                ],
              ),

            // Overlay untuk edit
            if (hasExistingImage || hasNewImage)
              Positioned(
                bottom: 0,
                left: 0,
                right: 0,
                child: Container(
                  padding: const EdgeInsets.all(AppSizes.sm),
                  color: Colors.black54,
                  child: const Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.edit, color: Colors.white, size: 16),
                      SizedBox(width: 4),
                      Text(
                        'Ketuk untuk mengubah',
                        style: TextStyle(color: Colors.white, fontSize: 12),
                      ),
                    ],
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}
```

## Step 38: Profile Page

Buat file `lib/presentation/profile/pages/profile_page.dart`:

```dart
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../core/components/error_state.dart';
import '../../../core/components/loading_indicator.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_sizes.dart';
import '../../../core/extensions/build_context_ext.dart';
import '../../auth/blocs/logout/logout_bloc.dart';
import '../../auth/blocs/logout/logout_event.dart';
import '../../auth/blocs/logout/logout_state.dart';
import '../../auth/pages/login_page.dart';
import '../blocs/profile/profile_bloc.dart';
import '../blocs/profile/profile_event.dart';
import '../blocs/profile/profile_state.dart';

class ProfilePage extends StatefulWidget {
  const ProfilePage({super.key});

  @override
  State<ProfilePage> createState() => _ProfilePageState();
}

class _ProfilePageState extends State<ProfilePage> {
  @override
  void initState() {
    super.initState();
    context.read<ProfileBloc>().add(const ProfileEvent.getProfile());
  }

  Future<void> _confirmLogout() async {
    final confirm = await context.showConfirmDialog(
      title: 'Logout',
      message: 'Apakah anda yakin ingin keluar?',
      confirmText: 'Logout',
      confirmColor: AppColors.error,
    );

    if (confirm == true && mounted) {
      context.read<LogoutBloc>().add(const LogoutEvent.logout());
    }
  }

  @override
  Widget build(BuildContext context) {
    return BlocListener<LogoutBloc, LogoutState>(
      listener: (context, state) {
        state.maybeWhen(
          success: () {
            context.pushAndRemoveUntil(const LoginPage(), (route) => false);
          },
          error: (message) {
            context.showError(message);
          },
          orElse: () {},
        );
      },
      child: Scaffold(
        backgroundColor: AppColors.background,
        appBar: AppBar(
          backgroundColor: AppColors.surface,
          elevation: 0,
          title: const Text(
            'Profil',
            style: TextStyle(
              color: AppColors.onSurface,
              fontWeight: FontWeight.bold,
            ),
          ),
          leading: IconButton(
            icon: const Icon(Icons.arrow_back, color: AppColors.onSurface),
            onPressed: () => context.pop(),
          ),
        ),
        body: BlocBuilder<ProfileBloc, ProfileState>(
          builder: (context, state) {
            return state.when(
              initial: () => const LoadingIndicator(),
              loading: () => const LoadingIndicator(message: 'Memuat profil...'),
              success: (user) {
                return SingleChildScrollView(
                  padding: const EdgeInsets.all(AppSizes.md),
                  child: Column(
                    children: [
                      const SizedBox(height: AppSizes.lg),

                      // Avatar
                      CircleAvatar(
                        radius: 60,
                        backgroundColor: AppColors.primaryContainer,
                        child: Text(
                          user.name.substring(0, 1).toUpperCase(),
                          style: const TextStyle(
                            fontSize: 48,
                            fontWeight: FontWeight.bold,
                            color: AppColors.primary,
                          ),
                        ),
                      ),
                      const SizedBox(height: AppSizes.lg),

                      // Name
                      Text(
                        user.name,
                        style: const TextStyle(
                          fontSize: AppSizes.fontXxl,
                          fontWeight: FontWeight.bold,
                          color: AppColors.onSurface,
                        ),
                      ),
                      const SizedBox(height: AppSizes.xs),

                      // Email
                      Text(
                        user.email,
                        style: const TextStyle(
                          fontSize: AppSizes.fontMd,
                          color: AppColors.onSurfaceVariant,
                        ),
                      ),
                      const SizedBox(height: AppSizes.xl),

                      // Profile Info Card
                      _buildInfoCard(user),
                      const SizedBox(height: AppSizes.lg),

                      // Logout Button
                      _buildLogoutButton(),
                    ],
                  ),
                );
              },
              error: (message) => ErrorState(
                message: message,
                onRetry: () {
                  context.read<ProfileBloc>().add(const ProfileEvent.getProfile());
                },
              ),
            );
          },
        ),
      ),
    );
  }

  Widget _buildInfoCard(user) {
    return Card(
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AppSizes.radiusLg),
        side: BorderSide(color: AppColors.outlineVariant),
      ),
      child: Padding(
        padding: const EdgeInsets.all(AppSizes.md),
        child: Column(
          children: [
            _buildInfoRow(
              icon: Icons.person_outline,
              label: 'Nama',
              value: user.name,
            ),
            const Divider(height: AppSizes.lg),
            _buildInfoRow(
              icon: Icons.email_outlined,
              label: 'Email',
              value: user.email,
            ),
            const Divider(height: AppSizes.lg),
            _buildInfoRow(
              icon: Icons.calendar_today_outlined,
              label: 'Bergabung',
              value: user.createdAt != null
                  ? '${user.createdAt!.day}/${user.createdAt!.month}/${user.createdAt!.year}'
                  : '-',
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildInfoRow({
    required IconData icon,
    required String label,
    required String value,
  }) {
    return Row(
      children: [
        Container(
          padding: const EdgeInsets.all(AppSizes.sm),
          decoration: BoxDecoration(
            color: AppColors.primaryContainer,
            borderRadius: BorderRadius.circular(AppSizes.radiusSm),
          ),
          child: Icon(icon, size: 20, color: AppColors.primary),
        ),
        const SizedBox(width: AppSizes.md),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: const TextStyle(
                  fontSize: AppSizes.fontSm,
                  color: AppColors.onSurfaceVariant,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                value,
                style: const TextStyle(
                  fontSize: AppSizes.fontMd,
                  fontWeight: FontWeight.w500,
                  color: AppColors.onSurface,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildLogoutButton() {
    return BlocBuilder<LogoutBloc, LogoutState>(
      builder: (context, state) {
        final isLoading = state.maybeWhen(
          loading: () => true,
          orElse: () => false,
        );

        return SizedBox(
          width: double.infinity,
          child: OutlinedButton.icon(
            onPressed: isLoading ? null : _confirmLogout,
            icon: isLoading
                ? const SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : const Icon(Icons.logout, color: AppColors.error),
            label: Text(
              isLoading ? 'Logging out...' : 'Logout',
              style: const TextStyle(color: AppColors.error),
            ),
            style: OutlinedButton.styleFrom(
              padding: const EdgeInsets.symmetric(vertical: AppSizes.md),
              side: const BorderSide(color: AppColors.error),
            ),
          ),
        );
      },
    );
  }
}
```

---

# PART 10: MAIN.DART

## Step 39: Main Application

Buat file `lib/main.dart`:

```dart
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'bloc_providers.dart';
import 'core/constants/app_colors.dart';
import 'presentation/splash/pages/splash_page.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();

  // Set status bar style
  SystemChrome.setSystemUIOverlayStyle(
    const SystemUiOverlayStyle(
      statusBarColor: Colors.transparent,
      statusBarIconBrightness: Brightness.dark,
    ),
  );

  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiBlocProvider(
      providers: blocProviders,
      child: MaterialApp(
        title: 'Story App',
        debugShowCheckedModeBanner: false,
        theme: _buildTheme(),
        home: const SplashPage(),
      ),
    );
  }

  ThemeData _buildTheme() {
    return ThemeData(
      useMaterial3: true,
      colorScheme: ColorScheme.fromSeed(
        seedColor: AppColors.primary,
        brightness: Brightness.light,
      ),
      scaffoldBackgroundColor: AppColors.background,
      appBarTheme: const AppBarTheme(
        centerTitle: true,
        elevation: 0,
        backgroundColor: AppColors.surface,
        foregroundColor: AppColors.onSurface,
      ),
      cardTheme: CardTheme(
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
        ),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: AppColors.primary,
          foregroundColor: AppColors.onPrimary,
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: AppColors.surface,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: AppColors.outline),
        ),
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
      ),
      snackBarTheme: SnackBarThemeData(
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(8),
        ),
      ),
    );
  }
}
```

---

# PART 11: GENERATE FREEZED FILES & RUN

## Step 40: Generate Freezed Files

```bash
# Generate semua file Freezed
flutter pub run build_runner build --delete-conflicting-outputs

# Atau gunakan watch mode untuk auto-generate
flutter pub run build_runner watch --delete-conflicting-outputs
```

## Step 41: Run Laravel Backend

```bash
# Di folder story-api
cd /path/to/story-api

# Jalankan migration
php artisan migrate

# Buat storage link
php artisan storage:link

# Jalankan server
php artisan serve --host=0.0.0.0 --port=8000
```

## Step 42: Run Flutter App

```bash
# Di folder flutter_story_app
flutter run
```

---

# DIAGRAM FLOW LENGKAP

## Flow Login

```
┌─────────────────────────────────────────────────────────────────────────────┐
│                              LOGIN FLOW                                      │
├─────────────────────────────────────────────────────────────────────────────┤
│                                                                              │
│  LoginPage                    LoginBloc                AuthRemoteDatasource  │
│  ─────────                    ─────────                ─────────────────────  │
│      │                            │                            │             │
│      │ 1. User tap "Masuk"        │                            │             │
│      ├───────────────────────────►│                            │             │
│      │   LoginEvent.login()       │                            │             │
│      │                            │                            │             │
│      │                            │ 2. emit(loading)           │             │
│      │◄───────────────────────────┤                            │             │
│      │   state: Loading           │                            │             │
│      │   (show spinner)           │                            │             │
│      │                            │                            │             │
│      │                            │ 3. login(email, password)  │             │
│      │                            ├───────────────────────────►│             │
│      │                            │                            │             │
│      │                            │                            │ 4. POST     │
│      │                            │                            │    /login   │
│      │                            │                            │    ─────►   │
│      │                            │                            │             │
│      │                            │                            │ 5. Response │
│      │                            │                            │◄─────       │
│      │                            │                            │             │
│      │                            │ 6. Either<String, Auth>    │             │
│      │                            │◄───────────────────────────┤             │
│      │                            │                            │             │
│      │ 7. emit(success/error)     │                            │             │
│      │◄───────────────────────────┤                            │             │
│      │   state: Success/Error     │                            │             │
│      │                            │                            │             │
│      │ 8. Navigate to HomePage    │                            │             │
│      │   or show error message    │                            │             │
│      ▼                            ▼                            ▼             │
│                                                                              │
└─────────────────────────────────────────────────────────────────────────────┘
```

## Flow Create Story

```
┌─────────────────────────────────────────────────────────────────────────────┐
│                           CREATE STORY FLOW                                  │
├─────────────────────────────────────────────────────────────────────────────┤
│                                                                              │
│  AddStoryPage               CreateStoryBloc           StoryRemoteDatasource  │
│  ───────────                ────────────────          ──────────────────────  │
│      │                            │                            │             │
│      │ 1. Isi form + pilih gambar │                            │             │
│      │                            │                            │             │
│      │ 2. Tap "Publikasikan"      │                            │             │
│      ├───────────────────────────►│                            │             │
│      │ CreateStoryEvent.create()  │                            │             │
│      │                            │                            │             │
│      │                            │ 3. emit(loading)           │             │
│      │◄───────────────────────────┤                            │             │
│      │   state: Loading           │                            │             │
│      │                            │                            │             │
│      │                            │ 4. createStory(...)        │             │
│      │                            ├───────────────────────────►│             │
│      │                            │                            │             │
│      │                            │                            │ 5. POST     │
│      │                            │                            │  /stories   │
│      │                            │                            │  multipart  │
│      │                            │                            │  ─────────► │
│      │                            │                            │             │
│      │                            │ 6. Either<String, Story>   │             │
│      │                            │◄───────────────────────────┤             │
│      │                            │                            │             │
│      │ 7. emit(success)           │                            │             │
│      │◄───────────────────────────┤                            │             │
│      │                            │                            │             │
│      │ 8. Pop & return true       │                            │             │
│      │                            │                            │             │
│      │                            │                            │             │
│  HomePage                         │                            │             │
│  ────────                         │                            │             │
│      │                            │                            │             │
│      │ 9. Refresh stories         │                            │             │
│      ▼                            ▼                            ▼             │
│                                                                              │
└─────────────────────────────────────────────────────────────────────────────┘
```

---

# TIPS & BEST PRACTICES

## 1. Freezed Pattern Matching

```dart
// Gunakan when untuk handle semua state
state.when(
  initial: () => Container(),
  loading: () => CircularProgressIndicator(),
  success: (data) => Text(data),
  error: (msg) => Text(msg),
);

// Gunakan maybeWhen untuk handle sebagian state
state.maybeWhen(
  loading: () => true,
  orElse: () => false,
);
```

## 2. BlocConsumer vs BlocBuilder vs BlocListener

```dart
// BlocBuilder: Rebuild UI berdasarkan state
BlocBuilder<MyBloc, MyState>(
  builder: (context, state) => Widget,
);

// BlocListener: Side effects (navigate, snackbar)
BlocListener<MyBloc, MyState>(
  listener: (context, state) {
    // Navigate, show snackbar, etc
  },
);

// BlocConsumer: Keduanya
BlocConsumer<MyBloc, MyState>(
  listener: (context, state) {},
  builder: (context, state) => Widget,
);
```

## 3. Either (Dartz) untuk Error Handling

```dart
// Di Datasource
Future<Either<String, Data>> fetchData() async {
  try {
    // success
    return Right(data);
  } catch (e) {
    // error
    return Left(e.toString());
  }
}

// Di Bloc
final result = await datasource.fetchData();
result.fold(
  (error) => emit(State.error(error)),
  (data) => emit(State.success(data)),
);
```

---

# CHECKLIST FINAL

- [ ] Semua dependencies terinstall (`flutter pub get`)
- [ ] File Freezed sudah di-generate (`build_runner build`)
- [ ] Laravel backend sudah running
- [ ] Storage link sudah dibuat (`php artisan storage:link`)
- [ ] Base URL sudah benar di `variables.dart`
- [ ] Semua BLoC terdaftar di `bloc_providers.dart`

---

**Selamat Livecode!**

© JagoFlutter Academy 2026
