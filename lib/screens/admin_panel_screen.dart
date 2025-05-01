import 'package:flutter/material.dart';
import 'package:pluto_grid/pluto_grid.dart';
import 'package:flutter/services.dart';

class AdminScreen extends StatefulWidget {
  const AdminScreen({super.key});

  @override
  State<AdminScreen> createState() => _AdminScreenState();
}

class _AdminScreenState extends State<AdminScreen> {
  List<PlutoColumn> columns = [];
  List<PlutoRow> rows = [];

  late PlutoGridStateManager stateManager;

  @override
  void dispose() {
    SystemChrome.setPreferredOrientations([
      DeviceOrientation.portraitUp,
      DeviceOrientation.portraitDown,
    ]);
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

                  print(id);
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
      // PlutoColumn(
      //   title: 'action',
      //   field: 'action',
      //   type: PlutoColumnType.text(),
      //   renderer: (rendererContext) {
      //     return GestureDetector(
      //       onSecondaryTap: () {
      //         final row = rendererContext.row;
      //         final id = row.cells['order_index']?.value;
      //         print(id);
      //       },
      //       child: Icon(Icons.check_box),
      //     );
      //   },
      // ),
    ]);

    rows.addAll([
      PlutoRow(
        cells: {
          'order_index': PlutoCell(value: 22),
          'email': PlutoCell(value: "CCC"),
          'address': PlutoCell(value: "BBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBB"),
          'orders': PlutoCell(value: "DDD"),
          // 'action': PlutoCell(value: ''),
        },
      ),

      PlutoRow(
        cells: {
          'order_index': PlutoCell(value: 22),
          'email': PlutoCell(value: "CCC"),
          'address': PlutoCell(value: "BBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBB"),
          'orders': PlutoCell(value: "DDD"),
          // 'action': PlutoCell(value: ''),
        },
      ),

      PlutoRow(
        cells: {
          'order_index': PlutoCell(value: 11),
          'email': PlutoCell(value: "CCC"),
          'address': PlutoCell(value: "BBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBB"),
          'orders': PlutoCell(value: "DDD"),
          // 'action': PlutoCell(value: ''),
        },
      ),
    ]);
  }

  // void openDetail(PlutoRow? row) async {
  //   String? value = await showDialog(
  //     context: context,
  //     builder: (BuildContext ctx) {
  //       final textController = TextEditingController();
  //       return Dialog(
  //         child: LayoutBuilder(
  //           builder: (ctx, size) {
  //             return Container(
  //               padding: const EdgeInsets.all(15),
  //               width: 400,
  //               height: 500,
  //               child: SingleChildScrollView(
  //                 scrollDirection: Axis.vertical,
  //                 child: Column(
  //                   crossAxisAlignment: CrossAxisAlignment.start,
  //                   children: [
  //                     const Text('Update Cell'),
  //                     TextField(controller: textController, autofocus: true),
  //                     const SizedBox(height: 20),
  //                     ...row!.cells.entries
  //                         .map(
  //                           (e) => Padding(
  //                             padding: const EdgeInsets.all(8.0),
  //                             child: Text(e.value.value.toString()),
  //                           ),
  //                         )
  //                         .toList(),
  //                     const SizedBox(height: 20),
  //                     Center(
  //                       child: Wrap(
  //                         spacing: 10,
  //                         children: [
  //                           TextButton(
  //                             onPressed: () {
  //                               Navigator.pop(ctx, null);
  //                             },
  //                             child: const Text('Cancel.'),
  //                           ),
  //                           ElevatedButton(
  //                             onPressed: () {
  //                               Navigator.pop(ctx, textController.text);
  //                             },
  //                             style: ButtonStyle(
  //                               backgroundColor: MaterialStateProperty.all<Color>(Colors.blue),
  //                             ),
  //                             child: const Text('Update.', style: TextStyle(color: Colors.white)),
  //                           ),
  //                         ],
  //                       ),
  //                     ),
  //                   ],
  //                 ),
  //               ),
  //             );
  //           },
  //         ),
  //       );
  //     },
  //   );
  //
  //   if (value == null || value.isEmpty) {
  //     return;
  //   }
  //
  //   stateManager.changeCellValue(stateManager.currentRow!.cells['order_index']!, value, force: true);
  // }

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
            onChanged: (PlutoGridOnChangedEvent event) {
              print(event);
            },
            onLoaded: (PlutoGridOnLoadedEvent event) {
              stateManager = event.stateManager;

              stateManager.setShowColumnFilter(true);

              // stateManager.setSelectingMode(PlutoGridSelectingMode.cell);
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
