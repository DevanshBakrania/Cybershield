import 'package:flutter/material.dart';
import 'package:installed_apps/installed_apps.dart';
import 'package:installed_apps/app_info.dart';

class AppsPage extends StatefulWidget {
  const AppsPage({super.key});

  @override
  State<AppsPage> createState() => _AppsPageState();
}

enum _AppsFilter {
  all,
  user,
  system,
}

class _AppsPageState extends State<AppsPage> {
  List<AppInfo> _allApps = [];
  bool _loading = true;
  String? _error;
  _AppsFilter _filter = _AppsFilter.all;

  @override
  void initState() {
    super.initState();
    _loadApps();
  }

  Future<void> _loadApps() async {
    setState(() {
      _loading = true;
      _error = null;
    });

    try {
      final apps = await InstalledApps.getInstalledApps(true, true);

      apps.sort(
        (a, b) => (a.name ?? '')
            .toLowerCase()
            .compareTo((b.name ?? '').toLowerCase()),
      );

      if (!mounted) return;

      setState(() {
        _allApps = apps;
        _loading = false;
      });
    } catch (e) {
      if (!mounted) return;

      setState(() {
        _error = e.toString();
        _loading = false;
      });
    }
  }

  bool _isSystemApp(AppInfo app) {
    final package = app.packageName ?? '';

    return package.startsWith('com.android') ||
        package.startsWith('com.google.android') ||
        package.startsWith('android');
  }

  @override
  Widget build(BuildContext context) {
    const accent = Color(0xFF00E5FF);

    Iterable<AppInfo> visible = _allApps;

    if (_filter == _AppsFilter.user) {
      visible = _allApps.where((a) => !_isSystemApp(a));
    } else if (_filter == _AppsFilter.system) {
      visible = _allApps.where((a) => _isSystemApp(a));
    }

    final visibleList = visible.toList();

    final totalUser =
        _allApps.where((a) => !_isSystemApp(a)).length;
    final totalSystem =
        _allApps.where((a) => _isSystemApp(a)).length;

    return Scaffold(
      backgroundColor: const Color(0xFF00012B),
      body: SafeArea(
        child: Column(
          children: [
            Padding(
              padding:
                  const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Installed Apps',
                    style: TextStyle(
                      fontSize: 20,
                      color: accent,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'User: $totalUser  •  System: $totalSystem',
                    style: const TextStyle(
                      color: Color(0xFF8E8E93),
                      fontSize: 11,
                    ),
                  ),
                  const SizedBox(height: 12),

                  SizedBox(
                    height: 38,
                    child: SegmentedButton<_AppsFilter>(
                      style: SegmentedButton.styleFrom(
                        selectedForegroundColor: Colors.black,
                        selectedBackgroundColor: accent,
                        foregroundColor: Colors.white70,
                        side: const BorderSide(color: Colors.white10),
                      ),
                      segments: const [
                        ButtonSegment(
                          value: _AppsFilter.all,
                          label: Text('All'),
                        ),
                        ButtonSegment(
                          value: _AppsFilter.user,
                          label: Text('User'),
                        ),
                        ButtonSegment(
                          value: _AppsFilter.system,
                          label: Text('System'),
                        ),
                      ],
                      selected: {_filter},
                      onSelectionChanged: (selection) {
                        if (selection.isEmpty) return;
                        setState(() {
                          _filter = selection.first;
                        });
                      },
                    ),
                  ),
                ],
              ),
            ),

            Expanded(
              child: RefreshIndicator(
                onRefresh: _loadApps,
                color: accent,
                child: Builder(
                  builder: (context) {
                    if (_loading) {
                      return const Center(
                        child: CircularProgressIndicator(color: accent),
                      );
                    }

                    if (_error != null) {
                      return ListView(
                        physics:
                            const AlwaysScrollableScrollPhysics(),
                        children: [
                          const SizedBox(height: 80),
                          Center(
                            child: Text(
                              'Failed to load apps\n$_error',
                              textAlign: TextAlign.center,
                              style: const TextStyle(color: Colors.white70),
                            ),
                          ),
                        ],
                      );
                    }

                    if (visibleList.isEmpty) {
                      return ListView(
                        physics:
                            const AlwaysScrollableScrollPhysics(),
                        children: const [
                          SizedBox(height: 80),
                          Center(
                            child: Text(
                              'No apps found',
                              style: TextStyle(color: Colors.white70),
                            ),
                          ),
                        ],
                      );
                    }

                    return ListView.builder(
                      physics:
                          const AlwaysScrollableScrollPhysics(),
                      padding:
                          const EdgeInsets.symmetric(horizontal: 8),
                      itemCount: visibleList.length,
                      itemBuilder: (context, index) {
                        final app = visibleList[index];

                        return Card(
                          color: const Color(0xFF0A0D3A),
                          margin:
                              const EdgeInsets.symmetric(vertical: 4),
                          child: ListTile(
                            leading: app.icon != null
                                ? Image.memory(
                                    app.icon!,
                                    width: 40,
                                    height: 40,
                                  )
                                : const Icon(Icons.android,
                                    color: accent),
                            title: Text(
                              app.name ?? 'Unknown',
                              style: const TextStyle(
                                color: Colors.white,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            subtitle: Text(
                              app.packageName ?? '',
                              style: const TextStyle(
                                fontSize: 11,
                                color: Color(0xFF8E8E93),
                              ),
                            ),
                            onTap: () {
                              if (app.packageName != null) {
                                InstalledApps.startApp(
                                    app.packageName!);
                              }
                            },
                          ),
                        );
                      },
                    );
                  },
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}