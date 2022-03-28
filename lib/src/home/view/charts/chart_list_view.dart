import 'package:iot_center_flutter_mvc/src/view.dart';

class ChartListView extends StatefulWidget {
  const ChartListView({
    Key? key,
  }) : super(key: key);


  @override
  State<StatefulWidget> createState() {
    return _ChartListView();
  }
}

class _ChartListView extends StateMVC<ChartListView> {
  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(4),
      child: ListView(shrinkWrap: true, children: [
        Row(
          children: [
            Chart.gauge(
                measurement: "Temperature",
                endValue: 40,
                label: "Temperature",
                unit: '°C',
                startValue: 0),
            Chart.gauge(
                measurement: "CO2",
                endValue: 3000,
                label: "CO2",
                unit: 'ppm',
                startValue: 400),
          ],
        ),
        Row(
          children: [
            Chart.simple(measurement: 'TVOC', label: 'TVOC'),
          ],
        ),
        Row(
          children: [
            Chart.gauge(
                measurement: "Humidity",
                endValue: 100,
                label: "Humidity",
                unit: '%',
                startValue: 0),
            Chart.gauge(
                measurement: "Pressure",
                endValue: 1100,
                label: "Pressure",
                unit: 'hPa',
                startValue: 900),
          ],
        ),
        Row(
          children: [
            Chart.gauge(
                measurement: "CO2",
                endValue: 3000,
                label: "CO2",
                unit: 'ppm',
                startValue: 400),
          ],
        ),
      ]),
    );
  }
}
