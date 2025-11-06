import 'package:intl/intl.dart';
import 'package:appwrite/appwrite.dart';
import 'package:kantin_app/data/models/log.dart';
import 'package:kantin_app/data/models/project_info.dart';
import 'package:kantin_app/config/environment.dart';

/// A repository responsible for handling network interactions with the Appwrite server.
///
/// It provides a helper method to ping the server.
class BaseAppwriteRepository {
  static const String pingPath = "/ping";
  static const String appwriteProjectId = Environment.appwriteProjectId;
  static const String appwriteProjectName = Environment.appwriteProjectName;
  static const String appwritePublicEndpoint = Environment.appwritePublicEndpoint;

  final Client client = Client()
      .setProject(appwriteProjectId)
      .setEndpoint(appwritePublicEndpoint);

  static final BaseAppwriteRepository _instance = BaseAppwriteRepository._internal();

  BaseAppwriteRepository._internal();

  /// Singleton instance getter
  factory BaseAppwriteRepository() => _instance;

  ProjectInfo getProjectInfo() {
    return ProjectInfo(
      endpoint: appwritePublicEndpoint,
      projectId: appwriteProjectId,
      projectName: appwriteProjectName,
    );
  }

  /// Pings the Appwrite server and captures the response.
  ///
  /// @return [Log] containing request and response details.
  Future<Log> ping() async {
    try {
      final response = await client.ping();

      return Log(
        date: _getCurrentDate(),
        status: 200,
        method: "GET",
        path: pingPath,
        response: response,
      );
    } on AppwriteException catch (error) {
      return Log(
        date: _getCurrentDate(),
        status: error.code ?? 500,
        method: "GET",
        path: pingPath,
        response: error.message ?? "Unknown error",
      );
    }
  }

  /// Retrieves the current date in the format "MMM dd, HH:mm".
  ///
  /// @return [String] A formatted date.
  String _getCurrentDate() {
    return DateFormat("MMM dd, HH:mm").format(DateTime.now());
  }
}
