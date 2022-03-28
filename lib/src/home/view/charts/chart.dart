import 'package:influxdb_client/api.dart';
import 'package:iot_center_flutter_mvc/src/controller.dart';
import 'package:iot_center_flutter_mvc/src/view.dart';


class ChartData {
  ChartData({
    required this.data,
    required this.measurement,
    this.label = '',
    this.startValue = 0,
    this.endValue = 100,
    this.unit = '',
    this.size = 130,
    this.decimalPlaces = 0,
  });

  ChartData.simple({
    required this.data,
    required this.measurement,
    this.label = '',
  });

  List<FluxRecord> data = [];
  String measurement = '';
  String label = '';
  String unit = '';
  double startValue = 0;
  double endValue = 100;
  double size = 120;
  int? decimalPlaces;
}

class Chart extends StatefulWidget {
  Chart.simple({
    required this.measurement,
    required this.label,
    Key? key,
  }) : super(key: key) {
    chartType = ChartType.simple;
  }

  Chart.gauge({
    required this.measurement,
    required this.endValue,
    required this.label,
    required this.unit,
    required this.startValue,
    Key? key,
  }) : super(key: key) {
    chartType = ChartType.gauge;
  }

  String measurement = '';
  String label = '';
  double startValue = 0;
  double endValue = 100;
  String unit = '';
  ChartType chartType = ChartType.simple;

  @override
  State<StatefulWidget> createState() {
    return _Chart();
  }
}

class _Chart extends StateMVC<Chart> {
  _Chart() : super(Controller()) {
    con = controller as Controller;
  }

  @override
  void initState() {
    super.initState();
  }

  late Controller con;

  @override
  Widget build(BuildContext context) {
    var isGauge = widget.chartType == ChartType.gauge;

    return isGauge
        ? Expanded(
            child: Padding(
            padding: const EdgeInsets.all(5.0),
            child: Container(
                decoration: boxDecor,
                child: Padding(
                    padding: const EdgeInsets.all(10),
                    child: GaugeChart(
                      chartData: ChartData(
                        data: [],
                        measurement: widget.measurement,
                        label: widget.label,
                        startValue: widget.startValue,
                        endValue: widget.endValue,
                        unit: widget.unit,
                        size: 120,
                        decimalPlaces: 0,
                      ),
                    ))),
          ))
        : Expanded(
            child: Padding(
            padding: const EdgeInsets.all(5.0),
            child: Container(
                decoration: boxDecor,
                child: Padding(
                    padding: const EdgeInsets.all(10),
                    child: FutureBuilder<dynamic>(
                        future:
                            con.getDataFromInflux(widget.measurement, isGauge),
                        builder: (context, AsyncSnapshot<dynamic> snapshot) {
                          if (snapshot.hasError) {
                            return Text(snapshot.error.toString());
                          }
                          if (snapshot.hasData) {
                            return SimpleChart(
                              data: snapshot.data,
                              measurement: widget.measurement,
                              label: widget.label,
                            );
                          } else {
                            return const Text("loading...");
                          }
                        }))),
          ));
  }
}
