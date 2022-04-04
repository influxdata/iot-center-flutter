import 'package:iot_center_flutter_mvc/src/controller.dart';
import 'package:iot_center_flutter_mvc/src/view.dart';

class NewDevicePage extends StatefulWidget {
  const NewDevicePage({Key? key}) : super(key: key);

  @override
  _NewDevicePageState createState() {
    return _NewDevicePageState();
  }
}

class _NewDevicePageState extends StateMVC<NewDevicePage> {
  final _formKey = GlobalKey<FormState>();

  _NewDevicePageState() : super(Controller()) {
    con = controller as Controller;
    con.loadFieldNames();
  }

  late Controller con;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
        backgroundColor: lightGrey,
        appBar: AppBar(
          backgroundColor: darkBlue,
          title: const Text("New device"),
        ),
        body: Padding(
          padding:
              const EdgeInsets.only(top: 30, left: 15, right: 15, bottom: 10),
          child: Form(
            key: _formKey,
            child: ListView(
              children: [
                FormRow.textBoxRow(label: "Device ID:"),
                Padding(
                  padding:
                      const EdgeInsets.symmetric(vertical: 35, horizontal: 3),
                  child: FormButton(
                      label: 'Create Device',
                      onPressed: () {

                        if (_formKey.currentState!.validate()) {

                        }
                      }),
                ),
              ],
            ),
          ),
        ));
  }

  @override
  void initState() {
    super.initState();
  }
}
