
import 'package:iot_center_flutter_mvc/src/view.dart';
import 'package:shared_preferences/shared_preferences.dart';

class AddChartPage extends StatefulWidget {
  const AddChartPage({Key? key}) : super(key: key);

  @override
  _AddChartPageState createState() {
    return _AddChartPageState();
  }
}

class _AddChartPageState extends State<AddChartPage> {
  final _formKey = GlobalKey<FormState>();
  final TextEditingController _controller = TextEditingController();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color.fromRGBO(250, 250, 250, 1),
        appBar: AppBar(
          backgroundColor: const Color.fromRGBO(2, 10, 71, 1),
          title: const Text("Add chart"),
        ),
        body: Padding(
          padding:
              const EdgeInsets.only(top: 30, left: 15, right: 15, bottom: 10),
          child: Form(
            key: _formKey,
            child: ListView(
              children: [
                getTextBoxRow(
                  "Type:",
                  "",
                  (value) {
                    if (value == null || value.isEmpty) {
                      return '';
                    }
                    return null;
                  },
                ),
                getTextBoxRow(
                  "Label:",
                  "",
                  (value) {
                    if (value == null || value.isEmpty) {
                      return 'Please enter some text';
                    }
                    return null;
                  },
                ),
                getTextBoxRow(
                  "Field:",
                  "",
                  (value) {
                    if (value == null || value.isEmpty) {
                      return 'Please enter some text';
                    }
                    return null;
                  },
                ),
                getDoubleTextBoxRow(
                  "Range:",
                  "",
                  (value) {
                    if (value == null || value.isEmpty) {
                      return 'Please enter some text';
                    }
                    return null;
                  },
                ),
                getTextBoxRow(
                  "Rounded:",
                  "",
                  (value) {
                    if (value == null || value.isEmpty) {
                      return 'Please enter some text';
                    }
                    return null;
                  },
                ),
                getTextBoxRow(
                  "Unit:",
                  "",
                  (value) {
                    if (value == null || value.isEmpty) {
                      return 'Please enter some text';
                    }
                    return null;
                  },
                ),
                Padding(
                  padding:
                      const EdgeInsets.symmetric(vertical: 25, horizontal: 5),
                  child: ElevatedButton(
                    style: ButtonStyle(
                      padding:
                          MaterialStateProperty.all(const EdgeInsets.all(20)),
                      backgroundColor:
                          MaterialStateProperty.all(Colors.deepPurple),
                      textStyle: MaterialStateProperty.all(const TextStyle(
                          fontSize: 18, fontWeight: FontWeight.bold)),
                    ),
                    onPressed: () {
                      // Validate returns true if the form is valid, or false otherwise.
                      if (_formKey.currentState!.validate()) {
                        // If the form is valid, display a snackbar. In the real world,
                        // you'd often call a server or save the information in a database.
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(content: Text('Processing Data')),
                        );
                      }
                    },
                    child: const Text('Create'),
                  ),
                ),
              ],
            ),
          ),
        ));
  }

  Padding getTextBoxRow(
      String label, String? hintText, String? Function(String?)? validator) {
    return Padding(
      padding: const EdgeInsets.all(5),
      child: Row(
        children: [getLabel(label), getTextBox(hintText, validator)],
      ),
    );
  }

  Padding getDoubleTextBoxRow(
      String label, String? hintText, String? Function(String?)? validator) {
    return Padding(
      padding: const EdgeInsets.all(5),
      child: Row(
        children: [getLabel(label), getDoubleTextBox(hintText, validator)],
      ),
    );
  }

  Padding getDropDownRow(
      String label,
      String hintText,
      String value,
      List items,
      String mapValue,
      String? labelDropDown,
      void Function(String?)? onChange) {
    return Padding(
      padding: const EdgeInsets.all(5),
      child: Row(
        children: [
          getLabel(label),
          Expanded(
              flex: 3,
              child: MyDropDown(EdgeInsets.zero, hintText, value, items,
                  mapValue, label, onChange))
        ],
      ),
    );
  }

  Expanded getLabel(String label) {
    return Expanded(
        flex: 1,
        child: Text(
          label,
          style: const TextStyle(
            fontSize: 15,
            fontWeight: FontWeight.w600,
          ),
        ));
  }

  Expanded getTextBox(String? hintText, String? Function(String?)? validator) {
    return Expanded(
      flex: 3,
      child: TextFormField(
        decoration: InputDecoration(
          isDense: true,
          border: const OutlineInputBorder(),
          fillColor: Colors.white,
          filled: true,
          hintText: hintText,
        ),
        validator: validator,
      ),
    );
  }

  Expanded getDoubleTextBox(
      String? hintText, String? Function(String?)? validator) {
    return Expanded(
        flex: 3,
        child: Row(
          children: [
            Expanded(
              child: Padding(
                padding: const EdgeInsets.only(right: 4),
                child: TextFormField(
                  decoration: InputDecoration(
                    isDense: true,
                    border: const OutlineInputBorder(),
                    fillColor: Colors.white,
                    filled: true,
                    hintText: hintText,
                  ),
                  validator: validator,
                ),
              ),
            ),
            Expanded(
              child: Padding(
                padding: const EdgeInsets.only(left: 4),
                child: TextFormField(
                  decoration: InputDecoration(
                    isDense: true,
                    border: const OutlineInputBorder(),
                    fillColor: Colors.white,
                    filled: true,
                    hintText: hintText,
                  ),
                  validator: validator,
                ),
              ),
            )
          ],
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
