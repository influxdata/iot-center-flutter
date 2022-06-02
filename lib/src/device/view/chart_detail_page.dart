import 'package:influxdb_client/api.dart';
import 'package:iot_center_flutter_mvc/src/device/controller/chart_detail_controller.dart';
import 'package:iot_center_flutter_mvc/src/model.dart';
import 'package:iot_center_flutter_mvc/src/view.dart';

class ChartDetailPage extends StatefulWidget {
  const ChartDetailPage({Key? key, required this.chart, required this.newChart})
      : super(key: key);

  final Chart chart;
  final bool newChart;

  @override
  _ChartDetailPageState createState() {
    return _ChartDetailPageState();
  }
}

class _ChartDetailPageState extends StateMVC<ChartDetailPage> {
  final _formKey = GlobalKey<FormState>();

  late ChartDetailController con;

  _ChartDetailPageState() : super(ChartDetailController()) {
    con = controller as ChartDetailController;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
        appBar: AppBar(
            backgroundColor: darkBlue,
            title: widget.newChart
                ? const Text("New chart")
                : const Text("Edit chart"),
            actions: [
              Visibility(
                visible: !widget.newChart,
                child: IconButton(
                  icon: const Icon(Icons.delete),
                  color: Colors.white,
                  onPressed: () {
                    con.showAlertDialog(context, widget.chart);
                  },
                ),
              ),
            ]),
        backgroundColor: lightGrey,
        body: Padding(
          padding:
              const EdgeInsets.only(top: 30, left: 15, right: 15, bottom: 10),
          child: Form(
            key: _formKey,
            child: ListView(
              children: [
                DropDownListRow(
                  label: "Type:",
                  items: con.chartTypeList,
                  value: widget.chart.data.chartType.toString(),
                  onChanged: (value) {
                    setState(() {
                      con.isGauge = value == 'ChartType.gauge';
                    });
                  },
                  onSaved: (value) {
                    con.chartType = value!;
                  },
                ),
                FutureBuilder<List<FluxRecord>>(
                    future: con.fieldNames,
                    builder:
                        (context, AsyncSnapshot<List<FluxRecord>> snapshot) {
                      if (snapshot.hasError) {
                        return Text(snapshot.error.toString());
                      }
                      if (snapshot.hasData) {
                        final List<FluxRecord> data = snapshot.data!;
                        final items = data
                            .map((x) => DropDownItem(
                                label: x["_value"], value: x["_value"]))
                            .toList();

                        return DropDownListRow(
                          label: "Field:",
                          items: items,
                          value: widget.chart.data.measurement,
                          onChanged: (value) {},
                          onSaved: (value) {
                            widget.chart.data.measurement = value!;
                          },
                          addIfMissing: true,
                        );
                      } else {
                        return const Text("loading...");
                      }
                    }),
                TextBoxRow(
                  label: "Label:",
                  controller: con.label,
                ),
                Visibility(
                  visible: con.isGauge,
                  child: DoubleNumberBoxRow(
                    label: "Range:",
                    firstController: con.startValue,
                    secondController: con.endValue,
                  ),
                ),
                Visibility(
                  visible: con.isGauge,
                  child: NumberBoxRow(
                    label: "Rounded:",
                    controller: con.decimalPlaces,
                  ),
                ),
                TextBoxRow(
                  label: "Unit:",
                  controller: con.unit,
                ),
                Padding(
                  padding:
                      const EdgeInsets.symmetric(vertical: 35, horizontal: 3),
                  child: FormButton(
                      label: widget.newChart ? 'Create' : 'Update',
                      onPressed: () {
                        if (_formKey.currentState!.validate()) {
                          _formKey.currentState!.save();
                          con.saveChart(widget.newChart);
                          Navigator.pop(context);
                        }
                      }),
                ),
              ],
            ),
          ),
        ));
  }

  @override
  void initState() {
    super.initState();
    add(con);
    con.chart = widget.chart;
  }
}
