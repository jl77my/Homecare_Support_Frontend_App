// lib/features/caregiver/views/reports_view.dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';
import 'dart:convert';
import 'package:intl/intl.dart';
import '../../../core/models/enums.dart';
import '../../../core/models/models.dart';
import '../../auth/providers/auth_provider.dart';
import '../../family/providers/family_provider.dart';
import '../../family/views/family_pairing_view.dart';
import '../providers/caregiver_provider.dart';
import '../widgets/patient_selector_bar.dart';
import 'pairing_view.dart';

class ReportsView extends ConsumerStatefulWidget {
  const ReportsView({super.key});
  @override
  ConsumerState<ReportsView> createState() => _ReportsViewState();
}

class _ReportsViewState extends ConsumerState<ReportsView> {
  ReportCategory? _categoryFilter;
  String? _lightboxImageUrl;

  void _showNewReportModal(String activeElderlyId, {CareReport? existingReport}) {
    if (activeElderlyId.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please select a senior patient first.')),
      );
      return;
    }
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => _NewReportModal(patientId: activeElderlyId, existingReport: existingReport),
    );
  }

  void _confirmDeleteReport(String reportId, String patientId) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Report?'),
        content: const Text('This action cannot be undone.'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('CANCEL')),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFFEF4444)),
            onPressed: () async {
              Navigator.pop(context);
              final success = await ref.read(caregiverProvider.notifier).deleteCareReport(reportId, patientId);
              if (success && mounted) {
                ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Report deleted.'), backgroundColor: Color(0xFF10B981)));
              }
            },
            child: const Text('DELETE', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }

  Widget _buildMoodBanner(String? mood) {
    if (mood == null) {
      return Container(
        margin: const EdgeInsets.only(bottom: 16),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(24), border: Border.all(color: const Color(0xFFE2E8F0))),
        child: const Row(
          children: [
            Icon(Icons.face_retouching_off, color: Color(0xFF94A3B8), size: 28),
            SizedBox(width: 12),
            Text("No mood recorded yet today.", style: TextStyle(color: Color(0xFF64748B), fontWeight: FontWeight.bold, fontSize: 13)),
          ],
        ),
      );
    }
    String emoji = '😐';
    String label = 'OKAY';
    Color bgColor = const Color(0xFFFEFCE8);
    Color borderColor = const Color(0xFFFEF08A);
    Color textColor = const Color(0xFF854D0E);

    if (mood == 'Happy') {
      emoji = '😄';
      label = 'FEEL GREAT';
      bgColor = const Color(0xFFF0FDF4);
      borderColor = const Color(0xFFBBF7D0);
      textColor = const Color(0xFF166534);
    } else if (mood == 'Sad') {
      emoji = '😫';
      label = 'TIRED';
      bgColor = const Color(0xFFFEF2F2);
      borderColor = const Color(0xFFFECACA);
      textColor = const Color(0xFF991B1B);
    }
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(color: bgColor, borderRadius: BorderRadius.circular(32), border: Border.all(color: borderColor)),
      child: Row(
        children: [
          Text(emoji, style: const TextStyle(fontSize: 38)),
          const SizedBox(width: 16),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text("TODAY'S OVERALL MOOD", style: TextStyle(fontSize: 10, fontWeight: FontWeight.w900, color: textColor.withOpacity(0.7), letterSpacing: 0.8)),
              Text(label, style: TextStyle(fontSize: 20, fontWeight: FontWeight.w900, color: textColor)),
            ]
          )
        ]
      )
    );
  }

  @override
  Widget build(BuildContext context) {
    final authUser = ref.watch(authProvider).user;
    final isFamily = authUser?.role.toLowerCase() == 'family';
    final isCaregiver = authUser?.role.toLowerCase() == 'caregiver';

    final familyState = ref.watch(familyDashboardProvider);
    final caregiverState = ref.watch(caregiverProvider);

    final activeElderlyId = isFamily ? familyState.selectedElderlyId : caregiverState.activeElderlyId;
    final assignedSeniors = isFamily ? familyState.linkedSeniors : caregiverState.assignedSeniors;
    final reports = isFamily ? familyState.reports : caregiverState.reports;
    final todayMood = isFamily ? familyState.todayMood : caregiverState.todayMood; 

    final filteredReports = reports.where((r) {
      if (_categoryFilter != null && r.category != _categoryFilter) return false;
      return true;
    }).toList();

    return Stack(
      children: [
        ListView(
          padding: const EdgeInsets.only(bottom: 32),
          children: [
            if (!isFamily && !isCaregiver) const SizedBox.shrink() else
              PatientSelectorBar(
                assignedSeniors: assignedSeniors,
                selectedElderlyId: activeElderlyId,
                onElderlySelected: (newElderlyId) {
                  if (isFamily) {
                    ref.read(familyDashboardProvider.notifier).switchElderlyContext(newElderlyId);
                  } else {
                    ref.read(caregiverProvider.notifier).switchElderlyContext(newElderlyId);
                  }
                },
                onPairNewElderly: () {
                  Navigator.of(context).push(
                    MaterialPageRoute(builder: (context) => isFamily ? const FamilyPairingView() : const PairingView()),
                  );
                },
              ),
            
            _buildMoodBanner(todayMood),
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(32),
                border: Border.all(color: const Color(0xFFF1F5F9)),
                boxShadow: const [
                  BoxShadow(color: Color(0x0A000000), blurRadius: 12, offset: Offset(0, 4)),
                ],
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Care Reports Feed',
                        style: TextStyle(fontSize: 22, fontWeight: FontWeight.w900, color: Color(0xFF0F172A)),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        'Detailed daily logs, photos & injury updates',
                        style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: Colors.grey.shade600),
                      ),
                    ],
                  ),
                  if (isCaregiver)
                    ElevatedButton.icon(
                      onPressed: () => _showNewReportModal(activeElderlyId),
                      icon: const Icon(Icons.add_a_photo, size: 16),
                      label: const Text('NEW REPORT', style: TextStyle(fontSize: 11, fontWeight: FontWeight.w900)),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF2563EB),
                        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                      ),
                    ),
                ],
              ),
            ),
            const SizedBox(height: 16),
            SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                children: [
                  _buildCategoryChip('All Categories', null),
                  const SizedBox(width: 8),
                  _buildCategoryChip('📝 Daily Log', ReportCategory.dailyLog),
                  const SizedBox(width: 8),
                  _buildCategoryChip('🩹 Wound Care', ReportCategory.injuryWound),
                  const SizedBox(width: 8),
                  _buildCategoryChip('🍲 Meal & Food', ReportCategory.mealNutrition),
                  const SizedBox(width: 8),
                  _buildCategoryChip('🚶 Mobility', ReportCategory.mobilityExercise),
                  const SizedBox(width: 8),
                  _buildCategoryChip('⚕️ Medical', ReportCategory.medicalObservation),
                ],
              ),
            ),
            const SizedBox(height: 16),
            if (filteredReports.isEmpty)
              const Padding(
                padding: EdgeInsets.symmetric(vertical: 40),
                child: Center(
                  child: Column(
                    children: [
                      Icon(Icons.assignment_turned_in_outlined, size: 54, color: Color(0xFFCBD5E1)),
                      SizedBox(height: 10),
                      Text('No care reports in this filter', style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: Color(0xFF64748B))),
                    ],
                  ),
                ),
              )
            else
              ListView.separated(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                itemCount: filteredReports.length,
                separatorBuilder: (_, __) => const SizedBox(height: 18),
                itemBuilder: (context, index) {
                  final report = filteredReports[index];
                  return _buildReportCard(report, isFamily, isCaregiver, activeElderlyId);
                },
              ),
          ],
        ),
        if (_lightboxImageUrl != null)
          Positioned.fill(
            child: GestureDetector(
              onTap: () => setState(() => _lightboxImageUrl = null),
              child: Container(
                color: Colors.black.withOpacity(0.9),
                child: Stack(
                  children: [
                    Center(
                      child: InteractiveViewer(
                        child: _lightboxImageUrl!.startsWith('data:image')
                            ? Image.memory(base64Decode(_lightboxImageUrl!.split(',')[1]))
                            : Image.network(_lightboxImageUrl!),
                      ),
                    ),
                    Positioned(
                      top: 40,
                      right: 20,
                      child: IconButton(
                        icon: const Icon(Icons.close, color: Colors.white, size: 30),
                        onPressed: () => setState(() => _lightboxImageUrl = null),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
      ],
    );
  }

  Widget _buildCategoryChip(String label, ReportCategory? cat) {
    final isSelected = _categoryFilter == cat;
    return ChoiceChip(
      label: Text(
        label,
        style: TextStyle(
          fontSize: 12,
          fontWeight: FontWeight.w900,
          color: isSelected ? Colors.white : const Color(0xFF334155),
        ),
      ),
      selected: isSelected,
      onSelected: (_) => setState(() => _categoryFilter = cat),
      selectedColor: const Color(0xFF2563EB),
      backgroundColor: const Color(0xFFF1F5F9),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      showCheckmark: false,
    );
  }

  Widget _buildReportCard(CareReport report, bool isFamily, bool isCaregiver, String patientId) {
    final formattedDate = DateFormat('MMM d   hh:mm a').format(report.timestamp);

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(32),
        border: Border.all(color: const Color(0xFFE2E8F0)),
        boxShadow: const [BoxShadow(color: Color(0x0A000000), blurRadius: 16, offset: Offset(0, 4))],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: const Color(0xFFDCFCE7),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  '${report.category.label.toUpperCase()} ${report.category.emoji}',
                  style: const TextStyle(fontSize: 10, fontWeight: FontWeight.w900, color: Color(0xFF15803D)),
                ),
              ),
              const Spacer(),
              Text(formattedDate, style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w800, color: Color(0xFF94A3B8))),
              if (isCaregiver)
                Row(
                  children: [
                    IconButton(icon: const Icon(Icons.edit_outlined, size: 18, color: Color(0xFF2563EB)), onPressed: () => _showNewReportModal(patientId, existingReport: report)),
                    IconButton(icon: const Icon(Icons.delete_outline, size: 18, color: Color(0xFFEF4444)), onPressed: () => _confirmDeleteReport(report.id, patientId)),
                  ],
                ),
            ],
          ),
          const SizedBox(height: 16),
          Text(report.title, style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w900, color: Color(0xFF0F172A), height: 1.2)),
          const SizedBox(height: 12),
          Row(
            children: [
              CircleAvatar(
                radius: 12,
                backgroundColor: const Color(0xFF2563EB),
                backgroundImage: (report.caregiverProfilePhoto != null && report.caregiverProfilePhoto!.isNotEmpty)
                    ? (report.caregiverProfilePhoto!.startsWith('data:image')
                        ? MemoryImage(base64Decode(report.caregiverProfilePhoto!.split(',')[1]))
                        : NetworkImage(report.caregiverProfilePhoto!)) as ImageProvider
                    : null,
                child: (report.caregiverProfilePhoto == null || report.caregiverProfilePhoto!.isEmpty)
                    ? Text(
                        report.caregiverName.isNotEmpty ? report.caregiverName.substring(0, 1).toUpperCase() : 'C',
                        style: const TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.bold),
                      )
                    : null,
              ),
              const SizedBox(width: 8),
              Text.rich(
                TextSpan(
                  text: 'Logged by: ',
                  style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: Color(0xFF64748B)),
                  children: [
                    TextSpan(
                      text: report.caregiverName,
                      style: const TextStyle(fontWeight: FontWeight.w900, color: Color(0xFF0F172A)),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(color: const Color(0xFFF8FAFC), borderRadius: BorderRadius.circular(16)),
            child: Text(report.text, style: const TextStyle(fontSize: 13, color: Color(0xFF334155), height: 1.6, fontWeight: FontWeight.w500)),
          ),
          if (report.photoUrls.isNotEmpty) ...[
            const SizedBox(height: 20),
            const Row(
              children: [
                Icon(Icons.camera_alt_outlined, size: 14, color: Color(0xFF94A3B8)),
                SizedBox(width: 6),
                Text('UPLOADED PHOTO DOCUMENTATION', style: TextStyle(fontSize: 10, fontWeight: FontWeight.w900, color: Color(0xFF94A3B8), letterSpacing: 0.8)),
              ],
            ),
            const SizedBox(height: 10),
            SizedBox(
              height: 140,
              child: ListView.separated(
                scrollDirection: Axis.horizontal,
                itemCount: report.photoUrls.length,
                separatorBuilder: (_, __) => const SizedBox(width: 10),
                itemBuilder: (context, i) {
                  final url = report.photoUrls[i];
                  return GestureDetector(
                    onTap: () => setState(() => _lightboxImageUrl = url),
                    child: Stack(
                      children: [
                        ClipRRect(
                          borderRadius: BorderRadius.circular(16),
                          child: url.startsWith('data:image')
                              ? Image.memory(base64Decode(url.split(',')[1]), width: 200, height: 140, fit: BoxFit.cover)
                              : Image.network(
                                  url, width: 200, height: 140, fit: BoxFit.cover,
                                  errorBuilder: (_, __, ___) => Container(width: 200, height: 140, color: const Color(0xFFE2E8F0), child: const Icon(Icons.broken_image, color: Color(0xFF94A3B8))),
                                ),
                        ),
                      ],
                    ),
                  );
                },
              ),
            ),
          ],
          const SizedBox(height: 24),
          const Divider(height: 1, color: Color(0xFFF1F5F9)),
          const SizedBox(height: 16),
          Row(
            children: [
              const Icon(Icons.thumb_up_alt_outlined, size: 14, color: Color(0xFF94A3B8)),
              const SizedBox(width: 6),
              Text('FAMILY ACKNOWLEDGEMENTS (${report.acknowledgements.length})', style: const TextStyle(fontSize: 10, fontWeight: FontWeight.w900, color: Color(0xFF94A3B8), letterSpacing: 0.8)),
            ],
          ),
          const SizedBox(height: 12),
          if (report.acknowledgements.isNotEmpty) ...report.acknowledgements.map((ack) => _buildAckItem(ack)),
          if (isFamily) _buildAcknowledgeInput(report.id),
        ],
      ),
    );
  }

  Widget _buildAckItem(CareAcknowledgement ack) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFFF0FDF4),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFDCFCE7)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // FIX 2: Updates Family Member Acknowledgement Icon to Parse the dynamic family profile photo
          CircleAvatar(
            radius: 16,
            backgroundColor: const Color(0xFF10B981),
            backgroundImage: (ack.familyProfilePhoto != null && ack.familyProfilePhoto!.isNotEmpty)
                ? (ack.familyProfilePhoto!.startsWith('data:image')
                    ? MemoryImage(base64Decode(ack.familyProfilePhoto!.split(',')[1]))
                    : NetworkImage(ack.familyProfilePhoto!)) as ImageProvider
                : null,
            child: (ack.familyProfilePhoto == null || ack.familyProfilePhoto!.isEmpty)
                ? Text(
                    ack.familyName.isNotEmpty ? ack.familyName.substring(0, 1).toUpperCase() : 'F',
                    style: const TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.bold),
                  )
                : null,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      '${ack.familyName} (${ack.relationship})',
                      style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w900, color: Color(0xFF064E3B)),
                    ),
                    Text(
                      DateFormat('hh:mm a').format(ack.timestamp),
                      style: const TextStyle(fontSize: 10, fontWeight: FontWeight.w800, color: Color(0xFF059669)),
                    ),
                  ],
                ),
                const SizedBox(height: 4),
                Text(
                  ack.comment,
                  style: const TextStyle(fontSize: 13, color: Color(0xFF065F46), fontWeight: FontWeight.w500),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAcknowledgeInput(String reportId) {
    final commentController = TextEditingController();
    return Padding(
      padding: const EdgeInsets.only(top: 8.0),
      child: Row(
        children: [
          Expanded(
            child: TextField(
              controller: commentController,
              decoration: InputDecoration(
                hintText: 'Add thank you note or question...',
                hintStyle: const TextStyle(fontSize: 12, color: Color(0xFF94A3B8)),
                filled: true,
                fillColor: Colors.white,
                contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: const BorderSide(color: Color(0xFFE2E8F0)),
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: const BorderSide(color: Color(0xFFE2E8F0)),
                ),
              ),
            ),
          ),
          const SizedBox(width: 8),
          ElevatedButton.icon(
            onPressed: () async {
              final comment = commentController.text.trim();
              final success = await ref.read(familyDashboardProvider.notifier).acknowledgeReport(reportId, comment);
              if (success && mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Report acknowledged!'), backgroundColor: Color(0xFF10B981)),
                );
              }
            },
            icon: const Icon(Icons.check, size: 16),
            label: const Text('ACKNOWLEDGE', style: TextStyle(fontWeight: FontWeight.w900, fontSize: 11)),
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF10B981),
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            ),
          ),
        ],
      ),
    );
  }
}

class _NewReportModal extends ConsumerStatefulWidget {
  final String patientId;
  final CareReport? existingReport;

  const _NewReportModal({required this.patientId, this.existingReport});

  @override
  ConsumerState<_NewReportModal> createState() => _NewReportModalState();
}

class _NewReportModalState extends ConsumerState<_NewReportModal> {
  late TextEditingController _titleController;
  late TextEditingController _notesController;
  late ReportCategory _category;
  final ImagePicker _picker = ImagePicker();
  String? _base64Image;

  @override
  void initState() {
    super.initState();
    _titleController = TextEditingController(text: widget.existingReport?.title ?? '');
    _notesController = TextEditingController(text: widget.existingReport?.text ?? '');
    _category = widget.existingReport?.category ?? ReportCategory.dailyLog;
    _base64Image = widget.existingReport?.photoUrls.isNotEmpty == true ? widget.existingReport!.photoUrls.first : null;
  }

  @override
  void dispose() {
    _titleController.dispose();
    _notesController.dispose();
    super.dispose();
  }

  Future<void> _pickImage(ImageSource source) async {
    final XFile? image = await _picker.pickImage(source: source, imageQuality: 70);
    if (image != null) {
      final bytes = await image.readAsBytes();
      setState(() {
        _base64Image = "data:image/jpeg;base64,${base64Encode(bytes)}";
      });
    }
  }

  Future<void> _submitReport() async {
    final title = _titleController.text.trim();
    final notes = _notesController.text.trim();

    if (title.isEmpty || notes.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please provide a title and detailed notes.')),
      );
      return;
    }

    bool success = false;
    if (widget.existingReport == null) {
      success = await ref.read(caregiverProvider.notifier).submitCareReport(
        patientId: widget.patientId,
        category: _category.name,
        healthStatusNotes: title,
        dailyActivities: 'Daily Care Routine',
        observations: notes,
        photoUrl: _base64Image,
      );
    } else {
      success = await ref.read(caregiverProvider.notifier).editCareReport(
        patientId: widget.patientId,
        reportId: widget.existingReport!.id,
        category: _category.name,
        healthStatusNotes: title,
        dailyActivities: 'Daily Care Routine',
        observations: notes,
        photoUrl: _base64Image,
      );
    }

    if (success && mounted) {
      Navigator.pop(context);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(widget.existingReport == null ? 'Report submitted!' : 'Report updated!'),
          backgroundColor: const Color(0xFF10B981),
        ),
      );
    } else if (mounted) {
      final error = ref.read(caregiverProvider).errorMessage;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(error ?? 'Failed to save care report.')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final isLoading = ref.watch(caregiverProvider).isLoading;

    return Container(
      padding: EdgeInsets.only(
        top: 24,
        left: 24,
        right: 24,
        bottom: MediaQuery.of(context).viewInsets.bottom + 24,
      ),
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(36)),
      ),
      child: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  widget.existingReport == null ? 'Submit Care Report' : 'Edit Care Report',
                  style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w900, color: Color(0xFF0F172A)),
                ),
                IconButton(
                  icon: const Icon(Icons.close),
                  onPressed: () => Navigator.pop(context),
                ),
              ],
            ),
            const SizedBox(height: 16),
            TextField(
              controller: _titleController,
              decoration: const InputDecoration(
                labelText: 'Report Title',
                hintText: 'e.g. Skin scratch dressing applied',
              ),
            ),
            const SizedBox(height: 14),
            const Text('CATEGORY', style: TextStyle(fontSize: 10, fontWeight: FontWeight.w900, color: Color(0xFF94A3B8))),
            const SizedBox(height: 6),
            DropdownButtonFormField<ReportCategory>(
              value: _category,
              items: ReportCategory.values.map((cat) {
                return DropdownMenuItem(
                  value: cat,
                  child: Text('${cat.emoji} ${cat.label}'),
                );
              }).toList(),
              onChanged: (val) {
                if (val != null) setState(() => _category = val);
              },
              decoration: const InputDecoration(contentPadding: EdgeInsets.symmetric(horizontal: 16, vertical: 12)),
            ),
            const SizedBox(height: 14),
            TextField(
              controller: _notesController,
              maxLines: 3,
              decoration: const InputDecoration(
                labelText: 'Detailed Notes & Observations',
                hintText: 'Describe care activity, symptoms, wound status, or meal intake...',
              ),
            ),
            const SizedBox(height: 16),
            const Text('ATTACH PHOTO', style: TextStyle(fontSize: 10, fontWeight: FontWeight.w900, color: Color(0xFF94A3B8))),
            const SizedBox(height: 8),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: () => _pickImage(ImageSource.camera),
                    icon: const Icon(Icons.camera_alt),
                    label: const Text('CAMERA'),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: () => _pickImage(ImageSource.gallery),
                    icon: const Icon(Icons.photo_library),
                    label: const Text('GALLERY'),
                  ),
                ),
              ],
            ),
            if (_base64Image != null) ...[
              const SizedBox(height: 12),
              ClipRRect(
                borderRadius: BorderRadius.circular(12),
                child: _base64Image!.startsWith('data:image')
                    ? Image.memory(base64Decode(_base64Image!.split(',')[1]), height: 100, width: double.infinity, fit: BoxFit.cover)
                    : Image.network(_base64Image!, height: 100, width: double.infinity, fit: BoxFit.cover),
              ),
            ],
            const SizedBox(height: 24),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: isLoading ? null : _submitReport,
                icon: isLoading
                    ? const SizedBox(width: 18, height: 18, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                    : const Icon(Icons.save),
                label: Text(widget.existingReport == null ? 'SUBMIT REPORT NOW' : 'SAVE CHANGES', style: const TextStyle(fontWeight: FontWeight.w900, letterSpacing: 0.5)),
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF2563EB),
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}