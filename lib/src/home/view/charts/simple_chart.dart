import 'package:charts_flutter/flutter.dart' as charts;
import 'package:iot_center_flutter_mvc/src/controller.dart';
import 'package:iot_center_flutter_mvc/src/view.dart';

class SimpleChart extends StatefulWidget {
  const SimpleChart({
    Key? key,
    required this.chartData
  }) : super(key: key);

  final ChartData chartData;

  @override
  State<StatefulWidget> createState() {
    return _SimpleChart();
  }
}

class _SimpleChart extends StateMVC<SimpleChart> {
  void onPressed() {
    Navigator.push(
        context,
        MaterialPageRoute(
            builder: (c) => EditChartPage(
                  chart: widget,
              chartRefresh: (){},
                )));
  }

  late Controller con;

  _SimpleChart() : super(Controller()) {
    con = controller as Controller;
  }

  @override
  void initState() {
    add(con);
    super.initState();
    widget.chartData.refreshChart = () { refresh();};
  }

  @override
  Widget build(BuildContext context) {

    return FutureBuilder<dynamic>(
        future:
        con.getDataFromInflux(widget.chartData.measurement, false),
        builder: (context, AsyncSnapshot<dynamic> snapshot) {
          if (snapshot.hasError) {
            return Text(snapshot.error.toString());
          }
          if (snapshot.hasData) {
            var label = snapshot.data == null || snapshot.data!.isEmpty
                ? widget.chartData.measurement + " - no data"
                : widget.chartData.measurement;

            var series = [
              charts.Series<dynamic, DateTime>(
                id: widget.chartData.measurement,
                data: snapshot.data!,
                seriesColor: charts.ColorUtil.fromDartColor(pink),
                domainFn: (r, _) => DateTime.parse(r['_time']),
                measureFn: (r, _) => r["_value"],
              )
            ];

            return Column(children: [
              Row(
                children: [
                  Expanded(
                    child: Text(
                      label,
                      style: const TextStyle(
                          fontSize: 15, fontWeight: FontWeight.w700, color: darkBlue),
                    ),
                  ),
                  IconButton(
                    onPressed: onPressed,
                    icon: const Icon(Icons.settings),
                    iconSize: 17,
                    color: darkBlue,
                  ),
                ],
              ),
              SizedBox(
                height: 130,
                child: charts.TimeSeriesChart(
                  series,
                  animate: true,
                ),
              )
            ]);
          } else {
            return const Text("loading...");
          }
        });

  }
}
