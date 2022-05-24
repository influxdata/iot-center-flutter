import 'package:iot_center_flutter_mvc/src/model.dart';

Dashboard defaultDashboard = [
  Chart(
      row: 1,
      column: 1,
      data: ChartData.gauge(
        measurement: "Temperature",
        endValue: 40,
        label: "Temperature",
        unit: '°C',
        startValue: 0,
      )),
  Chart(
      row: 1,
      column: 2,
      data: ChartData.gauge(
        measurement: "CO2",
        endValue: 3000,
        label: "CO2",
        unit: 'ppm',
        startValue: 400,
      )),
  Chart(
      row: 2,
      column: 1,
      data: ChartData.simple(measurement: 'TVOC', label: 'TVOC', unit: 'ppm')),
  Chart(
      row: 3,
      column: 1,
      data: ChartData.gauge(
          measurement: "Humidity",
          endValue: 100,
          label: "Humidity",
          unit: '%',
          startValue: 0)),
  Chart(
      row: 3,
      column: 2,
      data: ChartData.gauge(
          measurement: "Pressure",
          endValue: 1100,
          label: "Pressure",
          unit: 'hPa',
          startValue: 900))
];
