import 'dart:io';
import 'package:dartz/dartz.dart';
import '../../core/constants/variables.dart';
import '../../core/utils/api_handler.dart';
import '../models/stories_response_model.dart';
import '../models/story_model.dart';

class StoryRemoteDatasource {
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

  Future<Either<String, StoryModel>> createStory({
    required String description,
    required File image,
    double? lat,
    double? lon,
  }) async {
    final fields = <String, String>{
      'title': description.length > 50 ? description.substring(0, 50) : description,
      'content': description,
    };
    if (lat != null) fields['lat'] = lat.toString();
    if (lon != null) fields['lon'] = lon.toString();

    final result = await ApiHandler.postMultipart(
      Variables.stories,
      fields: fields,
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

  Future<Either<String, StoryModel>> updateStory({
    required int id,
    required String description,
    File? image,
    double? lat,
    double? lon,
  }) async {
    final fields = <String, String>{
      '_method': 'PUT',
      'title': description.length > 50 ? description.substring(0, 50) : description,
      'content': description,
    };
    if (lat != null) fields['lat'] = lat.toString();
    if (lon != null) fields['lon'] = lon.toString();

    final result = await ApiHandler.postMultipart(
      Variables.storyById(id),
      fields: fields,
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

  Future<Either<String, String>> deleteStory({required int id}) async {
    final result = await ApiHandler.delete(Variables.storyById(id));

    return result.fold(
      (error) => Left(error),
      (data) => Right(data['message'] ?? 'Cerita berhasil dihapus'),
    );
  }
}
