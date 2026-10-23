import 'package:equatable/equatable.dart';
import '../../../core/models/product.dart';

class ProductResponseDto extends Equatable {
  final bool success;
  final String message;
  final ProductPageData? data;
  final String timestamp;

  const ProductResponseDto({
    required this.success,
    required this.message,
    this.data,
    this.timestamp = '',
  });

  factory ProductResponseDto.fromJson(Map<String, dynamic> json) {
    return ProductResponseDto(
      success: json['success'] as bool? ?? false,
      message: json['message']?.toString() ?? '',
      data: json['data'] != null && json['data'] is Map<String, dynamic>
          ? ProductPageData.fromJson(json['data'] as Map<String, dynamic>)
          : null,
      timestamp: json['timestamp']?.toString() ?? '',
    );
  }

  Map<String, dynamic> toJson() => {
    'success': success,
    'message': message,
    'data': data?.toJson(),
    'timestamp': timestamp,
  };

  @override
  List<Object?> get props => [success, message, data, timestamp];
}
