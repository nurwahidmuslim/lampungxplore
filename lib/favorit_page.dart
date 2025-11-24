// lib/favorit_page.dart
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

class FavoritPage extends StatefulWidget {
  const FavoritPage({super.key});

  @override
  State<FavoritPage> createState() => _FavoritPageState();
}

class _FavoritPageState extends State<FavoritPage> {
  int _currentIndex = 2; // Favorit aktif
  String _query = '';

  Stream<QuerySnapshot<Map<String, dynamic>>>? _favStream;

  @override
  void initState() {
    super.initState();
    _initStream();
  }

  void _initStream() {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      _favStream = null;
      return;
    }

    _favStream = FirebaseFirestore.instance
        .collection('users')
        .doc(user.uid)
        .collection('favorites')
        .orderBy('timestamp', descending: true)
        .snapshots();
  }

  void _onTabTapped(int index) {
    if (index == _currentIndex) return;

    switch (index) {
      case 0:
        Navigator.pushReplacementNamed(context, '/home');
        break;
      case 1:
        Navigator.pushReplacementNamed(context, '/upload'); // DIPERBAIKI: Mengganti /berita menjadi /upload
        break;
      case 2:
        break; // already on Favorit
      case 3:
        Navigator.pushReplacementNamed(context, '/profil');
        break;
    }
    setState(() => _currentIndex = index);
  }

  Future<void> _refresh() async {
    await Future.delayed(const Duration(milliseconds: 600));
    _initStream();
    setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F7FA),
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _currentIndex,
        onTap: _onTabTapped,
        type: BottomNavigationBarType.fixed,
        selectedItemColor: Colors.blue.shade400,
        unselectedItemColor: Colors.grey[600],
        items: const [
          BottomNavigationBarItem(
            icon: Icon(Icons.home_outlined),
            activeIcon: Icon(Icons.home),
            label: "Beranda",
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.cloud_upload_outlined), // DIPERBAIKI: Menggunakan ikon Upload
            activeIcon: Icon(Icons.cloud_upload), // DIPERBAIKI: Menggunakan ikon Upload
            label: "Upload", // DIPERBAIKI: Mengganti "Berita" menjadi "Upload"
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.favorite_border),
            activeIcon: Icon(Icons.favorite),
            label: "Favorit",
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.person_outline),
            activeIcon: Icon(Icons.person),
            label: "Profil",
          ),
        ],
      ),
      body: SafeArea(
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 520),
            child: Column(
              children: [
                // Top Bar
                Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 12,
                  ),
                  child: Row(
                    children: [
                      Material(
                        elevation: 0,
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(10),
                        child: IconButton(
                          onPressed: () {
                            if (Navigator.canPop(context)) {
                              Navigator.pop(context);
                            } else {
                              Navigator.pushReplacementNamed(context, '/home');
                            }
                          },
                          icon: Icon(Icons.arrow_back, color: Colors.grey[700]),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Text(
                          'Favorit',
                          style: TextStyle(
                            fontSize: 22,
                            fontWeight: FontWeight.w700,
                            color: Colors.grey[900],
                          ),
                        ),
                      ),
                      // DIPERBAIKI: Menggunakan Colors.teal[700] untuk konsistensi tema
                      Icon(Icons.favorite, color: Colors.teal[700], size: 28),
                      const SizedBox(width: 12),
                    ],
                  ),
                ),

                // Search
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  child: TextField(
                    decoration: InputDecoration(
                      hintText: 'Cari di favorit...',
                      filled: true,
                      fillColor: Colors.white,
                      prefixIcon: const Icon(Icons.search),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: BorderSide.none,
                      ),
                    ),
                    onChanged: (val) => setState(() => _query = val),
                  ),
                ),

                const SizedBox(height: 14),

                // Header Card
                // LOKASI PERUBAHAN WARNA HEADER CARD
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  child: Container(
                    width: double.infinity,
                    decoration: BoxDecoration(
                      // DIPERBAIKI: Menggunakan gradient yang sama dengan ProfilPage Header
                      gradient: LinearGradient(
                        colors: [Colors.teal.shade600!, Colors.teal.shade400!], 
                      ),
                      borderRadius: BorderRadius.circular(14),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.06),
                          blurRadius: 14,
                          offset: const Offset(0, 8),
                        ),
                      ],
                    ),
                    padding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 14,
                    ),
                    child: Row(
                      children: [
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: const [
                              Text(
                                'Daftar Favorit',
                                style: TextStyle(
                                  color: Colors.white,
                                  fontSize: 16,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              SizedBox(height: 4),
                              Text(
                                'Tempat-tempat yang kamu simpan',
                                style: TextStyle(
                                  color: Colors.white70,
                                  fontSize: 13,
                                ),
                              ),
                            ],
                          ),
                        ),
                        const CircleAvatar(
                          radius: 20,
                          backgroundColor: Colors.white24,
                          child: Icon(Icons.favorite, color: Colors.white),
                        ),
                      ],
                    ),
                  ),
                ),

                const SizedBox(height: 12),

                // Content
                Expanded(
                  child: RefreshIndicator(
                    onRefresh: _refresh,
                    child: StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
                      stream: _favStream,
                      builder: (context, snapshot) {
                        if (snapshot.connectionState ==
                            ConnectionState.waiting) {
                          return const Center(
                            child: CircularProgressIndicator(),
                          );
                        }
                        if (snapshot.hasError) {
                          return Center(
                            child: Text(
                              'Terjadi kesalahan:\n${snapshot.error}',
                              textAlign: TextAlign.center,
                              style: const TextStyle(color: Colors.red),
                            ),
                          );
                        }

                        final docs = snapshot.data?.docs ?? [];

                        final items = docs
                            .map(
                              (d) => {
                                'id': d.id,
                                'title': d.data()['title'] ?? 'Tanpa Judul',
                                'image': d.data()['image'] ?? '',
                                'location': d.data()['location'] ?? '-',
                                'destId':
                                    d.data()['destId'] ??
                                    d.id, // if you saved destId use it, otherwise fallback to favorite id
                                'raw': d.data(),
                              },
                            )
                            .where((item) {
                              final q = _query.toLowerCase();
                              return q.isEmpty ||
                                  item['title']
                                      .toString()
                                      .toLowerCase()
                                      .contains(q) ||
                                  item['location']
                                      .toString()
                                      .toLowerCase()
                                      .contains(q);
                            })
                            .toList();

                        if (items.isEmpty) return _emptyState();

                        final width = MediaQuery.of(context).size.width;
                        final isWide = width > 700;

                        return isWide
                            ? GridView.builder(
                                padding: const EdgeInsets.only(
                                  bottom: 20,
                                  top: 8,
                                ),
                                gridDelegate:
                                    const SliverGridDelegateWithFixedCrossAxisCount(
                                      crossAxisCount: 2,
                                      crossAxisSpacing: 12,
                                      mainAxisSpacing: 12,
                                      childAspectRatio: 1.7,
                                    ),
                                itemCount: items.length,
                                itemBuilder: (_, i) =>
                                    _favoriteCard(item: items[i]),
                              )
                            : ListView.separated(
                                padding: EdgeInsets.only(
                                  bottom: kBottomNavigationBarHeight + 20,
                                  top: 8,
                                ),
                                itemCount: items.length,
                                separatorBuilder: (_, __) =>
                                    const SizedBox(height: 12),
                                itemBuilder: (_, i) =>
                                    _favoriteCard(item: items[i]),
                              );
                      },
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

  Widget _favoriteCard({required Map<String, dynamic> item}) {
    return Material(
      elevation: 2,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
        ),
        child: Row(
          children: [
            ClipRRect(
              borderRadius: BorderRadius.circular(10),
              child: item['image'] != ''
                  ? Image.network(
                      item['image'],
                      width: 90,
                      height: 90,
                      fit: BoxFit.cover,
                    )
                  : Container(
                      width: 90,
                      height: 90,
                      color: Colors.grey.shade300,
                      child: const Icon(Icons.image, size: 40),
                    ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    item['title'] ?? 'Tanpa Judul',
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w700,
                      color: Colors.black87,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Row(
                    children: [
                      const Icon(
                        Icons.location_on,
                        size: 14,
                        color: Colors.grey,
                      ),
                      const SizedBox(width: 6),
                      Expanded(
                        child: Text(
                          item['location'] ?? '-',
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(fontSize: 13),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 10),
                  Row(
                    children: [
                      TextButton(
                        onPressed: () {
                          // Open detail page: prefer destId if present (points to destinations doc id)
                          final destId =
                              item['destId']?.toString() ??
                              item['id'].toString();
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (_) => DestinationDetailPage(id: destId),
                            ),
                          );
                        },
                        style: TextButton.styleFrom(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 12,
                            vertical: 8,
                          ),
                          backgroundColor: Colors.teal.shade50,
                          foregroundColor: Colors.teal,
                        ),
                        child: const Text("Lihat"),
                      ),
                      const SizedBox(width: 8),
                      IconButton(
                        onPressed: () async {
                          final user = FirebaseAuth.instance.currentUser;
                          if (user == null) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(
                                content: Text(
                                  'Harap login untuk menghapus favorit',
                                ),
                              ),
                            );
                            return;
                          }
                          try {
                            await FirebaseFirestore.instance
                                .collection('users')
                                .doc(user.uid)
                                .collection('favorites')
                                .doc(item['id'])
                                .delete();
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(
                                content: Text('Dihapus dari favorit'),
                              ),
                            );
                          } catch (e) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(content: Text('Gagal menghapus: $e')),
                            );
                          }
                        },
                        icon: const Icon(Icons.delete_outline),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _emptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.favorite_border, size: 70, color: Colors.grey[400]),
          const SizedBox(height: 14),
          const Text(
            "Belum ada favorit",
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600),
          ),
          const SizedBox(height: 8),
          const Text("Simpan destinasi favorit Anda dari halaman kategori."),
          const SizedBox(height: 20),
          ElevatedButton(
            onPressed: () => Navigator.pushReplacementNamed(context, '/home'),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.teal.shade700,
            ),
            child: const Text("Jelajah Sekarang"),
          ),
        ],
      ),
    );
  }
}

/// Detail page that fetches the latest destination document from `destinations/{id}`
class DestinationDetailPage extends StatelessWidget {
  final String id;
  const DestinationDetailPage({required this.id, super.key});

  @override
  Widget build(BuildContext context) {
    final docStream = FirebaseFirestore.instance
        .collection('destinations')
        .doc(id)
        .snapshots();

    return Scaffold(
      backgroundColor: const Color(0xFFF7F8FA),
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        foregroundColor: Colors.black87,
        title: const Text('Detail', overflow: TextOverflow.ellipsis),
      ),
      body: StreamBuilder<DocumentSnapshot>(
        stream: docStream,
        builder: (context, snap) {
          if (snap.connectionState == ConnectionState.waiting)
            return const Center(child: CircularProgressIndicator());
          if (snap.hasError) return Center(child: Text('Error: ${snap.error}'));
          if (!snap.hasData || !snap.data!.exists)
            return const Center(child: Text('Data tidak ditemukan'));

          final data = snap.data!.data() as Map<String, dynamic>;
          final title = (data['title'] ?? 'Tanpa Judul').toString();
          final description =
              (data['description'] ?? 'Deskripsi belum tersedia').toString();
          final location = (data['location'] ?? '-').toString();
          final category = (data['category'] ?? data['type'] ?? '-').toString();
          final List photos = (data['photos'] is List)
              ? data['photos']
              : <dynamic>[];
          final rating = data['rating'];
          final reviews = data['reviews'] ?? 0;
          final contact = data['contact'] ?? {};
          final facilities = (data['facilities'] is List)
              ? data['facilities']
              : <dynamic>[];

          return ListView(
            children: [
              // Photo carousel
              if (photos.isNotEmpty)
                SizedBox(
                  height: 280,
                  child: PageView.builder(
                    itemCount: photos.length,
                    itemBuilder: (context, idx) {
                      final p = (photos[idx] ?? '').toString();
                      return Hero(
                        tag: 'dest-$id',
                        child: p.isNotEmpty
                            ? Image.network(p, fit: BoxFit.cover)
                            : Container(
                                color: Colors.grey.shade200,
                                child: const Icon(Icons.image, size: 48),
                              ),
                      );
                    },
                  ),
                )
              else
                Container(
                  height: 220,
                  color: Colors.grey.shade200,
                  child: const Center(child: Icon(Icons.image, size: 48)),
                ),

              const SizedBox(height: 12),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 12,
                ),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: const BorderRadius.vertical(
                    top: Radius.circular(12),
                  ),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Expanded(
                          child: Text(
                            title,
                            style: const TextStyle(
                              fontSize: 20,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                        const SizedBox(width: 8),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 10,
                            vertical: 6,
                          ),
                          decoration: BoxDecoration(
                            color: Colors.blue.shade50,
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Row(
                            children: [
                              const Icon(
                                Icons.beach_access_rounded,
                                size: 14,
                                color: Colors.blue,
                              ),
                              const SizedBox(width: 8),
                              Text(
                                category,
                                style: const TextStyle(
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(width: 12),
                        if (rating != null)
                          Row(
                            children: [
                              const Icon(
                                Icons.star,
                                size: 16,
                                color: Colors.amber,
                              ),
                              const SizedBox(width: 4),
                              Text(rating.toString()),
                              const SizedBox(width: 6),
                              Text(
                                '($reviews)',
                                style: const TextStyle(color: Colors.black54),
                              ),
                            ],
                          ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    Row(
                      children: [
                        const Icon(
                          Icons.location_on,
                          size: 16,
                          color: Colors.grey,
                        ),
                        const SizedBox(width: 6),
                        Expanded(
                          child: Text(
                            location,
                            style: const TextStyle(fontSize: 14),
                          ),
                        ),
                        const SizedBox(width: 8),
                        ElevatedButton.icon(
                          onPressed: () =>
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(
                                  content: Text(
                                    'Buka Maps belum diimplementasikan',
                                  ),
                                ),
                              ),
                          icon: const Icon(Icons.map_outlined),
                          label: const Text('Buka di Maps'),
                          style: ElevatedButton.styleFrom(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 12,
                              vertical: 10,
                            ),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(10),
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    Text(
                      'Deskripsi',
                      style: TextStyle(
                        fontWeight: FontWeight.w700,
                        color: Colors.grey[800],
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(description, style: const TextStyle(height: 1.6)),
                    const SizedBox(height: 16),
                    if (facilities.isNotEmpty) ...[
                      Text(
                        'Fasilitas',
                        style: TextStyle(
                          fontWeight: FontWeight.w700,
                          color: Colors.grey[800],
                        ),
                      ),
                      const SizedBox(height: 8),
                      Wrap(
                        spacing: 8,
                        runSpacing: 8,
                        children: facilities
                            .map<Widget>(
                              (f) => Chip(
                                label: Text(f.toString()),
                                backgroundColor: Colors.grey[100],
                              ),
                            )
                            .toList(),
                      ),
                      const SizedBox(height: 16),
                    ],
                    Text(
                      'Kontak',
                      style: TextStyle(
                        fontWeight: FontWeight.w700,
                        color: Colors.grey[800],
                      ),
                    ),
                    const SizedBox(height: 8),
                    if (contact is Map && contact.isNotEmpty) ...[
                      if ((contact['phone'] ?? '').toString().isNotEmpty)
                        Row(
                          children: [
                            const Icon(Icons.phone, size: 16),
                            const SizedBox(width: 8),
                            Text(contact['phone'].toString()),
                            const SizedBox(width: 12),
                            TextButton(
                              onPressed: () {},
                              child: const Text('Panggil'),
                            ),
                          ],
                        ),
                      if ((contact['website'] ?? '').toString().isNotEmpty)
                        Row(
                          children: [
                            const Icon(Icons.link, size: 16),
                            const SizedBox(width: 8),
                            Expanded(
                              child: Text(
                                contact['website'].toString(),
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                            TextButton(
                              onPressed: () {},
                              child: const Text('Buka'),
                            ),
                          ],
                        ),
                    ] else
                      const Text('-', style: TextStyle(color: Colors.black54)),
                    const SizedBox(height: 18),

                    // actions: share + favorite (toggle saved favorite here too)
                    Row(
                      children: [
                        OutlinedButton.icon(
                          onPressed: () =>
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(
                                  content: Text(
                                    'Share belum diimplementasikan',
                                  ),
                                ),
                              ),
                          icon: const Icon(Icons.share),
                          label: const Text('Bagikan'),
                          style: OutlinedButton.styleFrom(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 12,
                              vertical: 12,
                            ),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(10),
                            ),
                          ),
                        ),
                        const SizedBox(width: 12),
                        _DetailFavoriteButton(id: id, data: data),
                        const Spacer(),
                      ],
                    ),
                    const SizedBox(height: 28),
                  ],
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}

/// Favorite toggle button used inside detail page
class _DetailFavoriteButton extends StatefulWidget {
  final String id;
  final Map<String, dynamic> data;
  const _DetailFavoriteButton({required this.id, required this.data});

  @override
  State<_DetailFavoriteButton> createState() => _DetailFavoriteButtonState();
}

class _DetailFavoriteButtonState extends State<_DetailFavoriteButton> {
  bool _isFav = false;
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _check();
  }

  Future<void> _check() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      setState(() {
        _isFav = false;
        _loading = false;
      });
      return;
    }
    final doc = await FirebaseFirestore.instance
        .collection('users')
        .doc(user.uid)
        .collection('favorites')
        .doc(widget.id)
        .get();
    setState(() {
      _isFav = doc.exists;
      _loading = false;
    });
  }

  Future<void> _toggle() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Harap login untuk menyimpan favorit')),
      );
      return;
    }
    final ref = FirebaseFirestore.instance
        .collection('users')
        .doc(user.uid)
        .collection('favorites')
        .doc(widget.id);
    setState(() => _loading = true);
    try {
      if (_isFav) {
        await ref.delete();
        setState(() => _isFav = false);
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(const SnackBar(content: Text('Dihapus dari favorit')));
      } else {
        await ref.set({
          'title': widget.data['title'] ?? 'Tanpa Judul',
          'category': widget.data['category'] ?? widget.data['type'],
          'image':
              (widget.data['photos'] is List &&
                  widget.data['photos'].isNotEmpty)
                  ? widget.data['photos'][0]
                  : '',
          'location': widget.data['location'] ?? '-',
          'destId': widget.id, // save link to original destination doc
          'timestamp': FieldValue.serverTimestamp(),
        });
        setState(() => _isFav = true);
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(const SnackBar(content: Text('Ditambahkan ke favorit')));
      }
    } catch (e) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Gagal: $e')));
    } finally {
      setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return _loading
        ? Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
            decoration: BoxDecoration(
              color: Colors.grey.shade100,
              borderRadius: BorderRadius.circular(10),
            ),
            child: const SizedBox(
              width: 16,
              height: 16,
              child: CircularProgressIndicator(strokeWidth: 2),
            ),
          )
        : ElevatedButton.icon(
            onPressed: _toggle,
            icon: Icon(_isFav ? Icons.favorite : Icons.favorite_border),
            label: Text(_isFav ? 'Disimpan' : 'Simpan'),
            style: ElevatedButton.styleFrom(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
              backgroundColor: _isFav ? Colors.redAccent : Colors.teal.shade600,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(10),
              ),
            ),
          );
  }
}