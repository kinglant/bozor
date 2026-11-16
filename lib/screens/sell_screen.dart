
import 'package:material_ui/material_ui.dart';
import 'package:flutter/services.dart';
import 'package:image_picker/image_picker.dart';
import 'package:provider/provider.dart';

import '../models/models.dart';
import '../state/market_store.dart';

class SellScreen extends StatefulWidget {
  const SellScreen({super.key, required this.onPublished});

  final VoidCallback onPublished;

  @override
  State<SellScreen> createState() => _SellScreenState();
}

class _SellScreenState extends State<SellScreen> {
  static const _maxPhotos = 5;

  final _formKey = GlobalKey<FormState>();
  final _title = TextEditingController();
  final _price = TextEditingController();
  final _description = TextEditingController();
  final _location = TextEditingController(text: 'San Francisco, CA');
  Category? _category;
  Condition _condition = Condition.good;
  final List<Uint8List> _photos = [];

  @override
  void dispose() {
    for (final c in [_title, _price, _description, _location]) {
      c.dispose();
    }
    super.dispose();
  }

  Future<void> _pickPhotos() async {
    try {
      final files = await ImagePicker().pickMultiImage(maxWidth: 1080, imageQuality: 75, limit: _maxPhotos - _photos.length);
      final bytes = await Future.wait(files.map((f) => f.readAsBytes()));
      if (!mounted) return;
      setState(() => _photos.addAll(bytes.take(_maxPhotos - _photos.length)));
    } catch (_) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Could not open the photo library.')));
    }
  }

  void _publish() {
    if (!_formKey.currentState!.validate()) return;
    context.read<MarketStore>().addListing(
          title: _title.text.trim(),
          description: _description.text.trim(),
          price: double.parse(_price.text),
          category: _category!,
          condition: _condition,
          location: _location.text.trim(),
          photos: List.of(_photos),
        );
    _formKey.currentState!.reset();
    for (final c in [_title, _price, _description]) {
      c.clear();
    }
    setState(() {
      _photos.clear();
      _category = null;
      _condition = Condition.good;
    });
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('🎉 Your item is live! Find it under Profile.')),
    );
    widget.onPublished();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final sectionTitle = theme.textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w700);

    return Scaffold(
      appBar: AppBar(title: const Text('Sell an item')),
      body: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 640),
          child: Form(
            key: _formKey,
            child: ListView(
              padding: const EdgeInsets.fromLTRB(16, 8, 16, 32),
              children: [
                Text('Photos (${_photos.length}/$_maxPhotos)', style: sectionTitle),
                const SizedBox(height: 8),
                SizedBox(
                  height: 96,
                  child: ListView(
                    scrollDirection: Axis.horizontal,
                    children: [
                      if (_photos.length < _maxPhotos)
                        InkWell(
                          onTap: _pickPhotos,
                          borderRadius: BorderRadius.circular(14),
                          child: Container(
                            width: 96,
                            decoration: BoxDecoration(
                              borderRadius: BorderRadius.circular(14),
                              border: Border.all(color: scheme.primary, width: 1.5),
                              color: scheme.primaryContainer.withValues(alpha: 0.4),
                            ),
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(Icons.add_a_photo_outlined, color: scheme.primary),
                                const SizedBox(height: 4),
                                Text('Add', style: TextStyle(color: scheme.primary, fontWeight: FontWeight.w600)),
                              ],
                            ),
                          ),
                        ),
                      for (var i = 0; i < _photos.length; i++)
                        Padding(
                          padding: const EdgeInsets.only(left: 10),
                          child: Stack(
                            children: [
                              ClipRRect(
                                borderRadius: BorderRadius.circular(14),
                                child: Image.memory(_photos[i], width: 96, height: 96, fit: BoxFit.cover),
                              ),
                              Positioned(
                                top: 4,
                                right: 4,
                                child: InkWell(
                                  onTap: () => setState(() => _photos.removeAt(i)),
                                  child: const CircleAvatar(
                                    radius: 12,
                                    backgroundColor: Colors.black54,
                                    child: Icon(Icons.close, size: 14, color: Colors.white),
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                    ],
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  'No photos? We\'ll show a nice illustration instead.',
                  style: theme.textTheme.bodySmall?.copyWith(color: scheme.onSurfaceVariant),
                ),
                const SizedBox(height: 20),
                TextFormField(
                  controller: _title,
                  textCapitalization: TextCapitalization.sentences,
                  maxLength: 70,
                  decoration: const InputDecoration(labelText: 'Title', hintText: 'e.g. iPhone 15, 128GB, black'),
                  validator: (v) => (v == null || v.trim().length < 4) ? 'Enter at least 4 characters' : null,
                ),
                const SizedBox(height: 12),
                TextFormField(
                  controller: _price,
                  keyboardType: const TextInputType.numberWithOptions(decimal: true),
                  inputFormatters: [FilteringTextInputFormatter.allow(RegExp(r'^\d{0,6}(\.\d{0,2})?'))],
                  decoration: const InputDecoration(labelText: 'Price', prefixText: '\$ '),
                  validator: (v) => (v == null || double.tryParse(v) == null) ? 'Enter a price (0 for free)' : null,
                ),
                const SizedBox(height: 16),
                DropdownButtonFormField<Category>(
                  initialValue: _category,
                  decoration: const InputDecoration(labelText: 'Category'),
                  items: [
                    for (final c in Category.values)
                      DropdownMenuItem(
                        value: c,
                        child: Row(children: [Icon(c.icon, size: 20), const SizedBox(width: 10), Text(c.label)]),
                      ),
                  ],
                  onChanged: (v) => setState(() => _category = v),
                  validator: (v) => v == null ? 'Choose a category' : null,
                ),
                const SizedBox(height: 20),
                Text('Condition', style: sectionTitle),
                const SizedBox(height: 8),
                SegmentedButton<Condition>(
                  showSelectedIcon: false,
                  segments: [for (final c in Condition.values) ButtonSegment(value: c, label: Text(c.label))],
                  selected: {_condition},
                  onSelectionChanged: (s) => setState(() => _condition = s.first),
                ),
                const SizedBox(height: 20),
                TextFormField(
                  controller: _description,
                  textCapitalization: TextCapitalization.sentences,
                  minLines: 4,
                  maxLines: 8,
                  maxLength: 1000,
                  decoration: const InputDecoration(
                    labelText: 'Description',
                    hintText: 'Describe the condition, what\'s included, and pickup details.',
                    alignLabelWithHint: true,
                  ),
                  validator: (v) => (v == null || v.trim().length < 10) ? 'Add a few more details' : null,
                ),
                const SizedBox(height: 12),
                TextFormField(
                  controller: _location,
                  decoration: const InputDecoration(labelText: 'Location', prefixIcon: Icon(Icons.location_on_outlined)),
                  validator: (v) => (v == null || v.trim().isEmpty) ? 'Enter a location' : null,
                ),
                const SizedBox(height: 28),
                FilledButton.icon(
                  style: FilledButton.styleFrom(minimumSize: const Size.fromHeight(54)),
                  onPressed: _publish,
                  icon: const Icon(Icons.rocket_launch_outlined),
                  label: const Text('Publish listing'),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
