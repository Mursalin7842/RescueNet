import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../main.dart';
import '../models/models.dart';
import '../services/db_service.dart';

class ResourcesScreen extends StatefulWidget {
  const ResourcesScreen({super.key});
  @override
  State<ResourcesScreen> createState() => _RS();
}

class _RS extends State<ResourcesScreen> {
  List<ResourceRequest> _res = [];
  List<Disaster> _disasters = [];
  bool _loading = true;

  @override
  void initState() { super.initState(); _load(); }

  Future<void> _load() async {
    setState(() => _loading = true);
    try {
      _res = await DbService().getAllResources();
      _disasters = await DbService().getDisasters();
    } catch (_) {}
    if (mounted) setState(() => _loading = false);
  }

  IconData _icon(String t) => switch (t) { 'food' => Icons.restaurant, 'water' => Icons.water_drop, 'medical' => Icons.medical_services, 'shelter' => Icons.home_rounded, 'clothing' => Icons.checkroom, _ => Icons.inventory_2 };
  Color _sColor(String s) => switch (s) { 'approved' => C.green, 'delivered' => C.blue, _ => C.orange };

  String _disasterName(String id) {
    final d = _disasters.where((d) => d.id == id);
    return d.isNotEmpty ? d.first.title : 'Unknown';
  }

  @override
  Widget build(BuildContext context) {
    final requested = _res.where((r) => r.status == 'requested').length;
    final approved = _res.where((r) => r.status == 'approved').length;
    final delivered = _res.where((r) => r.status == 'delivered').length;

    return Scaffold(
      appBar: AppBar(title: const Text('Resources')),
      body: RefreshIndicator(onRefresh: _load, color: C.red,
        child: _loading
            ? const Center(child: CircularProgressIndicator(color: C.red))
            : ListView(padding: const EdgeInsets.fromLTRB(20, 8, 20, 20), children: [
                Row(children: [
                  _Stat('Requested', '$requested', C.orange, Icons.pending_rounded),
                  const SizedBox(width: 10),
                  _Stat('Approved', '$approved', C.green, Icons.check_circle_rounded),
                  const SizedBox(width: 10),
                  _Stat('Delivered', '$delivered', C.blue, Icons.local_shipping_rounded),
                ]).animate().fadeIn(),
                const SizedBox(height: 16),
                // Category breakdown
                Container(padding: const EdgeInsets.all(16), decoration: BoxDecoration(color: Colors.white, borderRadius: C.radius, boxShadow: C.shadow),
                  child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                    const Text('By Category', style: TextStyle(fontWeight: FontWeight.w700, fontSize: 14, color: C.charcoal)),
                    const SizedBox(height: 12),
                    Wrap(spacing: 8, runSpacing: 8, children: ['food', 'water', 'medical', 'shelter', 'clothing', 'rescue'].map((t) {
                      final count = _res.where((r) => r.type == t).length;
                      return Container(padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                        decoration: BoxDecoration(color: C.bg, borderRadius: BorderRadius.circular(10)),
                        child: Row(mainAxisSize: MainAxisSize.min, children: [
                          Icon(_icon(t), size: 16, color: C.orange),
                          const SizedBox(width: 6),
                          Text('${t[0].toUpperCase()}${t.substring(1)}: $count', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: C.charcoal)),
                        ]),
                      );
                    }).toList()),
                  ]),
                ).animate().fadeIn(delay: 50.ms),
                const SizedBox(height: 16),
                if (_res.isEmpty)
                  Padding(padding: const EdgeInsets.only(top: 20), child: Center(child: Column(children: [
                    Icon(Icons.inventory_2_outlined, size: 64, color: C.mist.withAlpha(80)),
                    const SizedBox(height: 16),
                    Text('No resources requested', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600, color: C.mist)),
                    const SizedBox(height: 4),
                    Text('Go to a disaster detail to request resources', style: TextStyle(color: C.mist.withAlpha(150), fontSize: 13)),
                  ])))
                else
                  ..._res.asMap().entries.map((e) {
                    final r = e.value;
                    return GestureDetector(
                      onTap: () async {
                        await Navigator.push(context, MaterialPageRoute(builder: (_) => _ResourceDetail(res: r, disasterName: _disasterName(r.disasterId))));
                        _load();
                      },
                      child: Container(
                        margin: const EdgeInsets.only(bottom: 12), padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(color: Colors.white, borderRadius: C.radius, boxShadow: C.shadow),
                        child: Row(children: [
                          Container(padding: const EdgeInsets.all(12),
                            decoration: BoxDecoration(color: C.orange.withAlpha(15), borderRadius: BorderRadius.circular(14)),
                            child: Icon(_icon(r.type), color: C.orange, size: 24)),
                          const SizedBox(width: 14),
                          Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                            Text('${r.type[0].toUpperCase()}${r.type.substring(1)}', style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 15, color: C.charcoal)),
                            const SizedBox(height: 2),
                            Text('Qty: ${r.quantity} • ${_disasterName(r.disasterId)}', style: TextStyle(color: C.mist, fontSize: 12)),
                            if (r.notes != null && r.notes!.isNotEmpty)
                              Padding(padding: const EdgeInsets.only(top: 2), child: Text(r.notes!, style: TextStyle(color: C.mist, fontSize: 11), maxLines: 1, overflow: TextOverflow.ellipsis)),
                            const SizedBox(height: 6),
                            Container(padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                              decoration: BoxDecoration(color: _sColor(r.status).withAlpha(20), borderRadius: BorderRadius.circular(8)),
                              child: Text(r.status.toUpperCase(), style: TextStyle(fontSize: 10, fontWeight: FontWeight.w700, color: _sColor(r.status)))),
                          ])),
                          Icon(Icons.chevron_right_rounded, color: C.mist.withAlpha(100)),
                        ]),
                      ),
                    ).animate().fadeIn(delay: (e.key * 60).ms, duration: 400.ms);
                  }),
              ]),
      ),
    );
  }
}

// ── Resource Detail Page ──
class _ResourceDetail extends StatefulWidget {
  final ResourceRequest res;
  final String disasterName;
  const _ResourceDetail({required this.res, required this.disasterName});
  @override
  State<_ResourceDetail> createState() => _RDState();
}

class _RDState extends State<_ResourceDetail> {
  late ResourceRequest _r;

  @override
  void initState() { super.initState(); _r = widget.res; }

  IconData _icon(String t) => switch (t) { 'food' => Icons.restaurant, 'water' => Icons.water_drop, 'medical' => Icons.medical_services, 'shelter' => Icons.home_rounded, 'clothing' => Icons.checkroom, _ => Icons.inventory_2 };
  Color _sColor(String s) => switch (s) { 'approved' => C.green, 'delivered' => C.blue, _ => C.orange };

  Future<void> _updateStatus(String status) async {
    try {
      await DbService().updateResource(_r.id, {'status': status});
      setState(() => _r = ResourceRequest(id: _r.id, disasterId: _r.disasterId, userId: _r.userId, type: _r.type, quantity: _r.quantity, status: status, notes: _r.notes, createdAt: _r.createdAt));
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Status → $status'), backgroundColor: C.green));
    } catch (_) {}
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('${_r.type[0].toUpperCase()}${_r.type.substring(1)} Request')),
      body: ListView(padding: const EdgeInsets.all(20), children: [
        // Header
        Container(padding: const EdgeInsets.all(24), decoration: BoxDecoration(color: Colors.white, borderRadius: C.radius, boxShadow: C.shadow),
          child: Column(children: [
            Container(padding: const EdgeInsets.all(20), decoration: BoxDecoration(color: C.orange.withAlpha(15), shape: BoxShape.circle),
              child: Icon(_icon(_r.type), color: C.orange, size: 40)),
            const SizedBox(height: 16),
            Text('${_r.type[0].toUpperCase()}${_r.type.substring(1)}', style: TextStyle(fontSize: 22, fontWeight: FontWeight.w700, color: C.charcoal)),
            const SizedBox(height: 6),
            Container(padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 5),
              decoration: BoxDecoration(color: _sColor(_r.status).withAlpha(20), borderRadius: BorderRadius.circular(10)),
              child: Text(_r.status.toUpperCase(), style: TextStyle(fontWeight: FontWeight.w700, fontSize: 13, color: _sColor(_r.status)))),
          ]),
        ).animate().fadeIn(duration: 400.ms),
        const SizedBox(height: 16),
        // Details
        Container(padding: const EdgeInsets.all(16), decoration: BoxDecoration(color: Colors.white, borderRadius: C.radius, boxShadow: C.shadow),
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            const Text('Details', style: TextStyle(fontWeight: FontWeight.w700, fontSize: 15, color: C.charcoal)),
            const SizedBox(height: 12),
            _info(Icons.numbers_rounded, 'Quantity', '${_r.quantity}'),
            _info(Icons.warning_rounded, 'Disaster', widget.disasterName),
            if (_r.notes != null && _r.notes!.isNotEmpty) _info(Icons.notes_rounded, 'Notes', _r.notes!),
            if (_r.createdAt != null) _info(Icons.calendar_today_rounded, 'Requested', _r.createdAt!.substring(0, 16)),
          ]),
        ).animate().fadeIn(delay: 100.ms),
        const SizedBox(height: 16),
        // Status actions
        Container(padding: const EdgeInsets.all(16), decoration: BoxDecoration(color: Colors.white, borderRadius: C.radius, boxShadow: C.shadow),
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            const Text('Update Status', style: TextStyle(fontWeight: FontWeight.w700, fontSize: 15, color: C.charcoal)),
            const SizedBox(height: 14),
            Row(children: [
              _StatusBtn('Requested', Icons.pending_rounded, C.orange, () => _updateStatus('requested'), _r.status == 'requested'),
              const SizedBox(width: 8),
              _StatusBtn('Approved', Icons.check_circle_rounded, C.green, () => _updateStatus('approved'), _r.status == 'approved'),
              const SizedBox(width: 8),
              _StatusBtn('Delivered', Icons.local_shipping_rounded, C.blue, () => _updateStatus('delivered'), _r.status == 'delivered'),
            ]),
          ]),
        ).animate().fadeIn(delay: 200.ms),
      ]),
    );
  }

  Widget _info(IconData i, String l, String v) => Padding(padding: const EdgeInsets.only(bottom: 10),
    child: Row(children: [Icon(i, size: 18, color: C.mist), const SizedBox(width: 10), Text('$l: ', style: TextStyle(color: C.mist, fontSize: 13)), Expanded(child: Text(v, style: TextStyle(fontWeight: FontWeight.w600, color: C.charcoal, fontSize: 13)))]));
}

class _StatusBtn extends StatelessWidget {
  final String label; final IconData icon; final Color color; final VoidCallback onTap; final bool active;
  const _StatusBtn(this.label, this.icon, this.color, this.onTap, this.active);
  @override
  Widget build(BuildContext context) => Expanded(child: GestureDetector(onTap: onTap, child: AnimatedContainer(
    duration: const Duration(milliseconds: 200), padding: const EdgeInsets.symmetric(vertical: 14),
    decoration: BoxDecoration(color: active ? color.withAlpha(20) : C.bg, borderRadius: BorderRadius.circular(12),
        border: Border.all(color: active ? color : Colors.transparent, width: 2)),
    child: Column(children: [Icon(icon, color: active ? color : C.mist, size: 22), const SizedBox(height: 4),
      Text(label, style: TextStyle(fontSize: 10, fontWeight: FontWeight.w700, color: active ? color : C.mist))]),
  )));
}

class _Stat extends StatelessWidget {
  final String label, value; final Color color; final IconData icon;
  const _Stat(this.label, this.value, this.color, this.icon);
  @override
  Widget build(BuildContext context) => Expanded(child: Container(
    padding: const EdgeInsets.all(16), decoration: BoxDecoration(color: Colors.white, borderRadius: C.radius, boxShadow: C.shadow),
    child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Container(padding: const EdgeInsets.all(6), decoration: BoxDecoration(color: color.withAlpha(20), borderRadius: BorderRadius.circular(10)),
        child: Icon(icon, color: color, size: 18)),
      const SizedBox(height: 8),
      Text(value, style: TextStyle(fontSize: 22, fontWeight: FontWeight.w800, color: color)),
      Text(label, style: TextStyle(fontSize: 11, color: C.mist)),
    ]),
  ));
}
