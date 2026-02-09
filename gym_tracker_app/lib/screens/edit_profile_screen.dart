import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:image_picker/image_picker.dart';

class EditProfileScreen extends StatefulWidget {
  const EditProfileScreen({super.key});

  @override
  State<EditProfileScreen> createState() => _EditProfileScreenState();
}

class _EditProfileScreenState extends State<EditProfileScreen> {
  final _nameController = TextEditingController();
  final Set<int> _restDays = <int>{};
  final _picker = ImagePicker();

  static const _cloudName = 'dyavghrjk';
  static const _uploadPreset = 'gymtracker';

  String? _photoUrl;
  bool _loading = true;
  bool _saving = false;
  bool _uploadingPhoto = false;

  @override
  void dispose() {
    _nameController.dispose();
    super.dispose();
  }

  @override
  void initState() {
    super.initState();
    _loadProfile();
  }

  Future<void> _loadProfile() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      setState(() => _loading = false);
      return;
    }

    final ref = FirebaseDatabase.instance.ref('users/${user.uid}/profile');
    final snap = await ref.get();
    if (!mounted) return;

    final raw = snap.value;
    final data = raw is Map ? raw : <dynamic, dynamic>{};

    _nameController.text = (data['name'] ?? '').toString();
    _photoUrl = data['photoUrl']?.toString();

    final rest = _parseRestDays(data['restDays']);
    _restDays
      ..clear()
      ..addAll(rest);

    setState(() => _loading = false);
  }

  Set<int> _parseRestDays(dynamic raw) {
    final result = <int>{};
    if (raw is List) {
      for (final value in raw) {
        final parsed = _toInt(value);
        if (parsed != null) result.add(parsed);
      }
    } else if (raw is Map) {
      for (final value in raw.values) {
        final parsed = _toInt(value);
        if (parsed != null) result.add(parsed);
      }
    }
    return result;
  }

  int? _toInt(dynamic value) {
    if (value is int) return value;
    if (value is num) return value.toInt();
    if (value is String) return int.tryParse(value);
    return null;
  }

  Future<void> _pickPhoto() async {
    if (_uploadingPhoto) return;

    final user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("No hay sesión activa.")),
      );
      return;
    }

    final picked = await _picker.pickImage(
      source: ImageSource.gallery,
      imageQuality: 85,
      maxWidth: 1024,
    );
    if (picked == null) return;

    setState(() => _uploadingPhoto = true);
    try {
      final bytes = await picked.readAsBytes();
      final url = await _uploadToCloudinary(
        bytes: bytes,
        filename: picked.name,
      );
      if (url == null) {
        throw FirebaseException(
          plugin: 'cloudinary',
          message: 'Error subiendo imagen.',
        );
      }

      await FirebaseDatabase.instance.ref('users/${user.uid}/profile').update({
        'photoUrl': url,
        'updatedAt': ServerValue.timestamp,
      });

      if (!mounted) return;
      setState(() => _photoUrl = url);
    } on FirebaseException catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(e.message ?? "Error")));
    } finally {
      if (mounted) {
        setState(() => _uploadingPhoto = false);
      }
    }
  }

  Future<String?> _uploadToCloudinary({
    required List<int> bytes,
    required String filename,
  }) async {
    final uri = Uri.parse(
      'https://api.cloudinary.com/v1_1/$_cloudName/image/upload',
    );
    final request = http.MultipartRequest('POST', uri)
      ..fields['upload_preset'] = _uploadPreset
      ..files.add(
        http.MultipartFile.fromBytes(
          'file',
          bytes,
          filename: filename,
        ),
      );

    final response = await request.send();
    final body = await response.stream.bytesToString();
    if (response.statusCode < 200 || response.statusCode >= 300) {
      return null;
    }
    return _extractSecureUrl(body);
  }

  String? _extractSecureUrl(String json) {
    final match = RegExp(r'"secure_url"\s*:\s*"([^"]+)"').firstMatch(json);
    return match?.group(1);
  }

  Future<void> _saveProfile() async {
    if (_saving) return;

    final user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("No hay sesión activa.")),
      );
      return;
    }

    final name = _nameController.text.trim();

    setState(() => _saving = true);
    try {
      final restDays = _restDays.toList()..sort();
      await FirebaseDatabase.instance.ref('users/${user.uid}/profile').update({
        'name': name,
        'restDays': restDays,
        'updatedAt': ServerValue.timestamp,
      });
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Perfil actualizado.")),
      );
    } on FirebaseException catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(e.message ?? "Error")));
    } finally {
      if (mounted) {
        setState(() => _saving = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) {
      return const Scaffold(
        backgroundColor: Colors.white,
        body: Center(child: CircularProgressIndicator()),
      );
    }

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        surfaceTintColor: Colors.white,
        elevation: 0,
        title: const Text(
          "Editar perfil",
          style: TextStyle(fontWeight: FontWeight.w600),
        ),
      ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(20, 12, 20, 24),
        children: [
          Center(
            child: Stack(
              alignment: Alignment.bottomRight,
              children: [
                Container(
                  width: 90,
                  height: 90,
                  decoration: const BoxDecoration(
                    color: Color(0xFFE0E0E0),
                    shape: BoxShape.circle,
                  ),
                  child: _photoUrl == null
                      ? const Icon(
                          Icons.person,
                          size: 44,
                          color: Colors.black54,
                        )
                      : ClipOval(
                          child: Image.network(
                            _photoUrl!,
                            width: 90,
                            height: 90,
                            fit: BoxFit.cover,
                          ),
                        ),
                ),
                Container(
                  width: 30,
                  height: 30,
                  decoration: const BoxDecoration(
                    color: Color(0xFF2B2E34),
                    shape: BoxShape.circle,
                  ),
                  child: IconButton(
                    padding: EdgeInsets.zero,
                    icon: const Icon(Icons.camera_alt, color: Colors.white, size: 16),
                    onPressed: _uploadingPhoto ? null : _pickPhoto,
                  ),
                ),
                if (_uploadingPhoto)
                  const Positioned.fill(
                    child: ColoredBox(
                      color: Color(0x55000000),
                      child: Center(
                        child: SizedBox(
                          width: 26,
                          height: 26,
                          child: CircularProgressIndicator(strokeWidth: 2.2),
                        ),
                      ),
                    ),
                  ),
              ],
            ),
          ),
          const SizedBox(height: 16),
          const Text(
            "Nombre de usuario",
            style: TextStyle(fontWeight: FontWeight.w600),
          ),
          const SizedBox(height: 6),
          TextField(
            controller: _nameController,
            decoration: InputDecoration(
              hintText: "Tu nombre",
              filled: true,
              fillColor: const Color(0xFFF2F2F2),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide.none,
              ),
            ),
          ),
          const SizedBox(height: 16),
          const Text(
            "Días de descanso",
            style: TextStyle(fontWeight: FontWeight.w600),
          ),
          const SizedBox(height: 8),
          _RestDaysPicker(
            selected: _restDays,
            onChanged: (next) {
              setState(() {
                _restDays
                  ..clear()
                  ..addAll(next);
              });
            },
          ),
          const SizedBox(height: 16),
          const Text(
            "Estos días no afectan tu racha.",
            style: TextStyle(color: Colors.black54),
          ),
          const SizedBox(height: 16),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF2B2E34),
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(vertical: 12),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
            onPressed: _saving ? null : _saveProfile,
            child: _saving
                ? const SizedBox(
                    width: 22,
                    height: 22,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : const Text("Guardar cambios"),
          ),
        ],
      ),
    );
  }
}

class _RestDaysPicker extends StatelessWidget {
  const _RestDaysPicker({
    required this.selected,
    required this.onChanged,
  });

  final Set<int> selected;
  final ValueChanged<Set<int>> onChanged;

  static const _labels = <int, String>{
    1: "L",
    2: "M",
    3: "X",
    4: "J",
    5: "V",
    6: "S",
    7: "D",
  };

  @override
  Widget build(BuildContext context) {
    return Wrap(
      spacing: 8,
      children: _labels.entries.map((entry) {
        final isSelected = selected.contains(entry.key);
        return ChoiceChip(
          label: Text(entry.value),
          selected: isSelected,
          onSelected: (value) {
            final next = Set<int>.from(selected);
            if (value) {
              next.add(entry.key);
            } else {
              next.remove(entry.key);
            }
            onChanged(next);
          },
          selectedColor: const Color(0xFF2B2E34),
          labelStyle: TextStyle(
            color: isSelected ? Colors.white : Colors.black87,
            fontWeight: FontWeight.w600,
          ),
        );
      }).toList(),
    );
  }
}
