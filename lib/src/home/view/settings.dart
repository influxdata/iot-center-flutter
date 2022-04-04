import 'dart:developer' as developer;

import 'package:influxdb_client/api.dart';
import 'package:iot_center_flutter_mvc/src/model.dart';
import 'package:iot_center_flutter_mvc/src/view.dart';
import 'package:iot_center_flutter_mvc/src/controller.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:intl/intl.dart';

class SettingsPage extends StatefulWidget {
  const SettingsPage({Key? key}) : super(key: key);

  @override
  _SettingsPageState createState() {
    return _SettingsPageState();
  }
}

class _SettingsPageState extends StateMVC<SettingsPage> {
  final _formKey = GlobalKey<FormState>();

  _SettingsPageState() : super(Controller()) {
    con = controller as Controller;
    textCon = TextEditingController();

    selectedDevice = con.deviceList.first;
    deviceDetail = DeviceConfig();
  }

  late Controller con;
  late TextEditingController textCon;
  Map<String, dynamic>? selectedDevice;
  DeviceConfig? deviceDetail;
  bool _writeInProgress = false;


  @override
  Widget build(BuildContext context) {
    var size = MediaQuery.of(context).size;

    return Scaffold(
        extendBodyBehindAppBar: false,
        backgroundColor: lightGrey,
        appBar: AppBar(
          title: const Text('Settings'),
          backgroundColor: darkBlue,
          bottom: PreferredSize(
            preferredSize: Size(size.width, 80),
            child: Form(
              key: _formKey,
              child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: [
                    Expanded(
                        child: FormRow.textBoxRow(
                      hint: 'IoT Center URL:',
                      label: '',
                      controller: textCon,
                      padding: const EdgeInsets.fromLTRB(10, 10, 0, 20),
                      inputType: TextInputType.url,
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return 'Please enter valid URL';
                        }
                        return null;
                      },
                      onSaved: (value) async {
                        SharedPreferences prefs =
                            await SharedPreferences.getInstance();
                        prefs.setString("iot_center_url", value.toString());
                        developer.log("Saved: $value ",
                            name: "SharedPreferences");
                      },
                    )),
                    IconButton(
                        icon: const Icon(Icons.insert_link),
                        color: Colors.white,
                        onPressed: (() async {
                          if (_formKey.currentState!.validate()) {
                            _formKey.currentState!.save();
                          }
                        })),
                  ]),
            ),
          ),
        ),
        floatingActionButton: FloatingActionButton(
          backgroundColor: darkBlue,
          child: const Icon(Icons.add),
          onPressed: () {
            Navigator.push(context,
                MaterialPageRoute(builder: (c) => const NewDevicePage()));
          },
        ),
        body: Padding(
            padding: const EdgeInsets.all(10),
            child: ListView(
              children: [
                FormRow.dropDownListRow(
                  padding: const EdgeInsets.only(bottom: 20, left: 5, right: 5, top: 5),
                    label: 'Device',
                    items: con.deviceList,
                    value: selectedDevice!['deviceId'],
                    mapValue: 'deviceId',
                    mapLabel: 'deviceId',
                    hint: 'Select device',
                    onChanged: (value) {
                     setState(() { selectedDevice = con.deviceList
                         .firstWhere((device) => device['deviceId'] == value);
                     // deviceDetail = con.getDeviceConfig(selectedDevice!['deviceId']) as DeviceConfig?;
                     });
                    }),
                FormButton(
                  onPressed: () async {
                    if (_writeInProgress) {
                      return;
                    }
                    var x = await _writeSampleData(selectedDevice);
                    developer.log("Points written $x");
                  },
                  label: _writeInProgress
                      ? "Write in progress..."
                      : "Write testing data",
                ),

                const Padding(
                    padding:  EdgeInsets.only(bottom: 20, top: 35),
                    child: Center(
                        child: Text('Device Configuration',
                            style: TextStyle(
                              fontSize: 17,
                              fontWeight: FontWeight.w600,
                              color: darkBlue,
                            )))),
                FutureBuilder<DeviceConfig>(
                    future: con.getDeviceConfig(selectedDevice!['deviceId']),
                    builder: (context, AsyncSnapshot<DeviceConfig> snapshot) {
                      if (snapshot.hasError) {
                        return Text(snapshot.error.toString());
                      }
                      if (snapshot.hasData) {
                        deviceDetail = snapshot.data!;
                        return Column(
                          children: [
                            tile(selectedDevice!['deviceId'], 'Device Id',
                                Icons.device_thermostat),
                            tile(deviceDetail!.createdAt, 'Registration Time',
                                Icons.lock_clock),
                            tile(deviceDetail!.influxUrl, 'InfluxDB URL',
                                Icons.cloud_done_outlined),
                            tile(deviceDetail!.influxOrg,
                                'InfluxDB Organization', Icons.work),
                            tile(deviceDetail!.influxBucket, 'InfluxDB Bucket',
                                Icons.shopping_basket_rounded),
                            tile(
                                deviceDetail!.influxToken
                                        .toString()
                                        .substring(0, 3) +
                                    "...",
                                'InfluxDB Token',
                                Icons.theaters),
                          ],
                        );
                      } else {
                        return const Text("loading...");
                      }
                    }),
                const Padding(
                    padding: EdgeInsets.all(20),
                    child: Center(
                        child: Text('Device Measurements',
                            style: TextStyle(
                              fontSize: 17,
                              fontWeight: FontWeight.w600,
                              color: darkBlue,
                            )))),
                FutureBuilder<dynamic>(
                    future: con.getMeasurements(selectedDevice!['deviceId']),
                    builder: (context, AsyncSnapshot<dynamic> snapshot) {
                      if (snapshot.hasError) {
                        return Text(snapshot.error.toString());
                      }
                      if (snapshot.hasData) {
                        return _buildMeasurementList(snapshot.data);
                      } else {
                        return const Text("loading...");
                      }
                    }),
              ],
            )));
  }

  Future<num?> _writeSampleData(selectedDevice) async {
    setState(() {
      var device = selectedDevice['deviceId'];
      developer.log("write data.... $device");
      _writeInProgress = true;
      con.writeEmulatedData(device, (progressPercent, writtenPoints, totalPoints) {
        developer.log(
            "$progressPercent%, $writtenPoints of $totalPoints points written");
      }).then((value) {
        developer.log("Write completed. $value points written.");
        setState(() {
          _writeInProgress = false;
        });
        return value;
      });
    });
    return null;
  }


  ListTile tile(String title, String subtitle, IconData icon) => ListTile(
        title: Text(title),
        subtitle: Text(subtitle),
        leading: Icon(
          icon,
        ),
      );

  final _bold = const TextStyle(fontWeight: FontWeight.bold);

  Widget _buildMeasurementList(List<FluxRecord> records) {
    List<TableRow> rows = [];
    rows.add(TableRow(children: [
      Text("Field", style: _bold),
      Text("Count", style: _bold),
      Text("max time", style: _bold),
      Text("max", style: _bold),
      Text("min", style: _bold),
    ]));

    var format = NumberFormat.decimalPattern();
    for (var r in records) {
      rows.add(TableRow(children: [
        Text(
          r["_field"],
          textScaleFactor: 0.7,
        ),
        Text(r["count"].toString(), textScaleFactor: 0.7),
        Text(r["maxTime"], textScaleFactor: 0.7),
        Text(format.format(r["maxValue"]), textScaleFactor: 0.7),
        Text(format.format(r["minValue"]), textScaleFactor: 0.7),
      ]));
    }

    return Table(
        border: const TableBorder(
            top: BorderSide(),
            bottom: BorderSide(),
            horizontalInside: BorderSide(),
            verticalInside: BorderSide()),
        children: rows);
  }

  @override
  void initState() {
    super.initState();
    SharedPreferences.getInstance().then((prefs) {
      var val = prefs.getString("iot_center_url");
      textCon.text = val ?? "";
    });
  }
}
