class AddProductsResponseBody {
  String? name;
  AddProductsResponseBody({this.name});

  factory AddProductsResponseBody.fromJson(Map<String, dynamic> json) {
    return AddProductsResponseBody(name: json['name']);
  }
}
