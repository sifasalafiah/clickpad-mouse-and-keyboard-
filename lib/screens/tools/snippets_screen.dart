import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../theme/app_colors.dart';
import '../../utils/haptic_helper.dart';
import '../../utils/hid_helper.dart';

class SnippetItem {
  String id;
  String title;
  String text;

  SnippetItem({required this.id, required this.title, required this.text});

  Map<String, dynamic> toJson() => {'id': id, 'title': title, 'text': text};
  factory SnippetItem.fromJson(Map<String, dynamic> json) => SnippetItem(
        id: json['id'] ?? '',
        title: json['title'] ?? '',
        text: json['text'] ?? '',
      );
}

class SnippetsScreen extends StatefulWidget {
  const SnippetsScreen({super.key});

  @override
  State<SnippetsScreen> createState() => _SnippetsScreenState();
}

class _SnippetsScreenState extends State<SnippetsScreen> {
  static const String _prefsKey = 'clickpad_saved_snippets_v2';
  List<SnippetItem> _snippets = [];
  bool _isLoading = true;
  String? _sendingId;

  @override
  void initState() {
    super.initState();
    _loadSnippets();
  }

  Future<void> _loadSnippets() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getStringList(_prefsKey);
    if (raw != null && raw.isNotEmpty) {
      _snippets = raw.map((s) => SnippetItem.fromJson(jsonDecode(s))).toList();
    } else {
      // Default snippets praktis untuk orang umum / pekerjaan sehari-hari
      _snippets = [
        SnippetItem(
          id: '1',
          title: 'Salam Pembuka Formal',
          text: 'Selamat pagi / siang Bapak/Ibu, semoga dalam keadaan sehat selalu.',
        ),
        SnippetItem(
          id: '2',
          title: 'Konfirmasi Penerimaan',
          text: 'Baik, dokumen dan informasi sudah saya terima dengan baik. Terima kasih banyak!',
        ),
        SnippetItem(
          id: '3',
          title: 'Format Alamat Pengiriman',
          text: 'Nama:\nNo. HP/WA:\nAlamat Lengkap:\nKota/Kabupaten:\nKode Pos:',
        ),
        SnippetItem(
          id: '4',
          title: 'Salam Penutup Email',
          text: 'Demikian yang dapat saya sampaikan. Terima kasih atas perhatian dan kerja samanya.\n\nSalam hormat,',
        ),
        SnippetItem(
          id: '5',
          title: 'Pemberitahuan Sedang Rapat',
          text: 'Mohon maaf saat ini saya sedang berada di luar / rapat. Akan segera saya hubungi kembali.',
        ),
        SnippetItem(
          id: '6',
          title: 'Ucapan Terima Kasih',
          text: 'Terima kasih banyak atas bantuan dan kerja samanya!',
        ),
      ];
      _saveSnippets();
    }
    setState(() => _isLoading = false);
  }

  Future<void> _saveSnippets() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = _snippets.map((s) => jsonEncode(s.toJson())).toList();
    await prefs.setStringList(_prefsKey, raw);
  }

  Future<void> _sendSnippet(SnippetItem item) async {
    HapticHelper.mediumImpact();
    setState(() => _sendingId = item.id);

    await HidHelper.instance.sendText(item.text, sendEnter: false, charDelayMs: 14);

    if (mounted) {
      setState(() => _sendingId = null);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Typed "${item.title}" to PC!'),
          duration: const Duration(seconds: 1),
          backgroundColor: AppColors.success,
        ),
      );
    }
  }

  void _showAddEditModal({SnippetItem? existing}) {
    HapticHelper.selectionClick();
    final titleCtrl = TextEditingController(text: existing?.title ?? '');
    final textCtrl = TextEditingController(text: existing?.text ?? '');

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: AppColors.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) {
        return Padding(
          padding: EdgeInsets.only(
            left: 20,
            right: 20,
            top: 20,
            bottom: MediaQuery.of(ctx).viewInsets.bottom + 20,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                existing == null ? 'New Text Snippet' : 'Edit Text Snippet',
                style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: titleCtrl,
                decoration: InputDecoration(
                  labelText: 'Snippet Title',
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                ),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: textCtrl,
                maxLines: 4,
                decoration: InputDecoration(
                  labelText: 'Text Content to Type to PC',
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                ),
              ),
              const SizedBox(height: 16),
              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  TextButton(
                    onPressed: () => Navigator.pop(ctx),
                    child: Text('Cancel', style: TextStyle(color: AppColors.textMuted)),
                  ),
                  const SizedBox(width: 8),
                  ElevatedButton(
                    style: ElevatedButton.styleFrom(backgroundColor: AppColors.primary),
                    onPressed: () {
                      final title = titleCtrl.text.trim();
                      final text = textCtrl.text;
                      if (title.isEmpty || text.isEmpty) return;

                      setState(() {
                        if (existing != null) {
                          existing.title = title;
                          existing.text = text;
                        } else {
                          _snippets.add(SnippetItem(
                            id: DateTime.now().millisecondsSinceEpoch.toString(),
                            title: title,
                            text: text,
                          ));
                        }
                      });
                      _saveSnippets();
                      Navigator.pop(ctx);
                    },
                    child: const Text('Save Snippet', style: TextStyle(color: Colors.white)),
                  ),
                ],
              ),
            ],
          ),
        );
      },
    );
  }

  void _deleteSnippet(int index) {
    HapticHelper.mediumImpact();
    setState(() {
      _snippets.removeAt(index);
    });
    _saveSnippets();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('Quick Text Snippets', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 17)),
        actions: [
          IconButton(
            icon: const Icon(Icons.add_rounded),
            tooltip: 'Add Snippet',
            onPressed: () => _showAddEditModal(),
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _snippets.isEmpty
              ? Center(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.notes_rounded, size: 48, color: AppColors.textMuted),
                      const SizedBox(height: 12),
                      Text('No text snippets saved yet', style: TextStyle(color: AppColors.textMuted)),
                      const SizedBox(height: 8),
                      ElevatedButton.icon(
                        icon: const Icon(Icons.add),
                        label: const Text('Create Snippet'),
                        onPressed: () => _showAddEditModal(),
                      ),
                    ],
                  ),
                )
              : ListView.separated(
                  padding: const EdgeInsets.all(16),
                  itemCount: _snippets.length,
                  separatorBuilder: (context, index) => const SizedBox(height: 10),
                  itemBuilder: (context, idx) {
                    final item = _snippets[idx];
                    final isSending = _sendingId == item.id;

                    return Container(
                      decoration: BoxDecoration(
                        color: AppColors.surfaceElevated,
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(color: AppColors.border),
                      ),
                      child: ListTile(
                        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
                        leading: Container(
                          padding: const EdgeInsets.all(10),
                          decoration: BoxDecoration(
                            color: AppColors.primary.withAlpha(25),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Icon(Icons.text_snippet_rounded, color: AppColors.primaryLight, size: 20),
                        ),
                        title: Text(item.title, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
                        subtitle: Text(
                          item.text,
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(fontSize: 12, color: AppColors.textMuted, fontFamily: 'monospace'),
                        ),
                        trailing: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            IconButton(
                              icon: const Icon(Icons.edit_outlined, size: 18),
                              onPressed: () => _showAddEditModal(existing: item),
                            ),
                            IconButton(
                              icon: const Icon(Icons.delete_outline_rounded, size: 18, color: Colors.redAccent),
                              tooltip: 'Delete',
                              onPressed: () => _deleteSnippet(idx),
                            ),
                            IconButton(
                              icon: isSending
                                  ? const SizedBox(
                                      width: 18,
                                      height: 18,
                                      child: CircularProgressIndicator(strokeWidth: 2),
                                    )
                                  : const Icon(Icons.send_rounded, color: Colors.greenAccent),
                              tooltip: 'Send to PC',
                              onPressed: isSending ? null : () => _sendSnippet(item),
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                ),
    );
  }
}
