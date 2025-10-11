import 'dart:convert';
import 'dart:math';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:razorpay_flutter/razorpay_flutter.dart';
import '../../../data/repositories/payment_repository.dart';
import '../../../data/repositories/cart_repository.dart';
import '../../../data/models/payment_model.dart';
import '../../di/service_locator.dart';
import '../cart/cart_bloc.dart';
import '../cart/cart_event.dart';
import '../../config/app_config.dart';
import 'payment_event.dart';
import 'payment_state.dart';

class PaymentBloc extends Bloc<PaymentEvent, PaymentState> {
  final PaymentRepository _paymentRepository;
  late Razorpay _razorpay;
  String? _currentPaymentId; // Store current payment ID for success callback

  PaymentBloc({
    required PaymentRepository paymentRepository,
  }) : _paymentRepository = paymentRepository,
       super(const PaymentInitial()) {
    on<InitializePayment>(_onInitializePayment);
    on<ProcessPayment>(_onProcessPayment);
    on<PaymentSuccessEvent>(_onPaymentSuccess);
    on<PaymentFailedEvent>(_onPaymentFailed);
    on<LoadPaymentHistory>(_onLoadPaymentHistory);
    on<ClearPaymentState>(_onClearPaymentState);

    _initializeRazorpay();
  }

  void _initializeRazorpay() {
    _razorpay = Razorpay();
    _razorpay.on(Razorpay.EVENT_PAYMENT_SUCCESS, _handlePaymentSuccess);
    _razorpay.on(Razorpay.EVENT_PAYMENT_ERROR, _handlePaymentError);
    _razorpay.on(Razorpay.EVENT_EXTERNAL_WALLET, _handleExternalWallet);
  }

  Future<void> _onInitializePayment(InitializePayment event, Emitter<PaymentState> emit) async {
    try {
      emit(const PaymentLoading());

      // Get current user data
      final userData = _paymentRepository.getCurrentUserData();
      
      // Create payment courses from cart items
      final courses = await _paymentRepository.createPaymentCourses(event.cartItems);
      
      // Generate payment ID
      final paymentId = _paymentRepository.generatePaymentId();
      _currentPaymentId = paymentId; // Store for success callback
      
      // Create payment model
      final payment = PaymentModel(
        id: '', // Will be set when saved to Firestore
        userId: userData['userId']!,
        userEmail: userData['userEmail']!,
        userName: userData['userName']!,
        userPhone: userData['userPhone']!,
        courses: courses,
        totalAmount: event.totalAmount,
        discountAmount: event.discountAmount,
        finalAmount: event.finalAmount,
        couponCode: event.appliedCoupon?['code'],
        couponId: event.appliedCoupon?['id'],
        paymentId: paymentId,
        paymentStatus: 'pending',
        paymentMethod: 'razorpay',
        paymentDate: DateTime.now(),
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );

      // Create Razorpay options
      final razorpayOptions = {
        'key': AppConfig.razorpayKeyId,
        'amount': (event.finalAmount * 100).toInt(), // Convert to paise
        'name': 'Hackethos4U',
        'description': 'Course Purchase',
        'prefill': {
          'contact': userData['userPhone'],
          'email': userData['userEmail'],
        },
        'external': {
          'wallets': ['paytm']
        }
      };

      print('DEBUG - Payment Bloc - Payment initialized: $paymentId');
      print('DEBUG - Payment Bloc - Amount: ${event.finalAmount} (${(event.finalAmount * 100).toInt()} paise)');

      emit(PaymentInitialized(
        payment: payment,
        razorpayOptions: razorpayOptions,
      ));
    } catch (e) {
      print('ERROR - Payment Bloc - Failed to initialize payment: $e');
      emit(PaymentError(error: 'Failed to initialize payment: $e'));
    }
  }

  Future<void> _onProcessPayment(ProcessPayment event, Emitter<PaymentState> emit) async {
    try {
      emit(PaymentProcessing(payment: event.payment));

      // Save payment to Firestore first
      final savedPaymentId = await _paymentRepository.savePayment(event.payment);
      final updatedPayment = event.payment.copyWith(id: savedPaymentId);

      // Open Razorpay payment
      _razorpay.open(event.razorpayOptions);

      print('DEBUG - Payment Bloc - Payment processing started: ${event.payment.paymentId}');
    } catch (e) {
      print('ERROR - Payment Bloc - Failed to process payment: $e');
      emit(PaymentFailed(error: 'Failed to process payment: $e'));
    }
  }

  Future<void> _onPaymentSuccess(PaymentSuccessEvent event, Emitter<PaymentState> emit) async {
    try {
      print('DEBUG - Payment Bloc - Processing payment success for: ${event.paymentId}');
      
      // Update payment status in Firestore
      await _paymentRepository.updatePaymentStatus(event.paymentId, 'completed');
      print('DEBUG - Payment Bloc - Payment status updated to completed');

      // Get updated payment
      final updatedPayment = await _paymentRepository.getPaymentByPaymentId(event.paymentId);
      print('DEBUG - Payment Bloc - Retrieved updated payment: ${updatedPayment?.paymentStatus}');
      
      if (updatedPayment != null) {
        // Clear the cart after successful payment
        print('DEBUG - Payment Bloc - Starting cart clearing process after successful payment');
        
        try {
          // Get CartRepository directly from service locator
          final cartRepository = sl<CartRepository>();
          print('DEBUG - Payment Bloc - Got CartRepository from service locator: $cartRepository');
          
          final cartCleared = await cartRepository.clearCart();
          print('DEBUG - Payment Bloc - clearCart() returned: $cartCleared');
          
          if (cartCleared) {
            print('DEBUG - Payment Bloc - Entire cart document deleted from Firestore after successful payment');
            
            // Also clear the cart cache to ensure UI is updated
            try {
              await cartRepository.clearCartCache();
              print('DEBUG - Payment Bloc - Cart cache cleared successfully');
            } catch (e) {
              print('WARNING - Payment Bloc - Failed to clear cart cache: $e');
            }
          } else {
            print('WARNING - Payment Bloc - Failed to delete cart document from Firestore - clearCart() returned false');
          }
        } catch (e) {
          print('WARNING - Payment Bloc - Exception occurred while clearing cart after payment: $e');
          print('WARNING - Payment Bloc - Exception type: ${e.runtimeType}');
          // Don't fail the payment if cart clearing fails
        }

        emit(PaymentSuccess(
          payment: updatedPayment,
          razorpayPaymentId: event.razorpayPaymentId,
          razorpayOrderId: event.razorpayOrderId,
          razorpaySignature: event.razorpaySignature,
        ));
        print('DEBUG - Payment Bloc - PaymentSuccess state emitted');
        
        // Emit a special state to trigger direct navigation to My Purchases
        emit(PaymentCompletedNavigateToPurchases(
          payment: updatedPayment,
          razorpayPaymentId: event.razorpayPaymentId,
          razorpayOrderId: event.razorpayOrderId,
          razorpaySignature: event.razorpaySignature,
        ));
        print('DEBUG - Payment Bloc - PaymentCompletedNavigateToPurchases state emitted');
      } else {
        print('ERROR - Payment Bloc - Updated payment is null');
        emit(const PaymentError(error: 'Payment record not found after update'));
      }

      print('DEBUG - Payment Bloc - Payment successful: ${event.paymentId}');
    } catch (e) {
      print('ERROR - Payment Bloc - Failed to handle payment success: $e');
      emit(PaymentError(error: 'Failed to handle payment success: $e'));
    }
  }

  Future<void> _onPaymentFailed(PaymentFailedEvent event, Emitter<PaymentState> emit) async {
    try {
      if (event.paymentId != null) {
        // Update payment status in Firestore
        await _paymentRepository.updatePaymentStatus(event.paymentId!, 'failed');
      }

      emit(PaymentFailed(
        error: event.error,
      ));

      print('DEBUG - Payment Bloc - Payment failed: ${event.paymentId} - ${event.error}');
      
      // Also emit navigation state to go to My Purchases even on failure
      emit(PaymentFailedNavigateToPurchases(
        error: event.error,
        paymentId: event.paymentId,
      ));
      print('DEBUG - Payment Bloc - PaymentFailedNavigateToPurchases state emitted');
    } catch (e) {
      print('ERROR - Payment Bloc - Failed to handle payment failure: $e');
      emit(PaymentError(error: 'Failed to handle payment failure: $e'));
    }
  }

  Future<void> _onLoadPaymentHistory(LoadPaymentHistory event, Emitter<PaymentState> emit) async {
    try {
      emit(const PaymentLoading());

      final userData = _paymentRepository.getCurrentUserData();
      final payments = await _paymentRepository.getUserPayments(userData['userId']!);

      emit(PaymentHistoryLoaded(payments: payments));

      print('DEBUG - Payment Bloc - Payment history loaded: ${payments.length} payments');
    } catch (e) {
      print('ERROR - Payment Bloc - Failed to load payment history: $e');
      emit(PaymentError(error: 'Failed to load payment history: $e'));
    }
  }

  Future<void> _onClearPaymentState(ClearPaymentState event, Emitter<PaymentState> emit) async {
    _currentPaymentId = null; // Clear stored payment ID
    emit(const PaymentInitial());
  }

  void _handlePaymentSuccess(PaymentSuccessResponse response) {
    print('DEBUG - Payment Bloc - Razorpay payment success: ${response.paymentId}');
    
    // Extract payment details from response
    final razorpayPaymentId = response.paymentId ?? '';
    final orderId = response.orderId ?? '';
    final signature = response.signature ?? '';

    if (_currentPaymentId == null) {
      print('ERROR - Payment Bloc - No current payment ID found');
      add(PaymentFailedEvent(error: 'No current payment ID found'));
      return;
    }

    add(PaymentSuccessEvent(
      paymentId: _currentPaymentId!,
      razorpayPaymentId: razorpayPaymentId,
      razorpayOrderId: orderId,
      razorpaySignature: signature,
    ));
  }

  void _handlePaymentError(PaymentFailureResponse response) {
    print('DEBUG - Payment Bloc - Razorpay payment error: ${response.message}');
    
    add(PaymentFailedEvent(
      error: response.message ?? 'Payment failed',
    ));
  }

  void _handleExternalWallet(ExternalWalletResponse response) {
    print('DEBUG - Payment Bloc - External wallet selected: ${response.walletName}');
  }

  @override
  Future<void> close() {
    _razorpay.clear();
    return super.close();
  }
}
