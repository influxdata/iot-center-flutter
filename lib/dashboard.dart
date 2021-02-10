import 'package:charts_flutter/flutter.dart';
import 'package:flutter/material.dart';
import 'package:influxdb_client/api.dart';
import 'package:flutter_influx_app/simple_chart.dart';

class DashBoard extends StatefulWidget {

  @override
  State createState() => _DashBoardState();

  DashBoard();
}

class _DashBoardState extends State<DashBoard> {
  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: <Widget>[
          Expanded(
              flex: 5,
              child: FutureBuilder<List<Series<FluxRecord, DateTime>>>(
                  future: getFluxData(),
                  builder: (context,
                      AsyncSnapshot<List<Series<FluxRecord, DateTime>>>
                          snapshot) {
                    if (snapshot.hasData) {
                      return SimpleTimeSeriesChart(snapshot.data,
                          animate: false);
                    } else {
                      return Text("loading...");
                    }
                  })),
          Text(
            'Dashboard',
            style: Theme.of(context).textTheme.headline4,
          ),
        ],
      ),
    );
  }
}
