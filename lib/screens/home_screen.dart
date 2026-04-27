import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../main.dart';
import '../models/models.dart';
import '../services/db_service.dart';
import 'report_screen.dart';
import 'disaster_detail_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});
  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  List<Disaster> _disasters = [];
  bool _loading = true;
  String _filter = 'all';

  @override
  void initState() { super.initState(); _load(); }

  Future<void> _load() async {
    setState(() => _loading = true);
    try { _disasters = await DbService().getDisasters(); } catch (_) {}
    if (mounted) setState(() => _loading = false);
  }

  List<Disaster> get _filtered => _filter == 'all' ? _disasters : _disasters.where((d) => d.status == _filter).toList();
  Color _sevColor(String s) => switch (s) { 'critical' => C.red, 'high' => C.orange, 'medium' => Colors.amber.shade700, _ => C.green };
  IconData _typeIcon(String t) => switch (t) { 'earthquake' => Icons.terrain, 'flood' => Icons.water, 'fire' => Icons.local_fire_department_rounded, 'storm' => Icons.thunderstorm, 'landslide' => Icons.landscape, _ => Icons.warning_rounded };

  @override
  Widget build(BuildContext context) {
    final critical = _disasters.where((d) => d.severity == 'critical' && d.status != 'resolved').length;
    final active = _disasters.where((d) => d.status != 'resolved').length;
    final resolved = _disasters.where((d) => d.status == 'resolved').length;

    return Scaffold(
      appBar: AppBar(
        title: Row(children: [
          Container(padding: const EdgeInsets.all(6), decoration: BoxDecoration(gradient: C.gradient, borderRadius: BorderRadius.circular(10)),
            child: const Icon(Icons.emergency_rounded, color: Colors.white, size: 20)),
          const SizedBox(width: 10),
          const Text('RescueNet'),
        ]),
      ),
      body: RefreshIndicator(
        onRefresh: _load, color: C.red,
        child: _loading
            ? const Center(child: CircularProgressIndicator(color: C.red))
            : ListView(padding: const EdgeInsets.fromLTRB(20, 8, 20, 100), children: [
                // Stats cards
                Row(children: [
                  _Stat(label: 'Active', value: '$active', color: C.orange, icon: Icons.warning_amber_rounded),
                  const SizedBox(width: 10),
                  _Stat(label: 'Critical', value: '$critical', color: C.red, icon: Icons.error_rounded),
                  const SizedBox(width: 10),
                  _Stat(label: 'Resolved', value: '$resolved', color: C.green, icon: Icons.check_circle_rounded),
                ]).animate().fadeIn(duration: 400.ms).slideY(begin: 0.05),
                const SizedBox(height: 20),
                // Quick actions
                Container(
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(gradient: C.gradient, borderRadius: C.radius,
                      boxShadow: [BoxShadow(color: C.red.withAlpha(40), blurRadius: 20, offset: const Offset(0, 8))]),
                  child: Row(children: [
                    Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                      const Text('Report Emergency', style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.w700)),
                      const SizedBox(height: 4),
                      Text('Quick report a disaster in your area', style: TextStyle(color: Colors.white.withAlpha(180), fontSize: 12)),
                    ])),
                    ElevatedButton(
                      onPressed: () async { await Navigator.push(context, MaterialPageRoute(builder: (_) => const ReportScreen())); _load(); },
                      style: ElevatedButton.styleFrom(backgroundColor: Colors.white, foregroundColor: C.red),
                      child: const Text('Report Now'),
                    ),
                  ]),
                ).animate().fadeIn(delay: 100.ms, duration: 400.ms),
                const SizedBox(height: 20),
                // Filter chips
                SingleChildScrollView(scrollDirection: Axis.horizontal, child: Row(children: ['all', 'reported', 'responding', 'resolved'].map((f) =>
                  Padding(padding: const EdgeInsets.only(right: 8), child: GestureDetector(
                    onTap: () => setState(() => _filter = f),
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 250),
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                      decoration: BoxDecoration(
                        color: _filter == f ? C.red : Colors.white,
                        borderRadius: BorderRadius.circular(12),
                        boxShadow: _filter == f ? [BoxShadow(color: C.red.withAlpha(40), blurRadius: 10)] : C.shadow,
                      ),
                      child: Text(f[0].toUpperCase() + f.substring(1), style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600,
                          color: _filter == f ? Colors.white : C.mist)),
                    ),
                  )),
                ).toList())).animate().fadeIn(delay: 200.ms),
                const SizedBox(height: 16),
                // Disaster list
                if (_filtered.isEmpty)
                  Padding(padding: const EdgeInsets.only(top: 40), child: Center(child: Column(children: [
                    Icon(Icons.shield_rounded, size: 64, color: C.mist.withAlpha(80)),
                    const SizedBox(height: 16),
                    Text('All clear!', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600, color: C.mist)),
                    const SizedBox(height: 4),
                    Text('No disasters in this category', style: TextStyle(color: C.mist.withAlpha(150), fontSize: 13)),
                  ])))
                else
                  ..._filtered.asMap().entries.map((e) {
                    final d = e.value;
                    return Container(
                      margin: const EdgeInsets.only(bottom: 12),
                      decoration: BoxDecoration(color: Colors.white, borderRadius: C.radius, boxShadow: C.shadow),
                      child: InkWell(
                        borderRadius: C.radius,
                        onTap: () async { await Navigator.push(context, MaterialPageRoute(builder: (_) => DisasterDetailScreen(disaster: d))); _load(); },
                        child: Padding(padding: const EdgeInsets.all(16), child: Row(children: [
                          Container(
                            padding: const EdgeInsets.all(12),
                            decoration: BoxDecoration(color: _sevColor(d.severity).withAlpha(25), borderRadius: BorderRadius.circular(14)),
                            child: Icon(_typeIcon(d.type), color: _sevColor(d.severity), size: 26),
                          ),
                          const SizedBox(width: 14),
                          Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                            Text(d.title, style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 15, color: C.charcoal)),
                            const SizedBox(height: 4),
                            Row(children: [
                              Icon(Icons.location_on_rounded, size: 13, color: C.mist),
                              const SizedBox(width: 3),
                              Expanded(child: Text(d.locationName, style: TextStyle(color: C.mist, fontSize: 12), overflow: TextOverflow.ellipsis)),
                            ]),
                            const SizedBox(height: 8),
                            Row(children: [
                              _Badge(d.severity.toUpperCase(), _sevColor(d.severity)),
                              const SizedBox(width: 6),
                              _Badge(d.status.toUpperCase(), C.blue),
                              if (d.affectedCount > 0) ...[const SizedBox(width: 6), _Badge('${d.affectedCount} people', C.mist)],
                            ]),
                          ])),
                          Icon(Icons.chevron_right_rounded, color: C.mist.withAlpha(100)),
                        ])),
                      ),
                    ).animate().fadeIn(delay: (e.key * 60).ms, duration: 400.ms).slideX(begin: 0.03);
                  }),
              ]),
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () async { await Navigator.push(context, MaterialPageRoute(builder: (_) => const ReportScreen())); _load(); },
        backgroundColor: C.red, foregroundColor: Colors.white, elevation: 4,
        icon: const Icon(Icons.add_alert_rounded),
        label: const Text('Report', style: TextStyle(fontWeight: FontWeight.w600)),
      ),
    );
  }
}

class _Stat extends StatelessWidget {
  final String label, value; final Color color; final IconData icon;
  const _Stat({required this.label, required this.value, required this.color, required this.icon});
  @override
  Widget build(BuildContext context) => Expanded(child: Container(
    padding: const EdgeInsets.all(16),
    decoration: BoxDecoration(color: Colors.white, borderRadius: C.radius, boxShadow: C.shadow),
    child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Container(padding: const EdgeInsets.all(6), decoration: BoxDecoration(color: color.withAlpha(25), borderRadius: BorderRadius.circular(10)),
        child: Icon(icon, color: color, size: 18)),
      const SizedBox(height: 10),
      Text(value, style: TextStyle(fontSize: 24, fontWeight: FontWeight.w800, color: color)),
      Text(label, style: TextStyle(fontSize: 11, color: C.mist)),
    ]),
  ));
}

class _Badge extends StatelessWidget {
  final String text; final Color color;
  const _Badge(this.text, this.color);
  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
    decoration: BoxDecoration(color: color.withAlpha(20), borderRadius: BorderRadius.circular(8)),
    child: Text(text, style: TextStyle(color: color, fontSize: 10, fontWeight: FontWeight.w700)),
  );
}
