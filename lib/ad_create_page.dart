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

/// ---------- CONFIG ----------
const String cloudName = 'dodtteomx'; // <-- ganti dengan cloud name Anda
const String uploadPreset = 'lampung_xplore'; // <-- ganti unsigned preset Anda
const String cloudinaryFolder = 'iklan';

const String backendCreatePaymentUrl =
    'http://localhost:8080/create_midtrans_transaction';
const String backendPaymentStatusUrl = 'http://localhost:8080/payment_status';

/// Jika backend/merchant mengarahkan pengguna ke URL tertentu setelah bayar,
/// isi dengan prefix itu (mis: 'https://example.com/payment-success').
/// Jika kosong, deteksi akan mengandalkan query param 'status' atau kata kunci path.
const String paymentSuccessUrlPrefix = ''; // <-- sesuaikan jika perlu

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

    // NOTE: this widget is intended for Android/iOS only. Do not instantiate on Web.
    _controller = WebViewController()
      ..setJavaScriptMode(JavaScriptMode.unrestricted)
      ..setNavigationDelegate(
        NavigationDelegate(
          onPageFinished: (url) {
            setState(() => _loading = false);
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
        final alt =
            uri.queryParameters['transaction_status']?.toLowerCase() ??
            uri.queryParameters['result']?.toLowerCase();
        if (alt != null &&
            (alt.contains('settlement') ||
                alt.contains('paid') ||
                alt.contains('capture') ||
                alt.contains('success'))) {
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
      backgroundColor: Colors.black54,
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
              borderRadius: BorderRadius.circular(14),
              boxShadow: const [
                BoxShadow(color: Colors.black26, blurRadius: 8),
              ],
            ),
            child: Column(
              children: [
                Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 6,
                  ),
                  child: Row(
                    children: [
                      IconButton(
                        icon: const Icon(Icons.close),
                        onPressed: () => Navigator.of(context).pop(false),
                      ),
                      const Text(
                        'Pembayaran',
                        style: TextStyle(fontWeight: FontWeight.w600),
                      ),
                      const Spacer(),
                      TextButton(
                        onPressed: () {
                          Navigator.of(context).pop(true);
                        },
                        child: const Text('Saya sudah bayar'),
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
              ],
            ),
          ),
        ),
      ),
    );
  }
}

/// ---------- AD HISTORY PAGE (reads from Firestore) ----------
class AdHistoryPage extends StatelessWidget {
  const AdHistoryPage({super.key});

  String _formatDateFromMillis(dynamic v) {
    try {
      if (v == null) return '-';
      if (v is Timestamp) {
        final d = v.toDate().toLocal();
        return '${d.year}-${d.month.toString().padLeft(2, '0')}-${d.day.toString().padLeft(2, '0')}';
      }
      final ms = v is int ? v : int.parse(v.toString());
      final d = DateTime.fromMillisecondsSinceEpoch(ms).toLocal();
      return '${d.year}-${d.month.toString().padLeft(2, '0')}-${d.day.toString().padLeft(2, '0')}';
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
        st.contains('capture')) {
      return Colors.green;
    }
    if (st.contains('pending')) return Colors.orange;
    if (st.contains('failed') ||
        st.contains('expire') ||
        st.contains('cancel')) {
      return Colors.red;
    }
    return Colors.grey;
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
      appBar: AppBar(title: const Text('Riwayat Iklan')),
      body: StreamBuilder<QuerySnapshot>(
        stream: stream,
        builder: (context, snap) {
          if (snap.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (!snap.hasData || snap.data!.docs.isEmpty) {
            return const Center(child: Text('Belum ada riwayat iklan'));
          }
          final docs = snap.data!.docs;
          return RefreshIndicator(
            onRefresh: () async {
              // no-op (stream is live)
              return;
            },
            child: ListView.separated(
              padding: const EdgeInsets.all(12),
              itemCount: docs.length,
              separatorBuilder: (_, __) => const SizedBox(height: 8),
              itemBuilder: (context, idx) {
                final d = docs[idx];
                final m = d.data() as Map<String, dynamic>;
                final imageUrl = (m['imageUrl'] as String?) ?? '';
                final title = (m['title'] as String?) ?? 'Iklan';
                final orderId = (m['orderId'] as String?) ?? d.id;
                final start = _formatDateFromMillis(m['startAt']);
                final end = _formatDateFromMillis(m['endAt']);
                final amount = _formatCurrency(m['grossAmount']);
                final status = (m['status'] as String?) ?? '-';

                return Card(
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Padding(
                    padding: const EdgeInsets.all(12),
                    child: Row(
                      children: [
                        ClipRRect(
                          borderRadius: BorderRadius.circular(8),
                          child: imageUrl.isNotEmpty
                              ? Image.network(
                                  imageUrl,
                                  width: 88,
                                  height: 64,
                                  fit: BoxFit.cover,
                                  errorBuilder: (_, __, ___) => Container(
                                    width: 88,
                                    height: 64,
                                    color: Colors.grey[300],
                                    child: const Icon(Icons.broken_image),
                                  ),
                                )
                              : Container(
                                  width: 88,
                                  height: 64,
                                  color: Colors.grey[300],
                                  child: const Icon(Icons.image),
                                ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                title,
                                style: const TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                              const SizedBox(height: 6),
                              Text(
                                'Periode: $start — $end',
                                style: const TextStyle(fontSize: 12),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                amount,
                                style: const TextStyle(
                                  fontSize: 12,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                            ],
                          ),
                        ),
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.end,
                          children: [
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 8,
                                vertical: 4,
                              ),
                              decoration: BoxDecoration(
                                color: _statusColor(status).withOpacity(0.12),
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: Text(
                                status.toUpperCase(),
                                style: TextStyle(
                                  color: _statusColor(status),
                                  fontWeight: FontWeight.bold,
                                  fontSize: 12,
                                ),
                              ),
                            ),
                            const SizedBox(height: 8),
                            Text(
                              orderId,
                              style: const TextStyle(
                                fontSize: 10,
                                color: Colors.grey,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
          );
        },
      ),
    );
  }
}

/// ---------- AD CREATE PAGE ----------
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
  // mobile file
  File? _imageFile;
  // web bytes & filename
  Uint8List? _imageBytes;
  String? _imageName;

  bool _loading = false;

  // ---------------- helpers ----------------
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
          source: ImageSource.gallery,
          maxWidth: 1600,
          imageQuality: 80,
        );
        if (x == null) return;
        final bytes = await x.readAsBytes();
        setState(() {
          _imageBytes = bytes;
          _imageName = x.name;
          _imageFile = null;
        });
      } else {
        final XFile? x = await _picker.pickImage(
          source: ImageSource.gallery,
          maxWidth: 1600,
          imageQuality: 80,
        );
        if (x == null) return;
        setState(() {
          _imageFile = File(x.path);
          _imageBytes = null;
          _imageName = x.name;
        });
      }
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Gagal pilih gambar: $e')));
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
      'https://api.cloudinary.com/v1_1/$cloudName/image/upload',
    );
    final request = http.MultipartRequest('POST', uri)
      ..fields['upload_preset'] = uploadPreset
      ..fields['folder'] = folder;

    if (kIsWeb) {
      if (bytes == null) throw Exception('No bytes for web upload');
      final name =
          filename ?? 'upload_${DateTime.now().millisecondsSinceEpoch}.jpg';
      // try detect mime by extension
      String mime = 'image/jpeg';
      if (name.toLowerCase().endsWith('.png')) mime = 'image/png';
      if (name.toLowerCase().endsWith('.webp')) mime = 'image/webp';
      if (name.toLowerCase().endsWith('.gif')) mime = 'image/gif';
      request.files.add(
        http.MultipartFile.fromBytes(
          'file',
          bytes,
          filename: name,
          contentType: MediaType(mime.split('/')[0], mime.split('/')[1]),
        ),
      );
    } else {
      if (file == null) throw Exception('No file for mobile upload');
      request.files.add(await http.MultipartFile.fromPath('file', file.path));
    }

    final streamed = await request.send();
    final resp = await http.Response.fromStream(streamed);

    if (resp.statusCode >= 200 && resp.statusCode < 300) {
      final Map<String, dynamic> body = jsonDecode(resp.body);
      final url = body['secure_url'] as String?;
      if (url == null)
        throw Exception('Upload succeeded but no secure_url returned');
      return url;
    } else {
      throw Exception(
        'Cloudinary upload failed: ${resp.statusCode} ${resp.body}',
      );
    }
  }

  Future<void> _pickStartDate() async {
    final d = await showDatePicker(
      context: context,
      initialDate: _start,
      firstDate: DateTime.now().subtract(const Duration(days: 1)),
      lastDate: DateTime.now().add(const Duration(days: 365)),
    );
    if (d != null) setState(() => _start = d);
  }

  Future<void> _pickEndDate() async {
    final d = await showDatePicker(
      context: context,
      initialDate: _end,
      firstDate: _start,
      lastDate: DateTime.now().add(const Duration(days: 365)),
    );
    if (d != null) setState(() => _end = d);
  }

  // ---------------- main submit flow ----------------
  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    if (_selectedPlacementsCount == 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Pilih minimal satu penempatan iklan')),
      );
      return;
    }
    _formKey.currentState!.save();

    final u = FirebaseAuth.instance.currentUser;
    if (u == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Silakan login terlebih dahulu')),
      );
      return;
    }

    setState(() => _loading = true);
    String imageUrl = '';
    final adOrderId =
        'order_${DateTime.now().millisecondsSinceEpoch}_${u.uid.length >= 6 ? u.uid.substring(0, 6) : u.uid}';

    try {
      // upload to cloudinary if image present
      if (kIsWeb) {
        if (_imageBytes != null) {
          imageUrl = await _uploadToCloudinary(
            cloudName: cloudName,
            uploadPreset: uploadPreset,
            folder: cloudinaryFolder,
            bytes: _imageBytes,
            filename: _imageName,
          );
        }
      } else {
        if (_imageFile != null) {
          imageUrl = await _uploadToCloudinary(
            cloudName: cloudName,
            uploadPreset: uploadPreset,
            folder: cloudinaryFolder,
            file: _imageFile,
          );
        }
      }

      // build payload for backend
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

      // create provisional Firestore record under users/{uid}/ads_history/{orderId}
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
        'status': 'pending', // initial
        'createdAt': FieldValue.serverTimestamp(),
        'updatedAt': FieldValue.serverTimestamp(),
      });

      // call backend to create midtrans transaction
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

      // show info then open payment flow
      final open = await showDialog<bool>(
        context: context,
        builder: (c) => AlertDialog(
          title: const Text('Lanjut ke Pembayaran'),
          content: Text(
            kIsWeb
                ? 'Anda akan diarahkan ke halaman pembayaran (tab baru). Selesaikan pembayaran di sana.'
                : 'Anda akan diarahkan ke halaman pembayaran di dalam aplikasi. Selesaikan pembayaran di sana.',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(c, false),
              child: const Text('Batal'),
            ),
            ElevatedButton(
              onPressed: () => Navigator.pop(c, true),
              child: const Text('Lanjutkan'),
            ),
          ],
        ),
      );
      if (open != true) {
        setState(() => _loading = false);
        return;
      }

      // DIFFERENTIATION: Web vs Mobile
      if (kIsWeb) {
        // on web, do not use webview_flutter (not supported) - open in new tab
        final launched = await launchUrlString(
          paymentUrl,
          mode: LaunchMode.platformDefault,
        );
        if (!launched) throw Exception('Gagal membuka halaman pembayaran');
        // After user finishes paying in the new tab, they should come back and press "Saya sudah bayar"
        // We mimic the previous flow by showing the waiting dialog and polling backend for final confirmation.
      } else {
        // mobile: overlay WebView (automatic redirect detection inside)
        final result = await Navigator.of(context).push<bool>(
          PageRouteBuilder(
            opaque: false,
            pageBuilder: (context, anim1, anim2) =>
                PaymentOverlayPage(paymentUrl: paymentUrl),
            transitionsBuilder: (context, anim, sec, child) {
              return FadeTransition(opacity: anim, child: child);
            },
          ),
        );

        if (result != true) {
          // user closed overlay without confirming payment
          setState(() => _loading = false);
          return;
        }
      }

      // show waiting dialog while polling
      _showWaitingDialog();

      // poll payment status
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

      // close waiting dialog
      if (mounted) Navigator.of(context).pop();

      // update Firestore record based on result
      if (paid) {
        await userAdsRef.update({
          'status': 'settlement',
          'updatedAt': FieldValue.serverTimestamp(),
        });
      } else {
        await userAdsRef.update({
          'status': 'failed',
          'updatedAt': FieldValue.serverTimestamp(),
        });
      }

      if (!paid) {
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text(
              'Pembayaran tidak selesai atau timeout. Periksa riwayat di dashboard.',
            ),
          ),
        );
        setState(() => _loading = false);
        return;
      }

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Pembayaran berhasil. Iklan akan aktif.')),
      );
      Navigator.of(context).pop();
    } catch (e) {
      // best-effort: mark pending->failed locally if possible
      try {
        final u = FirebaseAuth.instance.currentUser;
        if (u != null) {
          final ref = FirebaseFirestore.instance
              .collection('users')
              .doc(u.uid)
              .collection('ads_history')
              .doc(adOrderId);
          await ref.set({
            'status': 'failed',
            'updatedAt': FieldValue.serverTimestamp(),
          }, SetOptions(merge: true));
        }
      } catch (_) {}
      if (mounted)
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Gagal: $e')));
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
          content: Row(
            children: const [
              SizedBox(width: 4),
              CircularProgressIndicator(),
              SizedBox(width: 16),
              Expanded(child: Text('Menunggu konfirmasi pembayaran...')),
            ],
          ),
        );
      },
    );
  }

  // ---------------- UI ----------------
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Buat Iklan (Upload & Bayar)'),
        actions: [
          IconButton(
            tooltip: 'Riwayat Iklan',
            icon: const Icon(Icons.history),
            onPressed: () {
              Navigator.of(
                context,
              ).push(MaterialPageRoute(builder: (_) => const AdHistoryPage()));
            },
          ),
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: ListView(
          children: [
            Card(
              elevation: 3,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              child: Padding(
                padding: const EdgeInsets.all(14),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Informasi Iklan',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 12),
                    Form(
                      key: _formKey,
                      child: Column(
                        children: [
                          TextFormField(
                            decoration: const InputDecoration(
                              labelText: 'Judul Iklan',
                            ),
                            onSaved: (v) => _title = v?.trim() ?? '',
                            validator: (v) => (v == null || v.trim().isEmpty)
                                ? 'Masukkan judul'
                                : null,
                          ),
                          const SizedBox(height: 12),
                          CheckboxListTile(
                            value: _placementBanner,
                            onChanged: (v) =>
                                setState(() => _placementBanner = v ?? false),
                            title: const Text('Banner Beranda (Poster Event)'),
                            controlAffinity: ListTileControlAffinity.trailing,
                          ),
                          CheckboxListTile(
                            value: _placementPopup,
                            onChanged: (v) =>
                                setState(() => _placementPopup = v ?? false),
                            title: const Text(
                              'Pop-up saat pertama buka aplikasi',
                            ),
                            controlAffinity: ListTileControlAffinity.trailing,
                          ),
                          const SizedBox(height: 8),
                          Row(
                            children: [
                              Expanded(
                                child: Text(
                                  'Mulai: ${_start.toLocal().toString().split(' ')[0]}',
                                ),
                              ),
                              TextButton(
                                onPressed: _pickStartDate,
                                child: const Text('Ubah'),
                              ),
                            ],
                          ),
                          Row(
                            children: [
                              Expanded(
                                child: Text(
                                  'Selesai: ${_end.toLocal().toString().split(' ')[0]}',
                                ),
                              ),
                              TextButton(
                                onPressed: _pickEndDate,
                                child: const Text('Ubah'),
                              ),
                            ],
                          ),
                          const SizedBox(height: 8),
                          (_imageFile == null && _imageBytes == null)
                              ? TextButton.icon(
                                  onPressed: _pickImage,
                                  icon: const Icon(Icons.image),
                                  label: const Text('Pilih Gambar'),
                                )
                              : Column(
                                  children: [
                                    ClipRRect(
                                      borderRadius: BorderRadius.circular(8),
                                      child: kIsWeb
                                          ? (_imageBytes != null
                                                ? Image.memory(
                                                    _imageBytes!,
                                                    height: 160,
                                                    width: double.infinity,
                                                    fit: BoxFit.cover,
                                                  )
                                                : Container(
                                                    height: 160,
                                                    color: Colors.grey,
                                                  ))
                                          : Image.file(
                                              _imageFile!,
                                              height: 160,
                                              width: double.infinity,
                                              fit: BoxFit.cover,
                                            ),
                                    ),
                                    TextButton(
                                      onPressed: _pickImage,
                                      child: const Text('Ubah Gambar'),
                                    ),
                                  ],
                                ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 14),
            Card(
              elevation: 2,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              child: Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: 14,
                  vertical: 12,
                ),
                child: Column(
                  children: [
                    Row(
                      children: const [
                        Icon(Icons.receipt_long_outlined, size: 20),
                        SizedBox(width: 10),
                        Text(
                          'Ringkasan Biaya',
                          style: TextStyle(fontWeight: FontWeight.w600),
                        ),
                      ],
                    ),
                    const SizedBox(height: 10),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text('Durasi'),
                        Text('$_daysCount hari'),
                      ],
                    ),
                    const SizedBox(height: 6),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text('Penempatan'),
                        Text('${_selectedPlacementsCount} lokasi'),
                      ],
                    ),
                    const SizedBox(height: 6),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text('Harga / hari / placement'),
                        Text('Rp ${_formatCurrency(PER_DAY_RATE)}'),
                      ],
                    ),
                    const Divider(),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text(
                          'TOTAL',
                          style: TextStyle(fontWeight: FontWeight.bold),
                        ),
                        Text(
                          'Rp ${_formatCurrency(_totalAmount)}',
                          style: const TextStyle(fontWeight: FontWeight.bold),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: _loading ? null : _submit,
              style: ElevatedButton.styleFrom(
                padding: const EdgeInsets.symmetric(vertical: 14),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              child: _loading
                  ? const SizedBox(
                      height: 18,
                      width: 18,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : const Text(
                      'Unggah & Bayar',
                      style: TextStyle(fontSize: 16),
                    ),
            ),
            const SizedBox(height: 12),
            Text(
              'Catatan: gambar diupload ke Cloudinary (folder: iklan). Pastikan cloudName + uploadPreset diatur.',
              style: Theme.of(context).textTheme.bodySmall,
            ),
          ],
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
        selectedItemColor: Colors.green,
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
