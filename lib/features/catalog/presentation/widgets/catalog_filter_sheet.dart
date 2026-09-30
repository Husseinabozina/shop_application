import 'package:flutter/material.dart';
import 'package:shop_application/features/catalog/domain/entities/catalog_filter.dart';

class CatalogFilterSheet extends StatefulWidget {
  final CatalogFilter initialFilter;

  const CatalogFilterSheet({
    super.key,
    required this.initialFilter,
  });

  @override
  State<CatalogFilterSheet> createState() => _CatalogFilterSheetState();
}

class _CatalogFilterSheetState extends State<CatalogFilterSheet> {
  late final TextEditingController _minPriceController;
  late final TextEditingController _maxPriceController;
  late bool _inStockOnly;

  @override
  void initState() {
    super.initState();
    _minPriceController = TextEditingController(
      text: _priceText(widget.initialFilter.minPrice),
    );
    _maxPriceController = TextEditingController(
      text: _priceText(widget.initialFilter.maxPrice),
    );
    _inStockOnly = widget.initialFilter.inStockOnly;
  }

  @override
  void dispose() {
    _minPriceController.dispose();
    _maxPriceController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final bottomInset = MediaQuery.viewInsetsOf(context).bottom;
    final theme = Theme.of(context);

    return Padding(
      padding: EdgeInsets.fromLTRB(
        18,
        18,
        18,
        18 + bottomInset,
      ),
      child: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              children: [
                Expanded(
                  child: Text(
                    'Filter products',
                    style: theme.textTheme.headlineSmall?.copyWith(
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                ),
                TextButton(
                  onPressed: _clear,
                  child: const Text('Clear'),
                ),
              ],
            ),
            const SizedBox(height: 18),
            Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _minPriceController,
                    keyboardType: const TextInputType.numberWithOptions(
                      decimal: true,
                    ),
                    decoration: const InputDecoration(
                      labelText: 'Min price',
                      prefixText: '$ ',
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: TextField(
                    controller: _maxPriceController,
                    keyboardType: const TextInputType.numberWithOptions(
                      decimal: true,
                    ),
                    decoration: const InputDecoration(
                      labelText: 'Max price',
                      prefixText: '$ ',
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            SwitchListTile.adaptive(
              contentPadding: EdgeInsets.zero,
              value: _inStockOnly,
              onChanged: (value) {
                setState(() => _inStockOnly = value);
              },
              title: const Text('In-stock products only'),
              subtitle: const Text(
                'Hide products that are currently sold out.',
              ),
            ),
            const SizedBox(height: 14),
            FilledButton(
              onPressed: _apply,
              child: const Text('Apply filters'),
            ),
          ],
        ),
      ),
    );
  }

  void _clear() {
    setState(() {
      _minPriceController.clear();
      _maxPriceController.clear();
      _inStockOnly = false;
    });
  }

  void _apply() {
    final minRaw = _minPriceController.text.trim();
    final maxRaw = _maxPriceController.text.trim();
    final minPrice = _parsePrice(minRaw);
    final maxPrice = _parsePrice(maxRaw);

    if ((minRaw.isNotEmpty && minPrice == null) ||
        (maxRaw.isNotEmpty && maxPrice == null)) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Enter valid non-negative prices.'),
        ),
      );
      return;
    }

    if (minPrice != null &&
        maxPrice != null &&
        minPrice > maxPrice) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Minimum price cannot be greater than maximum price.'),
        ),
      );
      return;
    }

    Navigator.of(context).pop(
      CatalogFilter(
        minPrice: minPrice,
        maxPrice: maxPrice,
        inStockOnly: _inStockOnly,
      ),
    );
  }

  double? _parsePrice(String raw) {
    final value = raw.trim();
    if (value.isEmpty) {
      return null;
    }

    final parsed = double.tryParse(value);
    if (parsed == null || parsed < 0) {
      return null;
    }
    return parsed;
  }

  String _priceText(double? value) {
    if (value == null) {
      return '';
    }
    return value == value.roundToDouble()
        ? value.toStringAsFixed(0)
        : value.toStringAsFixed(2);
  }
}
