import '../services/api_client.dart';

String friendlyError(Object error) {
  if (error is NoConnectionException) {
    return NoConnectionException.defaultMessage;
  }
  return error.toString();
}
