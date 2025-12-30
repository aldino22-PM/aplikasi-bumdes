import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';

import '../data/product_repository.dart';

class AddProductPage extends ConsumerStatefulWidget {
  const AddProductPage({super.key});

  @override
  ConsumerState<AddProductPage> createState() => _AddProductPageState();
}

class _AddProductPageState extends ConsumerState<AddProductPage> {
  final _formKey = GlobalKey<FormState>();
  final _title = TextEditingController();
  final _price = TextEditingController();
  final _category = TextEditingController();
  final _weight = TextEditingController(text: '250 gr');
  final _delivery = TextEditingController(text: '10-15 mnt');
  final _distance = TextEditingController(text: '1 km');
  final _picker = ImagePicker();
  XFile? _pickedImage;
  Uint8List? _previewBytes;
  String? _imageError;
  bool _loading = false;

  @override
  void dispose() {
    _title.dispose();
    _price.dispose();
    _category.dispose();
    _weight.dispose();
    _delivery.dispose();
    _distance.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Form(
        key: _formKey,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Tambah Produk',
              style: Theme.of(context)
                  .textTheme
                  .titleLarge
                  ?.copyWith(fontWeight: FontWeight.w700),
            ),
            const SizedBox(height: 12),
            _field(_title, 'Nama produk', prefix: Icons.eco, validator: _req),
            const SizedBox(height: 10),
            _field(_price, 'Harga (Rp)', prefix: Icons.attach_money,
                keyboardType: TextInputType.number, validator: _req),
            const SizedBox(height: 10),
            _imagePickerField(),
            const SizedBox(height: 10),
            _field(_category, 'Kategori', prefix: Icons.label, validator: _req),
            const SizedBox(height: 10),
            _field(_weight, 'Berat', prefix: Icons.scale),
            const SizedBox(height: 10),
            _field(_delivery, 'Estimasi kirim', prefix: Icons.timer),
            const SizedBox(height: 10),
            _field(_distance, 'Jarak', prefix: Icons.place),
            const SizedBox(height: 16),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                icon: _loading
                    ? const SizedBox(
                        height: 18,
                        width: 18,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: Colors.white,
                        ),
                      )
                    : const Icon(Icons.save),
                label: const Text('Simpan'),
                onPressed: _loading ? null : () => _submit(ref),
              ),
            )
          ],
        ),
      ),
    );
  }

  Future<void> _submit(WidgetRef ref) async {
    if (!(_formKey.currentState?.validate() ?? false)) return;
    if (_pickedImage == null) {
      setState(() => _imageError = 'Wajib upload foto produk');
      return;
    }
    setState(() => _loading = true);
    try {
      final repo = ref.read(productRepositoryProvider);
      await repo.createProduct(
        title: _title.text.trim(),
        price: int.tryParse(_price.text.trim()) ?? 0,
        imageFile: _pickedImage,
        category: _category.text.trim(),
        deliveryTime: _delivery.text.trim(),
        distance: _distance.text.trim(),
        weight: _weight.text.trim(),
      );
      ref.invalidate(productListProvider);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Produk berhasil ditambahkan')),
        );
        _formKey.currentState?.reset();
        setState(() {
          _pickedImage = null;
          _previewBytes = null;
        });
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Gagal menambah produk: $e')),
        );
      }
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  String? _req(String? value) =>
      (value == null || value.isEmpty) ? 'Wajib diisi' : null;

  Widget _field(TextEditingController c, String label,
      {IconData? prefix,
      TextInputType keyboardType = TextInputType.text,
      String? Function(String?)? validator}) {
    return TextFormField(
      controller: c,
      decoration: InputDecoration(
        labelText: label,
        prefixIcon: prefix != null ? Icon(prefix) : null,
      ),
      keyboardType: keyboardType,
      validator: validator,
    );
  }

  Widget _imagePickerField() {
    final borderColor =
        _imageError != null ? Theme.of(context).colorScheme.error : Colors.grey.shade300;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Foto Produk *',
          style: Theme.of(context)
              .textTheme
              .bodyMedium
              ?.copyWith(fontWeight: FontWeight.w600),
        ),
        const SizedBox(height: 6),
        InkWell(
          onTap: _loading ? null : _pickImage,
          child: Container(
            height: 180,
            width: double.infinity,
            decoration: BoxDecoration(
              color: const Color(0xFFF9FBFF),
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: borderColor, width: 1.2),
            ),
            child: _previewBytes != null
                ? ClipRRect(
                    borderRadius: BorderRadius.circular(12),
                    child: Image.memory(
                      _previewBytes!,
                      width: double.infinity,
                      height: 180,
                      fit: BoxFit.cover,
                    ),
                  )
                : Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.cloud_upload_outlined,
                          size: 40, color: Colors.grey.shade500),
                      const SizedBox(height: 10),
                      Text(
                        'Klik untuk upload foto',
                        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                              color: Colors.grey.shade600,
                              fontWeight: FontWeight.w600,
                            ),
                      ),
                      const SizedBox(height: 6),
                      Text(
                        'PNG, JPG (max. 5MB)',
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                              color: Colors.grey.shade500,
                              letterSpacing: 0.1,
                            ),
                      ),
                    ],
                  ),
          ),
        ),
        if (_imageError != null) ...[
          const SizedBox(height: 6),
          Text(
            _imageError!,
            style: TextStyle(
              color: Theme.of(context).colorScheme.error,
              fontSize: 12,
            ),
          ),
        ],
      ],
    );
  }

  Future<void> _pickImage() async {
    setState(() => _imageError = null);
    final file = await _picker.pickImage(
      source: ImageSource.gallery,
      maxWidth: 1600,
      imageQuality: 85,
    );
    if (file == null) return;

    final bytes = await file.readAsBytes();
    setState(() {
      _pickedImage = file;
      _previewBytes = bytes;
    });
  }
}
