import 'package:equatable/equatable.dart';

class InvoiceModel extends Equatable {
  final String id;
  final String userId;
  final String userName;
  final String userEmail;
  final String courseId;
  final String courseName;
  final String courseDescription;
  final double coursePrice;
  final String paymentId;
  final String paymentMethod;
  final DateTime purchaseDate;
  final DateTime accessEndDate;
  final String status;
  final String currency;
  final double taxAmount;
  final double totalAmount;
  final String? discountCode;
  final double? discountAmount;

  const InvoiceModel({
    required this.id,
    required this.userId,
    required this.userName,
    required this.userEmail,
    required this.courseId,
    required this.courseName,
    required this.courseDescription,
    required this.coursePrice,
    required this.paymentId,
    required this.paymentMethod,
    required this.purchaseDate,
    required this.accessEndDate,
    required this.status,
    this.currency = 'USD',
    this.taxAmount = 0.0,
    required this.totalAmount,
    this.discountCode,
    this.discountAmount,
  });

  factory InvoiceModel.fromMap(Map<String, dynamic> map) {
    return InvoiceModel(
      id: map['id']?.toString() ?? '',
      userId: map['userId']?.toString() ?? '',
      userName: map['userName']?.toString() ?? '',
      userEmail: map['userEmail']?.toString() ?? '',
      courseId: map['courseId']?.toString() ?? '',
      courseName: map['courseName']?.toString() ?? '',
      courseDescription: map['courseDescription']?.toString() ?? '',
      coursePrice: (map['coursePrice'] as num?)?.toDouble() ?? 0.0,
      paymentId: map['paymentId']?.toString() ?? '',
      paymentMethod: map['paymentMethod']?.toString() ?? '',
      purchaseDate: map['purchaseDate']?.toDate() ?? DateTime.now(),
      accessEndDate: map['accessEndDate']?.toDate() ?? DateTime.now(),
      status: map['status']?.toString() ?? '',
      currency: map['currency']?.toString() ?? 'USD',
      taxAmount: (map['taxAmount'] as num?)?.toDouble() ?? 0.0,
      totalAmount: (map['totalAmount'] as num?)?.toDouble() ?? 0.0,
      discountCode: map['discountCode']?.toString(),
      discountAmount: (map['discountAmount'] as num?)?.toDouble(),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'userId': userId,
      'userName': userName,
      'userEmail': userEmail,
      'courseId': courseId,
      'courseName': courseName,
      'courseDescription': courseDescription,
      'coursePrice': coursePrice,
      'paymentId': paymentId,
      'paymentMethod': paymentMethod,
      'purchaseDate': purchaseDate,
      'accessEndDate': accessEndDate,
      'status': status,
      'currency': currency,
      'taxAmount': taxAmount,
      'totalAmount': totalAmount,
      'discountCode': discountCode,
      'discountAmount': discountAmount,
    };
  }

  @override
  List<Object?> get props => [
        id,
        userId,
        userName,
        userEmail,
        courseId,
        courseName,
        courseDescription,
        coursePrice,
        paymentId,
        paymentMethod,
        purchaseDate,
        accessEndDate,
        status,
        currency,
        taxAmount,
        totalAmount,
        discountCode,
        discountAmount,
      ];

  InvoiceModel copyWith({
    String? id,
    String? userId,
    String? userName,
    String? userEmail,
    String? courseId,
    String? courseName,
    String? courseDescription,
    double? coursePrice,
    String? paymentId,
    String? paymentMethod,
    DateTime? purchaseDate,
    DateTime? accessEndDate,
    String? status,
    String? currency,
    double? taxAmount,
    double? totalAmount,
    String? discountCode,
    double? discountAmount,
  }) {
    return InvoiceModel(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      userName: userName ?? this.userName,
      userEmail: userEmail ?? this.userEmail,
      courseId: courseId ?? this.courseId,
      courseName: courseName ?? this.courseName,
      courseDescription: courseDescription ?? this.courseDescription,
      coursePrice: coursePrice ?? this.coursePrice,
      paymentId: paymentId ?? this.paymentId,
      paymentMethod: paymentMethod ?? this.paymentMethod,
      purchaseDate: purchaseDate ?? this.purchaseDate,
      accessEndDate: accessEndDate ?? this.accessEndDate,
      status: status ?? this.status,
      currency: currency ?? this.currency,
      taxAmount: taxAmount ?? this.taxAmount,
      totalAmount: totalAmount ?? this.totalAmount,
      discountCode: discountCode ?? this.discountCode,
      discountAmount: discountAmount ?? this.discountAmount,
    );
  }
}
