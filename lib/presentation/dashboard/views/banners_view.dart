import 'dart:typed_data';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../core/constants/api_endpoints.dart';
import '../../../core/network/api_exception.dart';
import '../../../logic/auth/auth_bloc.dart';
import '../../../logic/order/order_bloc.dart';

class BannersView extends StatefulWidget {
  final bool isWide;

  const BannersView({super.key, this.isWide = true});

  @override
  State<BannersView> createState() => _BannersViewState();
}

class _BannersViewState extends State<BannersView> {
  bool _isLoading = true;
  String? _errorMessage;
  List<Map<String, dynamic>> _banners = const [];

  @override
  void initState() {
    super.initState();
    _loadBanners();
  }

  Future<void> _loadBanners() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });
    try {
      final api = context.read<OrderBloc>().apiClient;
      final res = await api.get(ApiEndpoints.adminBanners, requiresAuth: true);
      final data = res['data'];
      final list = data is List
          ? data.whereType<Map>().map((e) => Map<String, dynamic>.from(e)).toList()
          : <Map<String, dynamic>>[];
      if (mounted) {
        setState(() {
          _banners = list;
          _isLoading = false;
        });
      }
    } on ApiException catch (e) {
      if (mounted) {
        setState(() {
          _isLoading = false;
          _errorMessage = e.message;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isLoading = false;
          _errorMessage = e.toString();
        });
      }
    }
  }

  Future<void> _pickAndUploadImage(String bannerId) async {
    try {
      final files = await FilePicker.pickFiles(
        type: FileType.custom,
        allowedExtensions: ['png', 'jpg', 'jpeg', 'webp'],
      );
      if (files.isEmpty) return;
      final file = files.first;
      final Uint8List bytes = await file.readAsBytes();
      if (bytes.isEmpty) return;

      final lower = file.name.toLowerCase();
      final contentType = lower.endsWith('.png')
          ? 'image/png'
          : (lower.endsWith('.webp') ? 'image/webp' : 'image/jpeg');

      if (!mounted) return;
      final api = context.read<OrderBloc>().apiClient;
      await api.postMultipart(
        ApiEndpoints.adminBannerImage(bannerId),
        fileFieldName: 'file',
        fileBytes: bytes,
        fileName: file.name,
        contentType: contentType,
        requiresAuth: true,
      );
      await _loadBanners();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            duration: Duration(seconds: 3),
            content: Text('Banner image uploaded & pushed live to website!'),
            backgroundColor: Color(0xFF059669),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Image upload failed: $e'),
            backgroundColor: const Color(0xFFDC2626),
          ),
        );
      }
    }
  }

  Future<void> _toggleBanner(String bannerId) async {
    try {
      final api = context.read<OrderBloc>().apiClient;
      await api.patch(ApiEndpoints.adminBannerToggle(bannerId), requiresAuth: true);
      await _loadBanners();
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to toggle banner: $e'),
            backgroundColor: const Color(0xFFDC2626),
          ),
        );
      }
    }
  }

  Future<void> _deleteBanner(String bannerId) async {
    try {
      final api = context.read<OrderBloc>().apiClient;
      await api.delete(ApiEndpoints.adminBannerById(bannerId), requiresAuth: true);
      await _loadBanners();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            duration: Duration(seconds: 3),
            content: Text('Banner deleted & removed from website!'),
            backgroundColor: Color(0xFF059669),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Delete failed: $e'),
            backgroundColor: const Color(0xFFDC2626),
          ),
        );
      }
    }
  }

  Future<void> _openBannerDialog({Map<String, dynamic>? existing}) async {
    final titleCtrl = TextEditingController(text: existing?['title']?.toString() ?? '');
    final subtitleCtrl = TextEditingController(text: existing?['subtitle']?.toString() ?? '');
    final tagCtrl = TextEditingController(text: existing?['tag']?.toString() ?? '');
    final ctaCtrl = TextEditingController(text: existing?['buttonText']?.toString() ?? '');
    final sortCtrl = TextEditingController(text: (existing?['sortOrder'] ?? _banners.length).toString());
    bool isActive = existing?['active'] ?? true;
    Uint8List? pickedBytes;
    String? pickedFileName;
    bool saving = false;

    final isDark = Theme.of(context).brightness == Brightness.dark;
    final surface = isDark ? const Color(0xFF161E2E) : Colors.white;
    final textPrimary = isDark ? Colors.white : const Color(0xFF0F172A);

    await showDialog<void>(
      context: context,
      barrierDismissible: false,
      builder: (dlgCtx) => StatefulBuilder(
        builder: (ctx, setDlgState) => AlertDialog(
          backgroundColor: surface,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
          title: Text(
            existing == null ? 'Create Hero Carousel Banner' : 'Edit Hero Carousel Banner',
            style: GoogleFonts.plusJakartaSans(fontSize: 16, fontWeight: FontWeight.w800, color: textPrimary),
          ),
          content: SizedBox(
            width: 500,
            child: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  OutlinedButton.icon(
                    onPressed: saving
                        ? null
                        : () async {
                            final files = await FilePicker.pickFiles(
                              type: FileType.custom,
                              allowedExtensions: ['png', 'jpg', 'jpeg', 'webp'],
                            );
                            if (files.isNotEmpty) {
                              final f = files.first;
                              final b = await f.readAsBytes();
                              if (b.isNotEmpty) {
                                setDlgState(() {
                                  pickedBytes = b;
                                  pickedFileName = f.name;
                                });
                              }
                            }
                          },
                    icon: const Icon(Icons.image_outlined, size: 18),
                    label: Text(
                      pickedFileName != null
                          ? 'Selected: $pickedFileName'
                          : (existing?['imageUrl'] != null
                              ? 'Replace Banner Image (Recommended: 1600×500)'
                              : 'Upload Banner Image * (Recommended: 1600×500)'),
                    ),
                  ),
                  if (pickedBytes != null) ...[
                    const SizedBox(height: 10),
                    ClipRRect(
                      borderRadius: BorderRadius.circular(8),
                      child: Image.memory(pickedBytes!, height: 110, fit: BoxFit.cover),
                    ),
                  ],
                  const SizedBox(height: 12),
                  TextField(
                    controller: titleCtrl,
                    decoration: const InputDecoration(
                      labelText: 'Headline Title (optional if image has text)',
                      border: OutlineInputBorder(),
                    ),
                  ),
                  const SizedBox(height: 10),
                  TextField(
                    controller: subtitleCtrl,
                    decoration: const InputDecoration(
                      labelText: 'Subtitle / Offer Text',
                      border: OutlineInputBorder(),
                    ),
                  ),
                  const SizedBox(height: 10),
                  Row(
                    children: [
                      Expanded(
                        child: TextField(
                          controller: tagCtrl,
                          decoration: const InputDecoration(
                            labelText: 'Badge Tag (e.g. SPECIAL OFFER)',
                            border: OutlineInputBorder(),
                          ),
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: TextField(
                          controller: ctaCtrl,
                          decoration: const InputDecoration(
                            labelText: 'Button Text (e.g. Shop Now)',
                            border: OutlineInputBorder(),
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 10),
                  Row(
                    children: [
                      SizedBox(
                        width: 130,
                        child: TextField(
                          controller: sortCtrl,
                          keyboardType: TextInputType.number,
                          decoration: const InputDecoration(
                            labelText: 'Sort Order',
                            border: OutlineInputBorder(),
                          ),
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: SwitchListTile(
                          value: isActive,
                          onChanged: (v) => setDlgState(() => isActive = v),
                          title: const Text('Active on Website'),
                          contentPadding: EdgeInsets.zero,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
          actions: [
            TextButton(
              onPressed: saving ? null : () => Navigator.of(dlgCtx).pop(),
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: saving
                  ? null
                  : () async {
                      setDlgState(() => saving = true);
                      try {
                        final api = context.read<OrderBloc>().apiClient;
                        final payload = {
                          'title': titleCtrl.text.trim(),
                          'subtitle': subtitleCtrl.text.trim(),
                          'tag': tagCtrl.text.trim(),
                          'buttonText': ctaCtrl.text.trim(),
                          'sortOrder': int.tryParse(sortCtrl.text.trim()) ?? 0,
                          'active': isActive,
                        };
                        String bannerId;
                        if (existing == null) {
                          final created = await api.post(
                            ApiEndpoints.adminBanners,
                            body: payload,
                            requiresAuth: true,
                          );
                          bannerId = (created['data'] as Map)['id'].toString();
                        } else {
                          bannerId = existing['id'].toString();
                          await api.put(
                            ApiEndpoints.adminBannerById(bannerId),
                            body: payload,
                            requiresAuth: true,
                          );
                        }
                        if (pickedBytes != null && pickedFileName != null) {
                          final lower = pickedFileName!.toLowerCase();
                          final ct = lower.endsWith('.png')
                              ? 'image/png'
                              : (lower.endsWith('.webp') ? 'image/webp' : 'image/jpeg');
                          await api.postMultipart(
                            ApiEndpoints.adminBannerImage(bannerId),
                            fileFieldName: 'file',
                            fileBytes: pickedBytes!,
                            fileName: pickedFileName!,
                            contentType: ct,
                            requiresAuth: true,
                          );
                        }
                        if (dlgCtx.mounted) Navigator.of(dlgCtx).pop();
                        await _loadBanners();
                        if (mounted) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                              duration: Duration(seconds: 3),
                              content: Text('Banner saved & synced live to website!'),
                              backgroundColor: Color(0xFF059669),
                            ),
                          );
                        }
                      } catch (e) {
                        setDlgState(() => saving = false);
                        if (mounted) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: Text('Save failed: $e'),
                              backgroundColor: const Color(0xFFDC2626),
                            ),
                          );
                        }
                      }
                    },
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF059669),
                foregroundColor: Colors.white,
              ),
              child: Text(saving ? 'Saving...' : 'Save & Publish Live'),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final surface = isDark ? const Color(0xFF161E2E) : Colors.white;
    final border = isDark ? const Color(0xFF1F2937) : const Color(0xFFE2E8F0);
    final textPrimary = isDark ? Colors.white : const Color(0xFF0F172A);
    final textSecondary = isDark ? const Color(0xFF94A3B8) : const Color(0xFF64748B);
    final session = context.watch<AuthBloc>().state.session;
    final canManage = session == null || session.isAdmin || session.hasPermission('CATALOG_MANAGE');

    return SingleChildScrollView(
      padding: EdgeInsets.symmetric(horizontal: widget.isWide ? 32 : 16, vertical: 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Home Carousel Banners',
                    style: GoogleFonts.plusJakartaSans(
                      fontSize: 18,
                      fontWeight: FontWeight.w800,
                      color: textPrimary,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    'Changes sync instantly to ebskrishidukaan.com over WebSocket',
                    style: GoogleFonts.plusJakartaSans(
                      fontSize: 12.5,
                      color: textSecondary,
                    ),
                  ),
                ],
              ),
              if (canManage)
                ElevatedButton.icon(
                  onPressed: () => _openBannerDialog(),
                  icon: const Icon(Icons.add_photo_alternate_rounded, size: 17),
                  label: const Text('Add Banner'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF059669),
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                  ),
                ),
            ],
          ),
          const SizedBox(height: 16),
          if (_isLoading)
            const Padding(
              padding: EdgeInsets.all(40),
              child: Center(child: CircularProgressIndicator()),
            )
          else if (_errorMessage != null)
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: const Color(0xFFFEE2E2),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Text(_errorMessage!, style: const TextStyle(color: Color(0xFF991B1B))),
            )
          else if (_banners.isEmpty)
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(36),
              decoration: BoxDecoration(
                color: surface,
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: border),
              ),
              child: Column(
                children: [
                  Icon(Icons.view_carousel_outlined, size: 42, color: textSecondary),
                  const SizedBox(height: 10),
                  Text(
                    'No dynamic banners uploaded yet',
                    style: GoogleFonts.plusJakartaSans(
                      fontSize: 15,
                      fontWeight: FontWeight.w700,
                      color: textPrimary,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'Add your first banner image to replace the default website carousel slides.',
                    style: GoogleFonts.plusJakartaSans(fontSize: 12.5, color: textSecondary),
                  ),
                ],
              ),
            )
          else
            ..._banners.map((b) {
              final id = b['id'].toString();
              final active = b['active'] == true;
              final imageUrl = b['imageUrl']?.toString() ?? '';
              final title = b['title']?.toString() ?? '';
              final subtitle = b['subtitle']?.toString() ?? '';
              final sortOrder = b['sortOrder'] ?? 0;

              return Container(
                margin: const EdgeInsets.only(bottom: 14),
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: surface,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: border),
                ),
                child: Row(
                  children: [
                    ClipRRect(
                      borderRadius: BorderRadius.circular(8),
                      child: imageUrl.isNotEmpty
                          ? Image.network(
                              imageUrl,
                              width: 180,
                              height: 82,
                              fit: BoxFit.cover,
                              errorBuilder: (_, _, _) => Container(
                                width: 180,
                                height: 82,
                                color: const Color(0xFFF1F5F9),
                                child: const Icon(Icons.broken_image_outlined),
                              ),
                            )
                          : Container(
                              width: 180,
                              height: 82,
                              color: const Color(0xFFECFDF5),
                              alignment: Alignment.center,
                              child: const Icon(Icons.image_outlined, color: Color(0xFF059669)),
                            ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
                                decoration: BoxDecoration(
                                  color: (active ? const Color(0xFF059669) : const Color(0xFF64748B))
                                      .withValues(alpha: 0.12),
                                  borderRadius: BorderRadius.circular(5),
                                ),
                                child: Text(
                                  active ? 'LIVE • #$sortOrder' : 'HIDDEN • #$sortOrder',
                                  style: GoogleFonts.plusJakartaSans(
                                    fontSize: 10.5,
                                    fontWeight: FontWeight.w800,
                                    color: active ? const Color(0xFF059669) : const Color(0xFF64748B),
                                  ),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 6),
                          Text(
                            title.isNotEmpty ? title : 'Image Banner #$sortOrder',
                            style: GoogleFonts.plusJakartaSans(
                              fontSize: 14.5,
                              fontWeight: FontWeight.w800,
                              color: textPrimary,
                            ),
                          ),
                          if (subtitle.isNotEmpty) ...[
                            const SizedBox(height: 2),
                            Text(
                              subtitle,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: GoogleFonts.plusJakartaSans(fontSize: 12, color: textSecondary),
                            ),
                          ],
                        ],
                      ),
                    ),
                    if (canManage) ...[
                      Switch(
                        value: active,
                        onChanged: (_) => _toggleBanner(id),
                        activeThumbColor: const Color(0xFF059669),
                      ),
                      IconButton(
                        tooltip: 'Upload / Replace Image',
                        onPressed: () => _pickAndUploadImage(id),
                        icon: const Icon(Icons.upload_file_rounded, color: Color(0xFF0284C7)),
                      ),
                      IconButton(
                        tooltip: 'Edit Banner',
                        onPressed: () => _openBannerDialog(existing: b),
                        icon: const Icon(Icons.edit_outlined),
                      ),
                      IconButton(
                        tooltip: 'Delete Banner',
                        onPressed: () => _deleteBanner(id),
                        icon: const Icon(Icons.delete_outline_rounded, color: Color(0xFFDC2626)),
                      ),
                    ],
                  ],
                ),
              );
            }),
        ],
      ),
    );
  }
}
