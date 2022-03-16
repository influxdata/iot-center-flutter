import 'package:iot_center_flutter_mvc/src/controller.dart';
import 'package:iot_center_flutter_mvc/src/view.dart';

class ChartListView extends StatefulWidget {
  const ChartListView({
    Key? key,
    required this.con,
  }) : super(key: key);

  final Controller con;

  @override
  State<StatefulWidget> createState() {
    return _ChartListView();
  }
}

class _ChartListView extends State<ChartListView> {
  refresh() {
    setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(4),
      child: ListView(shrinkWrap: true, children: [
        Row(
          children: [
            createChart(
                "Temperature", "Temperature", 0, 40, '°C', ChartType.gauge),
            createChart("CO2", "CO2", 400, 3000, 'ppm', ChartType.gauge),
          ],
        ),
        Row(
          children: [
            createChart("TVOC", "TVOC", 0, 0, 'ppm', ChartType.simple)
          ],
        ),
        Row(
          children: [
            createChart("Humidity", "Huminity", 0, 100, '%', ChartType.gauge),
            createChart(
                "Pressure", "Pressure", 900, 1100, 'hPa', ChartType.gauge),
          ],
        ),
        Row(
          children: [
            createChart("CO2", "CO2", 400, 3000, 'ppm', ChartType.gauge),
          ],
        ),
      ]),
    );
  }

  Widget createChart(String measurement, String label, double startValue,
      double endValue, String unit, ChartType chartType) {
    var getLast = chartType == ChartType.gauge;

    return getLast
        ? Expanded(
            child: Card(
                child: Padding(
                    padding: const EdgeInsets.all(10),
                    child: FutureBuilder<dynamic>(
                        future:
                            widget.con.getDataFromInflux(measurement, getLast),
                        builder: (context, AsyncSnapshot<dynamic> snapshot) {
                          if (snapshot.hasError) {
                            return Text(snapshot.error.toString());
                          }
                          if (snapshot.hasData) {
                            return GaugeChart(
                              notifyParent: refresh,
                              data: snapshot.data,
                              measurement: measurement,
                              label: label,
                              startValue: startValue,
                              endValue: endValue,
                              unit: unit,
                              size: 120,
                              decimalPlaces: 0,
                            );
                          } else {
                            return const Text("loading...");
                          }
                        }))))
        : Expanded(
            child: Card(
                child: Padding(
                    padding: const EdgeInsets.all(10),
                    child: FutureBuilder<dynamic>(
                        future:
                            widget.con.getDataFromInflux(measurement, getLast),
                        builder: (context, AsyncSnapshot<dynamic> snapshot) {
                          if (snapshot.hasError) {
                            return Text(snapshot.error.toString());
                          }
                          if (snapshot.hasData) {
                            return SimpleChart(
                              data: snapshot.data,
                              measurement: measurement,
                              label: label,
                            );
                          } else {
                            return const Text("loading...");
                          }
                        }))));
  }
}

enum ChartType {
  gauge,
  simple,
}
