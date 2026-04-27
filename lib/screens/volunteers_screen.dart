import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:url_launcher/url_launcher.dart';
import '../main.dart';
import '../models/models.dart';
import '../services/db_service.dart';

class VolunteersScreen extends StatefulWidget {
  const VolunteersScreen({super.key});
  @override
  State<VolunteersScreen> createState() => _VS();
}

class _VS extends State<VolunteersScreen> {
  List<Volunteer> _vols = [];
  List<Disaster> _disasters = [];
  bool _loading = true;

  @override
  void initState() { super.initState(); _load(); }

  Future<void> _load() async {
    setState(() => _loading = true);
    try {
      _vols = await DbService().getVolunteers();
      _disasters = await DbService().getDisasters();
    } catch (_) {}
    if (mounted) setState(() => _loading = false);
  }

  Future<void> _register() async {
    final nameC = TextEditingController();
    final phoneC = TextEditingController();
    final skillsC = TextEditingController();
    final ok = await showDialog<bool>(context: context, builder: (ctx) => AlertDialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      title: Row(children: [Icon(Icons.volunteer_activism, color: C.green), const SizedBox(width: 10), const Text('Register')]),
      content: Column(mainAxisSize: MainAxisSize.min, children: [
        TextField(controller: nameC, decoration: const InputDecoration(labelText: 'Full Name *', prefixIcon: Icon(Icons.person_rounded))),
        const SizedBox(height: 12),
        TextField(controller: phoneC, decoration: const InputDecoration(labelText: 'Phone *', prefixIcon: Icon(Icons.phone_rounded)), keyboardType: TextInputType.phone),
        const SizedBox(height: 12),
        TextField(controller: skillsC, decoration: const InputDecoration(labelText: 'Skills *', hintText: 'First Aid, Driving...', prefixIcon: Icon(Icons.build_rounded))),
      ]),
      actions: [TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Cancel')),
        ElevatedButton.icon(onPressed: () => Navigator.pop(ctx, true), icon: const Icon(Icons.check), label: const Text('Register'))],
    ));
    if (ok == true && nameC.text.isNotEmpty && phoneC.text.isNotEmpty) {
      try {
        final u = await DbService().getUser();
        await DbService().addVolunteer(Volunteer(id: '', userId: u.$id, fullName: nameC.text.trim(), phone: phoneC.text.trim(), skills: skillsC.text.trim()));
        _load();
        if (mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Registered! 🙌'), backgroundColor: Colors.green));
      } catch (_) {}
    }
  }

  @override
  Widget build(BuildContext context) {
    final available = _vols.where((v) => v.isAvailable).length;
    return Scaffold(
      appBar: AppBar(title: const Text('Volunteers')),
      body: RefreshIndicator(onRefresh: _load, color: C.red,
        child: _loading
            ? const Center(child: CircularProgressIndicator(color: C.red))
            : ListView(padding: const EdgeInsets.fromLTRB(20, 8, 20, 100), children: [
                Row(children: [
                  _Stat('Total', '${_vols.length}', C.blue, Icons.people_rounded),
                  const SizedBox(width: 10),
                  _Stat('Available', '$available', C.green, Icons.check_circle_rounded),
                  const SizedBox(width: 10),
                  _Stat('Deployed', '${_vols.length - available}', C.orange, Icons.assignment_ind_rounded),
                ]).animate().fadeIn(),
                const SizedBox(height: 20),
                // CTA
                Container(padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(color: C.green.withAlpha(15), borderRadius: C.radius, border: Border.all(color: C.green.withAlpha(40))),
                  child: Row(children: [
                    Icon(Icons.volunteer_activism, color: C.green, size: 36), const SizedBox(width: 16),
                    Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                      const Text('Join the Rescue Team', style: TextStyle(fontWeight: FontWeight.w700, fontSize: 16, color: C.charcoal)),
                      Text('Register to help during disasters', style: TextStyle(color: C.mist, fontSize: 12)),
                    ])),
                    ElevatedButton(onPressed: _register, style: ElevatedButton.styleFrom(backgroundColor: C.green), child: const Text('Join')),
                  ]),
                ).animate().fadeIn(delay: 100.ms),
                const SizedBox(height: 20),
                if (_vols.isEmpty)
                  Padding(padding: const EdgeInsets.only(top: 40), child: Center(child: Column(children: [
                    Icon(Icons.people_outline_rounded, size: 64, color: C.mist.withAlpha(80)),
                    const SizedBox(height: 16),
                    Text('No volunteers yet', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600, color: C.mist)),
                  ])))
                else
                  ..._vols.asMap().entries.map((e) {
                    final v = e.value;
                    return GestureDetector(
                      onTap: () async {
                        await Navigator.push(context, MaterialPageRoute(builder: (_) => _VolunteerDetail(vol: v, disasters: _disasters)));
                        _load();
                      },
                      child: Container(
                        margin: const EdgeInsets.only(bottom: 12), padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(color: Colors.white, borderRadius: C.radius, boxShadow: C.shadow),
                        child: Row(children: [
                          CircleAvatar(radius: 24, backgroundColor: v.isAvailable ? C.green.withAlpha(20) : C.orange.withAlpha(20),
                            child: Text(v.fullName.isNotEmpty ? v.fullName[0] : '?', style: TextStyle(fontSize: 20, fontWeight: FontWeight.w700, color: v.isAvailable ? C.green : C.orange))),
                          const SizedBox(width: 14),
                          Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                            Text(v.fullName, style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 15, color: C.charcoal)),
                            const SizedBox(height: 2),
                            Row(children: [Icon(Icons.phone, size: 12, color: C.mist), const SizedBox(width: 4), Text(v.phone, style: TextStyle(color: C.mist, fontSize: 12))]),
                            const SizedBox(height: 4),
                            Wrap(spacing: 4, runSpacing: 4, children: v.skills.split(',').where((s) => s.trim().isNotEmpty).map((s) => Container(
                              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                              decoration: BoxDecoration(color: C.blue.withAlpha(15), borderRadius: BorderRadius.circular(8)),
                              child: Text(s.trim(), style: TextStyle(fontSize: 10, color: C.blue, fontWeight: FontWeight.w600)),
                            )).toList()),
                          ])),
                          Column(children: [
                            Container(padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                              decoration: BoxDecoration(color: (v.isAvailable ? C.green : C.orange).withAlpha(15), borderRadius: BorderRadius.circular(8)),
                              child: Text(v.isAvailable ? 'Available' : 'Deployed', style: TextStyle(fontSize: 11, fontWeight: FontWeight.w700, color: v.isAvailable ? C.green : C.orange))),
                            const SizedBox(height: 6),
                            Icon(Icons.chevron_right_rounded, color: C.mist.withAlpha(100)),
                          ]),
                        ]),
                      ),
                    ).animate().fadeIn(delay: (e.key * 60).ms, duration: 400.ms);
                  }),
              ]),
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _register, backgroundColor: C.green, foregroundColor: Colors.white,
        icon: const Icon(Icons.person_add_rounded), label: const Text('Register', style: TextStyle(fontWeight: FontWeight.w600)),
      ),
    );
  }
}

// ── Volunteer Detail Page ──
class _VolunteerDetail extends StatefulWidget {
  final Volunteer vol;
  final List<Disaster> disasters;
  const _VolunteerDetail({required this.vol, required this.disasters});
  @override
  State<_VolunteerDetail> createState() => _VDState();
}

class _VDState extends State<_VolunteerDetail> {
  late Volunteer _v;

  @override
  void initState() { super.initState(); _v = widget.vol; }

  String _disasterName(String? id) {
    if (id == null) return 'None';
    final d = widget.disasters.where((d) => d.id == id);
    return d.isNotEmpty ? d.first.title : id;
  }

  Future<void> _call() async {
    final uri = Uri(scheme: 'tel', path: _v.phone);
    try { await launchUrl(uri); } catch (_) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Could not call ${_v.phone}')));
    }
  }

  Future<void> _toggleAvailability() async {
    try {
      await DbService().updateVolunteer(_v.id, {'isAvailable': !_v.isAvailable, if (!_v.isAvailable) 'assignedDisasterId': null});
      setState(() => _v = Volunteer(id: _v.id, userId: _v.userId, fullName: _v.fullName, phone: _v.phone, skills: _v.skills,
          isAvailable: !_v.isAvailable, assignedDisasterId: _v.isAvailable ? null : _v.assignedDisasterId, createdAt: _v.createdAt));
    } catch (_) {}
  }

  Future<void> _assignToDisaster() async {
    final active = widget.disasters.where((d) => d.status != 'resolved').toList();
    if (active.isEmpty) { ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('No active disasters'))); return; }
    final selected = await showDialog<Disaster>(context: context, builder: (ctx) => SimpleDialog(
      title: const Text('Assign to Disaster'), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      children: active.map((d) => SimpleDialogOption(
        onPressed: () => Navigator.pop(ctx, d),
        child: ListTile(leading: Icon(Icons.warning_rounded, color: C.orange), title: Text(d.title), subtitle: Text(d.locationName, style: TextStyle(fontSize: 12, color: C.mist))),
      )).toList(),
    ));
    if (selected != null) {
      try {
        await DbService().updateVolunteer(_v.id, {'isAvailable': false, 'assignedDisasterId': selected.id});
        setState(() => _v = Volunteer(id: _v.id, userId: _v.userId, fullName: _v.fullName, phone: _v.phone, skills: _v.skills,
            isAvailable: false, assignedDisasterId: selected.id, createdAt: _v.createdAt));
        if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Assigned to ${selected.title}'), backgroundColor: C.green));
      } catch (_) {}
    }
  }

  Future<void> _requestService() async {
    final noteC = TextEditingController();
    String type = 'rescue';
    final ok = await showDialog<bool>(context: context, builder: (ctx) => StatefulBuilder(builder: (ctx, setD) => AlertDialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      title: Text('Request ${_v.fullName}\'s Service'),
      content: Column(mainAxisSize: MainAxisSize.min, children: [
        Wrap(spacing: 6, runSpacing: 6, children: ['rescue', 'medical', 'transport', 'logistics', 'other'].map((t) => ChoiceChip(
          label: Text(t[0].toUpperCase() + t.substring(1)), selected: type == t, selectedColor: C.green.withAlpha(40),
          onSelected: (_) => setD(() => type = t),
        )).toList()),
        const SizedBox(height: 12),
        TextField(controller: noteC, decoration: const InputDecoration(labelText: 'Details'), maxLines: 2),
      ]),
      actions: [TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Cancel')),
        ElevatedButton(onPressed: () => Navigator.pop(ctx, true), style: ElevatedButton.styleFrom(backgroundColor: C.green), child: const Text('Send Request'))],
    )));
    if (ok == true && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Service request sent to ${_v.fullName}!'), backgroundColor: C.green));
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(_v.fullName)),
      body: ListView(padding: const EdgeInsets.all(20), children: [
        // Profile card
        Container(padding: const EdgeInsets.all(24), decoration: BoxDecoration(color: Colors.white, borderRadius: C.radius, boxShadow: C.shadow),
          child: Column(children: [
            CircleAvatar(radius: 40, backgroundColor: (_v.isAvailable ? C.green : C.orange).withAlpha(20),
              child: Text(_v.fullName.isNotEmpty ? _v.fullName[0] : '?', style: TextStyle(fontSize: 32, fontWeight: FontWeight.w800, color: _v.isAvailable ? C.green : C.orange))),
            const SizedBox(height: 14),
            Text(_v.fullName, style: TextStyle(fontSize: 22, fontWeight: FontWeight.w700, color: C.charcoal)),
            const SizedBox(height: 4),
            Container(padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
              decoration: BoxDecoration(color: (_v.isAvailable ? C.green : C.orange).withAlpha(20), borderRadius: BorderRadius.circular(10)),
              child: Text(_v.isAvailable ? '● Available' : '● Deployed', style: TextStyle(fontWeight: FontWeight.w700, fontSize: 13, color: _v.isAvailable ? C.green : C.orange))),
          ]),
        ).animate().fadeIn(duration: 400.ms),
        const SizedBox(height: 16),
        // Info card
        Container(padding: const EdgeInsets.all(16), decoration: BoxDecoration(color: Colors.white, borderRadius: C.radius, boxShadow: C.shadow),
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            const Text('Details', style: TextStyle(fontWeight: FontWeight.w700, fontSize: 15, color: C.charcoal)),
            const SizedBox(height: 12),
            _infoRow(Icons.phone_rounded, 'Phone', _v.phone, true),
            _infoRow(Icons.build_rounded, 'Skills', _v.skills, false),
            _infoRow(Icons.assignment_rounded, 'Assigned To', _disasterName(_v.assignedDisasterId), false),
            if (_v.createdAt != null) _infoRow(Icons.calendar_today_rounded, 'Registered', _v.createdAt!.substring(0, 10), false),
          ]),
        ).animate().fadeIn(delay: 100.ms),
        const SizedBox(height: 16),
        // Action buttons
        Container(padding: const EdgeInsets.all(16), decoration: BoxDecoration(color: Colors.white, borderRadius: C.radius, boxShadow: C.shadow),
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            const Text('Actions', style: TextStyle(fontWeight: FontWeight.w700, fontSize: 15, color: C.charcoal)),
            const SizedBox(height: 14),
            Row(children: [
              _ActionBtn('Call', Icons.phone_rounded, C.green, _call),
              const SizedBox(width: 10),
              _ActionBtn('Request', Icons.send_rounded, C.blue, _requestService),
              const SizedBox(width: 10),
              _ActionBtn('Assign', Icons.assignment_ind_rounded, C.orange, _assignToDisaster),
            ]),
            const SizedBox(height: 12),
            SizedBox(width: double.infinity, height: 46, child: OutlinedButton.icon(
              onPressed: _toggleAvailability,
              icon: Icon(_v.isAvailable ? Icons.pause_circle_rounded : Icons.play_circle_rounded, color: _v.isAvailable ? C.orange : C.green),
              label: Text(_v.isAvailable ? 'Mark as Deployed' : 'Mark as Available', style: TextStyle(color: _v.isAvailable ? C.orange : C.green, fontWeight: FontWeight.w600)),
              style: OutlinedButton.styleFrom(side: BorderSide(color: (_v.isAvailable ? C.orange : C.green).withAlpha(60)), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12))),
            )),
          ]),
        ).animate().fadeIn(delay: 200.ms),
      ]),
    );
  }

  Widget _infoRow(IconData i, String l, String v, bool tappable) => Padding(padding: const EdgeInsets.only(bottom: 10),
    child: GestureDetector(
      onTap: tappable ? _call : null,
      child: Row(children: [
        Icon(i, size: 18, color: C.mist), const SizedBox(width: 10),
        Text('$l: ', style: TextStyle(color: C.mist, fontSize: 13)),
        Expanded(child: Text(v, style: TextStyle(fontWeight: FontWeight.w600, color: tappable ? C.blue : C.charcoal, fontSize: 13,
            decoration: tappable ? TextDecoration.underline : null))),
      ]),
    ),
  );
}

class _ActionBtn extends StatelessWidget {
  final String label; final IconData icon; final Color color; final VoidCallback onTap;
  const _ActionBtn(this.label, this.icon, this.color, this.onTap);
  @override
  Widget build(BuildContext context) => Expanded(child: GestureDetector(onTap: onTap, child: Container(
    padding: const EdgeInsets.symmetric(vertical: 16),
    decoration: BoxDecoration(color: color.withAlpha(15), borderRadius: BorderRadius.circular(14)),
    child: Column(children: [Icon(icon, color: color, size: 26), const SizedBox(height: 6), Text(label, style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: color))]),
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
