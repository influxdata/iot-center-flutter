import 'package:influxdb_client/api.dart';
import 'package:iot_center_flutter_mvc/src/controller.dart';
import 'package:iot_center_flutter_mvc/src/view.dart';
import 'package:iot_center_flutter_mvc/src/model.dart';

class ChartWidget extends StatefulWidget {
  const ChartWidget({Key? key, required this.data, required this.editChartPage})
      : super(key: key);

  final ChartData data;
  final EditChartPage editChartPage;

  @override
  State<StatefulWidget> createState() {
    return _ChartWidget();
  }
}

class _ChartWidget extends StateMVC<ChartWidget> {
  @override
  void initState() {
    super.initState();
    isGauge = widget.data.chartType == ChartType.gauge;
    widget.data.refreshWidget = () {
      setState(() {
        isGauge = widget.data.chartType == ChartType.gauge;
      });
    };
  }

  var isGauge = true;

  @override
  Widget build(BuildContext context) {
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
                        ChartHeader(
                            data: widget.data,
                            editChartPage: widget.editChartPage),
                        chart
                      ],
                    )))));
  }
}

class ChartHeader extends StatefulWidget {
  const ChartHeader({Key? key, required this.data, required this.editChartPage})
      : super(key: key);

  final ChartData data;
  final EditChartPage editChartPage;

  @override
  State<StatefulWidget> createState() {
    return _ChartHeader();
  }
}

class _ChartHeader extends StateMVC<ChartHeader> {
  _ChartHeader() : super(Controller()) {
    con = controller as Controller;
  }

  @override
  void initState() {
    add(con);
    super.initState();
    widget.data.refreshHeader = () {
      setState(() {
        con.editable;
      });
    };
  }

  late Controller con;

  @override
  Widget build(BuildContext context) {
    return Padding(
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
              onPressed: () {
                Navigator.push(context,
                    MaterialPageRoute(builder: (c) => widget.editChartPage));
              },
              icon: const Icon(Icons.settings),
              iconSize: 17,
              color: darkBlue,
            ),
          ),
        ],
      ),
    );
  }
}
