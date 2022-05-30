import 'package:influxdb_client/api.dart';
import 'package:iot_center_flutter_mvc/src/view.dart';

enum ChartType {
  gauge,
  simple,
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
