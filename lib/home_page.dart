import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';

class HomePage extends StatelessWidget {
  const HomePage({super.key});

  @override
  Widget build(BuildContext context) {
    final user = FirebaseAuth.instance.currentUser;

    return Scaffold(
      body: SafeArea(
        child: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Banner + Search Bar
              Stack(
                children: [
                  Image.asset(
                    "assets/images/banner.jpg", // ganti dengan gambar banner
                    height: 220,
                    width: double.infinity,
                    fit: BoxFit.cover,
                  ),
                  Container(
                    height: 220,
                    width: double.infinity,
                    color: Colors.black.withOpacity(0.3),
                  ),
                  Positioned(
                    top: 20,
                    left: 16,
                    right: 16,
                    child: TextField(
                      decoration: InputDecoration(
                        hintText: "Search Destinations, Events, Food...",
                        filled: true,
                        fillColor: Colors.white,
                        prefixIcon: const Icon(Icons.search),
                        contentPadding: const EdgeInsets.symmetric(vertical: 0),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(30),
                          borderSide: BorderSide.none,
                        ),
                      ),
                    ),
                  ),
                  const Positioned(
                    bottom: 20,
                    left: 16,
                    child: Text(
                      "EXPLORE KALIMANTAN",
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 22,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 16),

              // Grid Menu
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: GridView.count(
                  crossAxisCount: 4,
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  children: const [
                    _MenuItem(
                      iconPath: "assets/icons/destination.png",
                      label: "Destination",
                    ),
                    _MenuItem(iconPath: "assets/icons/food.png", label: "Food"),
                    _MenuItem(
                      iconPath: "assets/icons/homestay.png",
                      label: "Homestay",
                    ),
                    _MenuItem(
                      iconPath: "assets/icons/budaya.png",
                      label: "Budaya",
                    ),
                    _MenuItem(iconPath: "assets/icons/alam.png", label: "Alam"),
                    _MenuItem(
                      iconPath: "assets/icons/religi.png",
                      label: "Religi",
                    ),
                    _MenuItem(
                      iconPath: "assets/icons/sejarah.png",
                      label: "Sejarah",
                    ),
                    _MenuItem(
                      iconPath: "assets/icons/produk.png",
                      label: "Produk",
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 16),

              // Top Destinations Section
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: const [
                    Text(
                      "Top Destinations",
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    Text("View all", style: TextStyle(color: Colors.blue)),
                  ],
                ),
              ),

              const SizedBox(height: 8),

              SizedBox(
                height: 180,
                child: ListView(
                  scrollDirection: Axis.horizontal,
                  children: const [
                    _DestinationCard(image: "assets/images/dest1.jpg"),
                    _DestinationCard(image: "assets/images/dest2.jpg"),
                    _DestinationCard(image: "assets/images/dest3.jpg"),
                  ],
                ),
              ),

              const SizedBox(height: 24),

              // User Info (opsional)
              if (user != null)
                Center(
                  child: Text(
                    "Login sebagai: ${user.email}",
                    style: Theme.of(context).textTheme.bodyMedium,
                  ),
                ),
            ],
          ),
        ),
      ),

      // Bottom Navigation
      bottomNavigationBar: BottomNavigationBar(
        selectedItemColor: Colors.green,
        unselectedItemColor: Colors.grey,
        type: BottomNavigationBarType.fixed,
        items: const [
          BottomNavigationBarItem(icon: Icon(Icons.home), label: "Home"),
          BottomNavigationBarItem(
            icon: Icon(Icons.shopping_bag),
            label: "Shopping",
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.favorite),
            label: "Favorite",
          ),
          BottomNavigationBarItem(icon: Icon(Icons.person), label: "Profile"),
        ],
      ),
    );
  }
}

// Widget Menu
class _MenuItem extends StatelessWidget {
  final String iconPath;
  final String label;

  const _MenuItem({required this.iconPath, required this.label});

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        CircleAvatar(
          radius: 28,
          backgroundColor: Colors.green.shade100,
          child: Image.asset(iconPath, height: 30, width: 30),
        ),
        const SizedBox(height: 8),
        Text(
          label,
          style: const TextStyle(fontSize: 12),
          textAlign: TextAlign.center,
        ),
      ],
    );
  }
}

// Widget Card Destinasi
class _DestinationCard extends StatelessWidget {
  final String image;
  const _DestinationCard({required this.image});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 160,
      margin: const EdgeInsets.only(left: 16),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(16),
        image: DecorationImage(image: AssetImage(image), fit: BoxFit.cover),
      ),
    );
  }
}
