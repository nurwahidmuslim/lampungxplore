// favorit_page_improved.dart
import 'package:flutter/material.dart';

class FavoritPage extends StatefulWidget {
  const FavoritPage({super.key});

  @override
  State<FavoritPage> createState() => _FavoritPageState();
}

class _FavoritPageState extends State<FavoritPage> {
  int _currentIndex = 2; // Favorit aktif

  // contoh data favorit (ganti dengan data nyata dari provider / firebase)
  final List<Map<String, String>> _favorites = List.generate(
    6,
    (i) => {
      'title': 'Pantai Klara ${i + 1}',
      'subtitle':
          'Pantai Klara adalah tempat rekreasi yang indah dan tenang untuk keluarga.',
      'image':
          'https://images.unsplash.com/photo-1507525428034-b723cf961d3e?auto=format&fit=crop&w=800&q=60',
    },
  );

  void _onTabTapped(int index) {
    if (index == _currentIndex) return;

    switch (index) {
      case 0:
        Navigator.pushReplacementNamed(context, '/home');
        break;
      case 1:
        Navigator.pushReplacementNamed(context, '/berita');
        break;
      case 2:
        // already on Favorit
        break;
      case 3:
        Navigator.pushReplacementNamed(context, '/profil');
        break;
    }

    setState(() => _currentIndex = index);
  }

  Future<void> _refresh() async {
    // simulate reload
    await Future.delayed(const Duration(milliseconds: 700));
    setState(() {
      // reload data dari sumber nyata
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F7FA),
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _currentIndex,
        onTap: _onTabTapped,
        type: BottomNavigationBarType.fixed,
        selectedItemColor: Colors.teal[700],
        unselectedItemColor: Colors.grey[600],
        items: const [
          BottomNavigationBarItem(
            icon: Icon(Icons.home_outlined),
            activeIcon: Icon(Icons.home),
            label: "Beranda",
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.article_outlined),
            activeIcon: Icon(Icons.article),
            label: "Berita",
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
                // Top bar with subtle card style
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
                          onPressed: () {},
                          icon: Icon(Icons.menu, color: Colors.grey[800]),
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
                      Icon(Icons.explore, color: Colors.teal[700], size: 28),
                      const SizedBox(width: 12),
                      GestureDetector(
                        onTap: () => Navigator.pushNamed(context, '/profil'),
                        child: CircleAvatar(
                          radius: 18,
                          backgroundColor: Colors.purple[50],
                          child: Icon(Icons.person, color: Colors.purple[400]),
                        ),
                      ),
                    ],
                  ),
                ),

                // search / filter row
                Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 8,
                  ),
                  child: Row(
                    children: [
                      Expanded(
                        child: TextField(
                          decoration: InputDecoration(
                            hintText: 'Cari favorit...',
                            isDense: true,
                            filled: true,
                            fillColor: Colors.white,
                            prefixIcon: const Icon(Icons.search),
                            contentPadding: const EdgeInsets.symmetric(
                              vertical: 12,
                            ),
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                              borderSide: BorderSide.none,
                            ),
                          ),
                          onChanged: (val) {
                            // implement cari
                          },
                        ),
                      ),
                      const SizedBox(width: 12),
                      Material(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(12),
                        child: IconButton(
                          onPressed: () {},
                          icon: const Icon(Icons.sort),
                          tooltip: 'Urutkan',
                        ),
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 8),

                // Header card with curved bottom
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  child: Container(
                    width: double.infinity,
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: [Colors.teal.shade600, Colors.teal.shade400],
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
                        CircleAvatar(
                          radius: 20,
                          backgroundColor: Colors.white24,
                          child: const Icon(
                            Icons.favorite,
                            color: Colors.white,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),

                const SizedBox(height: 12),

                // content
                Expanded(
                  child: RefreshIndicator(
                    onRefresh: _refresh,
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 12),
                      child: _favorites.isEmpty
                          ? _emptyState()
                          : ListView.separated(
                              padding: EdgeInsets.only(
                                bottom: kBottomNavigationBarHeight + 20,
                                top: 6,
                              ),
                              itemCount: _favorites.length,
                              separatorBuilder: (context, idx) =>
                                  const SizedBox(height: 12),
                              itemBuilder: (context, index) {
                                final item = _favorites[index];
                                return _favoriteCard(
                                  title: item['title']!,
                                  subtitle: item['subtitle']!,
                                  imageUrl: item['image']!,
                                  onView: () {
                                    // contoh navigasi ke halaman detail
                                    // Navigator.pushNamed(context, '/detail', arguments: item);
                                  },
                                  onRemove: () {
                                    setState(() => _favorites.removeAt(index));
                                    ScaffoldMessenger.of(context).showSnackBar(
                                      SnackBar(
                                        content: Text('Dihapus dari favorit'),
                                      ),
                                    );
                                  },
                                );
                              },
                            ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Tambah favorit (contoh)')),
        ),
        label: const Text('Tambah'),
        icon: const Icon(Icons.add),
      ),
    );
  }

  Widget _favoriteCard({
    required String title,
    required String subtitle,
    required String imageUrl,
    required VoidCallback onView,
    required VoidCallback onRemove,
  }) {
    return Material(
      elevation: 2,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
        ),
        padding: const EdgeInsets.all(12),
        child: Row(
          children: [
            ClipRRect(
              borderRadius: BorderRadius.circular(10),
              child: Image.network(
                imageUrl,
                width: 88,
                height: 88,
                fit: BoxFit.cover,
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
                      fontWeight: FontWeight.w700,
                      color: Colors.black87,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    subtitle,
                    style: TextStyle(fontSize: 13, color: Colors.grey[700]),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      TextButton(
                        onPressed: onView,
                        child: const Text('Lihat'),
                        style: TextButton.styleFrom(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 12,
                            vertical: 8,
                          ),
                          backgroundColor: Colors.teal.shade50,
                          foregroundColor: Colors.teal[700],
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(8),
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      IconButton(
                        onPressed: onRemove,
                        icon: const Icon(Icons.delete_outline),
                        tooltip: 'Hapus dari favorit',
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
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 24.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.favorite_border, size: 72, color: Colors.grey[400]),
            const SizedBox(height: 12),
            Text(
              'Belum ada favorit',
              style: TextStyle(
                fontSize: 18,
                color: Colors.grey[800],
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Simpan tempat yang kamu suka agar mudah diakses di sini.',
              textAlign: TextAlign.center,
              style: TextStyle(color: Colors.grey[600]),
            ),
            const SizedBox(height: 18),
            ElevatedButton(
              onPressed: () => ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Mulai jelajah sekarang')),
              ),
              child: const Text('Jelajah'),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.teal[700],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
