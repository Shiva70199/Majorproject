import 'package:flutter/material.dart';

/// Definition of supported SafeDocs document categories.
class DocumentCategoryDefinition {
  final String id;
  final String label;
  final String description;
  final IconData icon;
  final List<String> keywords;
  final String group;

  const DocumentCategoryDefinition({
    required this.id,
    required this.label,
    required this.description,
    required this.icon,
    required this.keywords,
    required this.group,
  });
}

/// Central registry for allowed document categories.
enum DocumentStatus { pending, verified, rejected }

extension DocumentStatusLabel on DocumentStatus {
  String get value {
    switch (this) {
      case DocumentStatus.pending:
        return 'pending';
      case DocumentStatus.verified:
        return 'verified';
      case DocumentStatus.rejected:
        return 'rejected';
    }
  }

  String get displayName {
    switch (this) {
      case DocumentStatus.pending:
        return 'Pending';
      case DocumentStatus.verified:
        return 'Verified';
      case DocumentStatus.rejected:
        return 'Rejected';
    }
  }
}

DocumentStatus parseDocumentStatus(String? value) {
  switch (value) {
    case 'verified':
      return DocumentStatus.verified;
    case 'rejected':
      return DocumentStatus.rejected;
    case 'pending':
    default:
      return DocumentStatus.pending;
  }
}

class DocumentCategories {
  static const academicGroup = 'Academic';
  static const certificateGroup = 'Certificates';

  static final List<DocumentCategoryDefinition> all = [
    const DocumentCategoryDefinition(
      id: 'tenth_marksheet',
      label: '10th Marksheet',
      description: 'Secondary school academic record',
      icon: Icons.school,
      keywords: [
        '10th',
        'ssc',
        's.s.l.c',
        'secondary',
        'matriculation',
        'board',
        'karnataka secondary education',
        'marks statement',
        'register no',
        'secondary school',
        'examination board',
      ],
      group: academicGroup,
    ),
    const DocumentCategoryDefinition(
      id: 'twelfth_marksheet',
      label: '12th Marksheet',
      description: 'Higher secondary academic record',
      icon: Icons.menu_book,
      keywords: [
        '12th',
        'hsc',
        'higher secondary',
        'intermediate',
        'pre-university',
        'pre university',
        'puc',
        'board',
        'department of pre-university',
        'register no',
        'college code',
        'certificate',
      ],
      group: academicGroup,
    ),
    ...List.generate(8, (index) {
      final semNumber = index + 1;
      final suffix = _ordinal(semNumber);
      return DocumentCategoryDefinition(
        id: 'ug_sem_$semNumber',
        label: '$suffix Sem Marksheet',
        description: 'UG semester $semNumber marksheet',
        icon: Icons.cast_for_education,
        keywords: [
          'ug',
          'semester $semNumber',
          'sem $semNumber',
          'sem-$semNumber',
          '$suffix semester',
          'marksheet',
          'transcript',
          'grade card',
          'university',
          'b.e',
          'bachelor',
          'usn',
          'sgpa',
          'cgpa',
          'credits',
          'grade point',
          'visvesvaraya',
          'technological university',
        ],
        group: academicGroup,
      );
    }),
    const DocumentCategoryDefinition(
      id: 'ug_certificate',
      label: 'UG Certificate',
      description: 'Final UG degree certificate',
      icon: Icons.workspace_premium,
      keywords: ['degree', 'certificate', 'bachelor', 'ug', 'graduation'],
      group: academicGroup,
    ),
    const DocumentCategoryDefinition(
      id: 'college_id_card',
      label: 'College ID Card',
      description: 'College issued identity card',
      icon: Icons.badge,
      keywords: [
        'id card',
        'identity card',
        'college id',
        'student id',
        'institute of technology',
        'institute',
        'technology',
        'sdm',
        'usn',
        'university seat number',
        'branch',
        'validity',
        'blood group',
        'date of birth',
        'd.o.b',
        'dob',
        'd o b',
        'address',
        'student signature',
        'principal',
        'photo',
        'barcode',
        'card',
        'student card',
        'college card',
        'institute card',
      ],
      group: certificateGroup,
    ),
    const DocumentCategoryDefinition(
      id: 'sports_certificate',
      label: 'Sports Certificate',
      description: 'Certificates for sports achievements',
      icon: Icons.sports_score,
      keywords: ['sports', 'athletics', 'tournament', 'medal', 'certificate'],
      group: certificateGroup,
    ),
    const DocumentCategoryDefinition(
      id: 'achievement_certificate',
      label: 'Achievement Certificate',
      description: 'Other valid achievement certificates',
      icon: Icons.emoji_events,
      keywords: ['certificate', 'achievement', 'award', 'merit', 'participation'],
      group: certificateGroup,
    ),
  ];

  static final Map<String, DocumentCategoryDefinition> _byId = {
    for (final category in all) category.id: category,
  };

  static DocumentCategoryDefinition? byId(String? id) {
    if (id == null) return null;
    return _byId[id];
  }

  static bool isAllowed(String id) => _byId.containsKey(id);

  static String _ordinal(int number) {
    if (number >= 11 && number <= 13) {
      return '${number}th';
    }
    switch (number % 10) {
      case 1:
        return '${number}st';
      case 2:
        return '${number}nd';
      case 3:
        return '${number}rd';
      default:
        return '${number}th';
    }
  }
}

