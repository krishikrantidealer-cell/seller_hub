import 'package:equatable/equatable.dart';

class SubCollectionItem extends Equatable {
  final String id;
  final String name;
  final String slug;
  final bool isActive;
  final String? image;
  final int productCount;

  const SubCollectionItem({
    required this.id,
    required this.name,
    required this.slug,
    this.isActive = true,
    this.image,
    this.productCount = 0,
  });

  factory SubCollectionItem.fromJson(Map<String, dynamic> json) {
    return SubCollectionItem(
      id: json['id'] as String? ?? json['_id'] as String? ?? '',
      name: json['name'] as String? ?? '',
      slug: json['slug'] as String? ?? '',
      isActive: json['isActive'] as bool? ?? true,
      image: json['image'] as String?,
      productCount: (json['productCount'] as num?)?.toInt() ?? 0,
    );
  }

  Map<String, dynamic> toJson() => {
    'id': id,
    'name': name,
    'slug': slug,
    'isActive': isActive,
    'image': image,
    'productCount': productCount,
  };

  SubCollectionItem copyWith({
    String? id,
    String? name,
    String? slug,
    bool? isActive,
    String? image,
    int? productCount,
  }) {
    return SubCollectionItem(
      id: id ?? this.id,
      name: name ?? this.name,
      slug: slug ?? this.slug,
      isActive: isActive ?? this.isActive,
      image: image ?? this.image,
      productCount: productCount ?? this.productCount,
    );
  }

  @override
  List<Object?> get props => [id, name, slug, isActive, image, productCount];
}

class CollectionItem extends Equatable {
  final String id;
  final String name;
  final String slug;
  final String description;
  final bool isActive;
  final int priority;
  final List<SubCollectionItem> subCollections;
  final int subCollectionCount;
  final String? createdAt;
  final String? updatedAt;
  final int productCount;
  final String? bannerTitle;

  const CollectionItem({
    required this.id,
    required this.name,
    required this.slug,
    this.description = '',
    this.isActive = true,
    this.priority = 0,
    this.subCollections = const [],
    this.subCollectionCount = 0,
    this.createdAt,
    this.updatedAt,
    this.productCount = 0,
    this.bannerTitle,
  });

  factory CollectionItem.fromJson(Map<String, dynamic> json) {
    final rawSubs = json['subCollections'] as List<dynamic>? ?? [];
    final subList = rawSubs
        .whereType<Map<String, dynamic>>()
        .map((s) => SubCollectionItem.fromJson(s))
        .toList();

    return CollectionItem(
      id: json['id'] as String? ?? json['_id'] as String? ?? '',
      name: json['name'] as String? ?? '',
      slug: json['slug'] as String? ?? '',
      description: json['description'] as String? ?? '',
      isActive: json['isActive'] as bool? ?? true,
      priority: (json['priority'] as num?)?.toInt() ?? 0,
      subCollections: subList,
      subCollectionCount: (json['subCollectionCount'] as num?)?.toInt() ?? subList.length,
      createdAt: json['createdAt'] as String?,
      updatedAt: json['updatedAt'] as String?,
      productCount: (json['productCount'] as num?)?.toInt() ?? 0,
      bannerTitle: json['bannerTitle'] as String?,
    );
  }

  Map<String, dynamic> toJson() => {
    'id': id,
    'name': name,
    'slug': slug,
    'description': description,
    'isActive': isActive,
    'priority': priority,
    'subCollections': subCollections.map((s) => s.toJson()).toList(),
    'subCollectionCount': subCollectionCount,
    'createdAt': createdAt,
    'updatedAt': updatedAt,
    'productCount': productCount,
    'bannerTitle': bannerTitle,
  };

  CollectionItem copyWith({
    String? id,
    String? name,
    String? slug,
    String? description,
    bool? isActive,
    int? priority,
    List<SubCollectionItem>? subCollections,
    int? subCollectionCount,
    String? createdAt,
    String? updatedAt,
    int? productCount,
    String? bannerTitle,
  }) {
    return CollectionItem(
      id: id ?? this.id,
      name: name ?? this.name,
      slug: slug ?? this.slug,
      description: description ?? this.description,
      isActive: isActive ?? this.isActive,
      priority: priority ?? this.priority,
      subCollections: subCollections ?? this.subCollections,
      subCollectionCount: subCollectionCount ?? this.subCollectionCount,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      productCount: productCount ?? this.productCount,
      bannerTitle: bannerTitle ?? this.bannerTitle,
    );
  }

  @override
  List<Object?> get props => [
    id,
    name,
    slug,
    description,
    isActive,
    priority,
    subCollections,
    subCollectionCount,
    createdAt,
    updatedAt,
    productCount,
    bannerTitle,
  ];
}

class CollectionsData extends Equatable {
  final int count;
  final List<CollectionItem> items;

  const CollectionsData({
    this.count = 0,
    this.items = const [],
  });

  factory CollectionsData.fromJson(Map<String, dynamic> json) {
    final rawItems = json['items'] as List<dynamic>? ?? [];
    final itemList = rawItems
        .whereType<Map<String, dynamic>>()
        .map((e) => CollectionItem.fromJson(e))
        .toList();

    return CollectionsData(
      count: (json['count'] as num?)?.toInt() ?? itemList.length,
      items: itemList,
    );
  }

  Map<String, dynamic> toJson() => {
    'count': count,
    'items': items.map((e) => e.toJson()).toList(),
  };

  @override
  List<Object?> get props => [count, items];
}
