// lib/home_page.dart
import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

// pastikan file CategoryPage ada di lib/category_page.dart
import 'category_page.dart';

// Jika Anda ingin membuka link eksternal ketika iklan diklik, uncomment dan tambahkan url_launcher ke pubspec
// import 'package:url_launcher/url_launcher_string.dart';

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  static const double _maxWidth = 480;
  int _currentIndex = 0;
  final User? user = FirebaseAuth.instance.currentUser;

  // filters for Top Destinasi
  final List<String> _filters = ['All', 'Wisata', 'Kuliner', 'Penginapan'];
  int _selectedFilterIndex = 0;

  final List<Map<String, dynamic>> _categories = [
    {'label': 'Alam', 'icon': Icons.park_outlined},
    {'label': 'Religi', 'icon': Icons.account_balance_outlined},
    {'label': 'Pantai', 'icon': Icons.beach_access_outlined},
    {'label': 'Gunung', 'icon': Icons.filter_hdr_outlined},
    {'label': 'Budaya', 'icon': Icons.museum_outlined},
    {'label': 'Sejarah', 'icon': Icons.landscape_outlined},
    {'label': 'Kuliner', 'icon': Icons.restaurant_outlined},
    {'label': 'Penginapan', 'icon': Icons.hotel_outlined},
  ];

  // set of favorite ids for quick lookup
  final Set<String> _favoriteIds = {};
  StreamSubscription<QuerySnapshot>? _favSub;

  // session-local seen banner ad ids to avoid double counting impressions per app run
  final Set<String> _seenBannerAdIds = {};

  @override
  void initState() {
    super.initState();
    _listenFavorites();
  }

  @override
  void dispose() {
    _favSub?.cancel();
    super.dispose();
  }

  void _listenFavorites() {
    final u = FirebaseAuth.instance.currentUser;
    _favSub?.cancel();
    if (u == null) return;

    _favSub = FirebaseFirestore.instance
        .collection('users')
        .doc(u.uid)
        .collection('favorites')
        .snapshots()
        .listen(
          (snapshot) {
            final ids = <String>{};
            for (final doc in snapshot.docs) {
              ids.add(doc.id);
            }
            setState(() {
              _favoriteIds
                ..clear()
                ..addAll(ids);
            });
          },
          onError: (err) {
            // ignore errors silently, or optionally show a message
          },
        );
  }

  void _onTabTapped(int index) {
    if (_currentIndex == index) return;
    setState(() => _currentIndex = index);

    switch (index) {
      case 0:
        Navigator.pushReplacementNamed(context, '/home');
        break;
      case 1:
        // Upload (premium/merchant) tab — buka halaman upload iklan
        _handleUploadTabTapped();
        break;
      case 2:
        Navigator.pushReplacementNamed(context, '/favorit');
        break;
      case 3:
        Navigator.pushReplacementNamed(context, '/profil');
        break;
    }
  }

  Future<void> _handleUploadTabTapped() async {
    final u = FirebaseAuth.instance.currentUser;
    if (u == null) {
      // not logged in
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Row(
            children: const [
              Icon(Icons.info_outline, size: 18),
              SizedBox(width: 8),
              Expanded(child: Text('Silakan login untuk mengunggah iklan')),
            ],
          ),
        ),
      );
      return;
    }

    // For now we directly open upload route; you may want to check merchant/premium flags first
    Navigator.pushReplacementNamed(context, '/upload');
  }

  Future<void> _toggleFavoriteById(String id, Map<String, dynamic> data) async {
    final u = FirebaseAuth.instance.currentUser;
    if (u == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Row(
            children: const [
              Icon(Icons.info_outline, size: 18),
              SizedBox(width: 8),
              Expanded(child: Text('Anda harus login untuk menyimpan favorit')),
            ],
          ),
        ),
      );
      return;
    }

    final favRef = FirebaseFirestore.instance
        .collection('users')
        .doc(u.uid)
        .collection('favorites')
        .doc(id);

    final already = _favoriteIds.contains(id);

    try {
      if (already) {
        await favRef.delete();
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(const SnackBar(content: Text('Dihapus dari favorit')));
      } else {
        await favRef.set({
          'title': data['title'] ?? 'Tanpa Judul',
          'category': data['category'] ?? data['type'] ?? '-',
          'image': (data['photos'] is List && data['photos'].isNotEmpty)
              ? data['photos'][0]
              : '',
          'location': data['location'] ?? '-',
          'timestamp': FieldValue.serverTimestamp(),
        });
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

  // ----------------------------------------------------------------
  // Impression & click recording (simple client-side implementation)
  // In production: move to Cloud Function for validation & anti-fraud.
  // ----------------------------------------------------------------
  void _recordImpressionOncePerSession(String adId) async {
    if (adId.isEmpty) return;
    if (_seenBannerAdIds.contains(adId)) return;
    _seenBannerAdIds.add(adId);

    try {
      final date = DateTime.now().toIso8601String().substring(
        0,
        10,
      ); // yyyy-MM-dd
      final metricRef = FirebaseFirestore.instance.doc(
        'ad_metrics/$adId/daily/$date',
      );

      await FirebaseFirestore.instance.runTransaction((tx) async {
        final s = await tx.get(metricRef);
        if (!s.exists) {
          tx.set(metricRef, {'date': date, 'views': 1, 'clicks': 0});
        } else {
          tx.update(metricRef, {'views': FieldValue.increment(1)});
        }
      });
    } catch (e) {
      // ignore errors silently
    }
  }

  void _recordClick(String adId) async {
    if (adId.isEmpty) return;
    try {
      final date = DateTime.now().toIso8601String().substring(0, 10);
      final metricRef = FirebaseFirestore.instance.doc(
        'ad_metrics/$adId/daily/$date',
      );

      await FirebaseFirestore.instance.runTransaction((tx) async {
        final s = await tx.get(metricRef);
        if (!s.exists) {
          tx.set(metricRef, {'date': date, 'views': 0, 'clicks': 1});
        } else {
          tx.update(metricRef, {'clicks': FieldValue.increment(1)});
        }
      });

      // optional: store click detail for auditing
      await FirebaseFirestore.instance.collection('ad_clicks').add({
        'adId': adId,
        'createdAt': FieldValue.serverTimestamp(),
      });
    } catch (e) {
      // ignore
    }
  }

  // ----------------------------------------------------------------
  // BUILD
  // ----------------------------------------------------------------

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[100],
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

      body: SafeArea(
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: _maxWidth),
            child: Column(
              children: [
                // Top greeting (non-scrolling)
                _topGreeting(),

                // Scrollable content below
                Expanded(
                  child: CustomScrollView(
                    slivers: [
                      const SliverToBoxAdapter(child: SizedBox(height: 12)),
                      _posterEvent(),
                      const SliverToBoxAdapter(child: SizedBox(height: 20)),

                      _categoryGrid(),
                      const SliverToBoxAdapter(child: SizedBox(height: 16)),

                      // ===== TOP DESTINASI (gabungkan Unggulan + Rekomendasi) =====
                      SliverToBoxAdapter(
                        child: _sectionHeader(
                          context,
                          'Top Destinasi',
                          onSeeAll: () {},
                        ),
                      ),

                      // filter row
                      SliverToBoxAdapter(child: _filterRow()),

                      // destinations list (uses Firestore and client-side filter)
                      _topDestinationsSliver(),

                      const SliverToBoxAdapter(child: SizedBox(height: 20)),

                      const SliverToBoxAdapter(child: SizedBox(height: 40)),
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

  // ---------------------------------------------------------
  //                     SECTIONS WIDGETS
  // ---------------------------------------------------------

  Widget _topGreeting() {
    // If user logged in, try to read their display name from Firestore (collection: users, field: name)
    if (user == null) {
      return Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [const Color.fromARGB(255, 30, 136, 229), Colors.blue.shade400],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          borderRadius: const BorderRadius.vertical(
            bottom: Radius.circular(12),
          ),
        ),
        child: Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Selamat datang,',
                    style: TextStyle(color: Colors.white.withOpacity(0.9)),
                  ),
                  const SizedBox(height: 6),
                  const Text(
                    'Tamu',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
            ),
            const CircleAvatar(
              backgroundColor: Colors.white24,
              child: Icon(Icons.person, color: Colors.white),
            ),
          ],
        ),
      );
    }

    // when user exists, stream the profile document to get 'name' field
    return StreamBuilder<DocumentSnapshot>(
      stream: FirebaseFirestore.instance
          .collection('users')
          .doc(user!.uid)
          .snapshots(),
      builder: (context, snap) {
        String displayName = 'Tamu';
        if (snap.hasData && snap.data!.exists) {
          final Map<String, dynamic>? data =
              snap.data!.data() as Map<String, dynamic>?;
          final n = data?['name'] as String?;
          if (n != null && n.trim().isNotEmpty) displayName = n.trim();
        } else if (user!.displayName != null &&
            user!.displayName!.trim().isNotEmpty) {
          displayName = user!.displayName!;
        }

        // build a nicer greeting card
        return Container(
          width: double.infinity,
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [Colors.indigo.shade700, Colors.indigo.shade500],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            borderRadius: const BorderRadius.vertical(
              bottom: Radius.circular(12),
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.08),
                blurRadius: 8,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Hai, $displayName!',
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      'Selamat menjelajah Lampung Xplore',
                      style: TextStyle(color: Colors.white.withOpacity(0.9)),
                    ),
                  ],
                ),
              ),
              // avatar with initials
              CircleAvatar(
                radius: 26,
                backgroundColor: Colors.white24,
                child: Text(
                  displayName.isNotEmpty ? _initials(displayName) : 'T',
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  String _initials(String name) {
    final parts = name.trim().split(RegExp('\\s+'));
    if (parts.isEmpty) return 'T';
    if (parts.length == 1) return parts[0][0].toUpperCase();
    return (parts[0][0] + parts[1][0]).toUpperCase();
  }

  // ---------------------------------------------------------
  // Poster Event -> menampilkan iklan active di placement 'banner_home'
  // ---------------------------------------------------------
  Widget _posterEvent() {
    return SliverToBoxAdapter(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16),
        child: StreamBuilder<QuerySnapshot>(
          stream: FirebaseFirestore.instance
              .collection('ads')
              .where('status', isEqualTo: 'active')
              .where('placement', isEqualTo: 'banner_home')
              .where(
                'startAt',
                isLessThanOrEqualTo: DateTime.now().millisecondsSinceEpoch,
              )
              .where(
                'endAt',
                isGreaterThanOrEqualTo: DateTime.now().millisecondsSinceEpoch,
              )
              .orderBy('createdAt', descending: true)
              .limit(1)
              .snapshots(),
          builder: (context, snap) {
            if (snap.connectionState == ConnectionState.waiting) {
              return Container(
                height: 100,
                decoration: BoxDecoration(
                  color: Colors.grey.shade200,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Center(child: CircularProgressIndicator()),
              );
            }

            final docs = snap.data?.docs ?? [];
            if (docs.isEmpty) {
              // fallback: placeholder poster event
              return Container(
                height: 100,
                decoration: BoxDecoration(
                  color: Colors.grey.shade200,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Center(child: Text("Poster Event")),
              );
            }

            final adDoc = docs.first;
            final Map<String, dynamic> ad =
                adDoc.data() as Map<String, dynamic>;
            final adId = adDoc.id;
            final imageUrl = (ad['image'] ?? '') as String;
            final title = (ad['title'] ?? '') as String;

            // record impression once per app session
            WidgetsBinding.instance.addPostFrameCallback((_) {
              _recordImpressionOncePerSession(adId);
            });

            return GestureDetector(
              onTap: () async {
                // action saat klik iklan
                final targetUrl = (ad['targetUrl'] ?? '') as String;
                if (targetUrl.isNotEmpty) {
                  // Uncomment jika menggunakan url_launcher
                  // await launchUrlString(targetUrl);
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text(
                        'Membuka link iklan (implementasikan redirect).',
                      ),
                    ),
                  );
                } else {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Iklan ditekan')),
                  );
                }

                // catat click
                _recordClick(adId);
              },
              child: Container(
                height: 120,
                width: double.infinity,
                decoration: BoxDecoration(
                  color: Colors.grey.shade200,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(12),
                  child: imageUrl.isNotEmpty
                      ? Image.network(
                          imageUrl,
                          fit: BoxFit.cover,
                          width: double.infinity,
                          errorBuilder: (_, __, ___) => Center(
                            child: Icon(
                              Icons.broken_image,
                              color: Colors.grey.shade600,
                            ),
                          ),
                        )
                      : Center(
                          child: Text(
                            title.isNotEmpty ? title : 'Poster Event',
                          ),
                        ),
                ),
              ),
            );
          },
        ),
      ),
    );
  }

  Widget _categoryGrid() {
    // navigasi langsung ke CategoryPage dengan parameter
    return SliverToBoxAdapter(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 12),
        child: Card(
          color: Colors.white,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
          child: Padding(
            padding: const EdgeInsets.all(12),
            child: Center(
              child: Wrap(
                alignment: WrapAlignment.center,
                spacing: 20,
                runSpacing: 16,
                children: _categories.map((item) {
                  final label = item['label'] as String;
                  final icon = item['icon'] as IconData;
                  // categoryKey akan digunakan untuk filter di CategoryPage
                  final categoryKey = label.toLowerCase().replaceAll(
                    RegExp(r'\s+'),
                    '',
                  );

                  return SizedBox(
                    width: 84,
                    child: GestureDetector(
                      onTap: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => CategoryPage(
                              categoryKey: categoryKey,
                              title: label,
                              icon: icon,
                            ),
                          ),
                        );
                      },
                      child: _categoryTile(label, icon),
                    ),
                  );
                }).toList(),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _filterRow() {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Row(
        children: List.generate(_filters.length, (index) {
          final label = _filters[index];
          final selected = index == _selectedFilterIndex;
          return Row(
            children: [
              GestureDetector(
                onTap: () => setState(() => _selectedFilterIndex = index),
                child: _filterChip(label, selected),
              ),
              const SizedBox(width: 8),
            ],
          );
        }),
      ),
    );
  }

  // ---------------------------------------------------------
  //                      FIRESTORE — TOP DESTINASI
  //  (Menampilkan seperti tampilan CategoryPage)
  // ---------------------------------------------------------

  Widget _topDestinationsSliver() {
    return SliverToBoxAdapter(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
        child: StreamBuilder<QuerySnapshot>(
          stream: FirebaseFirestore.instance
              .collection('destinations')
              .limit(300)
              .snapshots(),
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return const Center(
                child: SizedBox(
                  height: 180,
                  child: CircularProgressIndicator(),
                ),
              );
            }

            if (snapshot.hasError) {
              return Center(child: Text('Error: ${snapshot.error}'));
            }

            final docs = snapshot.data?.docs ?? [];
            final selectedFilter = _filters[_selectedFilterIndex];

            final wisataGroups = [
              'Alam',
              'Gunung',
              'Pantai',
              'Budaya',
              'Religi',
              'Sejarah',
            ];

            final filtered = docs
                .where((d) {
                  final data = d.data() as Map<String, dynamic>? ?? {};
                  final String category =
                      (data['category'] ?? data['type'] ?? '').toString();
                  final lower = category.toLowerCase();

                  if (selectedFilter == 'All') return true;
                  if (selectedFilter == 'Wisata') {
                    return wisataGroups.any(
                      (w) => lower.contains(w.toLowerCase()),
                    );
                  }
                  return lower.contains(selectedFilter.toLowerCase());
                })
                .map(
                  (d) => {'id': d.id, 'data': d.data() as Map<String, dynamic>},
                )
                .toList();

            if (filtered.isEmpty) {
              return Center(
                child: Padding(
                  padding: const EdgeInsets.symmetric(vertical: 40),
                  child: Text(
                    'Belum ada destinasi',
                    style: TextStyle(color: Colors.grey.shade600),
                  ),
                ),
              );
            }

            // show as vertical list that mirrors CategoryPage cards
            return LayoutBuilder(
              builder: (context, constraints) {
                final width = constraints.maxWidth;
                final isWide = width > 700;

                if (isWide) {
                  return GridView.builder(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    itemCount: filtered.length,
                    gridDelegate:
                        const SliverGridDelegateWithFixedCrossAxisCount(
                          crossAxisCount: 2,
                          crossAxisSpacing: 14,
                          mainAxisSpacing: 14,
                          childAspectRatio: 1.4,
                        ),
                    itemBuilder: (ctx, i) {
                      final it = filtered[i];
                      return _HomeDestinationCard(
                        id: it['id'] as String,
                        data: Map<String, dynamic>.from(
                          it['data'] as Map<String, dynamic>,
                        ),
                      );
                    },
                  );
                }

                return ListView.separated(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  itemCount: filtered.length,
                  separatorBuilder: (_, __) => const SizedBox(height: 12),
                  itemBuilder: (ctx, i) {
                    final it = filtered[i];
                    return _HomeDestinationCard(
                      id: it['id'] as String,
                      data: Map<String, dynamic>.from(
                        it['data'] as Map<String, dynamic>,
                      ),
                    );
                  },
                );
              },
            );
          },
        ),
      ),
    );
  }

  // ---------------------------------------------------------
  //                      HOME DESTINATION CARD
  //   (styled like CategoryPage._DestinationCard)
  // ---------------------------------------------------------

  Widget _HomeDestinationCard({
    required String id,
    required Map<String, dynamic> data,
  }) {
    final String title = (data['title'] ?? 'Tanpa Judul').toString();
    final String location =
        (data['location'] ?? data['region'] ?? 'Lokasi tidak diketahui')
            .toString();
    final String category = (data['category'] ?? data['type'] ?? '').toString();
    String imageUrl = '';
    try {
      final photos = data['photos'];
      if (photos is List && photos.isNotEmpty && photos[0] is String)
        imageUrl = photos[0] as String;
    } catch (_) {}

    final isFav = _favoriteIds.contains(id);

    return GestureDetector(
      onTap: () {
        // Navigate to detail page using the data map (detail layout matches CategoryPage)
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => DestinationDetailPage(
              id: id,
              data: data,
              icon: null,
              categoryTitle: category.isNotEmpty ? category : '-',
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
          color: Colors.white,
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Stack(
                children: [
                  SizedBox(
                    height: 170,
                    width: double.infinity,
                    child: imageUrl.isNotEmpty
                        ? Hero(
                            tag: 'home-dest-$id',
                            child: Image.network(
                              imageUrl,
                              fit: BoxFit.cover,
                              width: double.infinity,
                            ),
                          )
                        : Container(
                            color: Colors.grey.shade200,
                            child: const Center(
                              child: Icon(
                                Icons.image_outlined,
                                size: 40,
                                color: Colors.black26,
                              ),
                            ),
                          ),
                  ),
                  // favorite button top-right
                  Positioned(
                    right: 10,
                    top: 10,
                    child: InkWell(
                      onTap: () {
                        _toggleFavoriteById(id, data);
                      },
                      borderRadius: BorderRadius.circular(18),
                      child: Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: Colors.white.withOpacity(0.9),
                          shape: BoxShape.circle,
                        ),
                        child: Icon(
                          isFav ? Icons.favorite : Icons.favorite_border,
                          size: 18,
                          color: isFav ? Colors.redAccent : Colors.black54,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
              Padding(
                padding: const EdgeInsets.all(12),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      category.isNotEmpty ? category : '-',
                      style: const TextStyle(
                        fontSize: 12,
                        color: Colors.blue,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      title,
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w800,
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 8),
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
                            location,
                            style: TextStyle(color: Colors.grey.shade700),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
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

  // ---------------------------------------------------------
  //                      SMALL UI WIDGETS
  // ---------------------------------------------------------

  Widget _categoryTile(String label, IconData icon) {
    return Column(
      children: [
        Container(
          width: 64,
          height: 64,
          decoration: BoxDecoration(
            color: Colors.blue.shade50,
            shape: BoxShape.circle,
            border: Border.all(color: Colors.grey.shade200),
          ),
          child: Icon(icon, size: 28, color: Colors.blue.shade700),
        ),
        const SizedBox(height: 6),
        Text(label, style: const TextStyle(fontSize: 12)),
      ],
    );
  }

  Widget _sectionHeader(
    BuildContext context,
    String title, {
    VoidCallback? onSeeAll,
  }) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 6),
      child: Row(
        children: [
          Text(
            title,
            style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
          ),
          const Spacer(),
          GestureDetector(
            onTap: onSeeAll,
            child: const Text(
              "Lihat Semua",
              style: TextStyle(color: Colors.blue),
            ),
          ),
        ],
      ),
    );
  }

  Widget _filterChip(String label, bool selected) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
      decoration: BoxDecoration(
        color: selected ? Colors.blue.shade600 : Colors.white,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(
        label,
        style: TextStyle(
          color: selected ? Colors.white : Colors.black54,
          fontSize: 13,
        ),
      ),
    );
  }
}

// ---------------------------------------------------------
// DestinationDetailPage: layout sama seperti _DetailPage di category_page.dart
// ---------------------------------------------------------
class DestinationDetailPage extends StatelessWidget {
  final String id;
  final Map<String, dynamic> data;
  final IconData? icon; // optional, bisa null
  final String categoryTitle;

  const DestinationDetailPage({
    super.key,
    required this.id,
    required this.data,
    this.icon,
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
    final usedIcon = icon ?? Icons.place_outlined;

    return Scaffold(
      backgroundColor: const Color(0xFFF7F8FA),
      appBar: AppBar(
        elevation: 0,
        backgroundColor: Colors.transparent,
        foregroundColor: Colors.black87,
        title: Text(title, overflow: TextOverflow.ellipsis),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded, size: 18),
          onPressed: () {
            if (Navigator.canPop(context)) {
              Navigator.pop(context);
            } else {
              Navigator.pushReplacementNamed(context, '/home');
            }
          },
        ),
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          ClipRRect(
            borderRadius: BorderRadius.circular(14),
            child: imageUrl.isNotEmpty
                ? Hero(
                    tag: 'home-dest-$id', // match hero tag from home cards
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
                    Icon(usedIcon, color: Colors.blue),
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
              backgroundColor: Colors.deepPurple.shade50,
              foregroundColor: Colors.deepPurple,
              elevation: 0,
            ),
          ),
        ],
      ),
    );
  }
}
