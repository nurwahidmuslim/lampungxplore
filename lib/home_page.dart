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
                    "assets/images/banner.jpg",
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
                      "EXPLORE LAMPUNG",
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
                    _MenuItem(icon: Icons.place, label: "Destination"),
                    _MenuItem(icon: Icons.restaurant, label: "Food"),
                    _MenuItem(icon: Icons.home_filled, label: "Homestay"),
                    _MenuItem(icon: Icons.account_balance, label: "Budaya"),
                    _MenuItem(icon: Icons.landscape, label: "Alam"),
                    _MenuItem(icon: Icons.church, label: "Religi"),
                    _MenuItem(icon: Icons.history_edu, label: "Sejarah"),
                    _MenuItem(icon: Icons.shopping_basket, label: "Produk"),
                  ],
                ),
              ),

              const SizedBox(height: 16),

              // Top Destinations
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

              // User Info
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

// ========================
// Widget Menu (Icon Bawaan)
// ========================
class _MenuItem extends StatelessWidget {
  final IconData icon;
  final String label;

  const _MenuItem({required this.icon, required this.label});

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        CircleAvatar(
          radius: 28,
          backgroundColor: Colors.green.shade100,
          child: Icon(icon, size: 30, color: Colors.green),
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

// ========================
// Card Destinasi
// ========================
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
