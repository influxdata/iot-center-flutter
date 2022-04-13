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
  late Controller con;
  late TextEditingController iotUrlController;

  Map<String, dynamic>? _selectedDevice;
  Future<DeviceConfig>? _deviceDetail;
  Future<List<FluxRecord>>? _measurements;
  bool _writeInProgress = false;

  _SettingsPageState() : super(Controller()) {
    con = controller as Controller;
    iotUrlController = TextEditingController();

    _selectedDevice = con.deviceList.isNotEmpty ? con.deviceList.first : null;
    _deviceDetail = con.getDeviceConfig(_selectedDevice);
    _measurements = con.getMeasurements(_selectedDevice);
  }

  @override
  void initState() {
    super.initState();
    SharedPreferences.getInstance().then((prefs) {
      var val = prefs.getString("iot_center_url");
      iotUrlController.text = val ?? "";
    });
  }

  @override
  Widget build(BuildContext context) {
    var size = MediaQuery.of(context).size;

    return Scaffold(
        extendBodyBehindAppBar: false,
        backgroundColor: lightGrey,
        appBar: AppBar(
          title: const Text('Settings'),
          backgroundColor: darkBlue,
          actions: [
            IconButton(
                icon: const Icon(Icons.add),
                color: Colors.white,
                onPressed: (() {
                  showDialog(
                    context: context,
                    builder: (BuildContext context) {
                      return _newDeviceDialog(context);
                    },
                  );
                })),
            IconButton(
                icon: const Icon(Icons.insert_link),
                color: Colors.white,
                onPressed: (() {
                  showDialog(
                    context: context,
                    builder: (BuildContext context) {
                      return _popupDialog(context);
                    },
                  );
                })),
          ],
          bottom: PreferredSize(
            preferredSize: Size(size.width, 80),
            child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  Expanded(
                    child: FormRow.dropDownListRow(
                        padding: const EdgeInsets.fromLTRB(10, 10, 10, 20),
                        label: '',
                        items: con.deviceList,
                        value: _selectedDevice != null
                            ? _selectedDevice!['deviceId']
                            : '',
                        mapValue: 'deviceId',
                        mapLabel: 'deviceId',
                        hint: 'Select device',
                        onChanged: (value) {
                          setState(() {
                            _selectedDevice = con.deviceList.firstWhere(
                                (device) => device['deviceId'] == value);
                            _deviceDetail =
                                con.getDeviceConfig(_selectedDevice);
                            _measurements =
                                con.getMeasurements(_selectedDevice);
                          });
                        }),
                  ),
                ]),
          ),
        ),
        body: Padding(
            padding: const EdgeInsets.all(10),
            child: ListView(
              children: [
                FutureBuilder<DeviceConfig>(
                    future: _deviceDetail,
                    builder: (context, AsyncSnapshot<DeviceConfig> snapshot) {
                      if (snapshot.hasError) {
                        return Text(snapshot.error.toString());
                      }
                      if (snapshot.hasData && _selectedDevice != null) {
                        return Column(
                          children: [
                            tile(_selectedDevice!['deviceId'], 'Device Id',
                                Icons.device_thermostat),
                            tile(snapshot.data!.createdAt, 'Registration Time',
                                Icons.lock_clock),
                            tile(snapshot.data!.influxUrl, 'InfluxDB URL',
                                Icons.cloud_done_outlined),
                            tile(snapshot.data!.influxOrg,
                                'InfluxDB Organization', Icons.work),
                            tile(snapshot.data!.influxBucket, 'InfluxDB Bucket',
                                Icons.shopping_basket_rounded),
                            tile(
                                snapshot.data!.influxToken
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
                FormButton(
                  onPressed: () async {
                    if (_writeInProgress) {
                      return;
                    }
                    var x = await _writeSampleData(_selectedDevice);
                    developer.log("Points written $x");
                  },
                  label: _writeInProgress
                      ? "Write in progress..."
                      : "Write testing data",
                ),
                const Padding(
                    padding: EdgeInsets.only(bottom: 20, top: 25),
                    child: Center(
                        child: Text('Device Measurements',
                            style: TextStyle(
                              fontSize: 17,
                              fontWeight: FontWeight.w600,
                              color: darkBlue,
                            )))),
                FutureBuilder<dynamic>(
                    future: _measurements,
                    builder: (context, AsyncSnapshot<dynamic> snapshot) {
                      if (snapshot.hasError) {
                        return Text(snapshot.error.toString());
                      }
                      if (snapshot.hasData &&
                          snapshot.connectionState == ConnectionState.done) {
                        // return _buildMeasurementList(snapshot.data);
                        List<Widget> rows = [];
                        for (var record in snapshot.data) {
                          rows.add(measurementContainer(record));
                        }

                        return Column(
                          children: rows,
                        );
                      } else {
                        return const Text("loading...");
                      }
                    }),
              ],
            )));
  }

  Widget _popupDialog(BuildContext context) {
    final _formKey = GlobalKey<FormState>();

    return AlertDialog(
      title: const Text("IoT URL"),
      content: Form(
        key: _formKey,
        child: Row(mainAxisAlignment: MainAxisAlignment.spaceEvenly, children: [
          Expanded(
              child: FormRow.textBoxRow(
            hint: 'IoT Center URL:',
            label: '',
            controller: iotUrlController,
            padding: const EdgeInsets.fromLTRB(10, 10, 0, 20),
            inputType: TextInputType.url,
            validator: (value) {
              if (value == null || value.isEmpty) {
                return 'Please enter valid URL';
              }
              return null;
            },
            onSaved: (value) async {
              SharedPreferences prefs = await SharedPreferences.getInstance();
              prefs.setString("iot_center_url", value.toString());
              developer.log("Saved: $value ", name: "SharedPreferences");
            },
          )),
        ]),
      ),
      actions: [
        TextButton(
          child: const Text("Cancel"),
          onPressed: () {
            Navigator.of(context).pop();
          },
        ),
        TextButton(
            child: const Text("Save"),
            onPressed: (() async {
              if (_formKey.currentState!.validate()) {
                _formKey.currentState!.save();
              }
            })),
      ],
    );
  }

  Widget _newDeviceDialog(BuildContext context) {
    late TextEditingController newDeviceController = TextEditingController();
    final _deviceFormKey = GlobalKey<FormState>();

    return AlertDialog(
      title: const Text("New Device"),
      content: Form(
        key: _deviceFormKey,
        child: Row(mainAxisAlignment: MainAxisAlignment.spaceEvenly, children: [
          Expanded(
              child: FormRow.textBoxRow(
            hint: 'Device ID',
            label: '',
            controller: newDeviceController,
            padding: const EdgeInsets.fromLTRB(10, 10, 0, 20),
            onSaved: (value) async {},
          )),
        ]),
      ),
      actions: [
        TextButton(
          child: const Text("Cancel"),
          onPressed: () {
            Navigator.of(context).pop();
          },
        ),
        TextButton(
            child: const Text("Save"),
            onPressed: (() async {
              if (_deviceFormKey.currentState!.validate()) {
                _deviceFormKey.currentState!.save();
              }
            })),
      ],
    );
  }

  Future<num?> _writeSampleData(selectedDevice) async {
    setState(() {
      var device = selectedDevice['deviceId'];
      developer.log("write data.... $device");
      _writeInProgress = true;
      con.writeEmulatedData(device,
          (progressPercent, writtenPoints, totalPoints) {
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

  Widget measurementContainer(FluxRecord record) {
    var format = NumberFormat.decimalPattern();
    var textStyle = const TextStyle(
      fontWeight: FontWeight.w600,
    );

    return Padding(
      padding: const EdgeInsets.all(5.0),
      child: Container(
        decoration: boxDecor,
        child: Padding(
          padding: const EdgeInsets.all(10.0),
          child: Row(
            children: [
              SizedBox(
                  width: 130,
                  child: Text(
                    record["_field"],
                    style: textStyle,
                  )),
              Expanded(
                flex: 2,
                child: Column(
                  children: [
                    Row(
                      children: [
                        Expanded(
                            child: Text("Count",
                                style: textStyle, textScaleFactor: 0.8)),
                        Text(record["count"].toString(), textScaleFactor: 0.8),
                      ],
                    ),
                    Row(
                      children: [
                        Expanded(
                            child: Text("Max value",
                                style: textStyle, textScaleFactor: 0.8)),
                        Text(format.format(record["maxValue"]),
                            textScaleFactor: 0.8),
                      ],
                    ),
                    Row(
                      children: [
                        Expanded(
                            child: Text("Min value",
                                style: textStyle, textScaleFactor: 0.8)),
                        Text(format.format(record["minValue"]),
                            textScaleFactor: 0.8),
                      ],
                    ),
                    Row(
                      children: [
                        Expanded(
                            child: Text("Max time",
                                style: textStyle, textScaleFactor: 0.8)),
                        Text(record["maxTime"], textScaleFactor: 0.8),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
