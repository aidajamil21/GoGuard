import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../models/risk_label.dart';
import '../../services/alibaba_api_service.dart';
import '../../services/risk_engine.dart';
import '../../theme/app_colors.dart';
import '../../utils/phone_masker.dart';

class ScamDbScreen extends StatefulWidget {
  const ScamDbScreen({super.key});
  @override
  State<ScamDbScreen> createState() => _ScamDbScreenState();
}

class _ScamDbScreenState extends State<ScamDbScreen> {
  final _api = AlibabaApiService();
  final _searchCtrl = TextEditingController();
  bool _searching = false;
  _SearchResult? _searchResult;
  String? _searchError;

  @override
  void dispose() {
    _searchCtrl.dispose();
    super.dispose();
  }

  Future<void> _runSearch() async {
    final raw = _searchCtrl.text.trim();
    if (raw.isEmpty) return;

    // normalise to +60…
    String phone = raw;
    if (phone.startsWith('+60')) {
      // already fine
    } else if (phone.startsWith('60')) {
      phone = '+$phone';
    } else if (phone.startsWith('0')) {
      phone = '+6$phone';
    } else {
      phone = '+60$phone';
    }

    setState(() { _searching = true; _searchResult = null; _searchError = null; });

    try {
      final result = await _api.checkRecipient(phone: phone, userId: 'community_check');
      final gnn = (result['gnn_risk_score'] as num).toDouble();
      final xgb = (result['xgboost_risk_score'] as num?)?.toDouble() ?? gnn;
      final features = Map<String, dynamic>.from(result['graph_features'] ?? {});
      final riskResult = RiskEngine.compute(gnn, xgb);
      final reports = (features['num_reported_connections'] as num?)?.toInt() ?? 0;
      final isIsolated = features['is_isolated_node'] as bool? ?? false;
      setState(() {
        _searchResult = _SearchResult(
          phone: phone,
          gnn: gnn,
          label: riskResult.riskLabel,
          reports: reports,
          isIsolated: isIsolated,
        );
        _searching = false;
      });
    } catch (e) {
      setState(() { _searchError = 'Could not analyse number. Try again.'; _searching = false; });
    }
  }

  void _showReportSheet() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => const _ReportSheet(),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.surface,
      body: Column(
        children: [
          // ── Red header ────────────────────────────────────
          Container(
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [Color(0xFFB91C1C), Color(0xFFE8333A)],
              ),
            ),
            child: SafeArea(
              bottom: false,
              child: Padding(
                padding: const EdgeInsets.fromLTRB(20, 8, 20, 20),
                child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  Row(children: [
                    GestureDetector(
                      onTap: () => Navigator.pop(context),
                      child: Container(
                        width: 32, height: 32,
                        decoration: BoxDecoration(
                          color: Colors.white.withValues(alpha: 0.2),
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(Icons.arrow_back, color: Colors.white, size: 18),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Text('Scammer Warning List',
                      style: GoogleFonts.dmSans(fontSize: 18, fontWeight: FontWeight.w700, color: Colors.white)),
                  ]),
                  const SizedBox(height: 6),
                  Text('Community-powered · Updated 2 mins ago',
                    style: GoogleFonts.dmSans(fontSize: 12, color: Colors.white.withValues(alpha: 0.75))),
                ]),
              ),
            ),
          ),

          // ── Scrollable content ────────────────────────────
          Expanded(
            child: SingleChildScrollView(
              child: Column(children: [
                // ── Search ───────────────────────────────────
                Padding(
                  padding: const EdgeInsets.fromLTRB(16, 14, 16, 0),
                  child: Container(
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(14),
                      border: Border.all(color: AppColors.border),
                      boxShadow: [BoxShadow(color: AppColors.jadeGlow, blurRadius: 8, offset: const Offset(0, 2))],
                    ),
                    child: Row(children: [
                      const SizedBox(width: 14),
                      const Icon(Icons.search, color: AppColors.text3, size: 20),
                      const SizedBox(width: 10),
                      Expanded(
                        child: TextField(
                          controller: _searchCtrl,
                          keyboardType: TextInputType.phone,
                          style: GoogleFonts.dmSans(fontSize: 14, color: AppColors.text),
                          decoration: InputDecoration(
                            hintText: 'Search phone number (e.g. 0123456789)',
                            hintStyle: GoogleFonts.dmSans(fontSize: 14, color: AppColors.text3),
                            border: InputBorder.none,
                            isDense: true,
                            contentPadding: const EdgeInsets.symmetric(vertical: 14),
                          ),
                          onSubmitted: (_) => _runSearch(),
                        ),
                      ),
                      GestureDetector(
                        onTap: _runSearch,
                        child: Container(
                          margin: const EdgeInsets.all(6),
                          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                          decoration: BoxDecoration(
                            color: const Color(0xFFB91C1C),
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: Text('Check',
                            style: GoogleFonts.dmSans(fontSize: 13, fontWeight: FontWeight.w600, color: Colors.white)),
                        ),
                      ),
                    ]),
                  ),
                ),

                // ── Search result ─────────────────────────────
                if (_searching)
                  const Padding(
                    padding: EdgeInsets.symmetric(vertical: 24),
                    child: CircularProgressIndicator(color: Color(0xFFB91C1C)),
                  ),

                if (_searchError != null)
                  Padding(
                    padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
                    child: Container(
                      padding: const EdgeInsets.all(14),
                      decoration: BoxDecoration(
                        color: AppColors.dangerLight,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: AppColors.danger.withValues(alpha: 0.3)),
                      ),
                      child: Row(children: [
                        const Icon(Icons.error_outline, color: AppColors.danger, size: 18),
                        const SizedBox(width: 8),
                        Text(_searchError!, style: GoogleFonts.dmSans(fontSize: 13, color: AppColors.danger)),
                      ]),
                    ),
                  ),

                if (_searchResult != null) _buildSearchResultCard(_searchResult!),

                // ── Stats grid ───────────────────────────────
                Padding(
                  padding: const EdgeInsets.fromLTRB(16, 14, 16, 0),
                  child: GridView.count(
                    crossAxisCount: 2,
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    crossAxisSpacing: 10,
                    mainAxisSpacing: 10,
                    childAspectRatio: 1.9,
                    children: [
                      _statCard('2,341',  'Numbers reported today',       AppColors.danger),
                      _statCard('RM 4.2M','Estimated savings this month', AppColors.jade),
                      _statCard('89K',    'Total community reports',       AppColors.warn),
                      _statCard('97%',    'ML accuracy rate',              AppColors.jade),
                    ],
                  ),
                ),

                // ── High risk ────────────────────────────────
                _sectionHeader('🔴 High Risk Numbers'),

                _reportCard(
                  phone: '+60 12-XXX 4567',
                  badge: 'HIGH RISK',
                  badgeBg: const Color(0xFFFEE2E2),
                  badgeFg: const Color(0xFF991B1B),
                  chips: ['Investment scam', 'Impersonation', 'Odd hours'],
                  reports: '47 reports',
                  reportColor: AppColors.danger,
                  lastSeen: '2 hrs ago',
                  borderColor: const Color(0xFFFCA5A5),
                ),
                _reportCard(
                  phone: '+60 18-XXX 9012',
                  badge: 'HIGH RISK',
                  badgeBg: const Color(0xFFFEE2E2),
                  badgeFg: const Color(0xFF991B1B),
                  chips: ['Love scam', 'Fake profile'],
                  reports: '31 reports',
                  reportColor: AppColors.danger,
                  lastSeen: '5 hrs ago',
                  borderColor: const Color(0xFFFCA5A5),
                ),

                // ── Medium risk ──────────────────────────────
                _sectionHeader('🟡 Medium Risk'),

                _reportCard(
                  phone: '+60 11-XXX 3456',
                  badge: 'MEDIUM',
                  badgeBg: const Color(0xFFFEF3C7),
                  badgeFg: const Color(0xFF92400E),
                  chips: ['Parcel scam', 'New number'],
                  reports: '8 reports',
                  reportColor: AppColors.warn,
                  lastSeen: '1 day ago',
                  borderColor: const Color(0xFFFDE68A),
                ),

                const SizedBox(height: 16),
              ]),
            ),
          ),

          // ── Report button pinned at bottom ────────────────
          Container(
            color: AppColors.surface,
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 0),
            child: SafeArea(
              top: false,
              child: GestureDetector(
                onTap: _showReportSheet,
                child: Container(
                  width: double.infinity,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  decoration: BoxDecoration(
                    gradient: AppColors.dangerGradient,
                    borderRadius: BorderRadius.circular(16),
                    boxShadow: [BoxShadow(color: AppColors.danger.withValues(alpha: 0.3), blurRadius: 16, offset: const Offset(0, 4))],
                  ),
                  alignment: Alignment.center,
                  child: Row(mainAxisAlignment: MainAxisAlignment.center, children: [
                    const Icon(Icons.add_circle_outline, color: Colors.white, size: 20),
                    const SizedBox(width: 8),
                    Text('Report a Scammer',
                      style: GoogleFonts.dmSans(fontSize: 15, fontWeight: FontWeight.w700, color: Colors.white)),
                  ]),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSearchResultCard(_SearchResult r) {
    final (bg, fg, borderC, icon, labelText) = switch (r.label) {
      RiskLabel.low    => (const Color(0xFFECFDF5), const Color(0xFF065F46),
                           const Color(0xFF6EE7B7), Icons.verified_rounded, 'LOW RISK'),
      RiskLabel.medium => (const Color(0xFFFFFBEB), const Color(0xFF92400E),
                           const Color(0xFFFDE68A), Icons.warning_rounded,  'MEDIUM RISK'),
      RiskLabel.high   => (AppColors.dangerLight,   const Color(0xFF991B1B),
                           const Color(0xFFFCA5A5), Icons.block_rounded,    'HIGH RISK'),
    };

    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: borderC, width: 1.5),
          boxShadow: [const BoxShadow(color: Color(0x0A000000), blurRadius: 8, offset: Offset(0, 2))],
        ),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          // Result header
          Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: bg,
              borderRadius: const BorderRadius.vertical(top: Radius.circular(13)),
            ),
            child: Row(children: [
              Icon(icon, color: fg, size: 22),
              const SizedBox(width: 10),
              Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Text('AI Analysis Result', style: GoogleFonts.dmSans(fontSize: 11, color: fg.withValues(alpha: 0.7))),
                Text(maskPhone(r.phone), style: GoogleFonts.dmMono(fontSize: 14, fontWeight: FontWeight.w700, color: fg)),
              ])),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(color: fg, borderRadius: BorderRadius.circular(20)),
                child: Text(labelText,
                  style: GoogleFonts.dmSans(fontSize: 11, fontWeight: FontWeight.w700, color: Colors.white)),
              ),
            ]),
          ),
          // Detail rows
          Padding(
            padding: const EdgeInsets.all(14),
            child: Column(children: [
              _detailRow('GNN Risk Score', '${(r.gnn * 100).toStringAsFixed(0)}%', fg),
              _detailRow('Reported Connections', '${r.reports} linked report${r.reports == 1 ? '' : 's'}',
                r.reports > 0 ? AppColors.danger : AppColors.jade),
              _detailRow('Network Profile',
                r.isIsolated ? 'Isolated node (suspicious)' : 'Normal network',
                r.isIsolated ? AppColors.danger : AppColors.jade),
            ]),
          ),
        ]),
      ),
    );
  }

  Widget _detailRow(String label, String value, Color valueColor) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 5),
      child: Row(children: [
        Expanded(child: Text(label,
          style: GoogleFonts.dmSans(fontSize: 13, color: AppColors.text2))),
        Text(value,
          style: GoogleFonts.dmSans(fontSize: 13, fontWeight: FontWeight.w600, color: valueColor)),
      ]),
    );
  }

  Widget _statCard(String number, String label, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.border),
        boxShadow: [const BoxShadow(color: Color(0x08000000), blurRadius: 8, offset: Offset(0, 2))],
      ),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Text(number,
          style: GoogleFonts.dmSans(fontSize: 22, fontWeight: FontWeight.w700, color: color)),
        const SizedBox(height: 2),
        Text(label,
          style: GoogleFonts.dmSans(fontSize: 11, color: AppColors.text3),
          maxLines: 2),
      ]),
    );
  }

  Widget _sectionHeader(String title) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
      child: Row(children: [
        Text(title,
          style: GoogleFonts.dmSans(fontSize: 14, fontWeight: FontWeight.w600, color: AppColors.text)),
      ]),
    );
  }

  Widget _reportCard({
    required String phone,
    required String badge,
    required Color badgeBg,
    required Color badgeFg,
    required List<String> chips,
    required String reports,
    required Color reportColor,
    required String lastSeen,
    required Color borderColor,
  }) {
    return Container(
      margin: const EdgeInsets.fromLTRB(16, 0, 16, 10),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: borderColor, width: 1.5),
        boxShadow: [const BoxShadow(color: Color(0x08000000), blurRadius: 8, offset: Offset(0, 2))],
      ),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Row(children: [
          Text(phone,
            style: GoogleFonts.dmSans(fontSize: 15, fontWeight: FontWeight.w700, color: AppColors.text)),
          const Spacer(),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
            decoration: BoxDecoration(color: badgeBg, borderRadius: BorderRadius.circular(20)),
            child: Text(badge,
              style: GoogleFonts.dmSans(fontSize: 11, fontWeight: FontWeight.w600, color: badgeFg)),
          ),
        ]),
        const SizedBox(height: 8),
        Wrap(
          spacing: 6, runSpacing: 4,
          children: chips.map((c) => Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
            decoration: BoxDecoration(
              color: const Color(0xFFF3F4F6),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Text(c, style: GoogleFonts.dmSans(fontSize: 11, color: const Color(0xFF6B7280))),
          )).toList(),
        ),
        const SizedBox(height: 8),
        Row(children: [
          Text(reports,
            style: GoogleFonts.dmSans(fontSize: 11, fontWeight: FontWeight.w600, color: reportColor)),
          Text(' · Last: $lastSeen',
            style: GoogleFonts.dmSans(fontSize: 11, color: AppColors.text3)),
          const Spacer(),
          Text('View details ›',
            style: GoogleFonts.dmSans(fontSize: 11, fontWeight: FontWeight.w600, color: AppColors.jade)),
        ]),
      ]),
    );
  }
}

// ── Data class ────────────────────────────────────────────
class _SearchResult {
  final String phone;
  final double gnn;
  final RiskLabel label;
  final int reports;
  final bool isIsolated;
  const _SearchResult({required this.phone, required this.gnn, required this.label,
    required this.reports, required this.isIsolated});
}

// ── Report bottom sheet ───────────────────────────────────
class _ReportSheet extends StatefulWidget {
  const _ReportSheet();
  @override
  State<_ReportSheet> createState() => _ReportSheetState();
}

class _ReportSheetState extends State<_ReportSheet> {
  final _phoneCtrl = TextEditingController();
  final _descCtrl  = TextEditingController();
  String? _selectedType;
  bool _submitted = false;

  final _types = ['Investment Scam', 'Love Scam', 'Parcel Scam', 'Impersonation', 'Bank Fraud', 'Other'];

  @override
  void dispose() { _phoneCtrl.dispose(); _descCtrl.dispose(); super.dispose(); }

  void _submit() {
    if (_phoneCtrl.text.trim().isEmpty || _selectedType == null) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
        content: Text('Please enter a phone number and select a scam type'),
        behavior: SnackBarBehavior.floating,
      ));
      return;
    }
    setState(() => _submitted = true);
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      padding: EdgeInsets.fromLTRB(20, 20, 20, MediaQuery.of(context).viewInsets.bottom + 20),
      child: _submitted ? _successView() : _formView(),
    );
  }

  Widget _successView() {
    return Column(mainAxisSize: MainAxisSize.min, children: [
      const Text('✅', style: TextStyle(fontSize: 48)),
      const SizedBox(height: 12),
      Text('Report Submitted!',
        style: GoogleFonts.dmSans(fontSize: 18, fontWeight: FontWeight.w700, color: AppColors.jade)),
      const SizedBox(height: 6),
      Text('Thank you. Our team will review this number within 24 hours.',
        textAlign: TextAlign.center,
        style: GoogleFonts.dmSans(fontSize: 13, color: AppColors.text2)),
      const SizedBox(height: 20),
      GestureDetector(
        onTap: () => Navigator.pop(context),
        child: Container(
          width: double.infinity,
          padding: const EdgeInsets.symmetric(vertical: 14),
          decoration: BoxDecoration(
            gradient: AppColors.jadeGradient,
            borderRadius: BorderRadius.circular(14),
          ),
          alignment: Alignment.center,
          child: Text('Done', style: GoogleFonts.dmSans(fontSize: 15, fontWeight: FontWeight.w700, color: Colors.white)),
        ),
      ),
    ]);
  }

  Widget _formView() {
    return Column(mainAxisSize: MainAxisSize.min, crossAxisAlignment: CrossAxisAlignment.start, children: [
      // Handle
      Center(child: Container(width: 36, height: 4, decoration: BoxDecoration(
        color: AppColors.border, borderRadius: BorderRadius.circular(2)))),
      const SizedBox(height: 16),

      Text('Report a Scammer',
        style: GoogleFonts.dmSans(fontSize: 18, fontWeight: FontWeight.w700, color: AppColors.text)),
      const SizedBox(height: 4),
      Text('Your report helps protect the community',
        style: GoogleFonts.dmSans(fontSize: 12, color: AppColors.text3)),
      const SizedBox(height: 20),

      // Phone field
      Text('Phone / Account Number',
        style: GoogleFonts.dmSans(fontSize: 13, fontWeight: FontWeight.w600, color: AppColors.text2)),
      const SizedBox(height: 6),
      Container(
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: AppColors.border),
        ),
        child: TextField(
          controller: _phoneCtrl,
          keyboardType: TextInputType.phone,
          style: GoogleFonts.dmSans(fontSize: 14, color: AppColors.text),
          decoration: InputDecoration(
            hintText: 'e.g. 0123456789',
            hintStyle: GoogleFonts.dmSans(fontSize: 14, color: AppColors.text3),
            border: InputBorder.none,
            contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
            isDense: true,
          ),
        ),
      ),
      const SizedBox(height: 16),

      // Scam type chips
      Text('Scam Type',
        style: GoogleFonts.dmSans(fontSize: 13, fontWeight: FontWeight.w600, color: AppColors.text2)),
      const SizedBox(height: 8),
      Wrap(
        spacing: 8, runSpacing: 8,
        children: _types.map((t) {
          final sel = _selectedType == t;
          return GestureDetector(
            onTap: () => setState(() => _selectedType = sel ? null : t),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 7),
              decoration: BoxDecoration(
                color: sel ? const Color(0xFFB91C1C) : AppColors.surface,
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: sel ? const Color(0xFFB91C1C) : AppColors.border, width: 1.5),
              ),
              child: Text(t, style: GoogleFonts.dmSans(
                fontSize: 12, fontWeight: FontWeight.w500,
                color: sel ? Colors.white : AppColors.text2)),
            ),
          );
        }).toList(),
      ),
      const SizedBox(height: 16),

      // Description
      Text('What happened? (optional)',
        style: GoogleFonts.dmSans(fontSize: 13, fontWeight: FontWeight.w600, color: AppColors.text2)),
      const SizedBox(height: 6),
      Container(
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: AppColors.border),
        ),
        child: TextField(
          controller: _descCtrl,
          maxLines: 3,
          style: GoogleFonts.dmSans(fontSize: 14, color: AppColors.text),
          decoration: InputDecoration(
            hintText: 'Briefly describe the scam attempt...',
            hintStyle: GoogleFonts.dmSans(fontSize: 13, color: AppColors.text3),
            border: InputBorder.none,
            contentPadding: const EdgeInsets.all(14),
            isDense: true,
          ),
        ),
      ),
      const SizedBox(height: 20),

      // Submit button
      GestureDetector(
        onTap: _submit,
        child: Container(
          width: double.infinity,
          padding: const EdgeInsets.symmetric(vertical: 15),
          decoration: BoxDecoration(
            gradient: AppColors.dangerGradient,
            borderRadius: BorderRadius.circular(14),
            boxShadow: [BoxShadow(color: AppColors.danger.withValues(alpha: 0.3), blurRadius: 12, offset: const Offset(0, 4))],
          ),
          alignment: Alignment.center,
          child: Text('Submit Report',
            style: GoogleFonts.dmSans(fontSize: 15, fontWeight: FontWeight.w700, color: Colors.white)),
        ),
      ),
    ]);
  }
}
