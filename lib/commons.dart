import 'package:flutter/material.dart';

List timeOptions = [
  {"label": 'Past 5m', "value": '-5m'},
  {"label": 'Past 15m', "value": '-15m'},
  {"label": 'Past 1h', "value": '-1h'},
  {"label": 'Past 6h', "value": '-6h'},
  {"label": 'Past 1d', "value": '-1d'},
  {"label": 'Past 3d', "value": '-3d'},
  {"label": 'Past 7d', "value": '-7d'},
  {"label": 'Past 30d', "value": '-30d'},
];

Expanded buildDeviceSelector(
    Map? selectedDevice,
    List deviceList,
    String maxPastTime,
    void Function(String?)? onChangeDevice,
    void Function(String?)? onChangeTimeRange,
    void Function() onRefresh) {
  return Expanded(
      flex: 1,
      child: Row(mainAxisAlignment: MainAxisAlignment.spaceEvenly, children: [
        DropdownButton<String>(
          hint: const Text("Select device"),
          value: selectedDevice != null ? selectedDevice['deviceId'] : null,
          items: deviceList.map((dynamic map) {
            return DropdownMenuItem<String>(
                value: map['deviceId'].toString(),
                child: Text(
                  map['deviceId'],
                  style: const TextStyle(fontSize: 16),
                ));
          }).toList(),
          onChanged: onChangeDevice,
        ),
        DropdownButton<String>(
            hint: const Text("Time Range"),
            value: maxPastTime,
            items: timeOptions.map((dynamic map) {
              return DropdownMenuItem<String>(
                  value: map['value'].toString(),
                  child: Text(
                    map['label'],
                    style: const TextStyle(fontSize: 16),
                  ));
            }).toList(),
            onChanged: onChangeTimeRange),
        MaterialButton(
          onPressed: onRefresh,
          child: const Icon(Icons.autorenew_rounded),
        ),
      ]));
}
