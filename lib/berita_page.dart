import 'package:flutter/material.dart';

class BeritaPage extends StatefulWidget {
  const BeritaPage({super.key});

  @override
  State<BeritaPage> createState() => _BeritaPageState();
}

class _BeritaPageState extends State<BeritaPage> {
  int _currentIndex = 1; // TAB BERITA AKTIF

  void _onTabTapped(int index) {
    if (_currentIndex == index) return;

    switch (index) {
      case 0:
        Navigator.pushReplacementNamed(context, '/home');
        break;
      case 1:
        // sudah di halaman berita
        break;
      case 2:
        Navigator.pushReplacementNamed(context, '/favorit');
        break;
      case 3:
        Navigator.pushReplacementNamed(context, '/profil');
        break;
    }

    setState(() => _currentIndex = index);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[100],

      // ================================
      // BOTTOM NAVIGATION BAR
      // ================================
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _currentIndex,
        onTap: _onTabTapped,
        selectedItemColor: Colors.blue,
        unselectedItemColor: Colors.grey,
        type: BottomNavigationBarType.fixed,
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

      appBar: AppBar(
        leading: IconButton(
          icon: Icon(Icons.menu, color: Colors.grey[800]),
          onPressed: () {},
        ),

        title: Icon(Icons.explore, color: Colors.blue[700], size: 30),
        centerTitle: true,
        backgroundColor: Colors.white,
        elevation: 1,

        actions: [
          IconButton(
            icon: Icon(
              Icons.person_outline,
              color: Colors.purple[300],
              size: 30,
            ),
            onPressed: () {
              Navigator.pushNamed(context, '/profil');
            },
          ),
          const SizedBox(width: 10),
        ],
      ),

      body: ListView(
        padding: const EdgeInsets.all(12.0),
        children: const [
          NewsCard(),
          SizedBox(height: 12),
          NewsCard(),
          SizedBox(height: 12),
          NewsCard(),
        ],
      ),
    );
  }
}

// ========================================
// WIDGET KARTU BERITA
// ========================================
class NewsCard extends StatelessWidget {
  const NewsCard({super.key});

  @override
  Widget build(BuildContext context) {
    return Card(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15.0)),
      elevation: 3,
      clipBehavior: Clip.antiAlias,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Image.network(
            'https://asset.kompas.com/crops/O_n89x-O-m0-LNMvNK-j-g_k918=/0x0:780x520/750x500/data/photo/2022/07/26/62dfb01e33006.jpg',
            fit: BoxFit.cover,
            width: double.infinity,
            height: 220,
          ),

          Padding(
            padding: const EdgeInsets.all(15.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  "LAMPUNG POST | Senin, 14 Oktober 2024",
                  style: TextStyle(
                    color: Colors.blue[700],
                    fontWeight: FontWeight.bold,
                    fontSize: 12,
                  ),
                ),
                const SizedBox(height: 10),

                const Text(
                  "Momen Kacak Ini Lakukan Sesi Foto di Bukit Embun, Lampung Barat: Vibes-nya Kayak Negeri Dongeng di Atas Awan!",
                  style: TextStyle(
                    fontSize: 17,
                    fontWeight: FontWeight.bold,
                    color: Colors.black87,
                    height: 1.3,
                  ),
                ),
                const SizedBox(height: 5),

                const Text(
                  "TT/bukit_embun",
                  style: TextStyle(color: Colors.grey, fontSize: 12),
                ),
                const SizedBox(height: 15),

                Row(
                  children: [
                    CircleAvatar(
                      radius: 15,
                      backgroundColor: Colors.purple[100],
                      child: Icon(
                        Icons.person,
                        size: 20,
                        color: Colors.purple[300],
                      ),
                    ),
                    const SizedBox(width: 8),
                    const Text(
                      "@Lampungxplore",
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        color: Colors.black87,
                        fontSize: 14,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 10),

                const Text(
                  "Momen seorang wanita lakukan pemotretan di Bukit Embun, Lampung Barat, dengan latar belakang lautan awan + warna matahari terbit yang keemasan. #lampung",
                  style: TextStyle(
                    color: Colors.black54,
                    fontSize: 14,
                    height: 1.4,
                  ),
                ),
                const SizedBox(height: 10),

                Row(
                  children: [
                    IconButton(
                      icon: const Icon(
                        Icons.share_outlined,
                        color: Colors.black54,
                      ),
                      onPressed: () {},
                    ),
                    IconButton(
                      icon: const Icon(
                        Icons.camera_alt_outlined,
                        color: Colors.black54,
                      ),
                      onPressed: () {},
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
