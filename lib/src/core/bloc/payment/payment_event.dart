import 'package:equatable/equatable.dart';
import '../../../data/models/payment_model.dart';

abstract class PaymentEvent extends Equatable {
  const PaymentEvent();

  @override
  List<Object?> get props => [];
}

class InitializePayment extends PaymentEvent {
  final List<Map<String, dynamic>> cartItems;
  final double totalAmount;
  final double discountAmount;
  final double finalAmount;
  final Map<String, dynamic>? appliedCoupon;

  const InitializePayment({
    required this.cartItems,
    required this.totalAmount,
    required this.discountAmount,
    required this.finalAmount,
    this.appliedCoupon,
  });

  @override
  List<Object?> get props => [cartItems, totalAmount, discountAmount, finalAmount, appliedCoupon];
}

class ProcessPayment extends PaymentEvent {
  final PaymentModel payment;
  final Map<String, dynamic> razorpayOptions;

  const ProcessPayment({
    required this.payment,
    required this.razorpayOptions,
  });

  @override
  List<Object?> get props => [payment, razorpayOptions];
}

class PaymentSuccessEvent extends PaymentEvent {
  final String paymentId;
  final String razorpayPaymentId;
  final String razorpayOrderId;
  final String razorpaySignature;

  const PaymentSuccessEvent({
    required this.paymentId,
    required this.razorpayPaymentId,
    required this.razorpayOrderId,
    required this.razorpaySignature,
  });

  @override
  List<Object?> get props => [paymentId, razorpayPaymentId, razorpayOrderId, razorpaySignature];
}

class PaymentFailedEvent extends PaymentEvent {
  final String error;
  final String? paymentId;

  const PaymentFailedEvent({
    required this.error,
    this.paymentId,
  });

  @override
  List<Object?> get props => [error, paymentId];
}

class LoadPaymentHistory extends PaymentEvent {
  const LoadPaymentHistory();
}

class ClearPaymentState extends PaymentEvent {
  const ClearPaymentState();
}
