// lib/category_page.dart
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

class CategoryPage extends StatefulWidget {
  final String categoryKey; // contoh: 'pantai', 'alam', 'kuliner'
  final String title; // contoh: 'Pantai', 'Alam'
  final IconData icon; // ikon yang dipakai di header & chip

  const CategoryPage({
    super.key,
    required this.categoryKey,
    required this.title,
    required this.icon,
  });

  @override
  State<CategoryPage> createState() => _CategoryPageState();
}

class _CategoryPageState extends State<CategoryPage> {
  int _currentIndex = 0; // for bottom navigation

  void _onTabTapped(int index) {
    if (_currentIndex == index) return;
    setState(() => _currentIndex = index);

    switch (index) {
      case 0:
        Navigator.pushReplacementNamed(context, '/home');
        break;
      case 1:
        Navigator.pushReplacementNamed(context, '/berita');
        break;
      case 2:
        Navigator.pushReplacementNamed(context, '/favorit');
        break;
      case 3:
        Navigator.pushReplacementNamed(context, '/profil');
        break;
    }
  }

  @override
  Widget build(BuildContext context) {
    // ambil sample (limit) lalu filter di client agar tidak memicu composite-index error
    final Stream<QuerySnapshot> stream = FirebaseFirestore.instance
        .collection('destinations')
        .limit(300)
        .snapshots();

    return Scaffold(
      backgroundColor: const Color(0xFFF7F8FA),
      appBar: AppBar(
        elevation: 0,
        backgroundColor: Colors.transparent,
        foregroundColor: Colors.black87,
        centerTitle: false,
        title: Text(
          widget.title,
          style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w700),
        ),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded, size: 18),
          // kembali: jika bisa pop, pop; jika tidak, go to /home
          onPressed: () {
            if (Navigator.canPop(context)) {
              Navigator.pop(context);
            } else {
              Navigator.pushReplacementNamed(context, '/home');
            }
          },
        ),
      ),
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _currentIndex,
        onTap: _onTabTapped,
        type: BottomNavigationBarType.fixed,
        selectedItemColor: Colors.blue,
        unselectedItemColor: Colors.grey,
        items: const [
          BottomNavigationBarItem(
            icon: Icon(Icons.home_outlined),
            activeIcon: Icon(Icons.home),
            label: 'Beranda',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.article_outlined),
            activeIcon: Icon(Icons.article),
            label: 'Berita',
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
      body: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        child: Column(
          children: [
            // intro card
            Container(
              width: double.infinity,
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(14),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.04),
                    blurRadius: 18,
                    offset: const Offset(0, 6),
                  ),
                ],
              ),
              child: ListTile(
                leading: Container(
                  width: 46,
                  height: 46,
                  decoration: BoxDecoration(
                    color: Colors.blue.shade50,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(widget.icon, color: Colors.blue, size: 24),
                ),
                title: Text(
                  widget.title,
                  style: const TextStyle(
                    fontWeight: FontWeight.w700,
                    fontSize: 15,
                  ),
                ),
                subtitle: Text(
                  'Kumpulan destinasi ${widget.title.toLowerCase()} di Lampung',
                ),
                trailing: IconButton(
                  icon: const Icon(Icons.search_rounded),
                  onPressed: () {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('Fungsi pencarian belum ada'),
                      ),
                    );
                  },
                ),
              ),
            ),
            const SizedBox(height: 14),

            // content
            Expanded(
              child: StreamBuilder<QuerySnapshot>(
                stream: stream,
                builder: (context, snapshot) {
                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return const Center(child: CircularProgressIndicator());
                  }

                  if (snapshot.hasError) {
                    return Center(
                      child: Padding(
                        padding: const EdgeInsets.all(16.0),
                        child: Text(
                          'Terjadi kesalahan saat mengambil data:\n${snapshot.error}',
                          style: const TextStyle(
                            color: Colors.red,
                            fontSize: 13,
                          ),
                        ),
                      ),
                    );
                  }

                  final docs = snapshot.data?.docs ?? [];

                  // typed filtered list
                  final String key = widget.categoryKey.toLowerCase();
                  final List<Map<String, dynamic>> filtered = docs
                      .where((d) {
                        final data = d.data() as Map<String, dynamic>? ?? {};
                        final cat = ((data['category'] ?? data['type']) ?? '')
                            .toString();
                        return cat.toLowerCase().contains(key);
                      })
                      .map<Map<String, dynamic>>((d) {
                        final data = d.data() as Map<String, dynamic>;
                        return {'id': d.id, 'data': data};
                      })
                      .toList();

                  if (filtered.isEmpty) {
                    return _emptyState(context);
                  }

                  // sort by title
                  filtered.sort((a, b) {
                    final ta = ((a['data'] as Map)['title'] ?? '').toString();
                    final tb = ((b['data'] as Map)['title'] ?? '').toString();
                    return ta.toLowerCase().compareTo(tb.toLowerCase());
                  });

                  final width = MediaQuery.of(context).size.width;
                  final bool isWide = width > 700;

                  if (isWide) {
                    return GridView.builder(
                      padding: const EdgeInsets.only(bottom: 18),
                      gridDelegate:
                          const SliverGridDelegateWithFixedCrossAxisCount(
                            crossAxisCount: 2,
                            crossAxisSpacing: 14,
                            mainAxisSpacing: 14,
                            childAspectRatio: 1.4,
                          ),
                      itemCount: filtered.length,
                      itemBuilder: (context, index) {
                        final Map<String, dynamic> it = filtered[index];
                        return _DestinationCard(
                          id: it['id'] as String,
                          data: Map<String, dynamic>.from(it['data'] as Map),
                          icon: widget.icon,
                          categoryTitle: widget.title,
                        );
                      },
                    );
                  } else {
                    return ListView.separated(
                      padding: const EdgeInsets.only(bottom: 18),
                      itemCount: filtered.length,
                      separatorBuilder: (_, __) => const SizedBox(height: 12),
                      itemBuilder: (context, index) {
                        final Map<String, dynamic> it = filtered[index];
                        return _DestinationCard(
                          id: it['id'] as String,
                          data: Map<String, dynamic>.from(it['data'] as Map),
                          icon: widget.icon,
                          categoryTitle: widget.title,
                        );
                      },
                    );
                  }
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _emptyState(BuildContext context) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(widget.icon, size: 72, color: Colors.blue.shade100),
          const SizedBox(height: 14),
          Text(
            'Belum ada data ${widget.title.toLowerCase()}.',
            style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
          ),
          const SizedBox(height: 8),
          Text(
            'Pastikan dokumen destinasi memiliki field "category" atau "type" yang berisi kata "${widget.categoryKey}".',
            textAlign: TextAlign.center,
            style: TextStyle(color: Colors.grey.shade600),
          ),
        ],
      ),
    );
  }
}

/// Modern, aesthetic card widget with favorite persistence to Firestore per user.
class _DestinationCard extends StatefulWidget {
  final String id;
  final Map<String, dynamic> data;
  final IconData icon;
  final String categoryTitle;

  const _DestinationCard({
    required this.id,
    required this.data,
    required this.icon,
    required this.categoryTitle,
  });

  @override
  State<_DestinationCard> createState() => _DestinationCardState();
}

class _DestinationCardState extends State<_DestinationCard> {
  bool _isFavorite = false;
  bool _checkingFavorite = true;

  @override
  void initState() {
    super.initState();
    _checkFavoriteStatus();
  }

  Future<void> _checkFavoriteStatus() async {
    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user == null) {
        setState(() {
          _isFavorite = false;
          _checkingFavorite = false;
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
        _isFavorite = doc.exists;
        _checkingFavorite = false;
      });
    } catch (e) {
      // On error, assume not favorite but stop checking spinner
      setState(() => _checkingFavorite = false);
    }
  }

  String _firstPhoto() {
    try {
      final photos = widget.data['photos'];
      if (photos is List && photos.isNotEmpty && photos[0] is String) {
        return photos[0] as String;
      }
    } catch (_) {}
    return '';
  }

  Future<void> _toggleFavorite(BuildContext context) async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Anda harus login untuk menyimpan favorit'),
        ),
      );
      return;
    }

    final favRef = FirebaseFirestore.instance
        .collection('users')
        .doc(user.uid)
        .collection('favorites')
        .doc(widget.id);

    try {
      if (_isFavorite) {
        await favRef.delete();
        setState(() => _isFavorite = false);
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(const SnackBar(content: Text('Dihapus dari favorit')));
      } else {
        await favRef.set({
          'title': widget.data['title'] ?? 'Tanpa Judul',
          'category': widget.data['category'] ?? widget.data['type'],
          'image': _firstPhoto(),
          'location': widget.data['location'] ?? '-',
          'timestamp': FieldValue.serverTimestamp(),
        });
        setState(() => _isFavorite = true);
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(const SnackBar(content: Text('Ditambahkan ke favorit')));
      }
    } catch (e) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Gagal menyimpan favorit: $e')));
    }
  }

  @override
  Widget build(BuildContext context) {
    final String title = (widget.data['title'] ?? 'Tanpa Judul').toString();
    final String location =
        (widget.data['location'] ??
                widget.data['region'] ??
                'Lokasi tidak diketahui')
            .toString();
    final String category =
        (widget.data['category'] ?? widget.data['type'] ?? '').toString();
    final String imageUrl = _firstPhoto();

    return GestureDetector(
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => _DetailPage(
              id: widget.id,
              data: widget.data,
              icon: widget.icon,
              categoryTitle: widget.categoryTitle,
            ),
          ),
        );
      },
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 220),
        curve: Curves.easeOut,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.06),
              blurRadius: 16,
              offset: const Offset(0, 8),
            ),
          ],
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(16),
          child: Stack(
            children: [
              // Image
              SizedBox(
                height: 170,
                width: double.infinity,
                child: imageUrl.isNotEmpty
                    ? Hero(
                        tag: 'dest-${widget.id}',
                        child: Image.network(
                          imageUrl,
                          fit: BoxFit.cover,
                          errorBuilder: (_, __, ___) => _imagePlaceholder(),
                          loadingBuilder: (ctx, child, progress) {
                            if (progress == null) return child;
                            return Container(
                              color: Colors.grey.shade200,
                              child: const Center(
                                child: CircularProgressIndicator(),
                              ),
                            );
                          },
                        ),
                      )
                    : _imagePlaceholder(),
              ),

              // Gradient overlay
              Positioned.fill(
                child: Container(
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [
                        Colors.transparent,
                        Colors.black.withOpacity(0.55),
                      ],
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                    ),
                  ),
                ),
              ),

              // Category chip top-left
              Positioned(
                left: 12,
                top: 12,
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 10,
                    vertical: 6,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.85),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Row(
                    children: [
                      Icon(widget.icon, size: 14, color: Colors.blue),
                      const SizedBox(width: 6),
                      Text(
                        category.isNotEmpty ? category : widget.categoryTitle,
                        style: const TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                ),
              ),

              // Favorite button top-right
              Positioned(
                right: 10,
                top: 10,
                child: InkWell(
                  onTap: () async {
                    if (_checkingFavorite) return;
                    await _toggleFavorite(context);
                  },
                  borderRadius: BorderRadius.circular(18),
                  child: Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.9),
                      shape: BoxShape.circle,
                    ),
                    child: _checkingFavorite
                        ? const SizedBox(
                            width: 18,
                            height: 18,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          )
                        : Icon(
                            _isFavorite
                                ? Icons.favorite
                                : Icons.favorite_border,
                            size: 18,
                            color: _isFavorite
                                ? Colors.redAccent
                                : Colors.black54,
                          ),
                  ),
                ),
              ),

              // Bottom info (title & location)
              Positioned(
                left: 12,
                right: 12,
                bottom: 12,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.w800,
                        fontSize: 16,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Row(
                      children: [
                        const Icon(
                          Icons.location_on,
                          size: 14,
                          color: Colors.white70,
                        ),
                        const SizedBox(width: 6),
                        Expanded(
                          child: Text(
                            location,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(
                              color: Colors.white70,
                              fontSize: 13,
                            ),
                          ),
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
    );
  }

  Widget _imagePlaceholder() {
    return Container(
      color: Colors.grey.shade200,
      child: const Center(
        child: Icon(Icons.image_outlined, size: 40, color: Colors.black26),
      ),
    );
  }
}

/// Detail page with Hero image and more info
class _DetailPage extends StatelessWidget {
  final String id;
  final Map<String, dynamic> data;
  final IconData icon;
  final String categoryTitle;

  const _DetailPage({
    required this.id,
    required this.data,
    required this.icon,
    required this.categoryTitle,
  });

  String _firstPhoto() {
    try {
      final photos = data['photos'];
      if (photos is List && photos.isNotEmpty && photos[0] is String) {
        return photos[0] as String;
      }
    } catch (_) {}
    return '';
  }

  @override
  Widget build(BuildContext context) {
    final imageUrl = _firstPhoto();
    final title = (data['title'] ?? 'Tanpa Judul').toString();
    final description = (data['description'] ?? 'Deskripsi belum tersedia')
        .toString();
    final location = (data['location'] ?? 'Lokasi tidak diketahui').toString();
    final category = (data['category'] ?? data['type'] ?? '').toString();

    return Scaffold(
      backgroundColor: const Color(0xFFF7F8FA),
      appBar: AppBar(
        elevation: 0,
        backgroundColor: Colors.transparent,
        foregroundColor: Colors.black87,
        title: Text(title, overflow: TextOverflow.ellipsis),
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          ClipRRect(
            borderRadius: BorderRadius.circular(14),
            child: imageUrl.isNotEmpty
                ? Hero(
                    tag: 'dest-$id',
                    child: Image.network(
                      imageUrl,
                      height: 260,
                      width: double.infinity,
                      fit: BoxFit.cover,
                      errorBuilder: (_, __, ___) => Container(
                        height: 260,
                        color: Colors.grey.shade200,
                        child: const Center(child: Icon(Icons.image, size: 48)),
                      ),
                    ),
                  )
                : Container(
                    height: 260,
                    color: Colors.grey.shade200,
                    child: const Center(child: Icon(Icons.image, size: 48)),
                  ),
          ),
          const SizedBox(height: 14),
          Row(
            children: [
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 8,
                ),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Row(
                  children: [
                    Icon(icon, color: Colors.blue),
                    const SizedBox(width: 8),
                    Text(
                      category.isNotEmpty ? category : categoryTitle,
                      style: const TextStyle(fontWeight: FontWeight.w600),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  location,
                  style: TextStyle(color: Colors.grey.shade700),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Text(
            title,
            style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w800),
          ),
          const SizedBox(height: 12),
          Text(description, style: const TextStyle(height: 1.6)),
          const SizedBox(height: 20),
          ElevatedButton.icon(
            onPressed: () {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('Buka di Maps belum diimplementasikan'),
                ),
              );
            },
            icon: const Icon(Icons.map_outlined),
            label: const Text('Buka di Maps'),
            style: ElevatedButton.styleFrom(
              padding: const EdgeInsets.symmetric(vertical: 14),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
