import '../core/utils/json_utils.dart';
import 'auth_response.dart';

class GoogleAuthResponse {
  const GoogleAuthResponse({
    this.auth,
    this.profile,
  });

  final AuthResponse? auth;
  final GoogleProfileHint? profile;

  bool get needsProfile => profile != null;

  factory GoogleAuthResponse.fromJson(Map<String, dynamic> json) {
    if (boolFrom(json['needsProfile'])) {
      return GoogleAuthResponse(
        profile: GoogleProfileHint.fromJson(mapFrom(json['profile'])),
      );
    }

    return GoogleAuthResponse(
      auth: AuthResponse.fromJson(json),
    );
  }
}

class GoogleProfileHint {
  const GoogleProfileHint({
    required this.name,
    required this.email,
  });

  final String name;
  final String email;

  factory GoogleProfileHint.fromJson(Map<String, dynamic> json) {
    return GoogleProfileHint(
      name: stringFrom(json['name']),
      email: stringFrom(json['email']),
    );
  }
}
