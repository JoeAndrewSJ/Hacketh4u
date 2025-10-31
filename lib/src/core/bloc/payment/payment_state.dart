import 'package:equatable/equatable.dart';
import '../../../data/models/payment_model.dart';

abstract class PaymentState extends Equatable {
  const PaymentState();

  @override
  List<Object?> get props => [];
}

class PaymentInitial extends PaymentState {
  const PaymentInitial();
}

class PaymentLoading extends PaymentState {
  const PaymentLoading();
}

class PaymentInitialized extends PaymentState {
  final PaymentModel payment;
  final Map<String, dynamic> razorpayOptions;

  const PaymentInitialized({
    required this.payment,
    required this.razorpayOptions,
  });

  @override
  List<Object?> get props => [payment, razorpayOptions];
}

class PaymentProcessing extends PaymentState {
  final PaymentModel payment;

  const PaymentProcessing({required this.payment});

  @override
  List<Object?> get props => [payment];
}

class PaymentSuccess extends PaymentState {
  final PaymentModel payment;
  final String razorpayPaymentId;
  final String razorpayOrderId;
  final String razorpaySignature;

  const PaymentSuccess({
    required this.payment,
    required this.razorpayPaymentId,
    required this.razorpayOrderId,
    required this.razorpaySignature,
  });

  @override
  List<Object?> get props => [payment, razorpayPaymentId, razorpayOrderId, razorpaySignature];
}

class PaymentFailed extends PaymentState {
  final String error;
  final PaymentModel? payment;

  const PaymentFailed({
    required this.error,
    this.payment,
  });

  @override
  List<Object?> get props => [error, payment];
}

class PaymentHistoryLoaded extends PaymentState {
  final List<PaymentModel> payments;

  const PaymentHistoryLoaded({required this.payments});

  @override
  List<Object?> get props => [payments];
}

class PaymentError extends PaymentState {
  final String error;

  const PaymentError({required this.error});

  @override
  List<Object?> get props => [error];
}

class PaymentCompletedNavigateToPurchases extends PaymentState {
  final PaymentModel payment;
  final String razorpayPaymentId;
  final String razorpayOrderId;
  final String razorpaySignature;
  
  const PaymentCompletedNavigateToPurchases({
    required this.payment,
    required this.razorpayPaymentId,
    required this.razorpayOrderId,
    required this.razorpaySignature,
  });
  
  @override
  List<Object?> get props => [payment, razorpayPaymentId, razorpayOrderId, razorpaySignature];
}

class PaymentFailedNavigateToPurchases extends PaymentState {
  final String error;
  final String? paymentId;
  
  const PaymentFailedNavigateToPurchases({
    required this.error,
    this.paymentId,
  });
  
  @override
  List<Object?> get props => [error, paymentId];
}
