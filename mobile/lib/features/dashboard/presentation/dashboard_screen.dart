import 'package:flutter/material.dart';

import '../../../core/utils/responsive.dart';

// 1. Data model for the modules
class _ModuleData {
  final String title;
  final String subtitle;
  final IconData icon;
  final Color color;

  const _ModuleData({
    required this.title,
    required this.subtitle,
    required this.icon,
    required this.color,
  });
}

class DashboardScreen extends StatelessWidget {
  const DashboardScreen({super.key});

  static const double _maxContentWidth = 1200;

  // 2. List of modules used to dynamically build the layout
  static const List<_ModuleData> _modules = [
    _ModuleData(
      title: 'Point of Sale',
      subtitle: 'Sales and checkout',
      icon: Icons.shopping_cart_outlined,
      color: Color(0xFF2563EB),
    ),
    _ModuleData(
      title: 'Products',
      subtitle: 'Product catalogue',
      icon: Icons.inventory_2_outlined,
      color: Color(0xFF08916F),
    ),
    _ModuleData(
      title: 'Inventory',
      subtitle: 'Stock management',
      icon: Icons.warehouse_outlined,
      color: Color(0xFFD97706),
    ),
    _ModuleData(
      title: 'Customers',
      subtitle: 'Customer records',
      icon: Icons.people_outline,
      color: Color(0xFF7C3AED),
    ),
    _ModuleData(
      title: 'Purchases',
      subtitle: 'Supplier purchases',
      icon: Icons.local_shipping_outlined,
      color: Color(0xFFDB2777),
    ),
    _ModuleData(
      title: 'Reports',
      subtitle: 'Business insights',
      icon: Icons.bar_chart_outlined,
      color: Color(0xFF475569),
    ),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Row(
          children: [
            const Icon(Icons.storefront, size: 27),
            const SizedBox(width: 10),
            const Expanded(
              child: Text(
                'CraftingMPOS',
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
            ),
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
        child: LayoutBuilder(
          builder: (context, constraints) {
            final availableWidth = constraints.maxWidth;
            final horizontalPadding = Responsive.horizontalPadding(
              availableWidth,
            );

            return SingleChildScrollView(
              padding: EdgeInsets.symmetric(
                horizontal: horizontalPadding,
                vertical: 20,
              ),
              child: Center(
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: _maxContentWidth),
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
                        style: TextStyle(
                          fontSize: 14,
                          color: Colors.grey.shade600,
                        ),
                      ),
                      const SizedBox(height: 24),

                      // Application status
                      Container(
                        width: double.infinity,
                        padding: EdgeInsets.all(availableWidth < 360 ? 16 : 20),
                        decoration: BoxDecoration(
                          color: const Color(0xFF164E75),
                          borderRadius: BorderRadius.circular(18),
                        ),
                        child: const Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Icon(
                              Icons.point_of_sale,
                              color: Colors.white,
                              size: 32,
                            ),
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

                      LayoutBuilder(
                        builder: (context, gridConstraints) {
                          final columns = Responsive.gridColumns(
                            gridConstraints.maxWidth,
                          );

                          if (columns == 1) {
                            return Column(
                              children: [
                                for (final module in _modules) ...[
                                  _ModuleCard(
                                    title: module.title,
                                    subtitle: module.subtitle,
                                    icon: module.icon,
                                    color: module.color,
                                    horizontal: true,
                                  ),
                                  const SizedBox(height: 12),
                                ],
                              ],
                            );
                          } else {
                            return GridView.count(
                              crossAxisCount: columns,
                              crossAxisSpacing: 12,
                              mainAxisSpacing: 12,
                              shrinkWrap: true,
                              physics: const NeverScrollableScrollPhysics(),
                              childAspectRatio: columns == 2 ? 1.0 : 1.2,
                              children: _modules.map((module) {
                                return _ModuleCard(
                                  title: module.title,
                                  subtitle: module.subtitle,
                                  icon: module.icon,
                                  color: module.color,
                                );
                              }).toList(),
                            );
                          }
                        },
                      ),
                    ],
                  ),
                ),
              ),
            );
          },
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
  final bool horizontal;

  const _ModuleCard({
    required this.title,
    required this.subtitle,
    required this.icon,
    required this.color,
    this.horizontal = false,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: horizontal
            ? Row(
                children: [
                  Icon(icon, color: color, size: 30),
                  const SizedBox(width: 12),
                  Expanded(
                    child: _ModuleCardText(title: title, subtitle: subtitle),
                  ),
                ],
              )
            : Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(icon, color: color, size: 30),
                  const SizedBox(height: 12),
                  _ModuleCardText(title: title, subtitle: subtitle),
                ],
              ),
      ),
    );
  }
}

class _ModuleCardText extends StatelessWidget {
  final String title;
  final String subtitle;

  const _ModuleCardText({required this.title, required this.subtitle});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          title,
          maxLines: 2,
          overflow: TextOverflow.ellipsis,
          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15),
        ),
        const SizedBox(height: 4),
        Text(
          subtitle,
          maxLines: 2,
          overflow: TextOverflow.ellipsis,
          style: TextStyle(fontSize: 11, color: Colors.grey.shade600),
        ),
      ],
    );
  }
}
