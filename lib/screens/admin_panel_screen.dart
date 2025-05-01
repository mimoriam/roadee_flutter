import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:pluto_grid/pluto_grid.dart';
import 'package:flutter/services.dart';
import 'package:flutter/material.dart';
import 'package:roadee_flutter/draft_local/payment_checkout_screen.draft.dart';

class AdminScreen extends StatefulWidget {
  const AdminScreen({super.key});

  @override
  State<AdminScreen> createState() => _AdminScreenState();
}

class _AdminScreenState extends State<AdminScreen> {
  List<PlutoColumn> columns = [];
  List<PlutoRow> rows = [];
  late PlutoGridStateManager stateManager;

  late Map<String, dynamic>? user;

  Future<Map<String, dynamic>?> getUserData() async {
    final uid = FirebaseAuth.instance.currentUser?.uid;

    final doc = await FirebaseFirestore.instance.collection("users").doc(uid).get();
    return doc.data();
  }

  Future<List<Map<String, dynamic>>> getAllUsersData() async {
    final querySnapshot = await FirebaseFirestore.instance.collection("users").get();

    return querySnapshot.docs.map((doc) => doc.data()).toList();
  }

  void openGridPopup(BuildContext context, String selectFieldName, var user, int orderIndex) {
    // final ordersColumn = PlutoColumn(
    //   title: selectFieldName,
    //   field: selectFieldName,
    //   type: PlutoColumnType.text(),
    // );

    final List<PlutoColumn> ordersColumn = [];

    ordersColumn.addAll([
      PlutoColumn(title: "Assistant", field: "assistant_assigned", type: PlutoColumnType.text()),
      PlutoColumn(title: "Service", field: "service", type: PlutoColumnType.text()),
      PlutoColumn(title: "Status", field: "status", type: PlutoColumnType.text()),
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
              if (user["orders"][index + 1]["status"].toString() == OrderStatus.Completed.name) {
                return null;
              }
              return PlutoRow(
                cells: {
                  'assistant_assigned': PlutoCell(value: user["orders"][index + 1]["assistant_assigned"]),
                  'service': PlutoCell(value: user["orders"][index + 1]["service"]),
                  'status': PlutoCell(value: user["orders"][index + 1]["status"]),
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
                onPressed: () {
                  final row = rendererContext.row;
                  final id = row.cells['order_index']?.value;

                  openGridPopup(context, 'orders', user, id);
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
