import 'dart:developer' as developer;

import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

class SettingsPage extends StatefulWidget {
  const SettingsPage({Key? key}) : super(key: key);

  @override
  _SettingsPageState createState() {
    return _SettingsPageState();
  }
}

class _SettingsPageState extends State<SettingsPage> {
  final _formKey = GlobalKey<FormState>();
  final TextEditingController _controller = TextEditingController();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
        appBar: AppBar(
          title: const Text("Preferences"),
        ),
        body: Form(
          key: _formKey,
          child: Column(
            children: [
              TextFormField(
                enableSuggestions: false,
                keyboardType: TextInputType.url,
                controller: _controller,
                decoration: const InputDecoration(labelText: 'IoT Center URL:'),
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
                  developer.log("Saved: $value ", name: "SharedPreferences");
                },
              ),
              ElevatedButton(
                onPressed: () async {
                  if (_formKey.currentState!.validate()) {
                    _formKey.currentState!.save();
                  }
                },
                child: const Text('Save'),
              ),
            ],
          ),
        ));
  }

  @override
  void initState() {
    super.initState();
    SharedPreferences.getInstance().then((prefs) {
      var val = prefs.getString("iot_center_url");
      _controller.text = val ?? "";
    });
  }
}
