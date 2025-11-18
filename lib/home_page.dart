// lib/home_page.dart
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

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
                      SliverToBoxAdapter(child: _topDestinations()),

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
            colors: [Colors.blue.shade600, Colors.blue.shade400],
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

  Widget _posterEvent() {
    return SliverToBoxAdapter(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16),
        child: Container(
          height: 100,
          decoration: BoxDecoration(
            color: Colors.grey.shade200,
            borderRadius: BorderRadius.circular(12),
          ),
          child: const Center(child: Text("Poster Event")),
        ),
      ),
    );
  }

  Widget _categoryGrid() {
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
                children: _categories
                    .map(
                      (item) => SizedBox(
                        width: 84,
                        child: _categoryTile(item['label'], item['icon']),
                      ),
                    )
                    .toList(),
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
  //  (Gabungan Unggulan + Rekomendasi — dengan filter di client)
  // ---------------------------------------------------------

  Widget _topDestinations() {
    return SizedBox(
      height: 260,
      child: StreamBuilder<QuerySnapshot>(
        stream: FirebaseFirestore.instance
            .collection('destinations')
            .limit(50)
            .snapshots(),
        builder: (_, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          if (snapshot.hasError) {
            return Center(child: Text("Error: ${snapshot.error}"));
          }

          final docs = snapshot.data?.docs ?? [];

          // client-side filter based on selected filter
          final selectedFilter = _filters[_selectedFilterIndex];

          // kelompok kategori yang dihitung sebagai "Wisata"
          final wisataGroups = [
            'Alam',
            'Gunung',
            'Pantai',
            'Budaya',
            'Religi',
            'Sejarah',
          ];

          final filtered = docs.where((d) {
            final data = d.data() as Map<String, dynamic>;
            final String category = (data['category'] ?? data['type'] ?? '')
                .toString();
            final lower = category.toLowerCase();

            if (selectedFilter == 'All') return true;

            if (selectedFilter == 'Wisata') {
              return wisataGroups.any((w) => lower.contains(w.toLowerCase()));
            }

            // other filters (Kuliner / Penginapan) — match kategori atau type
            return lower.contains(selectedFilter.toLowerCase());
          }).toList();

          if (filtered.isEmpty) {
            return const Center(child: Text("Belum ada destinasi"));
          }

          return ListView.separated(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: 16),
            itemCount: filtered.length,
            separatorBuilder: (_, __) => const SizedBox(width: 12),
            itemBuilder: (_, i) {
              final data = filtered[i].data() as Map<String, dynamic>;

              final String title = data['title'] ?? 'Tanpa Judul';
              final String category = data['category'] ?? data['type'] ?? '-';
              final List photos = (data['photos'] is List)
                  ? data['photos']
                  : [];

              final img = photos.isNotEmpty ? photos[0] : null;

              return _destinationCardFirestore(
                title: title,
                category: category,
                imageUrl: img,
              );
            },
          );
        },
      ),
    );
  }

  // ---------------------------------------------------------
  //                  REUSABLE DESTINATION CARD (Firestore)
  // ---------------------------------------------------------

  Widget _destinationCardFirestore({
    required String title,
    required String category,
    required String? imageUrl,
  }) {
    return SizedBox(
      width: 190,
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.05),
              blurRadius: 6,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            ClipRRect(
              borderRadius: const BorderRadius.vertical(
                top: Radius.circular(12),
              ),
              child: imageUrl != null
                  ? Image.network(
                      imageUrl,
                      height: 130,
                      width: double.infinity,
                      fit: BoxFit.cover,
                    )
                  : Container(
                      height: 130,
                      color: Colors.grey.shade300,
                      child: const Icon(Icons.image, size: 40),
                    ),
            ),
            Padding(
              padding: const EdgeInsets.all(10),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    category,
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
                      fontWeight: FontWeight.bold,
                      fontSize: 15,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),
          ],
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
