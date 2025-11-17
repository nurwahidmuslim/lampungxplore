// home_page.dart
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  static const double _maxWidth = 480;
  int _currentIndex = 0;
  final User? user = FirebaseAuth.instance.currentUser;

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
            child: CustomScrollView(
              slivers: [
                // Sliver AppBar-like header with banner and search
                SliverToBoxAdapter(
                  child: Stack(
                    clipBehavior: Clip.none,
                    children: [
                      // Banner image
                      SizedBox(
                        height: 220,
                        width: double.infinity,
                        child: Image.asset(
                          'assets/images/banner.jpg',
                          fit: BoxFit.cover,
                          errorBuilder: (_, __, ___) =>
                              Container(color: Colors.blueGrey[700]),
                        ),
                      ),

                      // Dark overlay for contrast
                      Container(
                        height: 220,
                        width: double.infinity,
                        color: Colors.black.withOpacity(0.36),
                      ),

                      // Top bar row
                      Positioned(
                        top: 14,
                        left: 12,
                        right: 12,
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            IconButton(
                              onPressed: () {},
                              icon: const Icon(Icons.menu, color: Colors.white),
                              tooltip: 'Menu',
                            ),
                            const Text(
                              'LAMPUNG XPLORE',
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: 20,
                                fontWeight: FontWeight.bold,
                                letterSpacing: 1.2,
                              ),
                            ),
                            IconButton(
                              onPressed: () =>
                                  Navigator.pushNamed(context, '/profil'),
                              icon: const CircleAvatar(
                                backgroundColor: Colors.white,
                                child: Icon(
                                  Icons.person,
                                  color: Colors.black54,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),

                      // Search box overlapping bottom of banner
                      Positioned(
                        top: 140,
                        left: 16,
                        right: 16,
                        child: Material(
                          elevation: 6,
                          borderRadius: BorderRadius.circular(12),
                          child: Container(
                            height: 52,
                            padding: const EdgeInsets.symmetric(horizontal: 12),
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Row(
                              children: [
                                const Icon(Icons.search, color: Colors.grey),
                                const SizedBox(width: 10),
                                const Expanded(
                                  child: TextField(
                                    decoration: InputDecoration.collapsed(
                                      hintText:
                                          'Cari tempat, kategori, atau lokasi',
                                    ),
                                  ),
                                ),
                                IconButton(
                                  onPressed: () => ScaffoldMessenger.of(context)
                                      .showSnackBar(
                                        const SnackBar(
                                          content: Text(
                                            'Filter belum diimplementasikan',
                                          ),
                                        ),
                                      ),
                                  icon: Icon(
                                    Icons.filter_list,
                                    color: Colors.grey[700],
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),

                // Spacer so next content doesn't overlap search
                SliverToBoxAdapter(child: const SizedBox(height: 90)),

                // Poster event
                SliverToBoxAdapter(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    child: Container(
                      height: 100,
                      decoration: BoxDecoration(
                        color: Colors.grey.shade200,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: const Center(
                        child: Text(
                          'Poster event',
                          style: TextStyle(color: Colors.black54),
                        ),
                      ),
                    ),
                  ),
                ),

                const SliverToBoxAdapter(child: SizedBox(height: 20)),

                // Categories horizontal
                SliverToBoxAdapter(
                  child: SizedBox(
                    height: 86,
                    child: ListView(
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      scrollDirection: Axis.horizontal,
                      children: [
                        _categoryTile('Alam', Icons.park_outlined),
                        _categoryTile('Religi', Icons.account_balance_outlined),
                        _categoryTile('Pantai', Icons.beach_access_outlined),
                        _categoryTile('Gunung', Icons.filter_hdr_outlined),
                        _categoryTile('Kuliner', Icons.restaurant_outlined),
                      ],
                    ),
                  ),
                ),

                const SliverToBoxAdapter(child: SizedBox(height: 16)),

                // Section: Unggulan
                SliverToBoxAdapter(
                  child: _sectionHeader(context, 'Unggulan', onSeeAll: () {}),
                ),
                SliverToBoxAdapter(child: _horizontalDestinations()),

                const SliverToBoxAdapter(child: SizedBox(height: 8)),

                // Section: Terdekat
                SliverToBoxAdapter(
                  child: _sectionHeader(context, 'Terdekat', onSeeAll: () {}),
                ),
                SliverToBoxAdapter(child: _horizontalDestinations()),

                const SliverToBoxAdapter(child: SizedBox(height: 8)),

                // Section: Rekomendasi Kami
                SliverToBoxAdapter(
                  child: _sectionHeader(
                    context,
                    'Rekomendasi Kami',
                    onSeeAll: () {},
                  ),
                ),
                SliverToBoxAdapter(
                  child: SingleChildScrollView(
                    scrollDirection: Axis.horizontal,
                    padding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 8,
                    ),
                    child: Row(
                      children: [
                        _filterChip('All', true),
                        const SizedBox(width: 8),
                        _filterChip('Hotel', false),
                        const SizedBox(width: 8),
                        _filterChip('Religi', false),
                        const SizedBox(width: 8),
                        _filterChip('Kuliner', false),
                        const SizedBox(width: 8),
                        _filterChip('Pantai', false),
                      ],
                    ),
                  ),
                ),
                SliverToBoxAdapter(child: _horizontalDestinations()),

                const SliverToBoxAdapter(child: SizedBox(height: 20)),

                // Footer / login info
                if (user != null)
                  SliverToBoxAdapter(
                    child: Padding(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 12,
                      ),
                      child: Text(
                        'Login sebagai: ${user!.email}',
                        style: const TextStyle(color: Colors.black54),
                      ),
                    ),
                  ),

                const SliverToBoxAdapter(child: SizedBox(height: 40)),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _categoryTile(String label, IconData icon) {
    return Padding(
      padding: const EdgeInsets.only(right: 12),
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: Colors.blue.shade50,
              shape: BoxShape.circle,
              border: Border.all(color: Colors.grey.shade200),
            ),
            child: Icon(icon, size: 26, color: Colors.blue.shade700),
          ),
          const SizedBox(height: 8),
          Text(
            label,
            style: const TextStyle(fontSize: 12, color: Colors.black54),
          ),
        ],
      ),
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
              'Lihat Semua',
              style: TextStyle(color: Colors.blue, fontWeight: FontWeight.w600),
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
        border: Border.all(
          color: selected ? Colors.blue.shade600 : Colors.grey.shade300,
        ),
      ),
      child: Text(
        label,
        style: TextStyle(color: selected ? Colors.white : Colors.black54),
      ),
    );
  }

  Widget _horizontalDestinations() {
    return SizedBox(
      height: 250,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 16),
        itemCount: 4,
        separatorBuilder: (_, __) => const SizedBox(width: 12),
        itemBuilder: (context, index) => _destinationCard(context, index),
      ),
    );
  }

  Widget _destinationCard(BuildContext context, int index) {
    return SizedBox(
      width: 190,
      child: GestureDetector(
        onTap: () {
          // example: open detail
          // Navigator.pushNamed(context, '/detail', arguments: {...});
        },
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
              // image
              ClipRRect(
                borderRadius: const BorderRadius.only(
                  topLeft: Radius.circular(12),
                  topRight: Radius.circular(12),
                ),
                child: Image.asset(
                  'assets/images/dest1.jpg',
                  height: 130,
                  width: double.infinity,
                  fit: BoxFit.cover,
                  errorBuilder: (_, __, ___) =>
                      Container(height: 130, color: Colors.grey.shade300),
                ),
              ),

              Padding(
                padding: const EdgeInsets.all(10),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Hotel',
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.blue,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Row(
                      children: [
                        const Expanded(
                          child: Text(
                            'Pantai Klara',
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 15,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        const SizedBox(width: 6),
                        Icon(
                          Icons.favorite_border,
                          color: Colors.grey.shade600,
                          size: 20,
                        ),
                      ],
                    ),
                    const SizedBox(height: 6),
                    Row(
                      children: [
                        Icon(
                          Icons.location_on_outlined,
                          color: Colors.grey.shade600,
                          size: 14,
                        ),
                        const SizedBox(width: 6),
                        const Expanded(
                          child: Text(
                            'Pesawaran, Lampung',
                            style: TextStyle(fontSize: 12, color: Colors.grey),
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
}
