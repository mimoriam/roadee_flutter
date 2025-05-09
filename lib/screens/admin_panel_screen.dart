import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import 'package:roadee_flutter/screens/payment_checkout_screen.dart';

import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

import 'package:geocoding/geocoding.dart';
import 'package:pluto_grid/pluto_grid.dart';

class AdminScreen extends StatefulWidget {
  final Placemark placemark;

  const AdminScreen({super.key, required this.placemark});

  @override
  State<AdminScreen> createState() => _AdminScreenState();
}

class _AdminScreenState extends State<AdminScreen> {
  List<String> adminUsers = [];
  List<PlutoColumn> columns = [];
  List<PlutoRow> rows = [];
  late PlutoGridStateManager stateManager;

  late Map<String, dynamic>? user;

  Future<Map<String, dynamic>?> getUserData() async {
    final uid = FirebaseAuth.instance.currentUser?.uid;

    final doc = await FirebaseFirestore.instance.collection("users").doc(uid).get();

    adminUsers.add(doc.data()!["username"]);
    return doc.data();
  }

  Future<List<Map<String, dynamic>>> getAllUsersData() async {
    final querySnapshot = await FirebaseFirestore.instance.collection("users").get();

    return querySnapshot.docs.map((doc) => doc.data()).toList();
  }

  Future<void> updateAssistantForAnotherUser(String username) async {
    try {
      final query =
          await FirebaseFirestore.instance
              .collection("users")
              .where('username', isEqualTo: username)
              .limit(1)
              .get();

      final uid = FirebaseAuth.instance.currentUser?.uid;
      final docRef = query.docs.first.reference;
      final doc = await docRef.get();

      final orders = List<Map<String, dynamic>>.from(doc.data()?['orders'] ?? []);
      final ordersAssigned = List<Map<String, dynamic>>.from(doc.data()?['orders_assigned'] ?? []);

      // CHANGED HERE FROM ORDER INDEX TO ACTUAL ORDER IDX:
      // final order_idx = doc.data()?["order_index"];
      final order_idx = orders.length - 1;

      if (order_idx > 0) {
        orders[order_idx]["assistant_assigned"] = "${user?["username"]}";
        orders[order_idx]["assistant_address"] =
            widget.placemark.thoroughfare == ""
                ? "${widget.placemark.name} ~ ${widget.placemark.street} ~ ${widget.placemark.locality}"
                : "${widget.placemark.thoroughfare} ~ ${widget.placemark.subThoroughfare}";

        orders[order_idx]["assistant_city"] = widget.placemark.locality;
        orders[order_idx]["assistant_country"] = widget.placemark.country;

        orders[order_idx]["status"] = OrderStatus.OnRoute.name;

        orders[order_idx]["assistant_email"] = "${user?["email"]}";
        orders[order_idx]["assistant_id"] = "${user?["id"]}";
        // Order assigned From USER
        ordersAssigned[0]["orderAssignedFrom"] = username;
      }

      await docRef.update({'orders': orders});
      await FirebaseFirestore.instance.collection("users").doc(uid).update({
        "orders_assigned": ordersAssigned,
      });
      // await docRef.update({'order_assigned_idx': FieldValue.increment(1)});
      // await docRef.update({'orders_assigned': ordersAssigned});
    } on FirebaseAuthException {}
  }

  Future<void> updateStatusToCompleteOnCheck(String email) async {
    try {
      final query =
          await FirebaseFirestore.instance
              .collection("users")
              .where('email', isEqualTo: email)
              .limit(1)
              .get();

      final uid = FirebaseAuth.instance.currentUser?.uid;

      // final adminQuery =
      //     await FirebaseFirestore.instance.collection("users").where("id", isEqualTo: uid).limit(1).get();

      final docRef = query.docs.first.reference;
      final doc = await docRef.get();

      // final adminDocRef = query.docs.first.reference;
      // final adminDoc = await adminDocRef.get();

      final orders = List<Map<String, dynamic>>.from(doc.data()?['orders'] ?? []);
      final ordersAssigned = List<Map<String, dynamic>>.from(doc.data()?['orders_assigned'] ?? []);
      // final order_idx = doc.data()?["order_index"];
      final order_idx = orders.length - 1;

      if (order_idx > 0) {
        orders[order_idx]["status"] = OrderStatus.Completed.name;

        ordersAssigned[0]["orderAssignedFrom"] = "";

        await docRef.update({'order_index': FieldValue.increment(-1)});
        await docRef.update({'orders': orders});
        // await adminDocRef.update({'orders_assigned': adminOrdersAssigned});
        await FirebaseFirestore.instance.collection("users").doc(uid).update({
          // "orders": [{}],
          "orders_assigned": ordersAssigned,
        });
      }
    } catch (e) {}
  }

  void openGridPopup(BuildContext context, String selectFieldName, var queryUser, int orderIndex) {
    // final ordersColumn = PlutoColumn(
    //   title: selectFieldName,
    //   field: selectFieldName,
    //   type: PlutoColumnType.text(),
    // );

    final List<PlutoColumn> ordersColumn = [];

    ordersColumn.addAll([
      PlutoColumn(
        title: "Assistant",
        field: "assistant_assigned",
        type: PlutoColumnType.select(adminUsers),
        enableEditingMode: true,
      ),
      PlutoColumn(title: "Username", field: "username", type: PlutoColumnType.text()),
      PlutoColumn(title: "Service", field: "service", type: PlutoColumnType.text()),
      PlutoColumn(title: "Status", field: "status", type: PlutoColumnType.text()),
      PlutoColumn(title: "Assistant Address", field: "assistant_address", type: PlutoColumnType.text()),
    ]);

    // final List<PlutoRow> ordersRow = [];
    // ordersRow.addAll([
    //   PlutoRow(
    //     cells: {
    //       'assistant_assigned': PlutoCell(value: user!["orders"][1]["assistant_assigned"]),
    //       'service': PlutoCell(value: user!["orders"][1]["service"]),
    //       'status': PlutoCell(value: user!["orders"][1]["status"]),
    //     },
    //   ),
    // ]);
    //
    final ordersRow =
        List.generate(orderIndex, (index) => index)
            .map((index) {
              if (queryUser["orders"][index + 1]["status"].toString() == OrderStatus.Completed.name) {
                return null;
              }
              return PlutoRow(
                cells: {
                  'assistant_assigned': PlutoCell(
                    value: queryUser["orders"][index + 1]["assistant_assigned"],
                  ),
                  'username': PlutoCell(value: queryUser["username"]),
                  'service': PlutoCell(value: queryUser["orders"][index + 1]["service"]),
                  'status': PlutoCell(value: queryUser["orders"][index + 1]["status"]),
                  'assistant_address': PlutoCell(value: queryUser["orders"][index + 1]["assistant_address"]),
                },
              );
            })
            .whereType<PlutoRow>()
            .toList();

    PlutoGridPopup(
      context: context,
      columns: ordersColumn,
      rows: ordersRow,
      mode: PlutoGridMode.normal,
      configuration: PlutoGridConfiguration(
        columnSize: PlutoGridColumnSizeConfig(autoSizeMode: PlutoAutoSizeMode.scale),
      ),
      onLoaded: (PlutoGridOnLoadedEvent event) {
        event.stateManager.setShowColumnFilter(true);
      },
      onSelected: (PlutoGridOnSelectedEvent event) {},

      onChanged: (PlutoGridOnChangedEvent event) {
        if (event.column.field == 'assistant_assigned') {
          final selectedAdmin = event.value;
          updateAssistantForAnotherUser(event.row.cells['username']?.value);
        }
      },
    );
  }

  @override
  void dispose() {
    SystemChrome.setPreferredOrientations([DeviceOrientation.portraitUp, DeviceOrientation.portraitDown]);
    super.dispose();
  }

  @override
  void initState() {
    super.initState();

    SystemChrome.setPreferredOrientations([
      DeviceOrientation.landscapeRight,
      DeviceOrientation.landscapeLeft,
    ]);

    columns.addAll([
      PlutoColumn(
        title: 'index',
        field: 'order_index',
        type: PlutoColumnType.number(),
        renderer: (rendererContext) {
          return Row(
            children: [
              IconButton(
                icon: const Icon(Icons.check_box),
                onPressed: () async {
                  final row = rendererContext.row;
                  // final id = row.cells['order_index']?.value;
                  final id = row.cells['orders']?.value.length - 1;

                  if (id > 0) {
                    if (row.cells['orders']?.value[id]["assistant_assigned"].isNotEmpty) {
                      await updateStatusToCompleteOnCheck(row.cells["email"]?.value);
                    }
                  }

                  final query =
                      await FirebaseFirestore.instance
                          .collection("users")
                          .where('email', isEqualTo: row.cells['email']?.value)
                          .limit(1)
                          .get();

                  final queryUser = query.docs.first.data();

                  openGridPopup(context, 'orders', queryUser, id);
                },
                iconSize: 18,
                color: Colors.green,
                padding: const EdgeInsets.all(0),
              ),
              Expanded(
                child: Text(
                  rendererContext.row.cells[rendererContext.column.field]!.value.toString(),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          );
        },
      ),
      PlutoColumn(title: 'email', field: 'email', type: PlutoColumnType.text()),
      PlutoColumn(title: 'address', field: 'address', type: PlutoColumnType.text()),
      PlutoColumn(title: 'orders', field: 'orders', type: PlutoColumnType.text()),
    ]);

    setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Scaffold(
        appBar: AppBar(title: Text("Roadee Admin Panel")),
        body: Container(
          padding: const EdgeInsets.all(14),
          child: PlutoGrid(
            columns: columns,
            rows: rows,
            configuration: PlutoGridConfiguration(
              columnSize: PlutoGridColumnSizeConfig(autoSizeMode: PlutoAutoSizeMode.scale),
              columnFilter: PlutoGridColumnFilterConfig(
                filters: [...FilterHelper.defaultFilters],
                resolveDefaultColumnFilter: (column, resolver) {
                  return resolver<PlutoFilterTypeContains>() as PlutoFilterType;
                },
              ),
            ),
            onChanged: (PlutoGridOnChangedEvent event) {},
            onLoaded: (PlutoGridOnLoadedEvent event) async {
              stateManager = event.stateManager;

              user = await getUserData();
              var users = await getAllUsersData();

              setState(() {
                // stateManager.appendRows([
                //   PlutoRow(
                //     cells: {
                //       'order_index': PlutoCell(value: user!['order_index']),
                //       'email': PlutoCell(value: user!['email']),
                //       'address': PlutoCell(value: user!['address']),
                //       'orders': PlutoCell(value: user!['orders']),
                //       // 'action': PlutoCell(value: ''),
                //     },
                //   ),
                // ]);
                stateManager.appendRows(
                  List.generate(users.length, (index) => index)
                      .map((index) {
                        return PlutoRow(
                          cells: {
                            'order_index': PlutoCell(value: users[index]["order_index"]),
                            'email': PlutoCell(value: users[index]['email']),
                            'address': PlutoCell(value: users[index]['address']),
                            'orders': PlutoCell(value: users[index]['orders']),
                          },
                        );
                      })
                      .whereType<PlutoRow>()
                      .toList(),
                );
              });

              stateManager.setShowColumnFilter(true);
              stateManager.setSelectingMode(PlutoGridSelectingMode.row);
            },
            // onSelected: (PlutoGridOnSelectedEvent event) {
            //   if (event.row != null) {
            //     openDetail(event.row);
            //   }
            // },
            // mode: PlutoGridMode.select,
            createFooter: (stateManager) {
              stateManager.setPageSize(50, notify: false); // default 40
              return PlutoPagination(stateManager);
            },
          ),
        ),
      ),
    );
  }
}
