import 'package:iot_center_flutter_mvc/src/model.dart';

class Chart {
  Chart({required this.data, required this.row, required this.column});

  Chart.empty();

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

  int row = 0;
  int column = 0;
}
