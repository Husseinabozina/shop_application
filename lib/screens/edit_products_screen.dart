import 'package:flutter/material.dart';
import 'package:flutter/src/widgets/container.dart';
import 'package:flutter/src/widgets/framework.dart';
import 'package:provider/provider.dart';
import 'package:shop_application/provider/product.dart';
import 'package:shop_application/provider/products.dart';

class EditProductScreen extends StatefulWidget {
  static const String routeName = "/editProduct";
  const EditProductScreen({super.key});

  @override
  State<EditProductScreen> createState() => _EditProductScreenState();
}

class _EditProductScreenState extends State<EditProductScreen> {
  final _priceFocusNode = FocusNode();
  final _descrpitionFocusNode = FocusNode();
  final _imageUrlController = TextEditingController();
  final _imageUrlFocusNode = FocusNode();
  final _form = GlobalKey<FormState>();
  var _editedProduct =
      Product(price: 0, description: '', id: null, imageUrl: "", title: '');
  var _isloading = false;
  void initState() {
    // TODO: implement initState
    _imageUrlFocusNode.addListener(_updateTextController);
  }

  bool isdid = false;
  @override
  void didChangeDependencies() {
    if (!isdid) {
      var productid = ModalRoute.of(context)!.settings.arguments;
      if (productid != null) {
        _editedProduct = Provider.of<Products>(context, listen: false)
            .findById(productid as String);
        _imageUrlController.text = _editedProduct.imageUrl!;
      }
    }

    isdid = true;

    super.didChangeDependencies();
  }

  @override
  void dispose() {
    _imageUrlFocusNode.removeListener(_updateTextController);
    _priceFocusNode.dispose();
    _descrpitionFocusNode.dispose();
    _imageUrlController.dispose();
    _imageUrlFocusNode.dispose();

    super.dispose();
  }

  void _updateTextController() {
    if (!_imageUrlFocusNode.hasFocus) {
      if (_imageUrlController.text!.isEmpty ||
          (!_imageUrlController.text.startsWith('http') &&
              !_imageUrlController.text.startsWith('https'))) {
        return;
      }
      setState(() {});
    }
  }

  Future<void> _saveForm() async {
    final isValid = _form.currentState!.validate();
    if (!isValid) {
      return;
    }
    _form.currentState!.save();
    setState(() {
      _isloading = true;
      print(" isloading = $_isloading ");
    });

    if (_editedProduct.id != null) {
      await Provider.of<Products>(context, listen: false)
          .updateproduct(_editedProduct.id!, _editedProduct);
    } else {
      try {
        await Provider.of<Products>(context, listen: false)
            .addProductToJson(_editedProduct);
      } catch (error) {
        await showDialog<Null>(
            context: context,
            builder: (ctx) {
              return AlertDialog(
                title: Text("An error occured"),
                content: Text("somthing wrong"),
                actions: [
                  TextButton(
                      onPressed: () {
                        Navigator.of(ctx).pop();
                      },
                      child: Text('Okay'))
                ],
              );
            });
      }
    }
    setState(() {
      _isloading = false;
      print(" isloading = $_isloading ");
    });
    Navigator.pop(context);

    print(_editedProduct.title);
    print(_editedProduct.description);
    print(_editedProduct.imageUrl);
    print(_editedProduct.price);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text("edit product"),
        actions: [
          IconButton(
              onPressed: () {
                _saveForm();
              },
              icon: Icon(Icons.save))
        ],
      ),
      body: (_isloading)
          ? Center(child: CircularProgressIndicator())
          : Padding(
              padding: const EdgeInsets.all(16),
              child: Form(
                key: _form,
                child: ListView(
                  children: [
                    TextFormField(
                      initialValue: _editedProduct.title,
                      decoration: InputDecoration(labelText: "Title"),
                      textInputAction: TextInputAction.next,
                      onFieldSubmitted: (_) =>
                          FocusScope.of(context).requestFocus(_priceFocusNode),
                      onSaved: (value) {
                        _editedProduct = Product(
                            price: _editedProduct.price,
                            description: _editedProduct.description,
                            id: _editedProduct.id,
                            imageUrl: _editedProduct.imageUrl,
                            title: value!,
                            isFavorite: _editedProduct.isFavorite);
                      },
                      validator: (value) {
                        if (value!.isEmpty) {
                          return "please provide a value!";
                        }
                        return null;
                      },
                    ),
                    TextFormField(
                      initialValue: _editedProduct.price.toString(),
                      decoration: InputDecoration(labelText: "Price"),
                      textInputAction: TextInputAction.next,
                      keyboardType: TextInputType.number,
                      focusNode: _priceFocusNode,
                      onFieldSubmitted: (_) => FocusScope.of(context)
                          .requestFocus(_descrpitionFocusNode),
                      onSaved: (value) {
                        _editedProduct = Product(
                            price: double.parse(value!),
                            description: _editedProduct.description,
                            id: _editedProduct.id,
                            imageUrl: _editedProduct.imageUrl,
                            title: _editedProduct.title,
                            isFavorite: _editedProduct.isFavorite);
                      },
                      validator: (value) {
                        if (value!.isEmpty) {
                          return "please provide a value!";
                        }
                        if (double.parse(value) == null) {
                          return "please enter a valid number";
                        }
                        if (double.parse(value) <= 0) {
                          return "please enter a number greater than 0";
                        }
                        return null;
                      },
                    ),
                    TextFormField(
                      initialValue: _editedProduct.description,
                      decoration: InputDecoration(labelText: "Description"),
                      textInputAction: TextInputAction.next,
                      keyboardType: TextInputType.text,
                      maxLines: 3,
                      focusNode: _descrpitionFocusNode,
                      onSaved: (value) {
                        _editedProduct = Product(
                            price: _editedProduct.price,
                            description: value!,
                            id: _editedProduct.id,
                            imageUrl: _editedProduct.imageUrl,
                            title: _editedProduct.title,
                            isFavorite: _editedProduct.isFavorite);
                      },
                      validator: (value) {
                        if (value!.isEmpty) {
                          return "please provide a value!";
                        }
                        if (value!.length < 10) {
                          return "should be at least 10 charachter least";
                        }
                      },
                    ),
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        Container(
                          width: 100,
                          height: 100,
                          margin: EdgeInsets.only(top: 8, right: 10),
                          decoration: BoxDecoration(
                            border: Border.all(width: 1, color: Colors.grey),
                          ),
                          child: _imageUrlController.text.isEmpty
                              ? Text('Enter a UrL')
                              : FittedBox(
                                  child: Image.network(
                                    _imageUrlController.text,
                                    fit: BoxFit.cover,
                                  ),
                                ),
                        ),
                        Expanded(
                            child: TextFormField(
                          decoration: InputDecoration(labelText: 'Image URL'),
                          keyboardType: TextInputType.url,
                          textInputAction: TextInputAction.done,
                          controller: _imageUrlController,
                          focusNode: _imageUrlFocusNode,
                          onEditingComplete: () {
                            setState(() {});
                          },
                          onFieldSubmitted: (value) {
                            _saveForm();
                          },
                          onSaved: (value) {
                            _editedProduct = Product(
                                price: _editedProduct.price,
                                description: _editedProduct.description,
                                // id: _editedProduct.id,
                                id: _editedProduct.id,
                                imageUrl: value!,
                                title: _editedProduct.title,
                                isFavorite: _editedProduct.isFavorite);
                          },
                          validator: (value) {
                            if (value!.isEmpty) {
                              return "please provide a value";
                            }
                            if (!value.startsWith('http') ||
                                !value.startsWith('https')) {
                              return "please enter a valid URL";
                            }
                            return null;
                          },
                        )),
                      ],
                    )
                  ],
                ),
              ),
            ),
    );
  }
}
