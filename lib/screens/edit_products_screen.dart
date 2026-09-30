import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:shop_application/controllers/products_provider/products_provider.dart';
import 'package:shop_application/provider/product.dart';

class EditProductScreen extends StatefulWidget {
  static const String routeName = '/editProduct';

  const EditProductScreen({super.key});

  @override
  State<EditProductScreen> createState() => _EditProductScreenState();
}

class _EditProductScreenState extends State<EditProductScreen> {
  final _formKey = GlobalKey<FormState>();

  final _titleController = TextEditingController();
  final _priceController = TextEditingController();
  final _categoryController = TextEditingController();
  final _stockController = TextEditingController();
  final _descriptionController = TextEditingController();
  final _imageUrlController = TextEditingController();

  Product _product = Product();
  bool _didInitialize = false;
  bool _isSaving = false;

  bool get _isEditing =>
      _product.id != null || _product.productId != null;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();

    if (_didInitialize) {
      return;
    }
    _didInitialize = true;

    final productId = ModalRoute.of(context)?.settings.arguments as String?;
    if (productId != null) {
      _product = context.read<ProductsProvider>().findById(productId);
    }

    _titleController.text = _product.title ?? '';
    _priceController.text =
        _product.price == null ? '' : _product.price.toString();
    _categoryController.text = _product.category;
    _stockController.text = _product.stockQuantity?.toString() ?? '';
    _descriptionController.text = _product.description ?? '';
    _imageUrlController.text = _product.imageUrl ?? '';
  }

  @override
  void dispose() {
    _titleController.dispose();
    _priceController.dispose();
    _categoryController.dispose();
    _stockController.dispose();
    _descriptionController.dispose();
    _imageUrlController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        title: Text(_isEditing ? 'Edit product' : 'Add product'),
      ),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.fromLTRB(18, 8, 18, 120),
          children: [
            Text(
              _isEditing
                  ? 'Update the storefront listing'
                  : 'Create a storefront listing',
              style: theme.textTheme.headlineSmall?.copyWith(
                fontWeight: FontWeight.w900,
              ),
            ),
            const SizedBox(height: 6),
            Text(
              'Keep the product details clear and customer-friendly.',
              style: theme.textTheme.bodyMedium?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ),
            const SizedBox(height: 22),
            _ProductImagePreview(
              imageUrl: _imageUrlController.text.trim(),
            ),
            const SizedBox(height: 18),
            TextFormField(
              controller: _titleController,
              textInputAction: TextInputAction.next,
              decoration: const InputDecoration(
                labelText: 'Product title',
                prefixIcon: Icon(Icons.inventory_2_outlined),
              ),
              validator: _requiredValidator('Product title'),
            ),
            const SizedBox(height: 14),
            Row(
              children: [
                Expanded(
                  child: TextFormField(
                    controller: _priceController,
                    textInputAction: TextInputAction.next,
                    keyboardType: const TextInputType.numberWithOptions(
                      decimal: true,
                    ),
                    decoration: const InputDecoration(
                      labelText: 'Price',
                      prefixIcon: Icon(Icons.attach_money_rounded),
                    ),
                    validator: (value) {
                      final price = double.tryParse((value ?? '').trim());
                      if (price == null) {
                        return 'Enter a valid price.';
                      }
                      if (price <= 0) {
                        return 'Price must be greater than zero.';
                      }
                      return null;
                    },
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: TextFormField(
                    controller: _categoryController,
                    textInputAction: TextInputAction.next,
                    textCapitalization: TextCapitalization.words,
                    decoration: const InputDecoration(
                      labelText: 'Category',
                      prefixIcon: Icon(Icons.category_outlined),
                    ),
                    validator: _requiredValidator('Category'),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 14),
            TextFormField(
              controller: _stockController,
              keyboardType: TextInputType.number,
              textInputAction: TextInputAction.next,
              decoration: const InputDecoration(
                labelText: 'Stock quantity (optional)',
                helperText: 'Leave empty if inventory is not tracked',
                prefixIcon: Icon(Icons.inventory_outlined),
              ),
              validator: (value) {
                final text = (value ?? '').trim();
                if (text.isEmpty) {
                  return null;
                }

                final stock = int.tryParse(text);
                if (stock == null || stock < 0) {
                  return 'Enter a whole number of zero or more.';
                }
                return null;
              },
            ),
            const SizedBox(height: 14),
            TextFormField(
              controller: _descriptionController,
              minLines: 4,
              maxLines: 7,
              textInputAction: TextInputAction.newline,
              decoration: const InputDecoration(
                labelText: 'Description',
                alignLabelWithHint: true,
                prefixIcon: Icon(Icons.notes_rounded),
              ),
              validator: (value) {
                final text = (value ?? '').trim();
                if (text.isEmpty) {
                  return 'Description is required.';
                }
                if (text.length < 10) {
                  return 'Use at least 10 characters.';
                }
                return null;
              },
            ),
            const SizedBox(height: 14),
            TextFormField(
              controller: _imageUrlController,
              keyboardType: TextInputType.url,
              textInputAction: TextInputAction.done,
              decoration: const InputDecoration(
                labelText: 'Image URL',
                prefixIcon: Icon(Icons.image_outlined),
              ),
              onChanged: (_) {
                setState(() {});
              },
              validator: (value) {
                final text = (value ?? '').trim();
                if (text.isEmpty) {
                  return 'Image URL is required.';
                }

                final uri = Uri.tryParse(text);
                final validScheme =
                    uri?.scheme == 'http' || uri?.scheme == 'https';
                if (uri == null || !validScheme || uri.host.isEmpty) {
                  return 'Enter a valid http or https URL.';
                }
                return null;
              },
              onFieldSubmitted: (_) => _save(),
            ),
          ],
        ),
      ),
      bottomNavigationBar: SafeArea(
        minimum: const EdgeInsets.fromLTRB(18, 8, 18, 14),
        child: FilledButton.icon(
          onPressed: _isSaving ? null : _save,
          icon: _isSaving
              ? const SizedBox(
                  width: 20,
                  height: 20,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                  ),
                )
              : const Icon(Icons.check_rounded),
          label: Text(
            _isSaving
                ? 'Saving…'
                : _isEditing
                    ? 'Save changes'
                    : 'Add product',
          ),
        ),
      ),
    );
  }

  FormFieldValidator<String> _requiredValidator(String fieldName) {
    return (value) {
      if ((value ?? '').trim().isEmpty) {
        return '$fieldName is required.';
      }
      return null;
    };
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    setState(() {
      _isSaving = true;
    });

    final provider = context.read<ProductsProvider>();
    final stockText = _stockController.text.trim();
    final updatedProduct = _product.copyWith(
      title: _titleController.text.trim(),
      price: double.parse(_priceController.text.trim()),
      category: _categoryController.text.trim(),
      stockQuantity: stockText.isEmpty ? null : int.parse(stockText),
      clearStock: stockText.isEmpty,
      description: _descriptionController.text.trim(),
      imageUrl: _imageUrlController.text.trim(),
    );

    if (_isEditing) {
      await provider.updateProduct(updatedProduct);
    } else {
      await provider.addProduct(updatedProduct);
    }

    if (!mounted) {
      return;
    }

    setState(() {
      _isSaving = false;
    });

    final error = provider.updateProductErrorMessage;
    if (error != null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(error)),
      );
      return;
    }

    Navigator.of(context).pop();
  }
}

class _ProductImagePreview extends StatelessWidget {
  final String imageUrl;

  const _ProductImagePreview({
    required this.imageUrl,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return AspectRatio(
      aspectRatio: 16 / 9,
      child: ClipRRect(
        borderRadius: BorderRadius.circular(24),
        child: ColoredBox(
          color: theme.colorScheme.surfaceContainerHighest,
          child: imageUrl.isEmpty
              ? Center(
                  child: Icon(
                    Icons.add_photo_alternate_outlined,
                    size: 52,
                    color: theme.colorScheme.outline,
                  ),
                )
              : Image.network(
                  imageUrl,
                  fit: BoxFit.cover,
                  errorBuilder: (_, __, ___) {
                    return Center(
                      child: Icon(
                        Icons.broken_image_outlined,
                        size: 52,
                        color: theme.colorScheme.outline,
                      ),
                    );
                  },
                ),
        ),
      ),
    );
  }
}
