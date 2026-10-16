import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../services/settings_service.dart';
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
  static const String _prefsKey = 'clickpad_saved_snippets_en_v3';
  final SettingsService _settings = SettingsService.instance;
  List<SnippetItem> _snippets = [];
  bool _isLoading = true;
  String? _sendingId;

  @override
  void initState() {
    super.initState();
    _settings.addListener(_onSettingsUpdate);
    _loadSnippets();
  }

  @override
  void dispose() {
    _settings.removeListener(_onSettingsUpdate);
    super.dispose();
  }

  void _onSettingsUpdate() {
    if (mounted) setState(() {});
  }

  Future<void> _loadSnippets() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getStringList(_prefsKey);
    if (raw != null && raw.isNotEmpty) {
      _snippets = raw.map((s) => SnippetItem.fromJson(jsonDecode(s))).toList();
    } else {
      // Default practical everyday English templates for general users
      _snippets = [
        SnippetItem(
          id: '1',
          title: 'Professional Email Greeting',
          text: 'Dear Sir/Madam,\nI hope this email finds you well.',
        ),
        SnippetItem(
          id: '2',
          title: 'Status Follow-up',
          text: 'Hi team, just following up on this matter. Looking forward to your update. Thank you!',
        ),
        SnippetItem(
          id: '3',
          title: 'Receipt Confirmation',
          text: 'Thank you for sharing. I have received the files and details in good order.',
        ),
        SnippetItem(
          id: '4',
          title: 'Shipping Address Template',
          text: 'Full Name:\nPhone / WhatsApp:\nStreet Address:\nCity / State:\nZip / Postal Code:',
        ),
        SnippetItem(
          id: '5',
          title: 'Professional Email Sign-off',
          text: 'Thank you for your time and assistance.\n\nBest regards,',
        ),
        SnippetItem(
          id: '6',
          title: 'Away / Meeting Notice',
          text: 'Currently away from my desk in a meeting. I will get back to you as soon as possible.',
        ),
        SnippetItem(
          id: '7',
          title: 'Appreciation & Thanks',
          text: 'Thank you very much for your great support and partnership!',
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
                              visualDensity: VisualDensity.compact,
                              padding: EdgeInsets.zero,
                              constraints: const BoxConstraints(minWidth: 32, minHeight: 32),
                              icon: const Icon(Icons.edit_outlined, size: 18),
                              onPressed: () => _showAddEditModal(existing: item),
                            ),
                            IconButton(
                              visualDensity: VisualDensity.compact,
                              padding: EdgeInsets.zero,
                              constraints: const BoxConstraints(minWidth: 32, minHeight: 32),
                              icon: const Icon(Icons.delete_outline_rounded, size: 18, color: Colors.redAccent),
                              tooltip: 'Delete',
                              onPressed: () => _deleteSnippet(idx),
                            ),
                            IconButton(
                              visualDensity: VisualDensity.compact,
                              padding: EdgeInsets.zero,
                              constraints: const BoxConstraints(minWidth: 32, minHeight: 32),
                              icon: isSending
                                  ? const SizedBox(
                                      width: 16,
                                      height: 16,
                                      child: CircularProgressIndicator(strokeWidth: 2),
                                    )
                                  : const Icon(Icons.send_rounded, color: Colors.greenAccent, size: 18),
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
