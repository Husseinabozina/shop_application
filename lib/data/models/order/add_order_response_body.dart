class AddOrderResponseBody {
  String? name;

  AddOrderResponseBody({this.name});

  AddOrderResponseBody.fromJson(Map<String, dynamic> json) {
    name = json['name'];
  }

  toJson() {
    final Map<String, dynamic> data = new Map<String, dynamic>();
    data['name'] = this.name;
    return data;
  }
}
