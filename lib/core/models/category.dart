import 'package:equatable/equatable.dart';

/// Represents a Category item from the EBS Biocrop 3-level taxonomy hierarchy.
/// Level 0: Major Root categories (parentId == null)
/// Level 1: Sub-categories (parentId == rootId)
/// Level 2: Sub-sub-categories (parentId == subId)
class CategoryItem extends Equatable {
  final String id;
  final String name;
  final String slug;
  final String? parentId;
  final int level;
  final int sortOrder;
  final bool isActive;
  final String? iconUrl;
  final String? categoryImageUrl;
  final String? bannerImage;
  final String? bannerTitle;
  final String? cataloguePdf;
  final DateTime? createdAt;
  final DateTime? updatedAt;
  final List<CategoryItem> children;

  const CategoryItem({
    required this.id,
    required this.name,
    required this.slug,
    this.parentId,
    this.level = 0,
    this.sortOrder = 0,
    this.isActive = true,
    this.iconUrl,
    this.categoryImageUrl,
    this.bannerImage,
    this.bannerTitle,
    this.cataloguePdf,
    this.createdAt,
    this.updatedAt,
    this.children = const [],
  });

  bool get isRoot => level == 0;
  bool get isSub => level == 1;
  bool get isSubSub => level == 2;

  int get displayOrder => sortOrder;

  /// Effective icon or image identifier.
  /// iconUrl from DB ('🌾' or URL) takes precedence over categoryImageUrl.
  String? get effectiveIcon => iconUrl ?? categoryImageUrl;

  /// Whether any icon or image is configured.
  bool get hasIcon => effectiveIcon != null && effectiveIcon!.trim().isNotEmpty;

  /// Checks if the icon is a text emoji (e.g. '🌾', '🌱', '🐛', '🚜')
  /// rather than a network URL or local file path.
  bool get isEmojiIcon {
    final icon = effectiveIcon?.trim();
    if (icon == null || icon.isEmpty) return false;
    if (icon.startsWith('http://') ||
        icon.startsWith('https://') ||
        icon.startsWith('/') ||
        icon.startsWith('assets/')) {
      return false;
    }
    final lower = icon.toLowerCase();
    if (lower.endsWith('.png') ||
        lower.endsWith('.jpg') ||
        lower.endsWith('.jpeg') ||
        lower.endsWith('.svg') ||
        lower.endsWith('.webp') ||
        lower.endsWith('.gif')) {
      return false;
    }
    return true;
  }

  String get levelLabel {
    switch (level) {
      case 0:
        return 'L0 Root';
      case 1:
        return 'L1 Sub';
      case 2:
        return 'L2 Leaf';
      default:
        return 'L$level';
    }
  }

  int get directChildrenCount => children.length;

  int get totalDescendantsCount {
    int count = children.length;
    for (final child in children) {
      count += child.children.length;
    }
    return count;
  }

  factory CategoryItem.fromJson(Map<String, dynamic> json) {
    DateTime? parseDate(dynamic val) {
      if (val == null) return null;
      if (val is DateTime) return val;
      return DateTime.tryParse(val.toString());
    }

    int parseInt(dynamic val, int fallback) {
      if (val == null) return fallback;
      if (val is num) return val.toInt();
      return int.tryParse(val.toString()) ?? fallback;
    }

    bool parseBool(dynamic val, bool fallback) {
      if (val == null) return fallback;
      if (val is bool) return val;
      return val.toString().toLowerCase() == 'true';
    }

    String? parseString(dynamic val) {
      if (val == null) return null;
      final str = val.toString().trim();
      return str.isEmpty ? null : str;
    }

    final childrenList = <CategoryItem>[];
    if (json['children'] is List) {
      for (final child in json['children']) {
        if (child is Map<String, dynamic>) {
          childrenList.add(CategoryItem.fromJson(child));
        }
      }
    }

    final parsedIcon = parseString(json['iconUrl']) ?? parseString(json['categoryImageUrl']);
    final parsedOrder = parseInt(json['displayOrder'], parseInt(json['sortOrder'], 0));

    return CategoryItem(
      id: json['id']?.toString() ?? json['_id']?.toString() ?? '',
      name: json['name']?.toString() ?? '',
      slug: json['slug']?.toString() ?? '',
      parentId: parseString(json['parentId']),
      level: parseInt(json['level'], 0),
      sortOrder: parsedOrder,
      isActive: parseBool(json['isActive'], true),
      iconUrl: parseString(json['iconUrl']) ?? parsedIcon,
      categoryImageUrl: parseString(json['categoryImageUrl']) ??
          (parsedIcon != null && (parsedIcon.startsWith('http') || parsedIcon.startsWith('/')) ? parsedIcon : null),
      bannerImage: parseString(json['bannerImage']),
      bannerTitle: parseString(json['bannerTitle']),
      cataloguePdf: parseString(json['cataloguePdf']),
      createdAt: parseDate(json['createdAt']),
      updatedAt: parseDate(json['updatedAt']),
      children: childrenList,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'slug': slug,
      'parentId': parentId,
      'level': level,
      'displayOrder': sortOrder,
      'sortOrder': sortOrder,
      'isActive': isActive,
      'iconUrl': iconUrl ?? categoryImageUrl,
      'categoryImageUrl': categoryImageUrl,
      'bannerImage': bannerImage,
      'bannerTitle': bannerTitle,
      'cataloguePdf': cataloguePdf,
      'createdAt': createdAt?.toIso8601String(),
      'updatedAt': updatedAt?.toIso8601String(),
      'children': children.map((c) => c.toJson()).toList(),
    };
  }

  CategoryItem copyWith({
    String? id,
    String? name,
    String? slug,
    String? parentId,
    int? level,
    int? sortOrder,
    int? displayOrder,
    bool? isActive,
    String? iconUrl,
    String? categoryImageUrl,
    String? bannerImage,
    String? bannerTitle,
    String? cataloguePdf,
    DateTime? createdAt,
    DateTime? updatedAt,
    List<CategoryItem>? children,
  }) {
    return CategoryItem(
      id: id ?? this.id,
      name: name ?? this.name,
      slug: slug ?? this.slug,
      parentId: parentId ?? this.parentId,
      level: level ?? this.level,
      sortOrder: displayOrder ?? sortOrder ?? this.sortOrder,
      isActive: isActive ?? this.isActive,
      iconUrl: iconUrl ?? this.iconUrl,
      categoryImageUrl: categoryImageUrl ?? this.categoryImageUrl,
      bannerImage: bannerImage ?? this.bannerImage,
      bannerTitle: bannerTitle ?? this.bannerTitle,
      cataloguePdf: cataloguePdf ?? this.cataloguePdf,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      children: children ?? this.children,
    );
  }

  @override
  List<Object?> get props => [
        id,
        name,
        slug,
        parentId,
        level,
        sortOrder,
        isActive,
        iconUrl,
        categoryImageUrl,
        bannerImage,
        bannerTitle,
        cataloguePdf,
        createdAt,
        updatedAt,
        children,
      ];
}
