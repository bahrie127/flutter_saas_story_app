import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../data/datasources/auth_remote_datasource.dart';
import '../data/datasources/story_remote_datasource.dart';
import '../presentation/auth/blocs/login/login_bloc.dart';
import '../presentation/auth/blocs/logout/logout_bloc.dart';
import '../presentation/auth/blocs/register/register_bloc.dart';
import '../presentation/profile/blocs/profile/profile_bloc.dart';
import '../presentation/story/blocs/create_story/create_story_bloc.dart';
import '../presentation/story/blocs/delete_story/delete_story_bloc.dart';
import '../presentation/story/blocs/get_stories/get_stories_bloc.dart';
import '../presentation/story/blocs/update_story/update_story_bloc.dart';

class BlocProviders extends StatelessWidget {
  final Widget child;

  const BlocProviders({
    super.key,
    required this.child,
  });

  @override
  Widget build(BuildContext context) {
    final authDatasource = AuthRemoteDatasource();
    final storyDatasource = StoryRemoteDatasource();

    return MultiBlocProvider(
      providers: [
        BlocProvider(
          create: (context) => LoginBloc(authDatasource),
        ),
        BlocProvider(
          create: (context) => RegisterBloc(authDatasource),
        ),
        BlocProvider(
          create: (context) => LogoutBloc(authDatasource),
        ),
        BlocProvider(
          create: (context) => ProfileBloc(authDatasource),
        ),
        BlocProvider(
          create: (context) => GetStoriesBloc(storyDatasource),
        ),
        BlocProvider(
          create: (context) => CreateStoryBloc(storyDatasource),
        ),
        BlocProvider(
          create: (context) => UpdateStoryBloc(storyDatasource),
        ),
        BlocProvider(
          create: (context) => DeleteStoryBloc(storyDatasource),
        ),
      ],
      child: child,
    );
  }
}
