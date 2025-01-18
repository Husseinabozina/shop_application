class RegisterResponse {
  final String kind;
  final String idToken;
  final String email;
  final String refreshToken;
  final String expiresIn;
  final String localId;

  RegisterResponse({
    required this.kind,
    required this.idToken,
    required this.email,
    required this.refreshToken,
    required this.expiresIn,
    required this.localId,
  });

  // Factory constructor to parse the JSON data
  factory RegisterResponse.fromJson(Map<String, dynamic> json) {
    return RegisterResponse(
      kind: json['kind'] as String,
      idToken: json['idToken'] as String,
      email: json['email'] as String,
      refreshToken: json['refreshToken'] as String,
      expiresIn: json['expiresIn'] as String,
      localId: json['localId'] as String,
    );
  }

  // Method to convert the object to a JSON format
  Map<String, dynamic> toJson() {
    return {
      'kind': kind,
      'idToken': idToken,
      'email': email,
      'refreshToken': refreshToken,
      'expiresIn': expiresIn,
      'localId': localId,
    };
  }
}
