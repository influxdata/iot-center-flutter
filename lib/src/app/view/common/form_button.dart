import 'package:iot_center_flutter_mvc/src/view.dart';

class FormButton extends StatelessWidget {
  const FormButton({required this.label, this.onPressed, Key? key}) : super(key: key);

  final void Function()? onPressed;
  final String? label;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        boxShadow: const [
          BoxShadow(color: Color.fromRGBO(201, 201, 201, 1.0), blurRadius: 4.0)
        ],
        gradient: pinkPurpleGradient,
        borderRadius: BorderRadius.circular(6),
      ),
      child: ElevatedButton(
        style: ButtonStyle(
          padding: MaterialStateProperty.all(const EdgeInsets.all(20)),
          backgroundColor: MaterialStateProperty.all(Colors.transparent),
          shadowColor: MaterialStateProperty.all(Colors.transparent),
          textStyle: MaterialStateProperty.all(
              const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
        ),
        onPressed: onPressed,
        child: Text(label!),
      ),
    );
  }
}
