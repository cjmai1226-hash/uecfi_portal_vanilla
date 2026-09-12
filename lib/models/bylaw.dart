class Bylaw {
  final String chapter;
  final String title;
  final String content;

  const Bylaw({
    required this.chapter,
    required this.title,
    required this.content,
  });

  String get formattedChapter {
    final clean = chapter.trim();
    if (clean.toLowerCase().startsWith('chapter')) {
      return clean;
    }
    return 'Chapter $clean';
  }

  factory Bylaw.fromMap(Map<String, dynamic> map) {
    return Bylaw(
      chapter: map['bylaw_chapter']?.toString() ?? '',
      title: map['bylaw_title']?.toString() ?? '',
      content: map['bylaw_content']?.toString() ?? '',
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'bylaw_chapter': chapter,
      'bylaw_title': title,
      'bylaw_content': content,
    };
  }
}
