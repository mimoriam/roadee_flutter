import 'package:flutter/material.dart';
import 'package:flutter_stripe/flutter_stripe.dart';
import 'package:dio/dio.dart';

import 'package:roadee_flutter/constants.dart';

class StripeService {
  StripeService._();

  static final StripeService instance = StripeService._();
  late String paymentResult;

  Future<String> makePayment() async {
    try {
      String? paymentIntentClientSecret = await _createPaymentIntent(10, "usd");

      if (paymentIntentClientSecret == null) return "No_Client";

      await Stripe.instance.initPaymentSheet(
        paymentSheetParameters: SetupPaymentSheetParameters(
          paymentIntentClientSecret: paymentIntentClientSecret,
          merchantDisplayName: "Roadee",
          // preferredNetworks: [CardBrand.Amex],
          appearance: PaymentSheetAppearance(
            colors: PaymentSheetAppearanceColors(
              primary: Colors.black,
              background: Colors.white,
              primaryText: Colors.black,
              secondaryText: Colors.black,
              placeholderText: Colors.black87,
              componentBackground: Colors.white,
              componentText: Colors.black87,
            ),
            shapes: PaymentSheetShape(borderRadius: 8),
            primaryButton: PaymentSheetPrimaryButtonAppearance(
              colors: PaymentSheetPrimaryButtonTheme(
                dark: PaymentSheetPrimaryButtonThemeColors(
                  background: Colors.blue,
                  text: Colors.white,
                ),
              ),
            ),
          ),
        ),
      );

      await _processPayment();
      return paymentResult;
    } catch (e) {
      // print(e);
    }

    return "empty";
  }

  Future<void> _processPayment() async {
    try {
      await Stripe.instance.presentPaymentSheet();
      paymentResult = "Complete";
      // await Stripe.instance.confirmPaymentSheetPayment();
    } on Exception catch (e) {
      if (e is StripeException) {
        // print(e);
        paymentResult = "Error";
      }
    } catch (e) {
      paymentResult = "Error";
    }
  }

  Future<String?> _createPaymentIntent(int amount, String currency) async {
    try {
      final Dio dio = Dio();

      Map<String, dynamic> data = {
        "amount": _calculateAmount(amount),
        "currency": currency,
        // "payment_method_types": ['card'],
      };

      var response = await dio.post(
        "https://api.stripe.com/v1/payment_intents",
        data: data,
        options: Options(
          contentType: Headers.formUrlEncodedContentType,
          headers: {
            "Authorization": "Bearer $secretKey",
            "Content-Type": 'application/x-www-form-urlencoded',
          },
        ),
      );

      if (response.data != null) {
        print(response.data["client_secret"]);
        return response.data["client_secret"];
      }
    } catch (e) {
      print(e);
    }

    return null;
  }

  String _calculateAmount(int amount) {
    final calculatedAmount = (amount * 100).toString();
    return calculatedAmount;
  }
}
