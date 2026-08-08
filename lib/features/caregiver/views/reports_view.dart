import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/models/enums.dart';
import '../../../core/models/models.dart';
import '../../auth/providers/auth_provider.dart';
import '../../family/providers/family_provider.dart';
import '../../family/views/family_pairing_view.dart';
import '../providers/caregiver_provider.dart';
import '../services/caregiver_service.dart';
import '../widgets/patient_selector_bar.dart';
import 'pairing_view.dart';

class ReportsView extends ConsumerStatefulWidget {
  const ReportsView({super.key});

  @override
  ConsumerState<ReportsView> createState() => _ReportsViewState();
}

class _ReportsViewState extends ConsumerState<ReportsView> {
  ReportCategory? _categoryFilter;
  ReportSeverity? _severityFilter;
  String? _lightboxImageUrl;

  void _showNewReportModal(String activeElderlyId) {
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
      builder: (context) => _NewReportModal(patientId: activeElderlyId),
    );
  }

  void _showAcknowledgeDialog(CareReport report) {
    final commentController = TextEditingController();
    final authUser = ref.read(authProvider).user;
    final familyName = authUser?.name ?? 'Family Member';
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(28)),
        title: const Row(
          children: [
            Icon(Icons.thumb_up_outlined, color: Color(0xFF2563EB), size: 24),
            SizedBox(width: 10),
            Text('Acknowledge Report', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w900)),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Acknowledge "${report.title}" as $familyName.',
              style: const TextStyle(fontSize: 13, color: Color(0xFF64748B)),
            ),
            const SizedBox(height: 14),
            TextField(
              controller: commentController,
              maxLines: 2,
              decoration: const InputDecoration(
                hintText: 'Add an optional note to the caregiver...',
                labelText: 'Optional Comment',
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('Report acknowledged! Caregiver has been notified.'),
                  backgroundColor: Color(0xFF10B981),
                ),
              );
            },
            style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF2563EB)),
            child: const Text('Confirm Acknowledgment'),
          ),
        ],
      ),
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
    // NOTE: If using dummy reports for Family, replace caregiverState.reports with real fetched ones later.
    final reports = caregiverState.reports; 

    final filteredReports = reports.where((r) {
      if (_categoryFilter != null && r.category != _categoryFilter) return false;
      if (_severityFilter != null && r.severity != _severityFilter) return false;
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
            
            // Header Card
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
            // Category Filter Chips
            SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                children: [
                  _buildCategoryChip('All Categories', null),
                  const SizedBox(width: 8),
                  _buildCategoryChip('  Daily Log', ReportCategory.dailyLog),
                  const SizedBox(width: 8),
                  _buildCategoryChip('  Wound Care', ReportCategory.injuryWound),
                  const SizedBox(width: 8),
                  _buildCategoryChip('  Meal & Food', ReportCategory.mealNutrition),
                  const SizedBox(width: 8),
                  _buildCategoryChip('  Mobility', ReportCategory.mobilityExercise),
                  const SizedBox(width: 8),
                  _buildCategoryChip('  Medical', ReportCategory.medicalObservation),
                ],
              ),
            ),
            const SizedBox(height: 12),
            // Severity Filter Row
            Row(
              children: [
                const Text('SEVERITY: ', style: TextStyle(fontSize: 10, fontWeight: FontWeight.w900, color: Color(0xFF94A3B8))),
                const SizedBox(width: 6),
                _buildSeverityChip('All', null),
                const SizedBox(width: 6),
                _buildSeverityChip('Routine', ReportSeverity.routine),
                const SizedBox(width: 6),
                _buildSeverityChip('Attention', ReportSeverity.attention),
                const SizedBox(width: 6),
                _buildSeverityChip('Urgent', ReportSeverity.urgent),
              ],
            ),
            const SizedBox(height: 16),
            // Feed
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
                  return _buildReportCard(report, isFamily);
                },
              ),
          ],
        ),
        // Lightbox Overlay
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
                        child: Image.network(_lightboxImageUrl!),
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

  Widget _buildSeverityChip(String label, ReportSeverity? sev) {
    final isSelected = _severityFilter == sev;
    return InkWell(
      onTap: () => setState(() => _severityFilter = sev),
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
        decoration: BoxDecoration(
          color: isSelected ? const Color(0xFF0F172A) : const Color(0xFFF1F5F9),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Text(
          label,
          style: TextStyle(
            fontSize: 10,
            fontWeight: FontWeight.w900,
            color: isSelected ? Colors.white : const Color(0xFF64748B),
          ),
        ),
      ),
    );
  }

  Widget _buildReportCard(CareReport report, bool isFamily) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(32),
        border: Border.all(color: const Color(0xFFE2E8F0)),
        boxShadow: const [
          BoxShadow(color: Color(0x0A000000), blurRadius: 16, offset: Offset(0, 4)),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: const Color(0xFFEFF6FF),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: const Color(0xFFBFDBFE)),
                ),
                child: Text(
                  '${report.category.emoji} ${report.category.label.toUpperCase()}',
                  style: const TextStyle(fontSize: 10, fontWeight: FontWeight.w900, color: Color(0xFF1D4ED8)),
                ),
              ),
              const SizedBox(width: 8),
              _buildSeverityBadge(report.severity),
              const Spacer(),
              Text(
                _formatTimeAgo(report.timestamp),
                style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: Color(0xFF94A3B8)),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            report.title,
            style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w900, color: Color(0xFF0F172A), height: 1.2),
          ),
          const SizedBox(height: 4),
          Row(
            children: [
              const Icon(Icons.person, size: 14, color: Color(0xFF64748B)),
              const SizedBox(width: 4),
              Text(
                'Logged by ${report.caregiverName}',
                style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w700, color: Color(0xFF64748B)),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            report.text,
            style: const TextStyle(fontSize: 14, color: Color(0xFF334155), height: 1.5, fontWeight: FontWeight.w500),
          ),
          if (report.photoUrls.isNotEmpty) ...[
            const SizedBox(height: 14),
            SizedBox(
              height: 120,
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
                          child: Image.network(
                            url,
                            width: 140,
                            height: 120,
                            fit: BoxFit.cover,
                            errorBuilder: (_, __, ___) => Container(
                              width: 140,
                              height: 120,
                              color: const Color(0xFFE2E8F0),
                              child: const Icon(Icons.broken_image, color: Color(0xFF94A3B8)),
                            ),
                          ),
                        ),
                        Positioned(
                          right: 6,
                          bottom: 6,
                          child: Container(
                              padding: const EdgeInsets.all(4),
                              decoration: BoxDecoration(
                                color: Colors.black.withOpacity(0.6),
                                shape: BoxShape.circle,
                              ),
                            child: const Icon(Icons.fullscreen, color: Colors.white, size: 16),
                          ),
                        ),
                      ],
                    ),
                  );
                },
              ),
            ),
          ],
          if (isFamily) ...[
            const SizedBox(height: 16),
            SizedBox(
              width: double.infinity,
              child: OutlinedButton.icon(
                onPressed: () => _showAcknowledgeDialog(report),
                icon: const Icon(Icons.thumb_up_alt_outlined, size: 18),
                label: const Text('ACKNOWLEDGE REPORT', style: TextStyle(fontWeight: FontWeight.w900, fontSize: 12)),
                style: OutlinedButton.styleFrom(
                  foregroundColor: const Color(0xFF2563EB),
                  side: const BorderSide(color: Color(0xFFBFDBFE), width: 1.5),
                  padding: const EdgeInsets.symmetric(vertical: 12),
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildSeverityBadge(ReportSeverity severity) {
    Color bg;
    Color text;
    switch (severity) {
      case ReportSeverity.routine:
        bg = const Color(0xFFF1F5F9);
        text = const Color(0xFF475569);
        break;
      case ReportSeverity.attention:
        bg = const Color(0xFFFEF3C7);
        text = const Color(0xFFB45309);
        break;
      case ReportSeverity.urgent:
        bg = const Color(0xFFFEE2E2);
        text = const Color(0xFFB91C1C);
        break;
    }
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(color: bg, borderRadius: BorderRadius.circular(10)),
      child: Text(
        severity.label.toUpperCase(),
        style: TextStyle(fontSize: 9, fontWeight: FontWeight.w900, color: text),
      ),
    );
  }

  String _formatTimeAgo(DateTime dateTime) {
    final diff = DateTime.now().difference(dateTime);
    if (diff.inHours < 1) return '${diff.inMinutes} mins ago';
    if (diff.inHours < 24) return '${diff.inHours} hours ago';
    return '${diff.inDays} days ago';
  }
}

class _NewReportModal extends ConsumerStatefulWidget {
  final String patientId;
  const _NewReportModal({required this.patientId});

  @override
  ConsumerState<_NewReportModal> createState() => _NewReportModalState();
}

class _NewReportModalState extends ConsumerState<_NewReportModal> {
  final _titleController = TextEditingController();
  final _notesController = TextEditingController();
  final _photoUrlController = TextEditingController();
  ReportCategory _category = ReportCategory.dailyLog;
  ReportSeverity _severity = ReportSeverity.routine;

  @override
  void dispose() {
    _titleController.dispose();
    _notesController.dispose();
    _photoUrlController.dispose();
    super.dispose();
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
    final success = await ref.read(caregiverProvider.notifier).submitCareReport(
          patientId: widget.patientId,
          healthStatusNotes: title,
          dailyActivities: 'Daily Care Routine',
          observations: notes,
          photoUrl: _photoUrlController.text.trim().isEmpty ? null : _photoUrlController.text.trim(),
        );
    if (success && mounted) {
      Navigator.pop(context);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('New Care Report submitted and synchronized with backend!'),
          backgroundColor: Color(0xFF10B981),
        ),
      );
    } else if (mounted) {
      final error = ref.read(caregiverProvider).errorMessage;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(error ?? 'Failed to submit care report.')),
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
                const Text(
                  'Submit Care Report',
                  style: TextStyle(fontSize: 20, fontWeight: FontWeight.w900, color: Color(0xFF0F172A)),
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
            const SizedBox(height: 14),
            TextField(
              controller: _photoUrlController,
              decoration: const InputDecoration(
                labelText: 'Photo URL (Optional)',
                hintText: 'Paste image link or photo evidence URL...',
              ),
            ),
            const SizedBox(height: 24),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: isLoading ? null : _submitReport,
                icon: isLoading
                    ? const SizedBox(width: 18, height: 18, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                    : const Icon(Icons.send),
                label: const Text('SUBMIT REPORT NOW', style: TextStyle(fontWeight: FontWeight.w900, letterSpacing: 0.5)),
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