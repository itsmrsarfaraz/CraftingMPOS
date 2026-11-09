import 'package:flutter/material.dart';

class DashboardScreen extends StatelessWidget {
  const DashboardScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Row(
          children: [
            Icon(Icons.storefront, size: 27),
            SizedBox(width: 10),
            Text('CraftingMPOS', style: TextStyle(fontWeight: FontWeight.bold)),
          ],
        ),
        actions: [
          IconButton(
            onPressed: () {},
            icon: const Icon(Icons.notifications_none),
            tooltip: 'Notifications',
          ),
          const SizedBox(width: 8),
        ],
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Welcome to CraftingMPOS',
                style: TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF172B4D),
                ),
              ),
              const SizedBox(height: 8),
              Text(
                'Your retail business management system.',
                style: TextStyle(fontSize: 14, color: Colors.grey.shade600),
              ),
              const SizedBox(height: 24),

              // Application status
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: const Color(0xFF164E75),
                  borderRadius: BorderRadius.circular(18),
                ),
                child: const Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Icon(Icons.point_of_sale, color: Colors.white, size: 32),
                    SizedBox(height: 16),
                    Text(
                      'Your business starts here.',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    SizedBox(height: 8),
                    Text(
                      'Manage sales, products, inventory and '
                      'business operations from one application.',
                      style: TextStyle(
                        color: Colors.white70,
                        fontSize: 14,
                        height: 1.5,
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 28),

              const Text(
                'Business Modules',
                style: TextStyle(
                  fontSize: 19,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF172B4D),
                ),
              ),
              const SizedBox(height: 16),

              GridView.count(
                crossAxisCount: 2,
                crossAxisSpacing: 12,
                mainAxisSpacing: 12,
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                childAspectRatio: 1.25,
                children: const [
                  _ModuleCard(
                    title: 'Point of Sale',
                    subtitle: 'Sales and checkout',
                    icon: Icons.shopping_cart_outlined,
                    color: Color(0xFF2563EB),
                  ),
                  _ModuleCard(
                    title: 'Products',
                    subtitle: 'Product catalogue',
                    icon: Icons.inventory_2_outlined,
                    color: Color(0xFF08916F),
                  ),
                  _ModuleCard(
                    title: 'Inventory',
                    subtitle: 'Stock management',
                    icon: Icons.warehouse_outlined,
                    color: Color(0xFFD97706),
                  ),
                  _ModuleCard(
                    title: 'Customers',
                    subtitle: 'Customer records',
                    icon: Icons.people_outline,
                    color: Color(0xFF7C3AED),
                  ),
                  _ModuleCard(
                    title: 'Purchases',
                    subtitle: 'Supplier purchases',
                    icon: Icons.local_shipping_outlined,
                    color: Color(0xFFDB2777),
                  ),
                  _ModuleCard(
                    title: 'Reports',
                    subtitle: 'Business insights',
                    icon: Icons.bar_chart_outlined,
                    color: Color(0xFF475569),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _ModuleCard extends StatelessWidget {
  final String title;
  final String subtitle;
  final IconData icon;
  final Color color;

  const _ModuleCard({
    required this.title,
    required this.subtitle,
    required this.icon,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, color: color, size: 30),
            const SizedBox(height: 12),
            Text(
              title,
              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15),
            ),
            const SizedBox(height: 4),
            Text(
              subtitle,
              style: TextStyle(fontSize: 11, color: Colors.grey.shade600),
            ),
          ],
        ),
      ),
    );
  }
}
