import 'package:influxdb_client/api.dart';
import 'package:iot_center_flutter_mvc/src/controller.dart';
import 'package:iot_center_flutter_mvc/src/view.dart';

class Chart {
  Chart({required this.data, required this.row, required this.column}) {
    widget = ChartWidget(
      data: data,
      editChartPage: EditChartPage(
        chart: this,
      ),
    );
  }

  Chart.fromJson(Map<String, dynamic> json) {
    var chartType = json['chartType'];

    if (chartType == 'ChartType.gauge') {
      data = ChartData.gauge(
          measurement: json['measurement'],
          endValue: json['endValue'],
          label: json['label'],
          unit: json['unit'],
          startValue: json['startValue'],
          decimalPlaces: json['decimalPlaces']);
      row = json['row'];
      column = json['column'];
    } else {
      data = ChartData.simple(
        measurement: json['measurement'],
        label: json['label'],
        unit: json['unit'],
      );
      row = json['row'];
      column = json['column'];
    }

    widget = ChartWidget(
      data: data,
      editChartPage: EditChartPage(
        chart: this,
      ),
    );
  }

  Map<String, dynamic> toJson() => {
        'measurement': data.measurement,
        'label': data.label,
        'unit': data.unit,
        'startValue': data.startValue,
        'endValue': data.endValue,
        'decimalPlaces': data.decimalPlaces,
        'chartType': data.chartType.toString(),
        'row': row,
        'column': column,
      };

  late ChartData data;
  late ChartWidget widget;

  int row = 0;
  int column = 0;
}

class ChartData {
  ChartData.gauge({
    required this.measurement,
    this.label = '',
    this.startValue = 0,
    this.endValue = 100,
    this.unit = '',
    this.size = 130,
    this.decimalPlaces = 0,
  }) {
    chartType = ChartType.gauge;
  }

  ChartData.simple({
    required this.measurement,
    this.label = '',
    this.unit = '',
  }) {
    chartType = ChartType.simple;
  }

  Map<String, dynamic> toJson() => {
        'measurement': measurement,
        'label': label,
        'unit': unit,
        'startValue': startValue,
        'endValue': endValue,
        'decimalPlaces': decimalPlaces,
        'chartType': chartType.toString(),
        // 'row': row,
        // 'column': column,
      };

  List<FluxRecord> data = [];
  String measurement = '';
  String label = '';
  String unit = '';
  double startValue = 0;
  double endValue = 100;
  double size = 120;
  int? decimalPlaces;

  Function()? refreshChart;
  Function()? removeChart;
  Function()? editableChart;

  ChartType chartType = ChartType.simple;
}

class ChartWidget extends StatefulWidget {
  const ChartWidget({Key? key, required this.data, required this.editChartPage}) : super(key: key);

  final ChartData data;
  final EditChartPage editChartPage;

  @override
  State<StatefulWidget> createState() {
    return _ChartWidget();
  }
}

class _ChartWidget extends StateMVC<ChartWidget> {
  _ChartWidget() : super(Controller()) {
    con = controller as Controller;
  }

  @override
  void initState() {
    add(con);
    super.initState();
    widget.data.editableChart = () {
      setState(() {con.editable;});
    };
  }

  late Controller con;

  @override
  Widget build(BuildContext context) {
    var isGauge = widget.data.chartType == ChartType.gauge;

    Widget chart = isGauge
        ? GaugeChart(
            chartData: widget.data,
          )
        : SimpleChart(
            chartData: widget.data,
          );

    return Expanded(
        child: Padding(
            padding: const EdgeInsets.all(5.0),
            child: Container(
                decoration: boxDecor,
                child: Padding(
                    padding: const EdgeInsets.all(10),
                    child: Column(
                      children: [
                        Padding(
                          padding: con.editable
                              ? const EdgeInsets.only(bottom: 0)
                              : const EdgeInsets.only(bottom: 15, top: 15),
                          child: Row(
                            children: [
                              Expanded(
                                child: Text(
                                  widget.data.label,
                                  style: const TextStyle(
                                    fontSize: 15,
                                    fontWeight: FontWeight.w700,
                                    color: darkBlue,
                                  ),
                                ),
                              ),
                              Visibility(
                                visible: con.editable,
                                child: IconButton(
                                  onPressed: (){
                                    Navigator.push(
                                        context,
                                        MaterialPageRoute(
                                            builder: (c) => widget.editChartPage));
                                  },
                                  icon: const Icon(Icons.settings),
                                  iconSize: 17,
                                  color: darkBlue,
                                ),
                              ),
                            ],
                          ),
                        ),
                        chart
                      ],
                    )))));
  }
}
