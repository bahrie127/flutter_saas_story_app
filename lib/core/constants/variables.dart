class Variables {
  static const String baseUrl = 'http://192.168.70.107:8000/api';

  // Auth endpoints
  static const String register = '$baseUrl/register';
  static const String login = '$baseUrl/login';
  static const String logout = '$baseUrl/logout';
  static const String profile = '$baseUrl/profile';

  // Story endpoints
  static const String stories = '$baseUrl/stories';
  static const String myStories = '$baseUrl/my-stories';

  static String storyById(int id) => '$baseUrl/stories/$id';
}
