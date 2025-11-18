// lib/admin_page.dart
import 'dart:io';
import 'dart:convert';
import 'dart:typed_data';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:cloud_functions/cloud_functions.dart';
import 'package:flutter/foundation.dart' show kIsWeb, kDebugMode;
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:http/http.dart' as http;
import 'package:http_parser/http_parser.dart';

const List<String> wisataCategories = [
  'Alam',
  'Religi',
  'Sejarah',
  'Budaya',
  'Pantai',
  'Gunung',
  'Air Terjun',
  'Taman',
  'Lainnya',
];

/// GANTI dengan credential Cloudinary-mu:
const String cloudName = 'dodtteomx';
const String uploadPreset = 'lampung_xplore';

class AdminPage extends StatefulWidget {
  const AdminPage({super.key});

  @override
  State<AdminPage> createState() => _AdminPageState();
}

class _AdminPageState extends State<AdminPage> with TickerProviderStateMixin {
  static const double _maxWidth = 920;
  final CollectionReference _destRef = FirebaseFirestore.instance.collection(
    'destinations',
  );
  final CollectionReference _usersRef = FirebaseFirestore.instance.collection(
    'users',
  );
  final ImagePicker _picker = ImagePicker();

  late final TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  // ---------------- Cloudinary helper ----------------
  /// Upload single XFile to Cloudinary (unsigned).
  /// Returns map {'url': ..., 'public_id': ...} on success, otherwise null.
  Future<Map<String, String>?> _uploadToCloudinary(XFile file) async {
    try {
      final uri = Uri.parse(
        'https://api.cloudinary.com/v1_1/$cloudName/image/upload',
      );

      // read bytes (works for web & mobile)
      final Uint8List bytes = await file.readAsBytes();

      final request = http.MultipartRequest('POST', uri)
        ..fields['upload_preset'] = uploadPreset;

      // attempt to determine mime type from filename extension (simple)
      String mimeType = 'image/jpeg';
      final nameLower = file.name.toLowerCase();
      if (nameLower.endsWith('.png')) mimeType = 'image/png';
      if (nameLower.endsWith('.webp')) mimeType = 'image/webp';
      if (nameLower.endsWith('.gif')) mimeType = 'image/gif';

      request.files.add(
        http.MultipartFile.fromBytes(
          'file',
          bytes,
          filename: file.name,
          contentType: MediaType(
            mimeType.split('/')[0],
            mimeType.split('/')[1],
          ),
        ),
      );

      final streamed = await request.send();
      final response = await http.Response.fromStream(streamed);

      if (response.statusCode >= 200 && response.statusCode < 300) {
        final Map<String, dynamic> body = jsonDecode(response.body);
        final secureUrl = body['secure_url'] as String?;
        final publicId = body['public_id'] as String?;
        if (secureUrl != null && publicId != null) {
          return {'url': secureUrl, 'public_id': publicId};
        }
        return null;
      } else {
        // debug print
        if (kDebugMode) {
          debugPrint('Cloudinary upload failed: ${response.statusCode}');
          debugPrint('body: ${response.body}');
        }
        return null;
      }
    } catch (e) {
      if (kDebugMode) debugPrint('upload error: $e');
      return null;
    }
  }

  // ---------------- UI ----------------
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Admin — Lampung Xplore'),
        bottom: TabBar(
          controller: _tabController,
          tabs: const [
            Tab(text: 'Destinasi'),
            Tab(text: 'Users'),
          ],
        ),
        actions: [
          IconButton(
            onPressed: () => _showEditDestinationDialog(context),
            icon: const Icon(Icons.add),
            tooltip: 'Tambah destinasi',
          ),
        ],
      ),
      body: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: _maxWidth),
          child: TabBarView(
            controller: _tabController,
            children: [_buildDestinationsTab(), _buildUsersTab()],
          ),
        ),
      ),
    );
  }

  // ---------------- Destinations ----------------
  Widget _buildDestinationsTab() {
    return Padding(
      padding: const EdgeInsets.all(12),
      child: StreamBuilder<QuerySnapshot>(
        stream: _destRef.orderBy('createdAt', descending: true).snapshots(),
        builder: (context, snap) {
          if (snap.hasError) return Center(child: Text('Error: ${snap.error}'));
          if (snap.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          final docs = snap.data?.docs ?? [];
          if (docs.isEmpty) {
            return const Center(
              child: Text('Belum ada destinasi. Klik + untuk menambahkan.'),
            );
          }

          return ListView.separated(
            itemCount: docs.length,
            separatorBuilder: (_, __) => const SizedBox(height: 8),
            itemBuilder: (context, index) {
              final d = docs[index];
              final data = (d.data() as Map<String, dynamic>?) ?? {};
              return _destinationTile(d.id, data);
            },
          );
        },
      ),
    );
  }

  Widget _destinationTile(String id, Map<String, dynamic> data) {
    final String title = data['title'] ?? '-';
    final String type = data['type'] ?? '-';
    final String subtitle =
        (data['category'] ??
                data['restaurantName'] ??
                (data['address']?['street'] ?? ''))
            .toString();

    // Normalize photos: support old List<String> and new List<Map>
    final rawPhotos = (data['photos'] as List<dynamic>?) ?? [];
    String? firstPhotoUrl;
    final List<Map<String, String>> photos = [];
    for (final p in rawPhotos) {
      if (p is String) {
        photos.add({'url': p, 'public_id': ''});
      } else if (p is Map) {
        photos.add({
          'url': (p['url'] ?? '')?.toString() ?? '',
          'public_id': (p['public_id'] ?? '')?.toString() ?? '',
        });
      }
    }
    if (photos.isNotEmpty) firstPhotoUrl = photos.first['url'];

    return Card(
      child: ListTile(
        leading: firstPhotoUrl == null || firstPhotoUrl.isEmpty
            ? const Icon(Icons.image_not_supported, size: 44)
            : ClipRRect(
                borderRadius: BorderRadius.circular(6),
                child: Image.network(
                  firstPhotoUrl,
                  width: 84,
                  height: 64,
                  fit: BoxFit.cover,
                  errorBuilder: (_, __, ___) => const Icon(Icons.broken_image),
                ),
              ),
        title: Text(title),
        subtitle: Text('$type • $subtitle'),
        trailing: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            IconButton(
              icon: const Icon(Icons.edit, color: Colors.blue),
              onPressed: () => _showEditDestinationDialog(
                context,
                docId: id,
                existing: data,
              ),
            ),
            IconButton(
              icon: const Icon(Icons.delete, color: Colors.redAccent),
              onPressed: () =>
                  _confirmDeleteDestination(context, id, title, photos),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _confirmDeleteDestination(
    BuildContext context,
    String id,
    String title,
    List<Map<String, String>> photos,
  ) async {
    final bool? ok = await showDialog<bool>(
      context: context,
      builder: (c) => AlertDialog(
        title: const Text('Hapus destinasi'),
        content: Text('Yakin ingin menghapus "$title"?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(c, false),
            child: const Text('Batal'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(c, true),
            child: const Text('Hapus'),
          ),
        ],
      ),
    );

    if (ok != true) return;

    try {
      // Panggil Cloud Function yang akan menghapus asset Cloudinary dan dokumen Firestore
      final functions = FirebaseFunctions.instance;
      // Nama function: deleteDestinationAndImages (lihat functions/index.js)
      final callable = functions.httpsCallable('deleteDestinationAndImages');
      final res = await callable.call(<String, dynamic>{'docId': id});
      final data = res.data;
      if (!mounted) return;

      // result handling: tampilkan ringkasan
      if (data != null && data['ok'] == true) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Destinasi dan gambar berhasil dihapus'),
          ),
        );
      } else {
        // jika function gagal, masih coba hapus dokumen lokal saja
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Hapus sebagian/gagal: ${data ?? 'unknown'}')),
        );
      }
    } catch (e) {
      // fallback: jika Cloud Function gagal, coba hapus dokumen Firestore saja (tanpa menghapus gambar)
      try {
        await _destRef.doc(id).delete();
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text(
              'Dokumen dihapus (gambar mungkin tersisa di Cloudinary)',
            ),
          ),
        );
      } catch (e2) {
        if (!mounted) return;
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Gagal hapus: $e | $e2')));
      }
    }
  }

  // --------------- Create / Edit Destination Dialog ----------------
  Future<void> _showEditDestinationDialog(
    BuildContext context, {
    String? docId,
    Map<String, dynamic>? existing,
  }) async {
    // initial state
    String type = existing?['type'] as String? ?? 'wisata';
    String category =
        existing?['category'] as String? ?? wisataCategories.first;
    final titleCtrl = TextEditingController(
      text: existing?['title'] as String? ?? '',
    );
    final locationCtrl = TextEditingController(
      text: existing?['location'] as String? ?? '',
    );
    final descCtrl = TextEditingController(
      text: existing?['description'] as String? ?? '',
    );
    final restaurantCtrl = TextEditingController(
      text: existing?['restaurantName'] as String? ?? '',
    );
    final priceCtrl = TextEditingController(
      text: existing?['pricePerNight']?.toString() ?? '',
    );
    final contactCtrl = TextEditingController(
      text:
          existing?['contact'] as String? ??
          existing?['phone'] as String? ??
          '',
    );
    final mapsCtrl = TextEditingController(
      text: existing?['mapsUrl'] as String? ?? '',
    );

    // menu (kuliner)
    List<Map<String, dynamic>> menuItems = [];
    if (existing != null && existing['menu'] is List) {
      try {
        menuItems = (existing['menu'] as List)
            .map((e) => Map<String, dynamic>.from(e as Map))
            .toList();
      } catch (_) {
        menuItems = [];
      }
    }

    // address
    Map<String, dynamic> address = {
      'street': '',
      'kecamatan': '',
      'kabupaten': '',
      'provinsi': '',
      'postalCode': '',
    };
    if (existing != null && existing['address'] is Map) {
      address = Map<String, dynamic>.from(
        existing['address'] as Map<String, dynamic>,
      );
    }
    final streetCtrl = TextEditingController(
      text: address['street'] as String? ?? '',
    );
    final kecCtrl = TextEditingController(
      text: address['kecamatan'] as String? ?? '',
    );
    final kabCtrl = TextEditingController(
      text: address['kabupaten'] as String? ?? '',
    );
    final provCtrl = TextEditingController(
      text: address['provinsi'] as String? ?? '',
    );
    final postalCtrl = TextEditingController(
      text: address['postalCode'] as String? ?? '',
    );

    // social links
    List<Map<String, String>> socialLinks = [];
    if (existing != null && existing['socialLinks'] is List) {
      socialLinks = (existing['socialLinks'] as List).map((e) {
        final m = Map<String, dynamic>.from(e as Map);
        return {
          'label': (m['label'] ?? '').toString(),
          'url': (m['url'] ?? '').toString(),
        };
      }).toList();
    }

    // photos: existing urls and new picked images
    // Normalize existing photos into List<Map<String,String>>
    List<Map<String, String>> existingPhotos = [];
    if (existing != null && existing['photos'] is List) {
      try {
        final raw = existing['photos'] as List;
        for (final p in raw) {
          if (p is String) {
            existingPhotos.add({'url': p, 'public_id': ''});
          } else if (p is Map) {
            existingPhotos.add({
              'url': (p['url'] ?? '')?.toString() ?? '',
              'public_id': (p['public_id'] ?? '')?.toString() ?? '',
            });
          }
        }
      } catch (_) {
        existingPhotos = [];
      }
    }

    // For picked images we store XFile + bytes (for web preview)
    List<XFile> pickedFiles = [];
    List<Uint8List?> pickedBytes = [];

    await showDialog<void>(
      context: context,
      barrierDismissible: false,
      builder: (c) {
        return StatefulBuilder(
          builder: (context, setStateDialog) {
            Future<void> pickMultiImages() async {
              try {
                final List<XFile>? files = await _picker.pickMultiImage(
                  imageQuality: 80,
                );
                if (files != null && files.isNotEmpty) {
                  for (final f in files) {
                    pickedFiles.add(f);
                    if (kIsWeb) {
                      final b = await f.readAsBytes();
                      pickedBytes.add(b);
                    } else {
                      pickedBytes.add(null);
                    }
                  }
                  setStateDialog(() {});
                }
              } catch (e) {
                // fallback single
                final XFile? file = await _picker.pickImage(
                  source: ImageSource.gallery,
                  imageQuality: 80,
                );
                if (file != null) {
                  pickedFiles.add(file);
                  if (kIsWeb) {
                    final b = await file.readAsBytes();
                    pickedBytes.add(b);
                  } else {
                    pickedBytes.add(null);
                  }
                  setStateDialog(() {});
                }
              }
            }

            Future<void> uploadAndSave() async {
              final title = titleCtrl.text.trim();
              final description = descCtrl.text.trim();
              if (title.isEmpty) {
                if (!mounted) return;
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Judul wajib diisi')),
                );
                return;
              }

              final Map<String, dynamic> payload = {
                'type': type,
                'title': title,
                'description': description,
                'updatedAt': FieldValue.serverTimestamp(),
              };

              if (mapsCtrl.text.trim().isNotEmpty)
                payload['mapsUrl'] = mapsCtrl.text.trim();

              // type-specific
              if (type == 'wisata') {
                payload['category'] = category;
                payload['location'] = locationCtrl.text.trim();
                payload['socialLinks'] = socialLinks
                    .map((e) => {'label': e['label'], 'url': e['url']})
                    .toList();
              } else if (type == 'kuliner') {
                payload['restaurantName'] = restaurantCtrl.text.trim();
                payload['menu'] = menuItems
                    .map(
                      (m) => {
                        'name': m['name'] ?? '',
                        'price': m['price'] ?? 0,
                        'portion': m['portion'] ?? '',
                      },
                    )
                    .toList();
                payload['address'] = {
                  'street': streetCtrl.text.trim(),
                  'kecamatan': kecCtrl.text.trim(),
                  'kabupaten': kabCtrl.text.trim(),
                  'provinsi': provCtrl.text.trim(),
                  'postalCode': postalCtrl.text.trim(),
                };
                payload['phone'] = contactCtrl.text.trim();
                payload['socialLinks'] = socialLinks
                    .map((e) => {'label': e['label'], 'url': e['url']})
                    .toList();
              } else if (type == 'penginapan') {
                payload['address'] = {
                  'street': streetCtrl.text.trim(),
                  'kecamatan': kecCtrl.text.trim(),
                  'kabupaten': kabCtrl.text.trim(),
                  'provinsi': provCtrl.text.trim(),
                  'postalCode': postalCtrl.text.trim(),
                };
                payload['contact'] = contactCtrl.text.trim();
                if (priceCtrl.text.trim().isNotEmpty) {
                  final p = double.tryParse(priceCtrl.text.trim());
                  if (p != null) payload['pricePerNight'] = p;
                }
                payload['socialLinks'] = socialLinks
                    .map((e) => {'label': e['label'], 'url': e['url']})
                    .toList();
              }

              try {
                // create doc id if new
                String docRefId = docId ?? _destRef.doc().id;

                // upload new images to Cloudinary (returns list of map url+public_id)
                final List<Map<String, String>> newPhotos = [];
                for (var i = 0; i < pickedFiles.length; i++) {
                  final XFile f = pickedFiles[i];
                  final uploaded = await _uploadToCloudinary(f);
                  if (uploaded != null) newPhotos.add(uploaded);
                }

                // merge photos (existingPhotos already normalized to List<Map<String,String>>)
                final photosFinal = [...existingPhotos, ...newPhotos];
                payload['photos'] = photosFinal;

                if (docId != null) {
                  await _destRef.doc(docRefId).update(payload);
                } else {
                  payload['createdAt'] = FieldValue.serverTimestamp();
                  await _destRef.doc(docRefId).set(payload);
                }

                if (!mounted) return;
                ScaffoldMessenger.of(
                  context,
                ).showSnackBar(const SnackBar(content: Text('Tersimpan')));
                Navigator.of(context).pop();
              } catch (e) {
                if (!mounted) return;
                ScaffoldMessenger.of(
                  context,
                ).showSnackBar(SnackBar(content: Text('Gagal simpan: $e')));
              }
            }

            // helpers for dynamic lists
            void addSocial() {
              socialLinks.add({'label': '', 'url': ''});
              setStateDialog(() {});
            }

            void addMenuItem() {
              menuItems.add({'name': '', 'price': 0, 'portion': ''});
              setStateDialog(() {});
            }

            void removePickedAt(int idx) {
              pickedFiles.removeAt(idx);
              pickedBytes.removeAt(idx);
              setStateDialog(() {});
            }

            void removeExistingPhotoAt(int idx) {
              existingPhotos.removeAt(idx);
              setStateDialog(() {});
            }

            return AlertDialog(
              title: Text(
                docId == null ? 'Tambah Destinasi' : 'Edit Destinasi',
              ),
              content: SizedBox(
                width: double.maxFinite,
                child: SingleChildScrollView(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      DropdownButtonFormField<String>(
                        value: type,
                        items: const [
                          DropdownMenuItem(
                            value: 'wisata',
                            child: Text('Wisata (Alam/Religi/Budaya/Sejarah)'),
                          ),
                          DropdownMenuItem(
                            value: 'kuliner',
                            child: Text('Kuliner'),
                          ),
                          DropdownMenuItem(
                            value: 'penginapan',
                            child: Text('Penginapan'),
                          ),
                        ],
                        onChanged: (v) =>
                            setStateDialog(() => type = v ?? 'wisata'),
                        decoration: const InputDecoration(labelText: 'Tipe'),
                      ),
                      const SizedBox(height: 8),

                      if (type == 'wisata') ...[
                        DropdownButtonFormField<String>(
                          value: category,
                          items: wisataCategories
                              .map(
                                (c) =>
                                    DropdownMenuItem(value: c, child: Text(c)),
                              )
                              .toList(),
                          onChanged: (v) => setStateDialog(
                            () => category = v ?? wisataCategories.first,
                          ),
                          decoration: const InputDecoration(
                            labelText: 'Kategori Wisata',
                          ),
                        ),
                        const SizedBox(height: 8),
                        TextField(
                          controller: locationCtrl,
                          decoration: const InputDecoration(
                            labelText: 'Lokasi singkat',
                          ),
                        ),
                        const SizedBox(height: 8),
                      ],

                      TextField(
                        controller: titleCtrl,
                        decoration: const InputDecoration(
                          labelText: 'Judul / Nama',
                        ),
                      ),
                      const SizedBox(height: 8),
                      TextField(
                        controller: descCtrl,
                        minLines: 3,
                        maxLines: 6,
                        decoration: const InputDecoration(
                          labelText: 'Deskripsi',
                        ),
                      ),
                      const SizedBox(height: 8),

                      if (type == 'kuliner') ...[
                        TextField(
                          controller: restaurantCtrl,
                          decoration: const InputDecoration(
                            labelText: 'Nama Restoran',
                          ),
                        ),
                        const SizedBox(height: 8),
                        const Text(
                          'Menu (nama + harga + porsi)',
                          style: TextStyle(fontWeight: FontWeight.w600),
                        ),
                        const SizedBox(height: 6),
                        for (var mi = 0; mi < menuItems.length; mi++)
                          Row(
                            children: [
                              Expanded(
                                flex: 3,
                                child: TextField(
                                  controller: TextEditingController(
                                    text:
                                        menuItems[mi]['name']?.toString() ?? '',
                                  ),
                                  decoration: const InputDecoration(
                                    labelText: 'Nama Menu',
                                  ),
                                  onChanged: (v) => menuItems[mi]['name'] = v,
                                ),
                              ),
                              const SizedBox(width: 8),
                              Expanded(
                                flex: 2,
                                child: TextField(
                                  controller: TextEditingController(
                                    text:
                                        menuItems[mi]['price']?.toString() ??
                                        '',
                                  ),
                                  decoration: const InputDecoration(
                                    labelText: 'Harga',
                                  ),
                                  keyboardType: TextInputType.number,
                                  onChanged: (v) => menuItems[mi]['price'] =
                                      double.tryParse(v) ?? 0,
                                ),
                              ),
                              const SizedBox(width: 8),
                              Expanded(
                                flex: 2,
                                child: TextField(
                                  controller: TextEditingController(
                                    text:
                                        menuItems[mi]['portion']?.toString() ??
                                        '',
                                  ),
                                  decoration: const InputDecoration(
                                    labelText: 'Porsi',
                                  ),
                                  onChanged: (v) =>
                                      menuItems[mi]['portion'] = v,
                                ),
                              ),
                              IconButton(
                                icon: const Icon(Icons.delete),
                                onPressed: () => setStateDialog(
                                  () => menuItems.removeAt(mi),
                                ),
                              ),
                            ],
                          ),
                        TextButton.icon(
                          onPressed: addMenuItem,
                          icon: const Icon(Icons.add),
                          label: const Text('Tambah Menu'),
                        ),
                        const SizedBox(height: 8),
                      ],

                      if (type == 'kuliner' || type == 'penginapan') ...[
                        const SizedBox(height: 6),
                        const Text(
                          'Alamat lengkap',
                          style: TextStyle(fontWeight: FontWeight.w600),
                        ),
                        const SizedBox(height: 6),
                        TextField(
                          controller: streetCtrl,
                          decoration: const InputDecoration(
                            labelText: 'Alamat (jalan, no)',
                          ),
                        ),
                        const SizedBox(height: 6),
                        Row(
                          children: [
                            Expanded(
                              child: TextField(
                                controller: kecCtrl,
                                decoration: const InputDecoration(
                                  labelText: 'Kecamatan',
                                ),
                              ),
                            ),
                            const SizedBox(width: 8),
                            Expanded(
                              child: TextField(
                                controller: kabCtrl,
                                decoration: const InputDecoration(
                                  labelText: 'Kab/Kota',
                                ),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 6),
                        Row(
                          children: [
                            Expanded(
                              child: TextField(
                                controller: provCtrl,
                                decoration: const InputDecoration(
                                  labelText: 'Provinsi',
                                ),
                              ),
                            ),
                            const SizedBox(width: 8),
                            Expanded(
                              child: TextField(
                                controller: postalCtrl,
                                decoration: const InputDecoration(
                                  labelText: 'Kode Pos',
                                ),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 8),
                        TextField(
                          controller: contactCtrl,
                          decoration: InputDecoration(
                            labelText: type == 'kuliner'
                                ? 'No. Telp Penjual'
                                : 'Kontak (telp/email)',
                          ),
                        ),
                        const SizedBox(height: 8),
                      ],

                      if (type == 'penginapan') ...[
                        TextField(
                          controller: priceCtrl,
                          decoration: const InputDecoration(
                            labelText: 'Harga / malam',
                          ),
                          keyboardType: TextInputType.number,
                        ),
                        const SizedBox(height: 8),
                      ],

                      TextField(
                        controller: mapsCtrl,
                        decoration: const InputDecoration(
                          labelText: 'Maps URL (Google Maps link)',
                        ),
                      ),
                      const SizedBox(height: 8),

                      const Text(
                        'Sosial Media / Link (opsional)',
                        style: TextStyle(fontWeight: FontWeight.w600),
                      ),
                      const SizedBox(height: 6),
                      for (var si = 0; si < socialLinks.length; si++)
                        Row(
                          children: [
                            Expanded(
                              flex: 2,
                              child: TextField(
                                controller: TextEditingController(
                                  text: socialLinks[si]['label'],
                                ),
                                decoration: const InputDecoration(
                                  labelText: 'Label',
                                ),
                                onChanged: (v) => socialLinks[si]['label'] = v,
                              ),
                            ),
                            const SizedBox(width: 8),
                            Expanded(
                              flex: 5,
                              child: TextField(
                                controller: TextEditingController(
                                  text: socialLinks[si]['url'],
                                ),
                                decoration: const InputDecoration(
                                  labelText: 'URL',
                                ),
                                onChanged: (v) => socialLinks[si]['url'] = v,
                              ),
                            ),
                            IconButton(
                              icon: const Icon(Icons.delete),
                              onPressed: () => setStateDialog(
                                () => socialLinks.removeAt(si),
                              ),
                            ),
                          ],
                        ),
                      TextButton.icon(
                        onPressed: addSocial,
                        icon: const Icon(Icons.add),
                        label: const Text('Tambah Sosial Link'),
                      ),

                      const SizedBox(height: 8),
                      const Text(
                        'Gallery (bisa lebih dari 1 foto)',
                        style: TextStyle(fontWeight: FontWeight.w600),
                      ),
                      const SizedBox(height: 8),
                      Wrap(
                        spacing: 8,
                        runSpacing: 8,
                        children: [
                          for (var ei = 0; ei < existingPhotos.length; ei++)
                            Stack(
                              children: [
                                Image.network(
                                  existingPhotos[ei]['url'] ?? '',
                                  width: 100,
                                  height: 80,
                                  fit: BoxFit.cover,
                                  errorBuilder: (_, __, ___) => Container(
                                    width: 100,
                                    height: 80,
                                    color: Colors.grey,
                                  ),
                                ),
                                Positioned(
                                  top: 2,
                                  right: 2,
                                  child: GestureDetector(
                                    onTap: () => removeExistingPhotoAt(ei),
                                    child: Container(
                                      padding: const EdgeInsets.all(4),
                                      color: Colors.black.withOpacity(0.4),
                                      child: const Icon(
                                        Icons.close,
                                        size: 14,
                                        color: Colors.white,
                                      ),
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          for (var pi = 0; pi < pickedFiles.length; pi++)
                            Stack(
                              children: [
                                // web: show memory preview, mobile: show file
                                kIsWeb
                                    ? (pickedBytes[pi] != null
                                          ? Image.memory(
                                              pickedBytes[pi]!,
                                              width: 100,
                                              height: 80,
                                              fit: BoxFit.cover,
                                            )
                                          : Container(
                                              width: 100,
                                              height: 80,
                                              color: Colors.grey,
                                            ))
                                    : Image.file(
                                        File(pickedFiles[pi].path),
                                        width: 100,
                                        height: 80,
                                        fit: BoxFit.cover,
                                      ),
                                Positioned(
                                  top: 2,
                                  right: 2,
                                  child: GestureDetector(
                                    onTap: () => removePickedAt(pi),
                                    child: Container(
                                      padding: const EdgeInsets.all(4),
                                      color: Colors.black.withOpacity(0.4),
                                      child: const Icon(
                                        Icons.close,
                                        size: 14,
                                        color: Colors.white,
                                      ),
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          OutlinedButton.icon(
                            onPressed: pickMultiImages,
                            icon: const Icon(Icons.photo_library),
                            label: const Text('Pilih Foto'),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: const Text('Batal'),
                ),
                ElevatedButton(
                  onPressed: uploadAndSave,
                  child: const Text('Simpan'),
                ),
              ],
            );
          },
        );
      },
    );
  }

  // ---------------- Users ----------------
  Widget _buildUsersTab() {
    return Padding(
      padding: const EdgeInsets.all(12),
      child: Column(
        children: [
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 8.0),
            child: Row(
              children: [
                const Expanded(
                  child: Text(
                    'Daftar users (collection: users)',
                    style: TextStyle(fontWeight: FontWeight.bold),
                  ),
                ),
                IconButton(
                  onPressed: () => setState(() {}),
                  icon: const Icon(Icons.refresh),
                ),
              ],
            ),
          ),
          Expanded(
            child: StreamBuilder<QuerySnapshot>(
              stream: _usersRef
                  .orderBy('createdAt', descending: true)
                  .snapshots(),
              builder: (context, snap) {
                if (snap.hasError)
                  return Center(child: Text('Error: ${snap.error}'));
                if (snap.connectionState == ConnectionState.waiting)
                  return const Center(child: CircularProgressIndicator());
                final docs = snap.data?.docs ?? [];
                if (docs.isEmpty)
                  return const Center(child: Text('Belum ada users.'));
                return ListView.separated(
                  itemCount: docs.length,
                  separatorBuilder: (_, __) => const SizedBox(height: 6),
                  itemBuilder: (context, i) {
                    final d = docs[i];
                    final data = (d.data() as Map<String, dynamic>?) ?? {};
                    final name = data['name'] ?? '-';
                    final email = data['email'] ?? '-';
                    final role = data['role'] ?? 'user';
                    final photo = data['photoUrl'] as String?;
                    return Card(
                      child: ListTile(
                        leading: photo == null || photo.isEmpty
                            ? const CircleAvatar(child: Icon(Icons.person))
                            : CircleAvatar(
                                backgroundImage: NetworkImage(photo),
                              ),
                        title: Text(name),
                        subtitle: Text('$email • role: $role'),
                        trailing: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            if (role != 'admin')
                              TextButton(
                                onPressed: () => _promoteToAdmin(d.id),
                                child: const Text('Jadikan Admin'),
                              ),
                            IconButton(
                              icon: const Icon(
                                Icons.delete,
                                color: Colors.redAccent,
                              ),
                              onPressed: () => _confirmDeleteUser(d.id, name),
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _promoteToAdmin(String uid) async {
    final bool? ok = await showDialog<bool>(
      context: context,
      builder: (c) => AlertDialog(
        title: const Text('Promote ke Admin'),
        content: const Text('Yakin menjadikan user ini sebagai admin?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(c, false),
            child: const Text('Batal'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(c, true),
            child: const Text('Ya, Jadikan'),
          ),
        ],
      ),
    );

    if (ok != true) return;
    try {
      await _usersRef.doc(uid).update({
        'role': 'admin',
        'updatedAt': FieldValue.serverTimestamp(),
      });
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('User di-promote menjadi admin')),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Gagal promote: $e')));
    }
  }

  Future<void> _confirmDeleteUser(String uid, String name) async {
    final bool? ok = await showDialog<bool>(
      context: context,
      builder: (c) => AlertDialog(
        title: const Text('Hapus user (profil)'),
        content: Text(
          'Hapus dokumen profil "$name" di Firestore? (tidak menghapus credential di Firebase Auth)',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(c, false),
            child: const Text('Batal'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(c, true),
            child: const Text('Hapus'),
          ),
        ],
      ),
    );

    if (ok != true) return;
    try {
      await _usersRef.doc(uid).delete();
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Dokumen profil dihapus')));
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Gagal hapus: $e')));
    }
  }
}
