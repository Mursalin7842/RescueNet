import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../main.dart';
import '../models/models.dart';
import '../services/db_service.dart';

class DisasterDetailScreen extends StatefulWidget {
  final Disaster disaster;
  const DisasterDetailScreen({super.key, required this.disaster});
  @override
  State<DisasterDetailScreen> createState() => _DDS();
}

class _DDS extends State<DisasterDetailScreen> {
  late Disaster _d;
  List<ResourceRequest> _res = [];
  List<Volunteer> _vols = [];
  bool _loading = true;

  @override
  void initState() { super.initState(); _d = widget.disaster; _loadAll(); }

  Future<void> _loadAll() async {
    try {
      _res = await DbService().getResources(_d.id);
      _vols = await DbService().getVolunteers();
    } catch (_) {}
    if (mounted) setState(() => _loading = false);
  }

  Color _sc(String s) => switch (s) { 'critical' => C.red, 'high' => C.orange, 'medium' => Colors.amber.shade700, _ => C.green };
  IconData _ti(String t) => switch (t) { 'earthquake' => Icons.terrain, 'flood' => Icons.water, 'fire' => Icons.local_fire_department_rounded, 'storm' => Icons.thunderstorm, _ => Icons.warning_rounded };

  Future<void> _updateStatus(String s) async {
    try {
      await DbService().updateDisaster(_d.id, {'status': s});
      setState(() => _d = Disaster(id: _d.id, userId: _d.userId, title: _d.title, type: _d.type, severity: _d.severity, description: _d.description, locationName: _d.locationName, status: s, affectedCount: _d.affectedCount, createdAt: _d.createdAt));
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Status → $s'), backgroundColor: C.green));
    } catch (_) {}
  }

  Future<void> _assignVolunteer(Volunteer v) async {
    try {
      await DbService().updateVolunteer(v.id, {'isAvailable': false, 'assignedDisasterId': _d.id});
      _loadAll();
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('${v.fullName} assigned!'), backgroundColor: C.green));
    } catch (_) {}
  }

  Future<void> _requestResource() async {
    String type = 'food'; int qty = 1; String notes = '';
    final ok = await showDialog<bool>(context: context, builder: (ctx) => StatefulBuilder(builder: (ctx, setD) => AlertDialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      title: const Text('Request Resource'), content: Column(mainAxisSize: MainAxisSize.min, children: [
        Wrap(spacing: 6, runSpacing: 6, children: ['food', 'water', 'medical', 'shelter', 'clothing', 'rescue'].map((t) => ChoiceChip(
          label: Text(t[0].toUpperCase() + t.substring(1)), selected: type == t,
          selectedColor: C.red.withAlpha(40), onSelected: (_) => setD(() => type = t),
        )).toList()),
        const SizedBox(height: 12),
        TextField(decoration: const InputDecoration(labelText: 'Quantity'), keyboardType: TextInputType.number, onChanged: (v) => qty = int.tryParse(v) ?? 1),
        const SizedBox(height: 8),
        TextField(decoration: const InputDecoration(labelText: 'Notes (optional)'), onChanged: (v) => notes = v),
      ]), actions: [TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Cancel')),
        ElevatedButton(onPressed: () => Navigator.pop(ctx, true), child: const Text('Request'))],
    )));
    if (ok == true) {
      try { final u = await DbService().getUser(); await DbService().addResource(ResourceRequest(id: '', disasterId: _d.id, userId: u.$id, type: type, quantity: qty, notes: notes.isEmpty ? null : notes)); _loadAll(); } catch (_) {}
    }
  }

  @override
  Widget build(BuildContext context) {
    final available = _vols.where((v) => v.isAvailable).toList();
    final assigned = _vols.where((v) => v.assignedDisasterId == _d.id).toList();
    return Scaffold(
      appBar: AppBar(title: Text(_d.title)),
      body: ListView(padding: const EdgeInsets.all(20), children: [
        // Hero card
        Container(padding: const EdgeInsets.all(20), decoration: BoxDecoration(color: Colors.white, borderRadius: C.radius, boxShadow: C.shadow),
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Row(children: [
              Container(padding: const EdgeInsets.all(14), decoration: BoxDecoration(color: _sc(_d.severity).withAlpha(20), borderRadius: BorderRadius.circular(16)),
                child: Icon(_ti(_d.type), color: _sc(_d.severity), size: 32)),
              const SizedBox(width: 16),
              Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Text(_d.title, style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w800, color: C.charcoal)),
                const SizedBox(height: 6),
                Row(children: [_Badge(_d.severity.toUpperCase(), _sc(_d.severity)), const SizedBox(width: 6), _Badge(_d.status.toUpperCase(), C.blue)]),
              ])),
            ]),
            const Divider(height: 28),
            _info(Icons.location_on_rounded, _d.locationName),
            _info(Icons.people_rounded, '${_d.affectedCount} people affected'),
            if (_d.createdAt != null) _info(Icons.access_time_rounded, 'Reported: ${_d.createdAt!.substring(0, 16)}'),
          ]),
        ).animate().fadeIn(duration: 400.ms),
        const SizedBox(height: 16),
        // Status actions
        Container(padding: const EdgeInsets.all(16), decoration: BoxDecoration(color: Colors.white, borderRadius: C.radius, boxShadow: C.shadow),
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            const Text('Update Status', style: TextStyle(fontWeight: FontWeight.w700, fontSize: 15, color: C.charcoal)),
            const SizedBox(height: 12),
            Row(children: [
              _StatusBtn('Reported', Icons.flag_rounded, C.orange, () => _updateStatus('reported'), _d.status == 'reported'),
              const SizedBox(width: 8),
              _StatusBtn('Responding', Icons.emergency_rounded, C.blue, () => _updateStatus('responding'), _d.status == 'responding'),
              const SizedBox(width: 8),
              _StatusBtn('Resolved', Icons.check_circle_rounded, C.green, () => _updateStatus('resolved'), _d.status == 'resolved'),
            ]),
          ]),
        ).animate().fadeIn(delay: 100.ms),
        const SizedBox(height: 16),
        // Description
        Container(padding: const EdgeInsets.all(16), decoration: BoxDecoration(color: Colors.white, borderRadius: C.radius, boxShadow: C.shadow),
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            const Text('Description', style: TextStyle(fontWeight: FontWeight.w700, fontSize: 15, color: C.charcoal)),
            const SizedBox(height: 8),
            Text(_d.description, style: TextStyle(color: C.mist, height: 1.6)),
          ]),
        ),
        const SizedBox(height: 16),
        // Assigned volunteers
        _sectionHeader('Assigned Volunteers', Icons.people_rounded, '${assigned.length}'),
        if (assigned.isEmpty) _empty('No volunteers assigned yet')
        else ...assigned.map((v) => _volCard(v, false)),
        // Available to assign
        if (available.isNotEmpty) ...[
          const SizedBox(height: 12),
          Text('Available Volunteers', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: C.mist)),
          const SizedBox(height: 8),
          ...available.map((v) => _volCard(v, true)),
        ],
        const SizedBox(height: 16),
        // Resources
        _sectionHeader('Resources', Icons.inventory_2_rounded, '${_res.length}', trailing: TextButton.icon(
          onPressed: _requestResource, icon: const Icon(Icons.add, size: 18), label: const Text('Request'), style: TextButton.styleFrom(foregroundColor: C.red))),
        if (_res.isEmpty) _empty('No resources requested yet')
        else ..._res.map((r) => Container(
          margin: const EdgeInsets.only(bottom: 8), padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(14), boxShadow: C.shadow),
          child: Row(children: [
            Icon(_rIcon(r.type), color: C.orange, size: 22),
            const SizedBox(width: 12),
            Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text('${r.type[0].toUpperCase()}${r.type.substring(1)} × ${r.quantity}', style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 14)),
              if (r.notes != null) Text(r.notes!, style: TextStyle(color: C.mist, fontSize: 12)),
            ])),
            _Badge(r.status.toUpperCase(), r.status == 'delivered' ? C.green : r.status == 'approved' ? C.blue : C.orange),
          ]),
        )),
      ]),
    );
  }

  Widget _volCard(Volunteer v, bool canAssign) => Container(
    margin: const EdgeInsets.only(bottom: 8), padding: const EdgeInsets.all(12),
    decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(14), boxShadow: C.shadow),
    child: Row(children: [
      CircleAvatar(backgroundColor: C.green.withAlpha(20), radius: 20, child: Text(v.fullName.isNotEmpty ? v.fullName[0] : '?', style: TextStyle(color: C.green, fontWeight: FontWeight.w700))),
      const SizedBox(width: 12),
      Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Text(v.fullName, style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 14)),
        Text(v.skills, style: TextStyle(color: C.mist, fontSize: 12)),
      ])),
      if (canAssign) TextButton(onPressed: () => _assignVolunteer(v), child: const Text('Assign', style: TextStyle(color: Colors.green, fontWeight: FontWeight.w700))),
    ]),
  );

  Widget _info(IconData i, String t) => Padding(padding: const EdgeInsets.only(top: 8), child: Row(children: [Icon(i, size: 16, color: C.mist), const SizedBox(width: 8), Expanded(child: Text(t, style: TextStyle(color: C.mist, fontSize: 13)))]));
  Widget _empty(String t) => Padding(padding: const EdgeInsets.symmetric(vertical: 16), child: Center(child: Text(t, style: TextStyle(color: C.mist.withAlpha(120), fontSize: 13))));
  Widget _sectionHeader(String t, IconData i, String count, {Widget? trailing}) => Padding(padding: const EdgeInsets.only(bottom: 10),
    child: Row(children: [Icon(i, size: 18, color: C.charcoal), const SizedBox(width: 8), Text(t, style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 15)), const SizedBox(width: 6), _Badge(count, C.mist), const Spacer(), if (trailing != null) trailing]));
  IconData _rIcon(String t) => switch (t) { 'food' => Icons.restaurant, 'water' => Icons.water_drop, 'medical' => Icons.medical_services, 'shelter' => Icons.home, _ => Icons.inventory_2 };
}

class _Badge extends StatelessWidget {
  final String text; final Color color;
  const _Badge(this.text, this.color);
  @override
  Widget build(BuildContext context) => Container(padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
    decoration: BoxDecoration(color: color.withAlpha(20), borderRadius: BorderRadius.circular(8)),
    child: Text(text, style: TextStyle(color: color, fontSize: 10, fontWeight: FontWeight.w700)));
}

class _StatusBtn extends StatelessWidget {
  final String label; final IconData icon; final Color color; final VoidCallback onTap; final bool active;
  const _StatusBtn(this.label, this.icon, this.color, this.onTap, this.active);
  @override
  Widget build(BuildContext context) => Expanded(child: GestureDetector(onTap: onTap, child: AnimatedContainer(
    duration: const Duration(milliseconds: 200), padding: const EdgeInsets.symmetric(vertical: 12),
    decoration: BoxDecoration(color: active ? color.withAlpha(20) : C.bg, borderRadius: BorderRadius.circular(12),
        border: Border.all(color: active ? color : Colors.transparent, width: 2)),
    child: Column(children: [Icon(icon, color: active ? color : C.mist, size: 22), const SizedBox(height: 4),
      Text(label, style: TextStyle(fontSize: 10, fontWeight: FontWeight.w700, color: active ? color : C.mist))]),
  )));
}
