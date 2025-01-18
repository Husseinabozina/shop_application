class LoginResponse {
  final String kind;
  final String localId;
  final String email;
  final String displayName;
  final String idToken;
  final bool registered;

  LoginResponse({
    required this.kind,
    required this.localId,
    required this.email,
    required this.displayName,
    required this.idToken,
    required this.registered,
  });

  // Factory constructor to parse the JSON data
  factory LoginResponse.fromJson(Map<String, dynamic> json) {
    return LoginResponse(
      kind: json['kind'] as String,
      localId: json['localId'] as String,
      email: json['email'] as String,
      displayName: json['displayName'] as String,
      idToken: json['idToken'] as String,
      registered: json['registered'] as bool,
    );
  }

  // Method to convert the object to a JSON format
  Map<String, dynamic> toJson() {
    return {
      'kind': kind,
      'localId': localId,
      'email': email,
      'displayName': displayName,
      'idToken': idToken,
      'registered': registered,
    };
  }
}