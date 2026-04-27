import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:image_picker/image_picker.dart';
import 'package:appwrite/appwrite.dart';
import '../main.dart';
import '../services/db_service.dart';
import '../config/app_config.dart';
import '../models/models.dart';
import 'login_screen.dart';
import 'shell_screen.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});
  @override
  State<ProfileScreen> createState() => _PS();
}

class _PS extends State<ProfileScreen> {
  dynamic _user;
  List<Disaster> _myDisasters = [];
  List<Volunteer> _myVol = [];
  bool _loading = true;
  String? _photoUrl;

  @override
  void initState() { super.initState(); _load(); }

  Future<void> _load() async {
    try {
      _user = await DbService().getUser();
      if (_user != null) {
        final all = await DbService().getDisasters();
        _myDisasters = all.where((d) => d.userId == _user.$id).toList();
        final vols = await DbService().getVolunteers();
        _myVol = vols.where((v) => v.userId == _user.$id).toList();
        // Try loading profile photo from prefs
        if (_user.prefs?.data['photoFileId'] != null) {
          _photoUrl = '${AppConfig.endpoint}/storage/buckets/${AppConfig.profileBucket}/files/${_user.prefs.data['photoFileId']}/view?project=${AppConfig.projectId}';
        }
      }
    } catch (e) { debugPrint('Profile load: $e'); }
    if (mounted) setState(() => _loading = false);
  }

  Future<void> _pickImage() async {
    final picker = ImagePicker();
    final img = await picker.pickImage(source: ImageSource.gallery, maxWidth: 512);
    if (img == null) return;

    try {
      final storage = Storage(DbService().client);
      final file = await storage.createFile(
        bucketId: AppConfig.profileBucket,
        fileId: ID.unique(),
        file: InputFile.fromPath(path: img.path, filename: 'profile_${_user.$id}.jpg'),
      );
      // Save fileId in user prefs
      await DbService().account.updatePrefs(prefs: {'photoFileId': file.$id});
      setState(() {
        _photoUrl = '${AppConfig.endpoint}/storage/buckets/${AppConfig.profileBucket}/files/${file.$id}/view?project=${AppConfig.projectId}';
      });
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Profile photo updated! 📸'), backgroundColor: Colors.green));
    } catch (e) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Upload failed: $e'), backgroundColor: C.red));
    }
  }

  Future<void> _logout() async {
    final ok = await showDialog<bool>(context: context, builder: (ctx) => AlertDialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      title: const Text('Logout?'),
      content: const Text('You can login with another account after logging out.'),
      actions: [
        TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Cancel')),
        ElevatedButton(onPressed: () => Navigator.pop(ctx, true), style: ElevatedButton.styleFrom(backgroundColor: C.red), child: const Text('Logout')),
      ],
    ));
    if (ok == true) {
      try { await DbService().logout(); } catch (_) {}
      DbService().init(); // Reinitialize clean client
      if (mounted) {
        Navigator.pushAndRemoveUntil(context, MaterialPageRoute(builder: (c1) => LoginScreen(onLogin: () {
          Navigator.pushAndRemoveUntil(c1, MaterialPageRoute(builder: (c2) => const ShellScreen()), (r) => false);
        })), (r) => false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('My Profile')),
      body: _loading
          ? const Center(child: CircularProgressIndicator(color: C.red))
          : RefreshIndicator(onRefresh: _load, color: C.red, child: ListView(padding: const EdgeInsets.fromLTRB(20, 8, 20, 20), children: [
              // Profile card
              Container(
                padding: const EdgeInsets.all(24),
                decoration: BoxDecoration(color: Colors.white, borderRadius: C.radius, boxShadow: C.shadow),
                child: Column(children: [
                  GestureDetector(
                    onTap: _pickImage,
                    child: Stack(children: [
                      CircleAvatar(radius: 48,
                        backgroundColor: C.red.withAlpha(20),
                        backgroundImage: _photoUrl != null ? NetworkImage(_photoUrl!) : null,
                        child: _photoUrl == null
                            ? Text(_user?.name?.isNotEmpty == true ? _user.name[0].toUpperCase() : '?',
                                style: TextStyle(fontSize: 36, fontWeight: FontWeight.w800, color: C.red))
                            : null,
                      ),
                      Positioned(bottom: 0, right: 0, child: Container(
                        padding: const EdgeInsets.all(6),
                        decoration: BoxDecoration(color: C.red, shape: BoxShape.circle, border: Border.all(color: Colors.white, width: 2)),
                        child: const Icon(Icons.camera_alt_rounded, color: Colors.white, size: 16),
                      )),
                    ]),
                  ),
                  const SizedBox(height: 14),
                  Text(_user?.name ?? 'User', style: TextStyle(fontSize: 22, fontWeight: FontWeight.w700, color: C.charcoal)),
                  const SizedBox(height: 4),
                  Text(_user?.email ?? '', style: TextStyle(color: C.mist, fontSize: 13)),
                  const SizedBox(height: 16),
                  Row(mainAxisAlignment: MainAxisAlignment.center, children: [
                    _ProfileStat('Reports', '${_myDisasters.length}', C.red),
                    Container(width: 1, height: 30, margin: const EdgeInsets.symmetric(horizontal: 20), color: C.mist.withAlpha(40)),
                    _ProfileStat('Volunteer', _myVol.isNotEmpty ? 'Yes' : 'No', C.green),
                    Container(width: 1, height: 30, margin: const EdgeInsets.symmetric(horizontal: 20), color: C.mist.withAlpha(40)),
                    _ProfileStat('Status', _myVol.isNotEmpty && _myVol.first.isAvailable ? 'Active' : 'Idle', C.blue),
                  ]),
                ]),
              ).animate().fadeIn(duration: 400.ms),
              const SizedBox(height: 20),
              // My reports
              Text('My Disaster Reports', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700, color: C.charcoal)),
              const SizedBox(height: 10),
              if (_myDisasters.isEmpty)
                Container(padding: const EdgeInsets.all(24), decoration: BoxDecoration(color: Colors.white, borderRadius: C.radius),
                  child: Center(child: Text('No reports submitted yet', style: TextStyle(color: C.mist))))
              else
                ..._myDisasters.map((d) => Container(
                  margin: const EdgeInsets.only(bottom: 10), padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(14), boxShadow: C.shadow),
                  child: Row(children: [
                    Icon(Icons.report_rounded, color: C.red),
                    const SizedBox(width: 12),
                    Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                      Text(d.title, style: TextStyle(fontWeight: FontWeight.w600, color: C.charcoal)),
                      Text('${d.locationName} • ${d.status}', style: TextStyle(color: C.mist, fontSize: 12)),
                    ])),
                    Container(padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                      decoration: BoxDecoration(color: (d.status == 'resolved' ? C.green : C.orange).withAlpha(20), borderRadius: BorderRadius.circular(8)),
                      child: Text(d.status.toUpperCase(), style: TextStyle(fontSize: 10, fontWeight: FontWeight.w700, color: d.status == 'resolved' ? C.green : C.orange))),
                  ]),
                )),
              const SizedBox(height: 20),
              // Volunteer info
              if (_myVol.isNotEmpty) ...[
                Text('My Volunteer Profile', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700, color: C.charcoal)),
                const SizedBox(height: 10),
                Container(padding: const EdgeInsets.all(16), decoration: BoxDecoration(color: Colors.white, borderRadius: C.radius, boxShadow: C.shadow),
                  child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                    _row(Icons.phone_rounded, 'Phone', _myVol.first.phone),
                    _row(Icons.build_rounded, 'Skills', _myVol.first.skills),
                    _row(Icons.circle, 'Status', _myVol.first.isAvailable ? 'Available' : 'Deployed'),
                  ]),
                ),
                const SizedBox(height: 20),
              ],
              // Account info
              Container(padding: const EdgeInsets.all(16), decoration: BoxDecoration(color: Colors.white, borderRadius: C.radius, boxShadow: C.shadow),
                child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  const Text('Account', style: TextStyle(fontWeight: FontWeight.w700, fontSize: 15, color: C.charcoal)),
                  const SizedBox(height: 12),
                  _row(Icons.email_rounded, 'Email', _user?.email ?? ''),
                  _row(Icons.badge_rounded, 'User ID', _user?.$id ?? ''),
                  if (_user?.registration != null) _row(Icons.calendar_today_rounded, 'Joined', _user.registration.toString().substring(0, 10)),
                ]),
              ),
              const SizedBox(height: 20),
              // Logout
              SizedBox(width: double.infinity, height: 52, child: OutlinedButton.icon(
                onPressed: _logout,
                icon: const Icon(Icons.logout_rounded, color: C.red),
                label: const Text('Logout', style: TextStyle(color: C.red, fontWeight: FontWeight.w600, fontSize: 16)),
                style: OutlinedButton.styleFrom(side: BorderSide(color: C.red.withAlpha(60)), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14))),
              )),
              const SizedBox(height: 8),
              Center(child: Text('Switch to another account after logout', style: TextStyle(color: C.mist, fontSize: 11))),
            ])),
    );
  }

  Widget _row(IconData i, String l, String v) => Padding(padding: const EdgeInsets.only(bottom: 10),
    child: Row(children: [Icon(i, size: 18, color: C.mist), const SizedBox(width: 10), Text('$l: ', style: TextStyle(color: C.mist, fontSize: 13)), Expanded(child: Text(v, style: TextStyle(fontWeight: FontWeight.w600, color: C.charcoal, fontSize: 13)))]));
}

class _ProfileStat extends StatelessWidget {
  final String label, value; final Color color;
  const _ProfileStat(this.label, this.value, this.color);
  @override
  Widget build(BuildContext context) => Column(children: [
    Text(value, style: TextStyle(fontSize: 18, fontWeight: FontWeight.w800, color: color)),
    Text(label, style: TextStyle(fontSize: 11, color: C.mist)),
  ]);
}
