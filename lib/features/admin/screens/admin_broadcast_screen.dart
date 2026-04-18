import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../../core/theme/app_colors.dart';
import '../../../shared/models/broadcast_model.dart';
import '../services/broadcast_service.dart';

/// Screen where Admin composes and sends broadcasts.
class AdminBroadcastScreen extends StatefulWidget {
  const AdminBroadcastScreen({super.key});

  @override
  State<AdminBroadcastScreen> createState() => _AdminBroadcastScreenState();
}

class _AdminBroadcastScreenState extends State<AdminBroadcastScreen> {
  final _formKey = GlobalKey<FormState>();
  final _titleCtrl = TextEditingController();
  final _msgCtrl = TextEditingController();
  final _service = BroadcastService();

  bool _isSending = false;
  String? _selectedBusId;
  String? _selectedBusNumber;

  // Fetch buses for targeting
  Future<List<Map<String, String>>> _loadBuses() async {
    final snap =
        await FirebaseFirestore.instance.collection('buses').get();
    return snap.docs.map((d) {
      final data = d.data();
      return {'id': d.id, 'number': data['busNumber']?.toString() ?? d.id};
    }).toList();
  }

  Future<void> _send(String adminName) async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _isSending = true);
    try {
      final broadcast = BroadcastModel(
        id: '',
        title: _titleCtrl.text.trim(),
        message: _msgCtrl.text.trim(),
        targetBusId: _selectedBusId,
        targetBusNumber: _selectedBusNumber,
        sentByName: adminName,
        createdAt: DateTime.now(),
      );
      await _service.sendBroadcast(broadcast);
      if (mounted) {
        _titleCtrl.clear();
        _msgCtrl.clear();
        setState(() {
          _selectedBusId = null;
          _selectedBusNumber = null;
        });
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
          content: Text('Broadcast sent!'),
          backgroundColor: AppColors.success,
        ));
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text('Error: $e'),
          backgroundColor: AppColors.error,
        ));
      }
    } finally {
      if (mounted) setState(() => _isSending = false);
    }
  }

  @override
  void dispose() {
    _titleCtrl.dispose();
    _msgCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: Text('Broadcast Message',
            style: GoogleFonts.outfit(
                color: AppColors.textPrimary,
                fontWeight: FontWeight.w700,
                fontSize: 18)),
        backgroundColor: AppColors.surface,
        elevation: 0,
      ),
      body: Column(
        children: [
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(20),
              child: Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _sectionLabel('📢 New Broadcast'),
                    const SizedBox(height: 16),

                    // Title
                    _buildField(
                      controller: _titleCtrl,
                      label: 'Title',
                      hint: 'e.g. Bus delay today',
                      maxLines: 1,
                      validator: (v) =>
                          (v == null || v.trim().isEmpty) ? 'Required' : null,
                    ),
                    const SizedBox(height: 12),

                    // Message
                    _buildField(
                      controller: _msgCtrl,
                      label: 'Message',
                      hint: 'Write your announcement here...',
                      maxLines: 5,
                      validator: (v) =>
                          (v == null || v.trim().isEmpty) ? 'Required' : null,
                    ),
                    const SizedBox(height: 16),

                    // Target Bus selector
                    _sectionLabel('Target Audience'),
                    const SizedBox(height: 10),
                    FutureBuilder<List<Map<String, String>>>(
                      future: _loadBuses(),
                      builder: (context, snap) {
                        final buses = snap.data ?? [];
                        return Wrap(
                          spacing: 8,
                          runSpacing: 8,
                          children: [
                            _audienceChip(
                              label: 'All Parents',
                              selected: _selectedBusId == null,
                              onTap: () => setState(() {
                                _selectedBusId = null;
                                _selectedBusNumber = null;
                              }),
                            ),
                            ...buses.map((b) => _audienceChip(
                                  label: 'Bus ${b['number']}',
                                  selected: _selectedBusId == b['id'],
                                  onTap: () => setState(() {
                                    _selectedBusId = b['id'];
                                    _selectedBusNumber = b['number'];
                                  }),
                                )),
                          ],
                        );
                      },
                    ),
                    const SizedBox(height: 28),

                    // Send button
                    SizedBox(
                      width: double.infinity,
                      height: 52,
                      child: DecoratedBox(
                        decoration: BoxDecoration(
                          gradient: AppColors.adminGradient,
                          borderRadius: BorderRadius.circular(14),
                        ),
                        child: TextButton(
                          onPressed: _isSending ? null : () => _send('Admin'),
                          child: _isSending
                              ? const SizedBox(
                                  width: 22,
                                  height: 22,
                                  child: CircularProgressIndicator(
                                      strokeWidth: 2,
                                      color: Colors.white))
                              : Text('Send Broadcast 🚀',
                                  style: GoogleFonts.outfit(
                                      color: Colors.white,
                                      fontWeight: FontWeight.w700,
                                      fontSize: 15)),
                        ),
                      ),
                    ),

                    const SizedBox(height: 32),
                    _sectionLabel('📋 Sent Broadcasts'),
                    const SizedBox(height: 10),
                    _SentBroadcastsList(service: _service),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildField({
    required TextEditingController controller,
    required String label,
    required String hint,
    required int maxLines,
    String? Function(String?)? validator,
  }) {
    return TextFormField(
      controller: controller,
      maxLines: maxLines,
      validator: validator,
      style: GoogleFonts.outfit(color: AppColors.textPrimary),
      decoration: InputDecoration(
        labelText: label,
        hintText: hint,
        labelStyle: GoogleFonts.outfit(color: AppColors.textSecondary),
        hintStyle: GoogleFonts.outfit(color: AppColors.textHint),
        filled: true,
        fillColor: AppColors.surfaceElevated,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: AppColors.border),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: AppColors.border),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: AppColors.primary),
        ),
      ),
    );
  }

  Widget _audienceChip({
    required String label,
    required bool selected,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
        decoration: BoxDecoration(
          color: selected
              ? AppColors.adminColor.withValues(alpha: 0.15)
              : AppColors.surfaceElevated,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: selected ? AppColors.adminColor : AppColors.border,
            width: selected ? 1.5 : 1,
          ),
        ),
        child: Text(label,
            style: GoogleFonts.outfit(
                color: selected ? AppColors.adminColor : AppColors.textSecondary,
                fontWeight:
                    selected ? FontWeight.w700 : FontWeight.w400,
                fontSize: 13)),
      ),
    );
  }

  Widget _sectionLabel(String text) {
    return Text(text,
        style: GoogleFonts.outfit(
            fontSize: 14,
            fontWeight: FontWeight.w700,
            color: AppColors.textSecondary));
  }
}

// ── Sent broadcasts list (extracted for readability) ─────────────────────────
class _SentBroadcastsList extends StatelessWidget {
  final BroadcastService service;
  const _SentBroadcastsList({required this.service});

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<List<BroadcastModel>>(
      stream: service.streamAll(),
      builder: (context, snap) {
        final broadcasts = snap.data ?? [];
        if (broadcasts.isEmpty) {
          return Padding(
            padding: const EdgeInsets.symmetric(vertical: 20),
            child: Center(
              child: Text('No broadcasts sent yet.',
                  style: GoogleFonts.outfit(color: AppColors.textHint)),
            ),
          );
        }
        return Column(
          children: broadcasts
              .map((b) => _BroadcastAdminTile(broadcast: b, service: service))
              .toList(),
        );
      },
    );
  }
}

class _BroadcastAdminTile extends StatelessWidget {
  final BroadcastModel broadcast;
  final BroadcastService service;
  const _BroadcastAdminTile(
      {required this.broadcast, required this.service});

  @override
  Widget build(BuildContext context) {
    final date = broadcast.createdAt;
    final dateStr =
        '${date.day}/${date.month}/${date.year}  ${date.hour.toString().padLeft(2, '0')}:${date.minute.toString().padLeft(2, '0')}';

    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.surfaceElevated,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.border),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: AppColors.adminColor.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(10),
            ),
            child: const Icon(Icons.campaign_rounded,
                color: AppColors.adminColor, size: 18),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(broadcast.title,
                    style: GoogleFonts.outfit(
                        color: AppColors.textPrimary,
                        fontWeight: FontWeight.w700,
                        fontSize: 13)),
                Text(broadcast.message,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: GoogleFonts.outfit(
                        color: AppColors.textSecondary, fontSize: 11)),
                const SizedBox(height: 4),
                Text(
                  '${broadcast.targetBusNumber != null ? 'Bus ${broadcast.targetBusNumber}' : 'All Parents'}  •  $dateStr',
                  style: GoogleFonts.outfit(
                      color: AppColors.textHint, fontSize: 10),
                ),
              ],
            ),
          ),
          IconButton(
            icon: const Icon(Icons.delete_rounded,
                color: AppColors.error, size: 18),
            onPressed: () async {
              await service.delete(broadcast.id);
            },
            tooltip: 'Delete',
          ),
        ],
      ),
    );
  }
}
