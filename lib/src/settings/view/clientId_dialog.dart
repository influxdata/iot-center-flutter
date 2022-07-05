import 'package:iot_center_flutter_mvc/src/controller.dart';
import 'package:iot_center_flutter_mvc/src/view.dart';

class ClientIdDialog extends StatelessWidget {
  const ClientIdDialog({
    Key? key,
    required this.con,
    required this.currentClientId,
    required this.onClientRegistered,
  }) : super(key: key);

  final SettingsPageController con;
  final String currentClientId;
  final void Function(String clientId) onClientRegistered;

  @override
  Widget build(BuildContext context) {
    late var newDeviceController = TextEditingController();
    newDeviceController.text = currentClientId;
    final _formKey = GlobalKey<FormState>();

    return AlertDialog(
      title: const Text("New Device"),
      content: Form(
        key: _formKey,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Row(mainAxisAlignment: MainAxisAlignment.spaceEvenly, children: [
              Expanded(
                  child: TextBoxRow(
                hint: 'Device ID',
                label: '',
                controller: newDeviceController,
                padding: const EdgeInsets.fromLTRB(10, 10, 0, 20),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Device ID cannot be empty';
                  }
                  return null;
                },
              )),
            ]),
          ],
        ),
      ),
      actions: [
        TextButton(
          child: const Text("Cancel"),
          onPressed: () {
            Navigator.of(context).pop();
          },
        ),
        TextButton(
            child: const Text("Save", style: TextStyle(color: pink)),
            onPressed: (() async {
              if (_formKey.currentState!.validate()) {
                _formKey.currentState!.save();
                final clientId = newDeviceController.text;

                await con.createDevice(clientId, "mobile");
                onClientRegistered(clientId);

                Navigator.of(context).pop();
              }
            })),
      ],
    );
  }
}
