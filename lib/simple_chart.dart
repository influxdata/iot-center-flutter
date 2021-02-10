import 'dart:io';

import 'package:charts_flutter/flutter.dart';
import 'package:flutter/material.dart';
import 'package:influxdb_client/api.dart';

import 'commons.dart';


void main() {
  runApp(SimpleChart());
}

var client = new InfluxDBClient(
    url: getLocalhost(), token: 'my-token', org: 'my-org', bucket: 'my-bucket');

Future<Stream<FluxRecord>> fetchData() async {
  return client.getQueryService().query('''
  from(bucket: "my-bucket")
  |> range(start: -1h)
  |> filter(fn: (r) => r["_measurement"] == "cpu")
  |> filter(fn: (r) => r["_field"] == "usage_user" or r["_field"] == "usage_system")
  // |> filter(fn: (r) => r["cpu"] == "cpu-total")
  |> aggregateWindow(every: 1m, fn: mean, createEmpty: false)  
  ''');
}

extension Iterables<E> on Iterable<E> {
  Map<K, List<E>> groupBy<K>(K Function(E) keyFunction) => fold(
      <K, List<E>>{},
      (Map<K, List<E>> map, E element) =>
          map..putIfAbsent(keyFunction(element), () => <E>[]).add(element));
}

var colors = [
  MaterialPalette.blue.shadeDefault,
  MaterialPalette.red.shadeDefault,
  MaterialPalette.yellow.shadeDefault,
  MaterialPalette.green.shadeDefault,
  MaterialPalette.purple.shadeDefault,
  MaterialPalette.cyan.shadeDefault,
  MaterialPalette.deepOrange.shadeDefault,
  MaterialPalette.lime.shadeDefault,
  MaterialPalette.indigo.shadeDefault,
  MaterialPalette.pink.shadeDefault,
  MaterialPalette.teal.shadeDefault,
];

/// Create one series with sample hard coded data.
Future<List<Series<FluxRecord, DateTime>>> getFluxData() async {
  print("Fetching data from influxDB");
  var streamRecords = await fetchData();
  var data = await streamRecords.toList();
  var newMap = data.groupBy((r) => r.tableIndex);
  List<Series<FluxRecord, DateTime>> ret = [];
  newMap.forEach((key, value) {
    ret.add(Series<FluxRecord, DateTime>(
      id: '${value[0]['_field']}',
      colorFn: (r, c) => colors[value[0].tableIndex % colors.length],
      domainFn: (FluxRecord r, _) => DateTime.parse(r['_time']),
      measureFn: (FluxRecord r, _) => r['_value'],
      data: value,
    ));
  });
  return ret;
}

class SimpleChart extends StatelessWidget {
  // This widget is the root of your application.
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Flutter Demo',
      theme: ThemeData(
        primarySwatch: Colors.red,
        visualDensity: VisualDensity.adaptivePlatformDensity,
      ),
      home: MyHomePage(title: 'InfluxDB Client Demo'),
    );
  }
}

class MyHomePage extends StatefulWidget {
  MyHomePage({Key key, this.title}) : super(key: key);
  final String title;

  @override
  _MyHomePageState createState() => _MyHomePageState();
}

class _MyHomePageState extends State<MyHomePage> {
  int _counter = 0;
  var data;

  void _incrementCounter() {
    setState(() {
      _counter++;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.title),
      ),
      body: Center(
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

            // SimpleTimeSeriesChart(getFluxData(),animate: false)),
            Text(
              '$_counter',
              style: Theme.of(context).textTheme.headline4,
            ),
          ],
        ),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: _incrementCounter,
        tooltip: 'Reload',
        child: Icon(Icons.autorenew),
      ),
    );
  }
}

class SimpleTimeSeriesChart extends StatelessWidget {
  final List<Series> seriesList;
  final bool animate;

  SimpleTimeSeriesChart(this.seriesList, {this.animate});

  @override
  Widget build(BuildContext context) {
    return new TimeSeriesChart(
      seriesList,
      animate: animate,
      dateTimeFactory: const UTCDateTimeFactory(),
      // defaultRenderer: new LineRendererConfig(includePoints: true),
      // behaviors: [new SeriesLegend(position: BehaviorPosition.bottom)],
    );
  }
}
