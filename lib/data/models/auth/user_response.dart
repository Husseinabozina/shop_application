class UserResponse {
  String? userId;
  String? token;
  String? expiryDate;

  UserResponse({this.userId, this.token, this.expiryDate});

  UserResponse.fromJson(Map<String, dynamic> json) {
    userId = json['userId'];
    token = json['token'];
    expiryDate = json['expiryDate'];
  }
}
