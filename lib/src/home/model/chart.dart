import 'package:influxdb_client/api.dart';
import 'package:iot_center_flutter_mvc/src/view.dart';

enum ChartType {
  gauge,
  simple,
}

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

  List<FluxRecord> data = [];
  String measurement = '';
  String label = '';
  String unit = '';
  double startValue = 0;
  double endValue = 100;
  double size = 120;
  int? decimalPlaces;

  Function()? refreshHeader;
  Function()? refreshChart;
  Function()? refreshWidget;
  Function()? removeChart;

  ChartType chartType = ChartType.simple;
}
