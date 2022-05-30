import 'package:iot_center_flutter_mvc/src/model.dart';
import 'package:iot_center_flutter_mvc/src/view.dart';

class DashboardTab extends StatefulWidget {
  const DashboardTab({required this.selectedDevice, Key? key}) : super(key: key);

  final Device selectedDevice;

  @override
  _DashboardTabState createState() {
    return _DashboardTabState();
  }
}

class _DashboardTabState extends StateMVC<DashboardTab> {
  late DashboardController con;

  _DashboardTabState() : super(DashboardController()) {
    con = controller as DashboardController;
  }

  @override
  void initState() {
    con.selectedDevice = widget.selectedDevice;

    super.initState();
    add(con);
  }

  @override
  Widget build(BuildContext context) {
    con.setRowCount();
    return ListView.builder(
      itemCount: con.rowCount,
      itemBuilder: (context, index) {
        return con.buildChartListViewRow(index, context);
      },
    );
  }


}
