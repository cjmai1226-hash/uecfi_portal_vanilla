import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../models/bylaw.dart';
import '../../services/database_service.dart';

class ConstitutionBylawsScreen extends StatefulWidget {
  const ConstitutionBylawsScreen({super.key});

  @override
  State<ConstitutionBylawsScreen> createState() =>
      _ConstitutionBylawsScreenState();
}

class _ConstitutionBylawsScreenState extends State<ConstitutionBylawsScreen> {
  final DatabaseService _dbService = DatabaseService();
  final TextEditingController _searchController = TextEditingController();

  List<Bylaw> _bylaws = [];
  List<String> _chapters = [];
  String _selectedChapter = 'All';
  bool _isLoading = true;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _initData();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _initData() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final chapters = await _dbService.getChapters();
      final bylaws = await _dbService.getBylaws(
        query: _searchController.text,
        chapter: _selectedChapter == 'All' ? null : _selectedChapter,
      );

      if (mounted) {
        setState(() {
          _chapters = chapters;
          _bylaws = bylaws;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _errorMessage = 'Error loading bylaws: $e';
          _isLoading = false;
        });
      }
    }
  }

  Future<void> _fetchFilteredBylaws() async {
    try {
      final bylaws = await _dbService.getBylaws(
        query: _searchController.text,
        chapter: _selectedChapter == 'All' ? null : _selectedChapter,
      );

      if (mounted) {
        setState(() {
          _bylaws = bylaws;
        });
      }
    } catch (e) {
      debugPrint('Error filtering bylaws: $e');
    }
  }

  void _onSearchChanged(String _) {
    _fetchFilteredBylaws();
  }

  void _onChapterSelected(String chapter) {
    if (_selectedChapter == chapter) return;
    setState(() {
      _selectedChapter = chapter;
    });
    _fetchFilteredBylaws();
  }

  void _showBylawDetails(Bylaw bylaw) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final primaryColor = Theme.of(context).colorScheme.primary;
    final textPrimary = isDark ? const Color(0xFFF5F5FA) : const Color(0xFF0E0E14);
    final textSecondary = isDark ? const Color(0xFF9E9EAF) : const Color(0xFF6E6E82);
    final cardBg = isDark ? const Color(0xFF1E1E2A) : Colors.white;
    final borderColor = isDark ? const Color(0xFF2E2E3E) : const Color(0xFFE5E5ED);

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: cardBg,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (context) => DraggableScrollableSheet(
        initialChildSize: 0.72,
        minChildSize: 0.45,
        maxChildSize: 0.94,
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

                // Header Details with Chapter Badge and Copy Action
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
                        bylaw.formattedChapter.toUpperCase(),
                        style: TextStyle(
                          color: primaryColor,
                          fontSize: 11,
                          fontWeight: FontWeight.w800,
                          letterSpacing: 0.6,
                        ),
                      ),
                    ),
                    IconButton(
                      icon: const Icon(Icons.copy_rounded, size: 20),
                      tooltip: 'Copy Content',
                      color: textSecondary,
                      onPressed: () {
                        Clipboard.setData(
                          ClipboardData(
                            text:
                                '${bylaw.formattedChapter}: ${bylaw.title}\n\n${bylaw.content}',
                          ),
                        );
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: const Row(
                              children: [
                                Icon(Icons.check_circle_rounded, color: Colors.white, size: 20),
                                SizedBox(width: 10),
                                Text('Bylaw copied to clipboard'),
                              ],
                            ),
                            backgroundColor: const Color(0xFF00C853),
                            behavior: SnackBarBehavior.floating,
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                            duration: const Duration(seconds: 2),
                          ),
                        );
                      },
                    ),
                  ],
                ),
                const SizedBox(height: 10),

                // Title
                Text(
                  bylaw.title,
                  style: TextStyle(
                    color: textPrimary,
                    fontSize: 19,
                    fontWeight: FontWeight.w800,
                    height: 1.3,
                  ),
                ),

                const SizedBox(height: 14),
                Divider(color: borderColor),
                const SizedBox(height: 12),

                // Scrollable Content
                Expanded(
                  child: SingleChildScrollView(
                    controller: scrollController,
                    physics: const BouncingScrollPhysics(),
                    child: Text(
                      bylaw.content,
                      style: TextStyle(
                        fontSize: 15,
                        height: 1.65,
                        color: textPrimary,
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 12),
              ],
            ),
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final primaryColor = Theme.of(context).colorScheme.primary;
    final textPrimary = isDark ? const Color(0xFFF5F5FA) : const Color(0xFF0E0E14);
    final textSecondary = isDark ? const Color(0xFF9E9EAF) : const Color(0xFF6E6E82);
    final cardBg = isDark ? const Color(0xFF16161F) : Colors.white;
    final borderColor = isDark ? const Color(0xFF262633) : const Color(0xFFE5E5ED);

    return Scaffold(
      appBar: AppBar(
        title: Text(
          'Constitution and By-Laws',
          style: TextStyle(
            color: textPrimary,
            fontSize: 20,
            fontWeight: FontWeight.bold,
          ),
        ),
        elevation: 0,
        scrolledUnderElevation: 1,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_rounded),
          color: textPrimary,
          onPressed: () => Navigator.of(context).pop(),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh_rounded),
            color: textPrimary,
            tooltip: 'Reload',
            onPressed: _initData,
          ),
          const SizedBox(width: 4),
        ],
      ),
      body: Column(
        children: [
          // Search Input
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
            child: TextField(
              controller: _searchController,
              onChanged: _onSearchChanged,
              style: TextStyle(fontSize: 14.5, color: textPrimary),
              decoration: InputDecoration(
                hintText: 'Search by title, chapter or keyword...',
                hintStyle: TextStyle(fontSize: 13.5, color: textSecondary),
                prefixIcon: Icon(Icons.search_rounded, color: textSecondary),
                suffixIcon: _searchController.text.isNotEmpty
                    ? IconButton(
                        icon: const Icon(Icons.clear_rounded, size: 18),
                        color: textSecondary,
                        onPressed: () {
                          _searchController.clear();
                          _fetchFilteredBylaws();
                        },
                      )
                    : null,
                filled: true,
                fillColor: cardBg,
                contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(14),
                  borderSide: BorderSide(color: borderColor),
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(14),
                  borderSide: BorderSide(color: borderColor),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(14),
                  borderSide: BorderSide(color: primaryColor, width: 1.5),
                ),
              ),
            ),
          ),

          // Chapter Filter Pills
          if (_chapters.isNotEmpty)
            SizedBox(
              height: 42,
              child: ListView.separated(
                scrollDirection: Axis.horizontal,
                padding: const EdgeInsets.symmetric(horizontal: 16),
                itemCount: _chapters.length + 1,
                separatorBuilder: (context, index) => const SizedBox(width: 8),
                itemBuilder: (context, index) {
                  final chapterName = index == 0 ? 'All' : _chapters[index - 1];
                  final isSelected = _selectedChapter == chapterName;

                  String displayLabel = chapterName;
                  if (displayLabel.toLowerCase().startsWith('chapter')) {
                    displayLabel = 'Ch. ${displayLabel.substring(7).trim()}';
                  }

                  return ChoiceChip(
                    label: Text(
                      index == 0 ? 'All Chapters' : displayLabel,
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
                        color: isSelected
                            ? Colors.white
                            : (isDark ? Colors.white70 : Colors.black87),
                      ),
                    ),
                    selected: isSelected,
                    selectedColor: primaryColor,
                    backgroundColor: cardBg,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10),
                      side: BorderSide(
                        color: isSelected ? primaryColor : borderColor,
                        width: 1,
                      ),
                    ),
                    showCheckmark: false,
                    onSelected: (_) => _onChapterSelected(chapterName),
                  );
                },
              ),
            ),

          const SizedBox(height: 8),

          // Bylaws List
          Expanded(
            child: _isLoading
                ? Center(
                    child: CircularProgressIndicator(
                      valueColor: AlwaysStoppedAnimation<Color>(primaryColor),
                    ),
                  )
                : _errorMessage != null
                    ? Center(
                        child: Padding(
                          padding: const EdgeInsets.all(24),
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              const Icon(
                                Icons.error_outline_rounded,
                                size: 48,
                                color: Color(0xFFFF2A55),
                              ),
                              const SizedBox(height: 14),
                              Text(
                                _errorMessage!,
                                textAlign: TextAlign.center,
                                style: TextStyle(
                                  color: textSecondary,
                                  fontSize: 14,
                                ),
                              ),
                              const SizedBox(height: 18),
                              ElevatedButton(
                                onPressed: _initData,
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: primaryColor,
                                  foregroundColor: Colors.white,
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(10),
                                  ),
                                ),
                                child: const Text('RETRY DATABASE LOAD'),
                              ),
                            ],
                          ),
                        ),
                      )
                    : _bylaws.isEmpty
                        ? Center(
                            child: Column(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(
                                  Icons.menu_book_outlined,
                                  size: 48,
                                  color: textSecondary.withValues(alpha: 0.5),
                                ),
                                const SizedBox(height: 12),
                                Text(
                                  'No bylaws found matching your query.',
                                  style: TextStyle(
                                    color: textSecondary,
                                    fontSize: 14,
                                  ),
                                ),
                              ],
                            ),
                          )
                        : ListView.separated(
                            padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
                            itemCount: _bylaws.length,
                            separatorBuilder: (context, index) =>
                                const SizedBox(height: 10),
                            itemBuilder: (context, index) {
                              final bylaw = _bylaws[index];

                              return Container(
                                decoration: BoxDecoration(
                                  color: cardBg,
                                  borderRadius: BorderRadius.circular(16),
                                  border: Border.all(color: borderColor, width: 1.1),
                                  boxShadow: [
                                    BoxShadow(
                                      color: Colors.black.withValues(
                                        alpha: isDark ? 0.2 : 0.03,
                                      ),
                                      blurRadius: 10,
                                      offset: const Offset(0, 3),
                                    ),
                                  ],
                                ),
                                child: Material(
                                  color: Colors.transparent,
                                  borderRadius: BorderRadius.circular(16),
                                  clipBehavior: Clip.antiAlias,
                                  child: InkWell(
                                    onTap: () => _showBylawDetails(bylaw),
                                    splashColor: primaryColor.withValues(alpha: 0.12),
                                    hoverColor: primaryColor.withValues(alpha: 0.05),
                                    child: Padding(
                                      padding: const EdgeInsets.all(16),
                                      child: Row(
                                        children: [
                                          Expanded(
                                            child: Column(
                                              crossAxisAlignment:
                                                  CrossAxisAlignment.start,
                                              children: [
                                                Container(
                                                  padding: const EdgeInsets.symmetric(
                                                    horizontal: 8,
                                                    vertical: 3,
                                                  ),
                                                  decoration: BoxDecoration(
                                                    color: primaryColor.withValues(
                                                      alpha: isDark ? 0.2 : 0.1,
                                                    ),
                                                    borderRadius:
                                                        BorderRadius.circular(6),
                                                  ),
                                                  child: Text(
                                                    bylaw.formattedChapter
                                                        .toUpperCase(),
                                                    style: TextStyle(
                                                      fontSize: 10,
                                                      fontWeight: FontWeight.w800,
                                                      letterSpacing: 0.5,
                                                      color: primaryColor,
                                                    ),
                                                  ),
                                                ),
                                                const SizedBox(height: 8),
                                                Text(
                                                  bylaw.title,
                                                  style: TextStyle(
                                                    fontSize: 15.5,
                                                    color: textPrimary,
                                                    fontWeight: FontWeight.w700,
                                                  ),
                                                ),
                                                const SizedBox(height: 5),
                                                Text(
                                                  bylaw.content,
                                                  maxLines: 2,
                                                  overflow: TextOverflow.ellipsis,
                                                  style: TextStyle(
                                                    fontSize: 12.5,
                                                    height: 1.4,
                                                    color: textSecondary,
                                                  ),
                                                ),
                                              ],
                                            ),
                                          ),
                                          const SizedBox(width: 12),
                                          Container(
                                            width: 32,
                                            height: 32,
                                            decoration: BoxDecoration(
                                              color: primaryColor.withValues(
                                                alpha: isDark ? 0.15 : 0.08,
                                              ),
                                              shape: BoxShape.circle,
                                            ),
                                            child: Icon(
                                              Icons.chevron_right_rounded,
                                              color: primaryColor,
                                              size: 20,
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                  ),
                                ),
                              );
                            },
                          ),
          ),
        ],
      ),
    );
  }
}
