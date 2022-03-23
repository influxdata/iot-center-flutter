import 'package:iot_center_flutter_mvc/src/controller.dart';
import 'package:iot_center_flutter_mvc/src/view.dart';

class NewChartPage extends StatefulWidget {
  const NewChartPage({Key? key}) : super(key: key);

  @override
  _NewChartPageState createState() {
    return _NewChartPageState();
  }
}

class _NewChartPageState extends StateMVC<NewChartPage> {
  final _formKey = GlobalKey<FormState>();

  _NewChartPageState() : super(Controller()) {
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
          title: const Text("New chart"),
        ),
        body: Padding(
          padding:
              const EdgeInsets.only(top: 30, left: 15, right: 15, bottom: 10),
          child: Form(
            key: _formKey,
            child: ListView(
              children: [
                FormRow.dropDownListRow(
                  label: "Type:",
                  items: con.getChartTypeList(),
                  mapValue: 'value',
                  mapLabel: 'label',
                  onChanged: (value) {},
                ),
                FormRow.textBoxRow(label: "Label:"),
                FutureBuilder<dynamic>(
                    future: con.loadFieldNames(),
                    builder: (context, AsyncSnapshot<dynamic> snapshot) {
                      if (snapshot.hasError) {
                        return Text(snapshot.error.toString());
                      }
                      if (snapshot.hasData) {
                        return FormRow.dropDownListRow(
                          label: "Field:",
                          items: snapshot.data,
                          mapValue: '_value',
                          mapLabel: '_value',
                          onChanged: (value) {},
                        );
                      } else {
                        return const Text("loading...");
                      }
                    }),
                FormRow.doubleTextBoxRow(label: "Range:"),
                FormRow.textBoxRow(
                  label: "Rounded:",
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return '';
                    }
                    return null;
                  },
                ),
                FormRow.textBoxRow(label: "Unit:"),
                Padding(
                  padding:
                      const EdgeInsets.symmetric(vertical: 35, horizontal: 3),
                  child: FormButton(
                      label: 'Create',
                      onPressed: () {
                        // Validate returns true if the form is valid, or false otherwise.
                        if (_formKey.currentState!.validate()) {
                          // If the form is valid, display a snackbar. In the real world,
                          // you'd often call a server or save the information in a database.
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(content: Text('Processing Data')),
                          );
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
