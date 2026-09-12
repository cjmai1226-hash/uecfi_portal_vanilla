import 'package:flutter/material.dart';

enum LegalDocType { termsOfService, privacyPolicy, communityStandards, about }

class LegalAboutSheet extends StatelessWidget {
  final LegalDocType type;

  const LegalAboutSheet({super.key, required this.type});

  static void show(BuildContext context, LegalDocType type) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final cardBg = isDark ? const Color(0xFF1E1E2A) : Colors.white;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: cardBg,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (_) => LegalAboutSheet(type: type),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final primaryColor = Theme.of(context).colorScheme.primary;
    final textPrimary = isDark
        ? const Color(0xFFF5F5FA)
        : const Color(0xFF0E0E14);
    final textSecondary = isDark
        ? const Color(0xFF9E9EAF)
        : const Color(0xFF6E6E82);
    final borderColor = isDark
        ? const Color(0xFF2E2E3E)
        : const Color(0xFFE5E5ED);

    return DraggableScrollableSheet(
      initialChildSize: type == LegalDocType.about ? 0.78 : 0.85,
      minChildSize: 0.5,
      maxChildSize: 0.95,
      expand: false,
      builder: (context, scrollController) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Drag Handle
              Center(
                child: Container(
                  width: 44,
                  height: 4,
                  decoration: BoxDecoration(
                    color: isDark ? Colors.white24 : Colors.black12,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              const SizedBox(height: 18),

              // Header Tag & Action
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 10,
                      vertical: 4,
                    ),
                    decoration: BoxDecoration(
                      color: primaryColor.withValues(
                        alpha: isDark ? 0.25 : 0.12,
                      ),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(
                      _getHeaderBadge(type),
                      style: TextStyle(
                        color: primaryColor,
                        fontSize: 10.5,
                        fontWeight: FontWeight.w800,
                        letterSpacing: 0.8,
                      ),
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.close_rounded, size: 22),
                    color: textSecondary,
                    onPressed: () => Navigator.of(context).pop(),
                  ),
                ],
              ),
              const SizedBox(height: 8),

              // Title
              Text(
                _getTitle(type),
                style: TextStyle(
                  color: textPrimary,
                  fontSize: 22,
                  fontWeight: FontWeight.w800,
                  height: 1.25,
                ),
              ),
              const SizedBox(height: 4),

              // Subtitle / Effective Date
              Text(
                _getSubtitle(type),
                style: TextStyle(
                  color: textSecondary,
                  fontSize: 12.5,
                  fontWeight: FontWeight.w500,
                ),
              ),

              const SizedBox(height: 14),
              Divider(color: borderColor),
              const SizedBox(height: 10),

              // Scrollable Body Content
              Expanded(
                child: SingleChildScrollView(
                  controller: scrollController,
                  physics: const BouncingScrollPhysics(),
                  child: type == LegalDocType.about
                      ? _buildAboutContent(
                          context,
                          textPrimary,
                          textSecondary,
                          primaryColor,
                          borderColor,
                          isDark,
                        )
                      : _buildTextDocumentContent(
                          type,
                          textPrimary,
                          textSecondary,
                          primaryColor,
                        ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  String _getHeaderBadge(LegalDocType type) {
    switch (type) {
      case LegalDocType.termsOfService:
        return 'LEGAL TERMS';
      case LegalDocType.privacyPolicy:
        return 'DATA PROTECTION';
      case LegalDocType.communityStandards:
        return 'CODE OF CONDUCT';
      case LegalDocType.about:
        return 'OFFICIAL PORTAL';
    }
  }

  String _getTitle(LegalDocType type) {
    switch (type) {
      case LegalDocType.termsOfService:
        return 'Terms of Service';
      case LegalDocType.privacyPolicy:
        return 'Privacy Policy';
      case LegalDocType.communityStandards:
        return 'Community Standards';
      case LegalDocType.about:
        return 'About UECFI Portal';
    }
  }

  String _getSubtitle(LegalDocType type) {
    switch (type) {
      case LegalDocType.termsOfService:
        return 'Effective Date: September 2026 • District 3';
      case LegalDocType.privacyPolicy:
        return 'Philippine DPA (RA 10173) & Ecclesiastical Privacy Guidelines';
      case LegalDocType.communityStandards:
        return 'Christ-Centered Fellowship & Ministerial Stewardship Principles';
      case LegalDocType.about:
        return 'Union Espiritista Cristiana de Filipinas, Inc.';
    }
  }

  Widget _buildTextDocumentContent(
    LegalDocType type,
    Color textPrimary,
    Color textSecondary,
    Color primaryColor,
  ) {
    final sections = _getSections(type);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        for (final section in sections) ...[
          Text(
            section.heading,
            style: TextStyle(
              fontSize: 15,
              fontWeight: FontWeight.w700,
              color: textPrimary,
              height: 1.4,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            section.body,
            style: TextStyle(fontSize: 13.5, height: 1.6, color: textSecondary),
          ),
          const SizedBox(height: 18),
        ],
        const SizedBox(height: 16),
      ],
    );
  }

  Widget _buildAboutContent(
    BuildContext context,
    Color textPrimary,
    Color textSecondary,
    Color primaryColor,
    Color borderColor,
    bool isDark,
  ) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // App Identity Header Card
        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(18),
          decoration: BoxDecoration(
            color: isDark ? const Color(0xFF16161F) : const Color(0xFFF9F9FC),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: borderColor),
          ),
          child: Row(
            children: [
              ClipRRect(
                borderRadius: BorderRadius.circular(14),
                child: Image.asset(
                  'assets/images/uecfi_pmm_logo.png',
                  width: 58,
                  height: 58,
                  fit: BoxFit.contain,
                  errorBuilder: (context, error, stackTrace) => Container(
                    width: 58,
                    height: 58,
                    decoration: BoxDecoration(
                      color: primaryColor.withValues(alpha: 0.15),
                      borderRadius: BorderRadius.circular(14),
                    ),
                    child: Icon(
                      Icons.church_rounded,
                      color: primaryColor,
                      size: 30,
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'UECFI District 3 Portal',
                      style: TextStyle(
                        fontSize: 17,
                        fontWeight: FontWeight.w800,
                        color: textPrimary,
                      ),
                    ),
                    const SizedBox(height: 3),
                    Text(
                      'Version 1.0.0 (Vanilla Edition)',
                      style: TextStyle(
                        fontSize: 12.5,
                        fontWeight: FontWeight.w600,
                        color: primaryColor,
                      ),
                    ),
                    const SizedBox(height: 2),
                    // Text(
                    //   'District 3 • Central Ecclesiastical Council',
                    //   style: TextStyle(
                    //     fontSize: 12,
                    //     color: textSecondary,
                    //   ),
                    // ),
                  ],
                ),
              ),
            ],
          ),
        ),

        const SizedBox(height: 20),

        _buildAboutSection(
          title: 'Organization & Mission',
          body:
              'The Union Espiritista Cristiana de Filipinas, Inc. (UECFI) is dedicated to Christian spiritual fellowship, charitable works, moral elevation, and spreading the Gospel of love, charity, and truth. District 3 encompasses all church centers, mission stations, and foreign fellowships under the supervision of the District Overseer and Council.',
          textPrimary: textPrimary,
          textSecondary: textSecondary,
        ),

        _buildAboutSection(
          title: 'Purpose of the Portal',
          body:
              'The UECFI District 3 Portal serves as the official mobile gateway for ministers, church officers, and congregants. It provides direct access to the district member directory, church status records, official pastoral letters and announcements, interactive PDF forms and templates, and the doctrinal Constitution and By-Laws.',
          textPrimary: textPrimary,
          textSecondary: textSecondary,
        ),

        _buildAboutSection(
          title: 'Key System Capabilities',
          body:
              '• Unified Directory & Registry: Real-time member profiles and ministry assignments.\n• Center Status & Mapping: Comprehensive records of local, area, and foreign centers.\n• District Communications: Instant publishing of announcements and pastoral letters.\n• Documents & Forms: Offline downloadable application forms and official bylaws.\n• Role-Based Security: Multi-tiered access control protecting congregation data.',
          textPrimary: textPrimary,
          textSecondary: textSecondary,
        ),

        _buildAboutSection(
          title: 'District Governance',
          body:
              'Overseen by the UECFI Central District 3 Leadership, comprising the District Overseer, District Board of Trustees, Area Coordinators, and Local Senior Pastors in accordance with the UECFI Constitution.',
          textPrimary: textPrimary,
          textSecondary: textSecondary,
        ),

        const SizedBox(height: 10),

        // Copyright Footer
        Center(
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 12.0),
            child: Text(
              '© 2026 Union Espiritista Cristiana de Filipinas, Inc.\nAll Rights Reserved.',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 11.5,
                color: textSecondary.withValues(alpha: 0.8),
                height: 1.5,
              ),
            ),
          ),
        ),
        const SizedBox(height: 16),
      ],
    );
  }

  Widget _buildAboutSection({
    required String title,
    required String body,
    required Color textPrimary,
    required Color textSecondary,
  }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 18.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: TextStyle(
              fontSize: 15,
              fontWeight: FontWeight.w700,
              color: textPrimary,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            body,
            style: TextStyle(fontSize: 13.5, height: 1.6, color: textSecondary),
          ),
        ],
      ),
    );
  }

  List<_LegalSection> _getSections(LegalDocType type) {
    switch (type) {
      case LegalDocType.termsOfService:
        return const [
          _LegalSection(
            heading: '1. Acceptance of Terms',
            body:
                'By accessing or using the UECFI District 3 Portal ("the Portal"), you agree to be bound by these Terms of Service, all applicable church bylaws, and applicable national laws. If you do not agree with any of these terms, you must refrain from accessing or using the Portal.',
          ),
          _LegalSection(
            heading: '2. User Accounts & Role-Based Access',
            body:
                'Access to the Portal is granted to authorized ministers, church officers, and members of UECFI District 3. You are solely responsible for maintaining the confidentiality of your credentials. Access privileges are strictly governed by your ecclesiastical role (Administrator, District Leader, Area Coordinator, Local Officer, or Church Member). Sharing accounts or attempting unauthorized administrative access is strictly prohibited.',
          ),
          _LegalSection(
            heading: '3. Acceptable Use Policy',
            body:
                'The Portal is designed exclusively for church administration, member registration, pastoral care, and official fellowship communications. You agree not to: (a) extract, scrape, or distribute member contact details for commercial, marketing, or non-church purposes; (b) publish defamatory, obscene, or fraudulent content; or (c) compromise the integrity or security of the application.',
          ),
          _LegalSection(
            heading: '4. Official Publications & Pastoral Dispatches',
            body:
                'Announcements, notices, and pastoral letters posted by District Leaders and Administrators constitute official district communications. Users must respect the doctrinal integrity and ecclesiastical authority of published documents.',
          ),
          _LegalSection(
            heading: '5. Intellectual Property & Church Heritage',
            body:
                'All texts, logos, official application forms, constitution archives, and graphical layouts contained within the Portal remain the intellectual and spiritual property of the Union Espiritista Cristiana de Filipinas, Inc. Reproduction or redistribution outside authorized activities is prohibited without prior written consent from the District Council.',
          ),
          _LegalSection(
            heading: '6. Account Suspension & Termination',
            body:
                'The District Council reserves the right to suspend, limit, or revoke access to the Portal for any user who violates these Terms, breaches the church code of conduct, or ceases to be in good standing within the fellowship.',
          ),
          _LegalSection(
            heading: '7. Amendments to Terms',
            body:
                'UECFI District 3 reserves the right to revise or update these Terms at any time. Continued access to the Portal following any modifications signifies acceptance of the revised Terms.',
          ),
        ];

      case LegalDocType.privacyPolicy:
        return const [
          _LegalSection(
            heading: '1. Commitment to Privacy & RA 10173 Compliance',
            body:
                'UECFI Central District 3 is committed to protecting the privacy, sanctity, and confidentiality of all member information in strict alignment with the Philippine Data Privacy Act of 2012 (Republic Act No. 10173) and our sacred pastoral obligation to safeguard our flock.',
          ),
          _LegalSection(
            heading: '2. Personal Data We Collect',
            body:
                'When registering or updating profiles in the Portal, the following information may be collected: full legal name, date of birth, contact telephone number, residential address, email address, marital status, spiritual milestones (conversion, water baptism, confirmation), ministry gifts, positions held, and center affiliation.',
          ),
          _LegalSection(
            heading: '3. Purpose of Processing',
            body:
                'Personal information is processed solely for official church ministry purposes, including: (a) maintaining the official district directory and church center rosters; (b) pastoral visitation and spiritual care; (c) credentialing for district assemblies and conferences; (d) communications regarding district programs and emergencies; and (e) demographic and statistical reporting to the General Assembly.',
          ),
          _LegalSection(
            heading: '4. Role-Based Privacy & Compartmentalization',
            body:
                'We enforce strict role-based data partitioning. Local officers can only access member details within their designated center. Area coordinators have access to centers within their area, while sensitive confidential records are protected against unauthorized discovery across general membership tiers.',
          ),
          _LegalSection(
            heading: '5. Security of Information',
            body:
                'We employ industry-standard encryption protocols via Google Firebase Firestore and secure local SQLite storage. Administrative credentials and session tokens are protected to prevent unauthorized data breaches or leaks.',
          ),
          _LegalSection(
            heading: '6. Member Rights & Data Access',
            body:
                'Members possess the right to: (a) view and review their recorded personal data; (b) request prompt correction of inaccurate or outdated information; and (c) raise concerns regarding pastoral data privacy by contacting the local center pastor or the District Secretariat.',
          ),
        ];

      case LegalDocType.communityStandards:
        return const [
          _LegalSection(
            heading: '1. Christ-Centered Fellowship',
            body:
                '"Therefore, as God\'s chosen people, holy and dearly loved, clothe yourselves with compassion, kindness, humility, gentleness and patience" (Colossians 3:12). All interactions, official dispatches, and member records must uphold biblical standards of love, honor, and truth.',
          ),
          _LegalSection(
            heading: '2. Edifying Communication',
            body:
                'Any communications, announcements, or messages shared through District 3 channels must build up the body of Christ (Ephesians 4:29). Slander, abusive language, partisan divisiveness, gossiping, or unauthorized solicitations have no place in the fellowship.',
          ),
          _LegalSection(
            heading: '3. Sacred Trust of Contact Information',
            body:
                'The member directory is a ministry resource grounded in mutual spiritual trust. Members and officers must never use phone numbers, email addresses, or personal information found in the directory for external commercial marketing, unsolicited mass messaging, or non-ministry purposes.',
          ),
          _LegalSection(
            heading: '4. Doctrinal Harmony & Respect for Order',
            body:
                'All published posts and ministry initiatives must harmonize with the doctrinal tenets and bylaws of the Union Espiritista Cristiana de Filipinas, Inc. Ecclesiastical authority and the leadership structure must be honored.',
          ),
          _LegalSection(
            heading: '5. Biblical Reconciliation & Grievance',
            body:
                'In the event of interpersonal conflicts, administrative misunderstandings, or concerns regarding church governance, members and leaders agree to follow the biblical framework of reconciliation outlined in Matthew 18:15-17 through local pastoral counsel and the District Board.',
          ),
        ];

      case LegalDocType.about:
        return const [];
    }
  }
}

class _LegalSection {
  final String heading;
  final String body;

  const _LegalSection({required this.heading, required this.body});
}
