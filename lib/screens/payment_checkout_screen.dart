import 'package:flutter/material.dart';

import 'package:flutter_form_builder/flutter_form_builder.dart';

import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:roadee_flutter/constants.dart';
import 'package:roadee_flutter/screens/home_screen.dart';
import 'package:roadee_flutter/services/stripe_service.dart';

enum OrderStatus { Pending, OnRoute, Completed, Empty }

class PaymentCheckoutScreen extends StatefulWidget {
  final String name;
  final String email;
  final String phone;
  final int serviceSelected;
  final String addressSelected;

  const PaymentCheckoutScreen({
    super.key,
    required this.name,
    required this.email,
    required this.phone,
    required this.serviceSelected,
    required this.addressSelected,
  });

  @override
  State<PaymentCheckoutScreen> createState() => _PaymentCheckoutScreenState();
}

class _PaymentCheckoutScreenState extends State<PaymentCheckoutScreen> {
  final _formKey = GlobalKey<FormBuilderState>();

  Future<void> addOrderToDB() async {
    try {
      final user = FirebaseAuth.instance.currentUser!;

      await FirebaseFirestore.instance.collection('users').doc(user.uid).update(
        {
          "order_index": FieldValue.increment(1),
          "orders": FieldValue.arrayUnion([
            {
              "assistant_assigned": "",
              "assistant_address": "",
              "assistant_city": "",
              "assistant_country": "",
              "orderCreatedAt": DateTime.now(),
              "promo code": "",
              "service": serviceSelectedIndex[widget
                  .serviceSelected],
              "status": OrderStatus.Pending.name,
              "payment": "Successful",
            },
          ]),
        },
      );
    } on FirebaseAuthException {}
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[100],
      body: SafeArea(
        child: Stack(
          children: [
            GestureDetector(
              onTap: () => FocusScope.of(context).unfocus(),
              child: LayoutBuilder(
                builder: (context, constraints) {
                  double cardWidth =
                      constraints.maxWidth > 600 ? 500 : double.infinity;

                  return Center(
                    child: SingleChildScrollView(
                      padding: const EdgeInsets.all(16),
                      child: Center(
                        child: ConstrainedBox(
                          constraints: BoxConstraints(maxWidth: cardWidth),
                          child: IntrinsicHeight(
                            child: FormBuilder(
                              key: _formKey,
                              child: Card(
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                elevation: 4,
                                child: Padding(
                                  padding: const EdgeInsets.all(20),
                                  child: Column(
                                    mainAxisSize: MainAxisSize.min,
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Row(
                                        children: [
                                          const Icon(
                                            Icons.local_shipping,
                                            size: 32,
                                            color: Colors.amber,
                                          ),
                                          const SizedBox(width: 10),
                                          const Text(
                                            "Payment Checkout",
                                            style: TextStyle(
                                              fontSize: 22,
                                              fontWeight: FontWeight.bold,
                                            ),
                                          ),
                                        ],
                                      ),
                                      const Divider(height: 30),
                                      const Text(
                                        "Service",
                                        style: TextStyle(
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                      const SizedBox(height: 8),
                                      Row(
                                        mainAxisAlignment:
                                            MainAxisAlignment.spaceBetween,
                                        children: [
                                          Text(
                                            serviceSelectedIndex[widget
                                                .serviceSelected]!,
                                          ),
                                          Text(
                                            "\$${serviceSelectedIndexPayment[widget.serviceSelected]![0][serviceSelectedIndex[widget.serviceSelected]]}.00",
                                          ),
                                        ],
                                      ),
                                      const Divider(height: 30),
                                      Row(
                                        mainAxisAlignment:
                                            MainAxisAlignment.spaceBetween,
                                        children: [
                                          Text(
                                            "Total",
                                            style: TextStyle(
                                              fontWeight: FontWeight.bold,
                                            ),
                                          ),
                                          Text(
                                            "\$${serviceSelectedIndexPayment[widget.serviceSelected]![0][serviceSelectedIndex[widget.serviceSelected]]}.00",
                                            style: TextStyle(
                                              fontWeight: FontWeight.bold,
                                            ),
                                          ),
                                        ],
                                      ),
                                      const SizedBox(height: 20),
                                      SizedBox(
                                        width: double.infinity,
                                        child: ElevatedButton(
                                          style: ElevatedButton.styleFrom(
                                            padding: const EdgeInsets.symmetric(
                                              vertical: 16,
                                            ),
                                            shape: RoundedRectangleBorder(
                                              borderRadius:
                                                  BorderRadius.circular(8),
                                            ),
                                            backgroundColor: Colors.blue,
                                          ),
                                          onPressed: () async {
                                            var result = await StripeService
                                                .instance
                                                .makePayment(
                                                  serviceSelectedIndexPayment[widget
                                                      .serviceSelected]![0][serviceSelectedIndex[widget
                                                      .serviceSelected]]!,
                                                );

                                            if (result == "Error") {
                                            } else {
                                              await addOrderToDB();
                                            }

                                            Navigator.pushReplacement(
                                              context,
                                              MaterialPageRoute(
                                                builder:
                                                    (context) => HomeScreen(),
                                              ),
                                            );
                                          },
                                          child: const Text(
                                            "Confirm Payment",
                                            style: TextStyle(
                                              fontSize: 16,
                                              fontWeight: FontWeight.bold,
                                              color: Colors.white,
                                            ),
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                            ),
                          ),
                        ),
                      ),
                    ),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}
