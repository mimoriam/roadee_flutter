import 'package:flutter/material.dart';

import 'package:flutter_form_builder/flutter_form_builder.dart';
import 'package:form_builder_validators/form_builder_validators.dart';

import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

enum OrderStatus { Pending, OnRoute, Completed }

class PaymentCheckoutScreen extends StatefulWidget {
  const PaymentCheckoutScreen({super.key});

  @override
  State<PaymentCheckoutScreen> createState() => _PaymentCheckoutScreenState();
}

class _PaymentCheckoutScreenState extends State<PaymentCheckoutScreen> {
  final _formKey = GlobalKey<FormBuilderState>();

  Future<void> updatePaymentOrderData() async {
    try {
      final user = FirebaseAuth.instance.currentUser!;

      // Update Firestore email
      await FirebaseFirestore.instance.collection('users').doc(user.uid).update(
        {
          "orders": FieldValue.arrayUnion([
            {
              "assistant_assigned": "",
              "billing_address": "asdasdasdsad",
              "card number": "2134 4123 2141 4214",
              "cvc": "431",
              "mm_yy": "03/27",
              "orderCreatedAt": DateTime.now(),
              "promo code": "13",
              "service": "tire change 3",
              "status": OrderStatus.Pending.name,
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

                  return SingleChildScrollView(
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
                                  crossAxisAlignment: CrossAxisAlignment.start,
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
                                      style: TextStyle(fontWeight: FontWeight.bold),
                                    ),
                                    const SizedBox(height: 8),
                                    Row(
                                      mainAxisAlignment:
                                          MainAxisAlignment.spaceBetween,
                                      children: const [
                                        Text("Tire Change"),
                                        Text("\$50.00"),
                                      ],
                                    ),
                                    const Divider(height: 30),
                                    const Text(
                                      "Payment Method",
                                      style: TextStyle(fontWeight: FontWeight.bold),
                                    ),
                                    const SizedBox(height: 10),
                                    FormBuilderTextField(
                                      name: "card_number",
                                      autovalidateMode: AutovalidateMode.disabled,
                                      decoration: InputDecoration(
                                        prefixIcon: const Icon(Icons.credit_card),
                                        hintText: "Card number",
                                        border: OutlineInputBorder(
                                          borderRadius: BorderRadius.circular(8),
                                        ),
                                      ),
                                    ),
                                    const SizedBox(height: 10),
                                    Row(
                                      children: [
                                        Expanded(
                                          child: FormBuilderTextField(
                                            name: "mm_yy",
                                            decoration: InputDecoration(
                                              hintText: "MM / YY",
                                              border: OutlineInputBorder(
                                                borderRadius: BorderRadius.circular(
                                                  8,
                                                ),
                                              ),
                                            ),
                                          ),
                                        ),
                                        const SizedBox(width: 10),
                                        Expanded(
                                          child: FormBuilderTextField(
                                            name: "cvc",
                                            decoration: InputDecoration(
                                              hintText: "CVC",
                                              border: OutlineInputBorder(
                                                borderRadius: BorderRadius.circular(
                                                  8,
                                                ),
                                              ),
                                            ),
                                          ),
                                        ),
                                      ],
                                    ),
                                    const SizedBox(height: 20),
                                    const Text(
                                      "Billing Address (optional)",
                                      style: TextStyle(fontWeight: FontWeight.bold),
                                    ),
                                    const SizedBox(height: 10),
                                    FormBuilderTextField(
                                      name: "billing_address",
                                      decoration: InputDecoration(
                                        hintText: "Billing address",
                                        border: OutlineInputBorder(
                                          borderRadius: BorderRadius.circular(8),
                                        ),
                                      ),
                                    ),
                                    const SizedBox(height: 20),
                                    const Text(
                                      "Promo Code",
                                      style: TextStyle(fontWeight: FontWeight.bold),
                                    ),
                                    const SizedBox(height: 10),
                                    Row(
                                      children: [
                                        Expanded(
                                          child: FormBuilderTextField(
                                            name: "promo_code",
                                            decoration: InputDecoration(
                                              hintText: "Enter code",
                                              border: OutlineInputBorder(
                                                borderRadius: BorderRadius.circular(
                                                  8,
                                                ),
                                              ),
                                            ),
                                          ),
                                        ),
                                        const SizedBox(width: 10),
                                        TextButton(
                                          onPressed: () {},
                                          child: const Text("Apply"),
                                        ),
                                      ],
                                    ),
                                    const Divider(height: 30),
                                    Row(
                                      mainAxisAlignment:
                                          MainAxisAlignment.spaceBetween,
                                      children: const [
                                        Text(
                                          "Total",
                                          style: TextStyle(
                                            fontWeight: FontWeight.bold,
                                          ),
                                        ),
                                        Text(
                                          "\$50.00",
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
                                            borderRadius: BorderRadius.circular(8),
                                          ),
                                          backgroundColor: Colors.blue,
                                        ),
                                        onPressed: () {
                                          updatePaymentOrderData();
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
