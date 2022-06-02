import 'package:iot_center_flutter_mvc/src/view.dart';
import 'package:iot_center_flutter_mvc/src/model.dart';

class ChartDetailController extends ControllerMVC {
  factory ChartDetailController([StateMVC? state]) =>
      _this ??= ChartDetailController._(state);
  ChartDetailController._(StateMVC? state)
      : _dashboardController = DashboardController(),
        super(state);
  static ChartDetailController? _this;
  final DashboardController _dashboardController;

  bool isGauge = true;
  var chartType = '';

  List<DropDownItem> chartTypeList = [
    DropDownItem(label: 'Gauge chart', value: ChartType.gauge.toString()),
    DropDownItem(label: 'Simple chart', value: ChartType.simple.toString()),
  ];
  get fieldNames => _dashboardController.fieldNames;

  Chart? _chart;
  Chart get chart => _chart!;

  set chart(Chart value) {
    setState(() {
      isGauge = value.data.chartType == ChartType.gauge;

      label.text = value.data.label;
      unit.text = value.data.unit;
      startValue.text = value.data.startValue.toStringAsFixed(0);
      endValue.text = value.data.endValue.toStringAsFixed(0);
      decimalPlaces.text = isGauge && value.data.decimalPlaces != null
          ? value.data.decimalPlaces!.toStringAsFixed(0)
          : '0';

      _chart = value;
    });
  }

  TextEditingController label = TextEditingController();
  TextEditingController startValue = TextEditingController();
  TextEditingController endValue = TextEditingController();
  TextEditingController decimalPlaces = TextEditingController();
  TextEditingController unit = TextEditingController();

  showAlertDialog(BuildContext context, Chart chart) {
    // set up the buttons
    Widget cancelButton = TextButton(
      child: const Text("Cancel"),
      onPressed: () {
        Navigator.of(context).pop();
      },
    );
    Widget continueButton = TextButton(
      child: const Text("Delete"),
      onPressed: () {
        _dashboardController.deleteChart(chart.row, chart.column);
        Navigator.of(context).pop();
        Navigator.of(context).pop();
      },
    );
    // set up the AlertDialog
    AlertDialog alert = AlertDialog(
      title: const Text("Delete chart"),
      actions: [
        cancelButton,
        continueButton,
      ],
    );
    // show the dialog
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return alert;
      },
    );
  }

  void saveChart(bool newChart) {
    chart.data.label = label.text;
    chart.data.startValue =
        _dashboardController.isGauge ? double.parse(startValue.text) : 0;
    chart.data.endValue =
        _dashboardController.isGauge ? double.parse(endValue.text) : 0;

    chart.data.decimalPlaces = isGauge ? int.parse(decimalPlaces.text) : 0;
    chart.data.unit = unit.text;

    chart.data.chartType =
        chartType == 'ChartType.gauge' ? ChartType.gauge : ChartType.simple;

    _dashboardController.saveChart(chart, newChart);
  }
}
