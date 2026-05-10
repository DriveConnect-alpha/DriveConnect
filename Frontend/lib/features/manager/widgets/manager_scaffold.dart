import 'package:flutter/material.dart';
import 'package:material_symbols_icons/symbols.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import '../../../core/providers/auth_provider.dart';

class ManagerScaffold extends StatelessWidget {
  final Widget child;
  final String title;

  const ManagerScaffold({
    super.key,
    required this.child,
    required this.title,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final authProvider = context.watch<AuthProvider>();
    final isDesktop = MediaQuery.of(context).size.width >= 1024;
    final isTablet = MediaQuery.of(context).size.width >= 600 && MediaQuery.of(context).size.width < 1024;
    final useSideRail = isDesktop || isTablet;

    final List<Map<String, dynamic>> menuItems = [
      {'icon': Symbols.dashboard, 'label': 'Dashboard', 'path': '/manager'},
      {'icon': Symbols.book_online, 'label': 'Reservas', 'path': '/manager/reservations'},
      {'icon': Symbols.inventory_2, 'label': 'Inventário', 'path': '/manager/inventory'},
      {'icon': Symbols.group, 'label': 'Clientes', 'path': '/manager/clients'},
      {'icon': Symbols.shield, 'label': 'Seguros', 'path': '/manager/insurance'},
      {'icon': Symbols.settings, 'label': 'Ajustes', 'path': '/manager/settings'},
    ];

    int currentIndex = _calculateSelectedIndex(context, menuItems);

    return Scaffold(
      appBar: AppBar(
        title: Text(title),
        actions: [
          if (!useSideRail)
            IconButton(
              icon: const Icon(Symbols.logout),
              onPressed: () => authProvider.logout(),
            ),
          const SizedBox(width: 8),
        ],
      ),
      drawer: !useSideRail
          ? Drawer(
              child: Column(
                children: [
                  UserAccountsDrawerHeader(
                    accountName: Text(authProvider.user?.email.split('@')[0] ?? 'Gerente'),
                    accountEmail: Text(authProvider.user?.email ?? ''),
                    currentAccountPicture: const CircleAvatar(child: Icon(Symbols.person)),
                    decoration: BoxDecoration(color: theme.colorScheme.primary),
                  ),
                  ...menuItems.map((item) => ListTile(
                        leading: Icon(item['icon']),
                        title: Text(item['label']),
                        selected: menuItems.indexOf(item) == currentIndex,
                        onTap: () {
                          context.go(item['path']);
                          Navigator.pop(context);
                        },
                      )),
                  const Spacer(),
                  const Divider(),
                  ListTile(
                    leading: const Icon(Symbols.logout, color: Colors.red),
                    title: const Text('Sair', style: TextStyle(color: Colors.red)),
                    onTap: () => authProvider.logout(),
                  ),
                ],
              ),
            )
          : null,
      body: Row(
        children: [
          if (useSideRail)
            NavigationRail(
              extended: isDesktop,
              selectedIndex: currentIndex,
              onDestinationSelected: (index) => context.go(menuItems[index]['path']),
              leading: isDesktop
                  ? Padding(
                      padding: const EdgeInsets.all(16.0),
                      child: Text(
                        'Drive Connect',
                        style: theme.textTheme.titleLarge?.copyWith(
                          color: theme.colorScheme.primary,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    )
                  : const Icon(Symbols.directions_car, size: 32),
              trailing: Expanded(
                child: Align(
                  alignment: Alignment.bottomCenter,
                  child: Padding(
                    padding: const EdgeInsets.only(bottom: 16.0),
                    child: IconButton(
                      icon: const Icon(Symbols.logout),
                      onPressed: () => authProvider.logout(),
                    ),
                  ),
                ),
              ),
              destinations: menuItems
                  .map((item) => NavigationRailDestination(
                        icon: Icon(item['icon']),
                        label: Text(item['label']),
                      ))
                  .toList(),
            ),
          const VerticalDivider(thickness: 1, width: 1),
          Expanded(child: child),
        ],
      ),
      bottomNavigationBar: !useSideRail
          ? BottomNavigationBar(
              currentIndex: currentIndex >= 4 ? 0 : currentIndex, // Ajuste simples
              onTap: (index) => context.go(menuItems[index]['path']),
              type: BottomNavigationBarType.fixed,
              items: menuItems.take(4).map((item) => BottomNavigationBarItem(
                icon: Icon(item['icon']),
                label: item['label'],
              )).toList(),
            )
          : null,
    );
  }

  int _calculateSelectedIndex(BuildContext context, List<Map<String, dynamic>> menuItems) {
    final location = GoRouterState.of(context).matchedLocation;
    int index = menuItems.indexWhere((item) => item['path'] == location);
    return index >= 0 ? index : 0;
  }
}
