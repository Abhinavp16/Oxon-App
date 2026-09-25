import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../core/providers/auth_provider.dart';
import '../../widgets/app_image.dart';

class BrandsScreen extends ConsumerStatefulWidget {
  const BrandsScreen({super.key});

  @override
  ConsumerState<BrandsScreen> createState() => _BrandsScreenState();
}

class _BrandsScreenState extends ConsumerState<BrandsScreen> {
  static const _blue = Color(0xFF1E40AF);
  static const _text = Color(0xFF0F172A);
  static const _muted = Color(0xFF64748B);
  List<Map<String, dynamic>> _brands = [];
  bool _loading = true;
  bool _failed = false;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() {
      _loading = true;
      _failed = false;
    });
    try {
      final response = await ref.read(apiClientProvider).get('/companies');
      final payload = response.data;
      final items = payload is Map ? payload['data'] : payload;
      final brands = (items is List ? items : const [])
          .whereType<Map>()
          .map<Map<String, dynamic>>((item) {
            final logo = item['logo'];
            return {
              'name': item['name']?.toString() ?? '',
              'logo': logo is Map
                  ? logo['url']?.toString() ?? ''
                  : logo?.toString() ?? '',
              'blurHash': logo is Map ? logo['blurHash']?.toString() ?? '' : '',
            };
          })
          .where((item) => item['name'].toString().isNotEmpty)
          .toList();
      if (!mounted) return;
      setState(() {
        _brands = brands;
        _loading = false;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _loading = false;
        _failed = true;
      });
    }
  }

  @override
  Widget build(BuildContext context) => Scaffold(
    backgroundColor: const Color(0xFFF8FAFC),
    appBar: AppBar(
      backgroundColor: Colors.white,
      foregroundColor: _text,
      title: Text(
        'Brands',
        style: GoogleFonts.outfit(fontWeight: FontWeight.w800),
      ),
    ),
    body: _loading
        ? const Center(child: CircularProgressIndicator(color: _blue))
        : _failed
        ? Center(
            child: FilledButton(onPressed: _load, child: const Text('Retry')),
          )
        : RefreshIndicator(
            onRefresh: _load,
            color: _blue,
            child: GridView.builder(
              physics: const AlwaysScrollableScrollPhysics(),
              padding: const EdgeInsets.all(16),
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 2,
                crossAxisSpacing: 12,
                mainAxisSpacing: 12,
                childAspectRatio: 1.15,
              ),
              itemCount: _brands.length,
              itemBuilder: (context, index) {
                final brand = _brands[index];
                final name = brand['name'].toString();
                return Material(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(16),
                  child: InkWell(
                    borderRadius: BorderRadius.circular(16),
                    onTap: () =>
                        context.push('/brand/${Uri.encodeComponent(name)}'),
                    child: Padding(
                      padding: const EdgeInsets.all(14),
                      child: Column(
                        children: [
                          Expanded(
                            child: brand['logo'].toString().isEmpty
                                ? const Icon(
                                    Icons.storefront_rounded,
                                    color: _muted,
                                    size: 38,
                                  )
                                : AppImage(
                                    imageUrl: brand['logo'].toString(),
                                    blurHash: brand['blurHash'].toString(),
                                    category: 'brand',
                                    name: name,
                                    fit: BoxFit.contain,
                                  ),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            name,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: GoogleFonts.plusJakartaSans(
                              fontWeight: FontWeight.w700,
                              color: _text,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                );
              },
            ),
          ),
  );
}
