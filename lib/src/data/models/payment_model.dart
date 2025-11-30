class PaymentModel {
  final String id;
  final String userId;
  final String userEmail;
  final String userName;
  final String userPhone;
  final List<PaymentCourse> courses;
  final double totalAmount;
  final double discountAmount;
  final double gstAmount;
  final double finalAmount;
  final String? couponCode;
  final String? couponId;
  final String paymentId;
  final String? razorpayPaymentId;
  final String paymentStatus;
  final String paymentMethod;
  final DateTime paymentDate;
  final DateTime createdAt;
  final DateTime updatedAt;

  PaymentModel({
    required this.id,
    required this.userId,
    required this.userEmail,
    required this.userName,
    required this.userPhone,
    required this.courses,
    required this.totalAmount,
    required this.discountAmount,
    this.gstAmount = 0.0,
    required this.finalAmount,
    this.couponCode,
    this.couponId,
    required this.paymentId,
    this.razorpayPaymentId,
    required this.paymentStatus,
    required this.paymentMethod,
    required this.paymentDate,
    required this.createdAt,
    required this.updatedAt,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'userId': userId,
      'userEmail': userEmail,
      'userName': userName,
      'userPhone': userPhone,
      'courses': courses.map((course) => course.toMap()).toList(),
      'totalAmount': totalAmount,
      'discountAmount': discountAmount,
      'gstAmount': gstAmount,
      'finalAmount': finalAmount,
      'couponCode': couponCode,
      'couponId': couponId,
      'paymentId': paymentId,
      'razorpayPaymentId': razorpayPaymentId,
      'paymentStatus': paymentStatus,
      'paymentMethod': paymentMethod,
      'paymentDate': paymentDate,
      'createdAt': createdAt,
      'updatedAt': updatedAt,
    };
  }

  factory PaymentModel.fromMap(Map<String, dynamic> map) {
    return PaymentModel(
      id: map['id'] ?? '',
      userId: map['userId'] ?? '',
      userEmail: map['userEmail'] ?? '',
      userName: map['userName'] ?? '',
      userPhone: map['userPhone'] ?? '',
      courses: (map['courses'] as List<dynamic>?)
          ?.map((course) => PaymentCourse.fromMap(course))
          .toList() ?? [],
      totalAmount: (map['totalAmount'] ?? 0.0).toDouble(),
      discountAmount: (map['discountAmount'] ?? 0.0).toDouble(),
      gstAmount: (map['gstAmount'] ?? 0.0).toDouble(),
      finalAmount: (map['finalAmount'] ?? 0.0).toDouble(),
      couponCode: map['couponCode'],
      couponId: map['couponId'],
      paymentId: map['paymentId'] ?? '',
      razorpayPaymentId: map['razorpayPaymentId'],
      paymentStatus: map['paymentStatus'] ?? '',
      paymentMethod: map['paymentMethod'] ?? '',
      paymentDate: map['paymentDate']?.toDate() ?? DateTime.now(),
      createdAt: map['createdAt']?.toDate() ?? DateTime.now(),
      updatedAt: map['updatedAt']?.toDate() ?? DateTime.now(),
    );
  }

  PaymentModel copyWith({
    String? id,
    String? userId,
    String? userEmail,
    String? userName,
    String? userPhone,
    List<PaymentCourse>? courses,
    double? totalAmount,
    double? discountAmount,
    double? gstAmount,
    double? finalAmount,
    String? couponCode,
    String? couponId,
    String? paymentId,
    String? razorpayPaymentId,
    String? paymentStatus,
    String? paymentMethod,
    DateTime? paymentDate,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return PaymentModel(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      userEmail: userEmail ?? this.userEmail,
      userName: userName ?? this.userName,
      userPhone: userPhone ?? this.userPhone,
      courses: courses ?? this.courses,
      totalAmount: totalAmount ?? this.totalAmount,
      discountAmount: discountAmount ?? this.discountAmount,
      gstAmount: gstAmount ?? this.gstAmount,
      finalAmount: finalAmount ?? this.finalAmount,
      couponCode: couponCode ?? this.couponCode,
      couponId: couponId ?? this.couponId,
      paymentId: paymentId ?? this.paymentId,
      razorpayPaymentId: razorpayPaymentId ?? this.razorpayPaymentId,
      paymentStatus: paymentStatus ?? this.paymentStatus,
      paymentMethod: paymentMethod ?? this.paymentMethod,
      paymentDate: paymentDate ?? this.paymentDate,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }
}

class PaymentCourse {
  final String courseId;
  final String courseTitle;
  final String instructorName;
  final String thumbnailUrl;
  final double price;
  final double originalPrice;
  final int subscriptionPeriod; // in days, 0 means lifetime
  final DateTime accessStartDate;
  final DateTime accessEndDate;

  PaymentCourse({
    required this.courseId,
    required this.courseTitle,
    required this.instructorName,
    required this.thumbnailUrl,
    required this.price,
    required this.originalPrice,
    required this.subscriptionPeriod,
    required this.accessStartDate,
    required this.accessEndDate,
  });

  Map<String, dynamic> toMap() {
    return {
      'courseId': courseId,
      'courseTitle': courseTitle,
      'instructorName': instructorName,
      'thumbnailUrl': thumbnailUrl,
      'price': price,
      'originalPrice': originalPrice,
      'subscriptionPeriod': subscriptionPeriod,
      'accessStartDate': accessStartDate,
      'accessEndDate': accessEndDate,
    };
  }

  factory PaymentCourse.fromMap(Map<String, dynamic> map) {
    return PaymentCourse(
      courseId: map['courseId'] ?? '',
      courseTitle: map['courseTitle'] ?? '',
      instructorName: map['instructorName'] ?? '',
      thumbnailUrl: map['thumbnailUrl'] ?? '',
      price: (map['price'] ?? 0.0).toDouble(),
      originalPrice: (map['originalPrice'] ?? 0.0).toDouble(),
      subscriptionPeriod: map['subscriptionPeriod'] ?? 0,
      accessStartDate: map['accessStartDate']?.toDate() ?? DateTime.now(),
      accessEndDate: map['accessEndDate']?.toDate() ?? DateTime.now(),
    );
  }

  PaymentCourse copyWith({
    String? courseId,
    String? courseTitle,
    String? instructorName,
    String? thumbnailUrl,
    double? price,
    double? originalPrice,
    int? subscriptionPeriod,
    DateTime? accessStartDate,
    DateTime? accessEndDate,
  }) {
    return PaymentCourse(
      courseId: courseId ?? this.courseId,
      courseTitle: courseTitle ?? this.courseTitle,
      instructorName: instructorName ?? this.instructorName,
      thumbnailUrl: thumbnailUrl ?? this.thumbnailUrl,
      price: price ?? this.price,
      originalPrice: originalPrice ?? this.originalPrice,
      subscriptionPeriod: subscriptionPeriod ?? this.subscriptionPeriod,
      accessStartDate: accessStartDate ?? this.accessStartDate,
      accessEndDate: accessEndDate ?? this.accessEndDate,
    );
  }
}
