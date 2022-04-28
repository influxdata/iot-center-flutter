import 'package:http/http.dart' as http;

extension ResponseExtension on http.Response {
  bool isSuccess() {
    return statusCode >= 200 && statusCode < 300;
  }
}
