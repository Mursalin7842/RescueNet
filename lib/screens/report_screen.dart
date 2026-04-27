import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../main.dart';
import '../models/models.dart';
import '../services/db_service.dart';

class ReportScreen extends StatefulWidget {
  const ReportScreen({super.key});
  @override
  State<ReportScreen> createState() => _ReportScreenState();
}

class _ReportScreenState extends State<ReportScreen> {
  final _title = TextEditingController();
  final _desc = TextEditingController();
  final _location = TextEditingController();
  final _affected = TextEditingController(text: '0');
  String _type = 'earthquake';
  String _severity = 'medium';
  bool _saving = false;

  final _types = [
    ('earthquake', Icons.terrain, 'Earthquake'),
    ('flood', Icons.water, 'Flood'),
    ('fire', Icons.local_fire_department_rounded, 'Fire'),
    ('storm', Icons.thunderstorm, 'Storm'),
    ('landslide', Icons.landscape, 'Landslide'),
    ('other', Icons.warning_rounded, 'Other'),
  ];

  Future<void> _submit() async {
    if (_title.text.isEmpty || _desc.text.isEmpty || _location.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Please fill all required fields')));
      return;
    }
    setState(() => _saving = true);
    try {
      final u = await DbService().getUser();
      await DbService().addDisaster(Disaster(id: '', userId: u.$id, title: _title.text.trim(), type: _type,
          severity: _severity, description: _desc.text.trim(), locationName: _location.text.trim(),
          affectedCount: int.tryParse(_affected.text) ?? 0));
      if (mounted) { Navigator.pop(context); ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Disaster reported successfully! ⚠️'), backgroundColor: Colors.green)); }
    } catch (e) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error: $e'), backgroundColor: C.red));
    }
    if (mounted) setState(() => _saving = false);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Report Disaster')),
      body: SingleChildScrollView(padding: const EdgeInsets.all(20), child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        // Title
        _label('Disaster Title *'),
        TextField(controller: _title, decoration: const InputDecoration(hintText: 'e.g. Flood in Dhaka North', prefixIcon: Icon(Icons.title_rounded))),
        const SizedBox(height: 20),
        // Type grid
        _label('Disaster Type'),
        const SizedBox(height: 8),
        GridView.count(crossAxisCount: 3, shrinkWrap: true, physics: const NeverScrollableScrollPhysics(),
          mainAxisSpacing: 10, crossAxisSpacing: 10, childAspectRatio: 1.3,
          children: _types.map((t) => GestureDetector(
            onTap: () => setState(() => _type = t.$1),
            child: AnimatedContainer(duration: const Duration(milliseconds: 200),
              decoration: BoxDecoration(
                color: _type == t.$1 ? C.red.withAlpha(15) : Colors.white,
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: _type == t.$1 ? C.red : Colors.grey.withAlpha(40), width: _type == t.$1 ? 2 : 1),
                boxShadow: _type == t.$1 ? [BoxShadow(color: C.red.withAlpha(20), blurRadius: 10)] : [],
              ),
              child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
                Icon(t.$2, color: _type == t.$1 ? C.red : C.mist, size: 28),
                const SizedBox(height: 6),
                Text(t.$3, style: TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: _type == t.$1 ? C.red : C.mist)),
              ]),
            ),
          )).toList(),
        ),
        const SizedBox(height: 20),
        // Severity
        _label('Severity Level'),
        const SizedBox(height: 8),
        Row(children: ['low', 'medium', 'high', 'critical'].map((s) {
          final c = switch (s) { 'critical' => C.red, 'high' => C.orange, 'medium' => Colors.amber.shade700, _ => C.green };
          final selected = _severity == s;
          return Expanded(child: GestureDetector(
            onTap: () => setState(() => _severity = s),
            child: AnimatedContainer(duration: const Duration(milliseconds: 200),
              margin: const EdgeInsets.symmetric(horizontal: 3),
              padding: const EdgeInsets.symmetric(vertical: 12),
              decoration: BoxDecoration(color: selected ? c.withAlpha(20) : Colors.white, borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: selected ? c : Colors.grey.withAlpha(40), width: selected ? 2 : 1)),
              child: Text(s[0].toUpperCase() + s.substring(1), textAlign: TextAlign.center,
                  style: TextStyle(fontSize: 11, fontWeight: FontWeight.w700, color: selected ? c : C.mist)),
            ),
          ));
        }).toList()),
        const SizedBox(height: 20),
        _label('Location *'),
        TextField(controller: _location, decoration: const InputDecoration(hintText: 'Area / City / District', prefixIcon: Icon(Icons.location_on_rounded))),
        const SizedBox(height: 14),
        _label('People Affected'),
        TextField(controller: _affected, decoration: const InputDecoration(hintText: '0', prefixIcon: Icon(Icons.people_rounded)), keyboardType: TextInputType.number),
        const SizedBox(height: 14),
        _label('Description *'),
        TextField(controller: _desc, decoration: const InputDecoration(hintText: 'Describe the situation in detail...'), maxLines: 4),
        const SizedBox(height: 28),
        SizedBox(width: double.infinity, height: 52, child: ElevatedButton.icon(
          onPressed: _saving ? null : _submit,
          icon: _saving ? const SizedBox(width: 18, height: 18, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white)) : const Icon(Icons.send_rounded),
          label: Text(_saving ? 'Reporting...' : 'Submit Report', style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600)),
        )),
      ])),
    );
  }

  Widget _label(String t) => Padding(padding: const EdgeInsets.only(bottom: 6), child: Text(t, style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: C.charcoal)));
}
