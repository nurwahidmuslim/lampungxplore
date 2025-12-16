// lib/ad_create_page.dart
import 'dart:io';
import 'dart:convert';
import 'dart:typed_data';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:http/http.dart' as http;
import 'package:http_parser/http_parser.dart';
import 'package:webview_flutter/webview_flutter.dart';
import 'package:url_launcher/url_launcher_string.dart';
import 'package:intl/intl.dart'; // Disarankan menambahkan intl di pubspec.yaml, tapi kode ini pakai format manual agar aman

/// ---------- CONFIG ----------
const String cloudName = 'dodtteomx'; 
const String uploadPreset = 'lampung_xplore'; 
const String cloudinaryFolder = 'iklan';

const String backendCreatePaymentUrl =
    'http://localhost:8080/create_midtrans_transaction'; // Ganti localhost dengan IP jika di HP
const String backendPaymentStatusUrl = 'http://localhost:8080/payment_status';

const String paymentSuccessUrlPrefix = '';

/// ---------- THEME CONSTANTS ----------
const Color kPrimaryColor = Color(0xFF0D47A1); // Blue Shade
const Color kSecondaryColor = Color(0xFF1976D2);
const Color kBackgroundColor = Color(0xFFF5F7FA);
const double kRadius = 16.0;

/// ---------- PAYMENT OVERLAY WIDGET (mobile only) ----------
class PaymentOverlayPage extends StatefulWidget {
  final String paymentUrl;

  const PaymentOverlayPage({super.key, required this.paymentUrl});

  @override
  State<PaymentOverlayPage> createState() => _PaymentOverlayPageState();
}

class _PaymentOverlayPageState extends State<PaymentOverlayPage> {
  late final WebViewController _controller;
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _controller = WebViewController()
      ..setJavaScriptMode(JavaScriptMode.unrestricted)
      ..setNavigationDelegate(
        NavigationDelegate(
          onPageFinished: (url) {
            if (mounted) setState(() => _loading = false);
          },
          onNavigationRequest: (navReq) {
            final url = navReq.url;
            if (_isSuccessUrl(url)) {
              if (mounted) Navigator.of(context).pop(true);
              return NavigationDecision.prevent;
            }
            return NavigationDecision.navigate;
          },
        ),
      )
      ..loadRequest(Uri.parse(widget.paymentUrl));
  }

  bool _isSuccessUrl(String url) {
    try {
      final lower = url.toLowerCase();
      if (paymentSuccessUrlPrefix.isNotEmpty) {
        final pref = paymentSuccessUrlPrefix.toLowerCase();
        if (lower.startsWith(pref) || lower.contains(pref)) return true;
      }
      final uri = Uri.tryParse(url);
      if (uri != null) {
        final status = uri.queryParameters['status']?.toLowerCase();
        if (status != null &&
            (status.contains('settlement') ||
                status.contains('paid') ||
                status.contains('capture') ||
                status.contains('success'))) {
          return true;
        }
      }
      if (lower.contains('/success') ||
          lower.contains('/finish') ||
          lower.contains('/settlement') ||
          lower.contains('payment_success') ||
          lower.contains('paid')) {
        return true;
      }
    } catch (_) {}
    return false;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black87,
      body: SafeArea(
        child: Center(
          child: Container(
            margin: const EdgeInsets.all(16),
            constraints: BoxConstraints(
              maxWidth: MediaQuery.of(context).size.width * 0.98,
              maxHeight: MediaQuery.of(context).size.height * 0.92,
            ),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(kRadius),
            ),
            child: Column(
              children: [
                Padding(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text(
                        'Pembayaran',
                        style: TextStyle(
                            fontWeight: FontWeight.bold, fontSize: 18),
                      ),
                      IconButton(
                        icon: const Icon(Icons.close),
                        onPressed: () => Navigator.of(context).pop(false),
                      ),
                    ],
                  ),
                ),
                const Divider(height: 1),
                Expanded(
                  child: Stack(
                    children: [
                      WebViewWidget(controller: _controller),
                      if (_loading)
                        const Center(child: CircularProgressIndicator()),
                    ],
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.all(12.0),
                  child: SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.green,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12)),
                      ),
                      onPressed: () => Navigator.of(context).pop(true),
                      child: const Text('Saya Sudah Membayar'),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

/// ---------- AD HISTORY PAGE ----------
class AdHistoryPage extends StatelessWidget {
  const AdHistoryPage({super.key});

  String _formatDateFromMillis(dynamic v) {
    try {
      if (v == null) return '-';
      if (v is Timestamp) {
        final d = v.toDate().toLocal();
        return '${d.day}/${d.month}/${d.year}';
      }
      final ms = v is int ? v : int.parse(v.toString());
      final d = DateTime.fromMillisecondsSinceEpoch(ms).toLocal();
      return '${d.day}/${d.month}/${d.year}';
    } catch (_) {
      return '-';
    }
  }

  String _formatCurrency(dynamic v) {
    try {
      final amount = (v is int) ? v : int.parse(v.toString());
      final s = amount.toString();
      final buf = StringBuffer();
      int len = s.length;
      for (int i = 0; i < len; i++) {
        buf.write(s[i]);
        final pos = len - i - 1;
        if (pos % 3 == 0 && pos != 0) buf.write('.');
      }
      return 'Rp ${buf.toString()}';
    } catch (_) {
      return '-';
    }
  }

  Color _statusColor(String? s) {
    final st = (s ?? '').toLowerCase();
    if (st.contains('settlement') ||
        st.contains('paid') ||
        st.contains('capture')) return Colors.green.shade600;
    if (st.contains('pending')) return Colors.orange.shade700;
    if (st.contains('failed') ||
        st.contains('expire') ||
        st.contains('cancel')) return Colors.red.shade600;
    return Colors.grey;
  }

  String _statusText(String? s) {
    final st = (s ?? '').toLowerCase();
    if (st.contains('settlement') || st.contains('paid')) return 'Aktif';
    if (st.contains('pending')) return 'Menunggu';
    if (st.contains('failed') || st.contains('cancel')) return 'Gagal';
    return st.toUpperCase();
  }

  @override
  Widget build(BuildContext context) {
    final u = FirebaseAuth.instance.currentUser;

    if (u == null) {
      return Scaffold(
        appBar: AppBar(title: const Text('Riwayat Iklan')),
        body: const Center(child: Text('Silakan login untuk melihat riwayat.')),
      );
    }

    final Stream<QuerySnapshot> stream = FirebaseFirestore.instance
        .collection('users')
        .doc(u.uid)
        .collection('ads_history')
        .orderBy('createdAt', descending: true)
        .snapshots();

    return Scaffold(
      backgroundColor: kBackgroundColor,
      appBar: AppBar(
        title: const Text('Riwayat Iklan'),
        backgroundColor: Colors.white,
        foregroundColor: Colors.black87,
        elevation: 0.5,
      ),
      body: StreamBuilder<QuerySnapshot>(
        stream: stream,
        builder: (context, snap) {
          if (snap.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (!snap.hasData || snap.data!.docs.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.history_edu, size: 80, color: Colors.grey.shade300),
                  const SizedBox(height: 16),
                  Text('Belum ada riwayat iklan',
                      style: TextStyle(color: Colors.grey.shade600)),
                ],
              ),
            );
          }
          final docs = snap.data!.docs;
          return ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: docs.length,
            itemBuilder: (context, idx) {
              final d = docs[idx];
              final m = d.data() as Map<String, dynamic>;
              final imageUrl = (m['imageUrl'] as String?) ?? '';
              final title = (m['title'] as String?) ?? 'Iklan';
              final start = _formatDateFromMillis(m['startAt']);
              final end = _formatDateFromMillis(m['endAt']);
              final amount = _formatCurrency(m['grossAmount']);
              final status = (m['status'] as String?) ?? '-';

              return Container(
                margin: const EdgeInsets.only(bottom: 16),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(12),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.grey.withOpacity(0.1),
                      blurRadius: 10,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: Padding(
                  padding: const EdgeInsets.all(12),
                  child: Row(
                    children: [
                      // Thumbnail Image
                      Container(
                        width: 80,
                        height: 80,
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(10),
                          color: Colors.grey.shade100,
                          image: imageUrl.isNotEmpty
                              ? DecorationImage(
                                  image: NetworkImage(imageUrl),
                                  fit: BoxFit.cover,
                                )
                              : null,
                        ),
                        child: imageUrl.isEmpty
                            ? const Icon(Icons.image, color: Colors.grey)
                            : null,
                      ),
                      const SizedBox(width: 14),
                      // Content
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Expanded(
                                  child: Text(
                                    title,
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                    style: const TextStyle(
                                      fontSize: 16,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ),
                                Container(
                                  padding: const EdgeInsets.symmetric(
                                      horizontal: 8, vertical: 4),
                                  decoration: BoxDecoration(
                                    color: _statusColor(status).withOpacity(0.1),
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                  child: Text(
                                    _statusText(status),
                                    style: TextStyle(
                                      color: _statusColor(status),
                                      fontWeight: FontWeight.bold,
                                      fontSize: 11,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 6),
                            Row(
                              children: [
                                const Icon(Icons.date_range,
                                    size: 14, color: Colors.grey),
                                const SizedBox(width: 4),
                                Text(
                                  '$start - $end',
                                  style: TextStyle(
                                      fontSize: 12, color: Colors.grey.shade700),
                                ),
                              ],
                            ),
                            const SizedBox(height: 6),
                            Text(
                              amount,
                              style: TextStyle(
                                fontSize: 14,
                                fontWeight: FontWeight.bold,
                                color: kPrimaryColor,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              );
            },
          );
        },
      ),
    );
  }
}

/// ---------- AD CREATE PAGE (UI REVAMPED) ----------
class AdCreatePage extends StatefulWidget {
  const AdCreatePage({super.key});
  @override
  State<AdCreatePage> createState() => _AdCreatePageState();
}

class _AdCreatePageState extends State<AdCreatePage> {
  final _formKey = GlobalKey<FormState>();
  final ImagePicker _picker = ImagePicker();

  String _title = '';
  bool _placementBanner = true;
  bool _placementPopup = false;
  static const int PER_DAY_RATE = 3000;
  DateTime _start = DateTime.now();
  DateTime _end = DateTime.now().add(const Duration(days: 7));
  File? _imageFile;
  Uint8List? _imageBytes;
  String? _imageName;

  bool _loading = false;

  int get _selectedPlacementsCount {
    int c = 0;
    if (_placementBanner) c++;
    if (_placementPopup) c++;
    return c;
  }

  int get _daysCount {
    final d = _end.difference(_start).inDays;
    return d >= 0 ? d + 1 : 1;
  }

  int get _totalAmount => (_selectedPlacementsCount > 0)
      ? PER_DAY_RATE * _selectedPlacementsCount * _daysCount
      : 0;

  String _formatCurrency(int amount) {
    final s = amount.toString();
    final buf = StringBuffer();
    int len = s.length;
    for (int i = 0; i < len; i++) {
      buf.write(s[i]);
      final pos = len - i - 1;
      if (pos % 3 == 0 && pos != 0) buf.write('.');
    }
    return buf.toString();
  }

  Future<void> _pickImage() async {
    try {
      if (kIsWeb) {
        final XFile? x = await _picker.pickImage(
            source: ImageSource.gallery, maxWidth: 1600, imageQuality: 80);
        if (x == null) return;
        final bytes = await x.readAsBytes();
        setState(() {
          _imageBytes = bytes;
          _imageName = x.name;
          _imageFile = null;
        });
      } else {
        final XFile? x = await _picker.pickImage(
            source: ImageSource.gallery, maxWidth: 1600, imageQuality: 80);
        if (x == null) return;
        setState(() {
          _imageFile = File(x.path);
          _imageBytes = null;
          _imageName = x.name;
        });
      }
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text('Gagal pilih gambar: $e')));
    }
  }

  Future<String> _uploadToCloudinary({
    required String cloudName,
    required String uploadPreset,
    required String folder,
    File? file,
    Uint8List? bytes,
    String? filename,
  }) async {
    final uri = Uri.parse(
        'https://api.cloudinary.com/v1_1/$cloudName/image/upload');
    final request = http.MultipartRequest('POST', uri)
      ..fields['upload_preset'] = uploadPreset
      ..fields['folder'] = folder;

    if (kIsWeb) {
      if (bytes == null) throw Exception('No bytes for web upload');
      final name = filename ?? 'upload_${DateTime.now().millisecondsSinceEpoch}.jpg';
      String mime = 'image/jpeg';
      if (name.toLowerCase().endsWith('.png')) mime = 'image/png';
      request.files.add(http.MultipartFile.fromBytes('file', bytes,
          filename: name,
          contentType: MediaType(mime.split('/')[0], mime.split('/')[1])));
    } else {
      if (file == null) throw Exception('No file for mobile upload');
      request.files.add(await http.MultipartFile.fromPath('file', file.path));
    }

    final streamed = await request.send();
    final resp = await http.Response.fromStream(streamed);

    if (resp.statusCode >= 200 && resp.statusCode < 300) {
      final Map<String, dynamic> body = jsonDecode(resp.body);
      final url = body['secure_url'] as String?;
      if (url == null) throw Exception('No secure_url returned');
      return url;
    } else {
      throw Exception('Cloudinary upload failed: ${resp.statusCode} ${resp.body}');
    }
  }

  Future<void> _pickStartDate() async {
    final d = await showDatePicker(
      context: context,
      initialDate: _start,
      firstDate: DateTime.now().subtract(const Duration(days: 1)),
      lastDate: DateTime.now().add(const Duration(days: 365)),
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: ColorScheme.light(primary: kPrimaryColor),
          ),
          child: child!,
        );
      },
    );
    if (d != null) {
      setState(() {
        _start = d;
        if (_end.isBefore(_start)) _end = _start.add(const Duration(days: 1));
      });
    }
  }

  Future<void> _pickEndDate() async {
    final d = await showDatePicker(
      context: context,
      initialDate: _end,
      firstDate: _start,
      lastDate: DateTime.now().add(const Duration(days: 365)),
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: ColorScheme.light(primary: kPrimaryColor),
          ),
          child: child!,
        );
      },
    );
    if (d != null) setState(() => _end = d);
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    if (_selectedPlacementsCount == 0) {
      ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Pilih minimal satu penempatan iklan')));
      return;
    }
    _formKey.currentState!.save();

    final u = FirebaseAuth.instance.currentUser;
    if (u == null) {
      ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Silakan login terlebih dahulu')));
      return;
    }

    setState(() => _loading = true);
    String imageUrl = '';
    final adOrderId =
        'order_${DateTime.now().millisecondsSinceEpoch}_${u.uid.length >= 6 ? u.uid.substring(0, 6) : u.uid}';

    try {
      if (kIsWeb) {
        if (_imageBytes != null) {
          imageUrl = await _uploadToCloudinary(
              cloudName: cloudName,
              uploadPreset: uploadPreset,
              folder: cloudinaryFolder,
              bytes: _imageBytes,
              filename: _imageName);
        }
      } else {
        if (_imageFile != null) {
          imageUrl = await _uploadToCloudinary(
              cloudName: cloudName,
              uploadPreset: uploadPreset,
              folder: cloudinaryFolder,
              file: _imageFile);
        }
      }

      final amount = _totalAmount;
      if (amount <= 0) throw Exception('Total amount harus > 0');

      final payload = {
        'orderId': adOrderId,
        'grossAmount': amount,
        'title': _title.isEmpty ? 'Iklan' : _title,
        'merchantId': u.uid,
        'placements': {
          if (_placementBanner) 'banner_home': true,
          if (_placementPopup) 'popup_first_open': true,
        },
        'imageUrl': imageUrl,
        'startAt': _start.millisecondsSinceEpoch,
        'endAt': _end.millisecondsSinceEpoch,
      };

      final userAdsRef = FirebaseFirestore.instance
          .collection('users')
          .doc(u.uid)
          .collection('ads_history')
          .doc(adOrderId);

      await userAdsRef.set({
        'orderId': adOrderId,
        'title': payload['title'],
        'imageUrl': imageUrl,
        'startAt': payload['startAt'],
        'endAt': payload['endAt'],
        'grossAmount': payload['grossAmount'],
        'placements': payload['placements'],
        'status': 'pending',
        'createdAt': FieldValue.serverTimestamp(),
        'updatedAt': FieldValue.serverTimestamp(),
      });

      final resp = await http
          .post(
            Uri.parse(backendCreatePaymentUrl),
            headers: {'Content-Type': 'application/json'},
            body: jsonEncode(payload),
          )
          .timeout(const Duration(seconds: 12));

      if (resp.statusCode != 200) {
        throw Exception('Server error: ${resp.statusCode} ${resp.body}');
      }

      final data = jsonDecode(resp.body) as Map<String, dynamic>;
      final paymentUrl =
          (data['paymentUrl'] ?? data['redirect_url'] ?? '') as String;
      final orderId = (data['orderId'] as String?) ?? adOrderId;

      if (paymentUrl.isEmpty) throw Exception('Payment URL kosong dari server');

      final open = await showDialog<bool>(
        context: context,
        builder: (c) => AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          title: const Text('Lanjut ke Pembayaran'),
          content: Text(kIsWeb
              ? 'Halaman pembayaran akan dibuka di tab baru.'
              : 'Halaman pembayaran akan dibuka di dalam aplikasi.'),
          actions: [
            TextButton(
                onPressed: () => Navigator.pop(c, false),
                child: const Text('Batal', style: TextStyle(color: Colors.grey))),
            ElevatedButton(
                style: ElevatedButton.styleFrom(backgroundColor: kPrimaryColor),
                onPressed: () => Navigator.pop(c, true),
                child:
                    const Text('Lanjutkan', style: TextStyle(color: Colors.white))),
          ],
        ),
      );
      if (open != true) {
        setState(() => _loading = false);
        return;
      }

      if (kIsWeb) {
        final launched = await launchUrlString(paymentUrl,
            mode: LaunchMode.platformDefault);
        if (!launched) throw Exception('Gagal membuka halaman pembayaran');
      } else {
        final result = await Navigator.of(context).push<bool>(
          PageRouteBuilder(
            opaque: false,
            pageBuilder: (context, anim1, anim2) =>
                PaymentOverlayPage(paymentUrl: paymentUrl),
            transitionsBuilder: (context, anim, sec, child) =>
                FadeTransition(opacity: anim, child: child),
          ),
        );
        if (result != true) {
          setState(() => _loading = false);
          return;
        }
      }

      _showWaitingDialog();

      bool paid = false;
      const maxAttempts = 20;
      const delaySec = 3;
      for (int i = 0; i < maxAttempts; i++) {
        await Future.delayed(const Duration(seconds: delaySec));
        try {
          final stResp = await http
              .get(Uri.parse('$backendPaymentStatusUrl?orderId=$orderId'))
              .timeout(const Duration(seconds: 8));
          if (stResp.statusCode == 200) {
            final st = jsonDecode(stResp.body) as Map<String, dynamic>;
            final status = (st['status'] ?? '').toString().toLowerCase();
            if (status == 'settlement' ||
                status == 'paid' ||
                status == 'capture') {
              paid = true;
              break;
            }
            if (status == 'failed') break;
          }
        } catch (_) {}
      }

      if (mounted) Navigator.of(context).pop();

      if (paid) {
        await userAdsRef.update({
          'status': 'settlement',
          'updatedAt': FieldValue.serverTimestamp(),
        });
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
                backgroundColor: Colors.green,
                content: Text('Pembayaran berhasil! Iklan aktif.')),
          );
          Navigator.of(context).pop();
        }
      } else {
        await userAdsRef.update({
          'status': 'failed',
          'updatedAt': FieldValue.serverTimestamp(),
        });
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
                backgroundColor: Colors.red,
                content: Text('Pembayaran gagal atau timeout.')),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(backgroundColor: Colors.red, content: Text('Gagal: $e')));
      }
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  void _showWaitingDialog() {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (c) {
        return AlertDialog(
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          content: Row(
            children: const [
              SizedBox(width: 4),
              CircularProgressIndicator(),
              SizedBox(width: 20),
              Expanded(child: Text('Menunggu konfirmasi pembayaran...')),
            ],
          ),
        );
      },
    );
  }

  // ---------- WIDGETS ----------

  Widget _buildSectionHeader(String title) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: Text(
        title,
        style: TextStyle(
          fontSize: 16,
          fontWeight: FontWeight.bold,
          color: Colors.blueGrey.shade800,
        ),
      ),
    );
  }

  Widget _buildImagePicker() {
    bool hasImage = _imageFile != null || _imageBytes != null;
    return GestureDetector(
      onTap: _pickImage,
      child: Container(
        height: 180,
        width: double.infinity,
        decoration: BoxDecoration(
          color: hasImage ? Colors.white : Colors.grey.shade100,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: hasImage ? kPrimaryColor : Colors.grey.shade400,
            width: hasImage ? 2 : 1,
            style: hasImage ? BorderStyle.solid : BorderStyle.solid,
          ),
          image: hasImage
              ? DecorationImage(
                  image: kIsWeb
                      ? MemoryImage(_imageBytes!) as ImageProvider
                      : FileImage(_imageFile!),
                  fit: BoxFit.cover,
                )
              : null,
        ),
        child: hasImage
            ? Stack(
                children: [
                  Container(
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(10),
                      gradient: LinearGradient(
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                        colors: [Colors.black12, Colors.black45],
                      ),
                    ),
                  ),
                  Center(
                    child: Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: Colors.black54,
                        shape: BoxShape.circle,
                      ),
                      child:
                          const Icon(Icons.edit, color: Colors.white, size: 28),
                    ),
                  ),
                ],
              )
            : Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.add_photo_alternate_rounded,
                      size: 48, color: Colors.grey.shade500),
                  const SizedBox(height: 8),
                  Text(
                    'Tap untuk upload gambar iklan',
                    style: TextStyle(
                        color: Colors.grey.shade600, fontWeight: FontWeight.w500),
                  ),
                ],
              ),
      ),
    );
  }

  Widget _buildDateSelector(
      String label, DateTime date, VoidCallback onTap) {
    return Expanded(
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
          decoration: BoxDecoration(
            border: Border.all(color: Colors.grey.shade300),
            borderRadius: BorderRadius.circular(12),
            color: Colors.white,
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: TextStyle(fontSize: 12, color: Colors.grey.shade600),
              ),
              const SizedBox(height: 4),
              Row(
                children: [
                  Icon(Icons.calendar_today_rounded,
                      size: 16, color: kPrimaryColor),
                  const SizedBox(width: 8),
                  Text(
                    '${date.day}/${date.month}/${date.year}',
                    style: const TextStyle(
                        fontWeight: FontWeight.bold, fontSize: 14),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: kBackgroundColor,
      appBar: AppBar(
        title: const Text('Buat Iklan Baru'),
        backgroundColor: Colors.white,
        foregroundColor: Colors.black87,
        elevation: 0.5,
        actions: [
          IconButton(
            tooltip: 'Riwayat',
            icon: Icon(Icons.history, color: kPrimaryColor),
            onPressed: () => Navigator.of(context)
                .push(MaterialPageRoute(builder: (_) => const AdHistoryPage())),
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Image Section
              _buildSectionHeader('Visual Iklan'),
              _buildImagePicker(),
              
              const SizedBox(height: 20),
              
              // Details Section
              _buildSectionHeader('Detail Informasi'),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: Colors.grey.shade300),
                ),
                child: TextFormField(
                  decoration: const InputDecoration(
                    icon: Icon(Icons.title, color: Colors.grey),
                    labelText: 'Judul Iklan',
                    border: InputBorder.none,
                  ),
                  onSaved: (v) => _title = v?.trim() ?? '',
                  validator: (v) => (v == null || v.trim().isEmpty)
                      ? 'Judul tidak boleh kosong'
                      : null,
                ),
              ),

              const SizedBox(height: 20),

              // Placement Section
              _buildSectionHeader('Penempatan'),
              Container(
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: Colors.grey.shade300),
                ),
                child: Column(
                  children: [
                    SwitchListTile(
                      activeColor: kPrimaryColor,
                      secondary: Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                            color: Colors.blue.shade50,
                            borderRadius: BorderRadius.circular(8)),
                        child: Icon(Icons.view_carousel, color: kPrimaryColor),
                      ),
                      title: const Text('Banner Beranda',
                          style: TextStyle(fontWeight: FontWeight.w600)),
                      subtitle: const Text('Tampil di slider halaman utama'),
                      value: _placementBanner,
                      onChanged: (v) => setState(() => _placementBanner = v),
                    ),
                    const Divider(height: 1),
                    SwitchListTile(
                      activeColor: kPrimaryColor,
                      secondary: Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                            color: Colors.purple.shade50,
                            borderRadius: BorderRadius.circular(8)),
                        child: const Icon(Icons.open_in_new, color: Colors.purple),
                      ),
                      title: const Text('Popup Iklan',
                          style: TextStyle(fontWeight: FontWeight.w600)),
                      subtitle: const Text('Muncul saat aplikasi dibuka'),
                      value: _placementPopup,
                      onChanged: (v) => setState(() => _placementPopup = v),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 20),

              // Date Section
              _buildSectionHeader('Durasi Penayangan'),
              Row(
                children: [
                  _buildDateSelector('Mulai Tanggal', _start, _pickStartDate),
                  const SizedBox(width: 12),
                  _buildDateSelector('Selesai Tanggal', _end, _pickEndDate),
                ],
              ),

              const SizedBox(height: 30),

              // Summary & Button
              Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(16),
                  boxShadow: [
                    BoxShadow(
                        color: Colors.grey.withOpacity(0.1),
                        blurRadius: 15,
                        offset: const Offset(0, 5)),
                  ],
                ),
                child: Column(
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text('Durasi', style: TextStyle(color: Colors.grey)),
                        Text('$_daysCount Hari',
                            style: const TextStyle(fontWeight: FontWeight.bold)),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text('Lokasi', style: TextStyle(color: Colors.grey)),
                        Text('$_selectedPlacementsCount Penempatan',
                            style: const TextStyle(fontWeight: FontWeight.bold)),
                      ],
                    ),
                    const Padding(
                      padding: EdgeInsets.symmetric(vertical: 12),
                      child: Divider(),
                    ),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text('Total Pembayaran',
                            style: TextStyle(
                                fontSize: 16, fontWeight: FontWeight.bold)),
                        Text(
                          'Rp ${_formatCurrency(_totalAmount)}',
                          style: TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                            color: kPrimaryColor,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 20),
                    SizedBox(
                      width: double.infinity,
                      height: 50,
                      child: ElevatedButton(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: kPrimaryColor,
                          shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12)),
                          elevation: 2,
                        ),
                        onPressed: _loading ? null : _submit,
                        child: _loading
                            ? const SizedBox(
                                height: 24,
                                width: 24,
                                child: CircularProgressIndicator(
                                    color: Colors.white, strokeWidth: 2),
                              )
                            : const Text(
                                'Bayar Sekarang',
                                style: TextStyle(
                                    fontSize: 16,
                                    fontWeight: FontWeight.bold,
                                    color: Colors.white),
                              ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 30),
            ],
          ),
        ),
      ),
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: 1,
        onTap: (i) {
          switch (i) {
            case 0:
              Navigator.pushReplacementNamed(context, '/home');
              break;
            case 1:
              break;
            case 2:
              Navigator.pushReplacementNamed(context, '/favorit');
              break;
            case 3:
              Navigator.pushReplacementNamed(context, '/profil');
              break;
          }
        },
        type: BottomNavigationBarType.fixed,
        selectedItemColor: const Color.fromARGB(255, 13, 158, 241),
        unselectedItemColor: Colors.grey,
        items: const [
          BottomNavigationBarItem(
            icon: Icon(Icons.home_outlined),
            activeIcon: Icon(Icons.home),
            label: 'Beranda',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.cloud_upload_outlined),
            activeIcon: Icon(Icons.cloud_upload),
            label: 'Upload',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.favorite_border),
            activeIcon: Icon(Icons.favorite),
            label: 'Favorit',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.person_outline),
            activeIcon: Icon(Icons.person),
            label: 'Profil',
          ),
        ],
      ),
    );
  }
}