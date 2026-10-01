import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:shop_application/features/catalog/presentation/controllers/catalog_controller.dart';
import 'package:shop_application/features/catalog/domain/entities/product.dart';

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
      _product = context.read<CatalogController>().findById(productId);
    }

    _titleController.text = _product.title ?? '';
    _priceController.text =
        _product.price == null ? '' : _product.price.toString();
    _categoryController.text = _product.category;
    _stockController.text = _product.stockQuantity?.toString() ?? '';
    _descriptionController.text = _product.description ?? '';
    _imageUrlController.text = _product.imageUrls.isNotEmpty
        ? _product.imageUrls.join('\n')
        : (_product.imageUrl ?? '');
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
    final previewImages = _parseImageUrlsInput(_imageUrlController.text);

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
              imageUrl:
                  previewImages.isEmpty ? '' : previewImages.first,
              imageCount: previewImages.length,
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
              textInputAction: TextInputAction.newline,
              minLines: 3,
              maxLines: 6,
              decoration: const InputDecoration(
                labelText: 'Image URLs',
                helperText: 'One URL per line, up to 6 images',
                alignLabelWithHint: true,
                prefixIcon: Icon(Icons.collections_outlined),
              ),
              onChanged: (_) {
                setState(() {});
              },
              validator: (value) {
                final images = _parseImageUrlsInput(value ?? '');
                if (images.isEmpty) {
                  return 'At least one image URL is required.';
                }
                if (images.length > 6) {
                  return 'Use no more than 6 images.';
                }

                for (final image in images) {
                  final uri = Uri.tryParse(image);
                  final validScheme =
                      uri?.scheme == 'http' || uri?.scheme == 'https';
                  if (uri == null ||
                      !validScheme ||
                      uri.host.isEmpty) {
                    return 'Every image must be a valid http or https URL.';
                  }
                }

                return null;
              },
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

  List<String> _parseImageUrlsInput(String raw) {
    return raw
        .split(RegExp(r'\r?\n'))
        .map((value) => value.trim())
        .where((value) => value.isNotEmpty)
        .toSet()
        .take(7)
        .toList();
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    setState(() {
      _isSaving = true;
    });

    final provider = context.read<CatalogController>();
    final stockText = _stockController.text.trim();
    final imageUrls = _parseImageUrlsInput(_imageUrlController.text);
    final updatedProduct = _product.copyWith(
      title: _titleController.text.trim(),
      price: double.parse(_priceController.text.trim()),
      category: _categoryController.text.trim(),
      stockQuantity: stockText.isEmpty ? null : int.parse(stockText),
      clearStock: stockText.isEmpty,
      description: _descriptionController.text.trim(),
      imageUrl: imageUrls.first,
      imageUrls: imageUrls,
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
  final int imageCount;

  const _ProductImagePreview({
    required this.imageUrl,
    required this.imageCount,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Stack(
      children: [
        AspectRatio(
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
        ),
        if (imageCount > 1)
          Positioned(
            right: 12,
            bottom: 12,
            child: Container(
              padding: const EdgeInsets.symmetric(
                horizontal: 10,
                vertical: 6,
              ),
              decoration: BoxDecoration(
                color: theme.colorScheme.surface.withValues(alpha: 0.9),
                borderRadius: BorderRadius.circular(99),
              ),
              child: Text(
                '$imageCount images',
                style: theme.textTheme.labelMedium?.copyWith(
                  fontWeight: FontWeight.w800,
                ),
              ),
            ),
          ),
      ],
    );
  }
}
