import 'package:influxdb_client/api.dart';
import 'package:iot_center_flutter_mvc/src/controller.dart';

import 'package:iot_center_flutter_mvc/src/view.dart';

class InfluxSettingsTab extends StatefulWidget {
  const InfluxSettingsTab({ required this.con, Key? key}) : super(key: key);

  final SettingsPageController con;

  @override
  _InfluxSettingsTabState createState() {
    return _InfluxSettingsTabState();
  }
}

class _InfluxSettingsTabState extends StateMVC<InfluxSettingsTab> {
  final _formKey = GlobalKey<FormState>();

  late TextEditingController urlController;
  late TextEditingController tokenController;
  late TextEditingController orgController;
  late TextEditingController bucketController;

  late InfluxDBClient client;

  @override
  void initState() {
    super.initState();
    client = widget.con.client;

    urlController = TextEditingController(text: client.url);
    tokenController = TextEditingController(text: client.token);
    orgController = TextEditingController(text: client.org);
    bucketController = TextEditingController(text: client.bucket);
  }

  @override
  Widget buildWidget(BuildContext context) {
    return Form(
      key: _formKey,
      child: ListView(
        children: [
          TextBoxRow(
            readOnly: widget.con.settingsReadonly,
            label: "Url:",
            controller: urlController,
            onSaved: (value) {
              client.url = value!;
            },
          ),
          TextBoxRow(
            readOnly: widget.con.settingsReadonly,
            label: "Token:",
            controller: tokenController,
            onSaved: (value) {
              client.token = value!;
            },
          ),
          TextBoxRow(
            readOnly: widget.con.settingsReadonly,
            label: "Org:",
            controller: orgController,
            onSaved: (value) {
              client.org = value!;
            },
          ),
          TextBoxRow(
            readOnly: widget.con.settingsReadonly,
            label: "Bucket:",
            controller: bucketController,
            onSaved: (value) {
              client.bucket = value!;
            },
          ),


          Visibility(
            visible: !widget.con.settingsReadonly,
            child: Padding(
              padding:
              const EdgeInsets.symmetric(vertical: 35, horizontal: 3),
              child: FormButton(
                  label: 'Save',
                  onPressed: () {
                    // Validate returns true if the form is valid, or false otherwise.
                    if (_formKey.currentState!.validate()) {
                      _formKey.currentState!.save();

                      widget.con.checkClient(client);

                    }
                  }),
            ),
          ),
        ],
      ),
    );
  }
}