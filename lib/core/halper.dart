import 'package:http/http.dart' as http;
import 'package:infoev/app/services/ConfigService.dart'; 

// Tambahkan getter untuk nilai dinamis
String get devUrl => ConfigService().devUrl;
String get baseUrl => ConfigService().baseUrl;
String get prodUrl => ConfigService().prodUrl; 

// Function for environment-specific URL
String getDevUrl({bool isProduction = false}) {
  return isProduction ? ConfigService().prodUrl : ConfigService().devUrl;
}

extension HttpResponseExtension on http.Response {
  bool get isOk => statusCode == 200;
  bool get isCreated => statusCode == 201;
  bool get isAccepted => statusCode == 202;
  bool get isNoContent => statusCode == 204;

  bool get isBadRequest => statusCode == 400;
  bool get isUnauthorized => statusCode == 401;
  bool get isForbidden => statusCode == 403;
  bool get isNotFound => statusCode == 404;
  bool get isMethodNotAllowed => statusCode == 405;
  bool get isConflict => statusCode == 409;

  bool get isInternalServerError => statusCode == 500;
  bool get isNotImplemented => statusCode == 501;
  bool get isBadGateway => statusCode == 502;
  bool get isServiceUnavailable => statusCode == 503;
}
