import 'package:iot_center_flutter_mvc/src/view.dart';

const Color darkBlue = Color.fromRGBO(2, 10, 71, 1);
const Color turquoise = Color.fromRGBO(94, 228, 228, 1);
const Color pink = Color.fromRGBO(211, 9, 113, 1);
const Color purple = Color.fromRGBO(155, 42, 255, 1);
const Color blue = Color.fromRGBO(147, 148, 255, 1);
const Color lightGrey = Color.fromRGBO(250, 250, 250, 1);
const Color darkGrey = Color.fromRGBO(86, 86, 86, 1.0);

const LinearGradient pinkPurpleGradient = LinearGradient(
  begin: Alignment.topLeft,
  end: Alignment.bottomRight,
  stops: [
    0,
    0.6,
  ],
  colors: [
    pink,
    purple,
  ],
);

const LinearGradient buttonGradient = LinearGradient(
  begin: Alignment.topCenter,
  end: Alignment.bottomCenter,
  colors: [
    pink,
    purple,
  ],
);

BoxDecoration boxDecor = BoxDecoration(
    color: Colors.white,
    borderRadius: BorderRadius.circular(5),
    boxShadow: const [
      BoxShadow(color: Color.fromRGBO(201, 201, 201, 1.0), blurRadius: 4.0)
    ]);
