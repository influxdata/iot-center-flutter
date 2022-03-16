import 'dart:math' show cos, pi, sin;

import 'package:flutter/material.dart';
import 'package:influxdb_client/api.dart';
import 'package:iot_center_flutter_mvc/src/home/view/edit_chart_page.dart';
import 'package:vector_math/vector_math.dart' show radians;

class GaugeChart extends StatefulWidget {
  GaugeChart({
    Key? key,
    required this.notifyParent,
    required this.data,
    required this.measurement,
    this.label = '',
    this.startValue = 0,
    this.endValue = 100,
    this.unit = '',
    this.size = 130,
    this.decimalPlaces = 0,
  }) : super(key: key);

  final Function() notifyParent;
  final List<FluxRecord> data;
  final String measurement;
  final String label;
  final String unit;
  double startValue;
  final double endValue;
  final double size;
  final int? decimalPlaces;

  @override
  State<StatefulWidget> createState() {
    return _GaugeChart();
  }

  refresh() => notifyParent();
}

class _GaugeChart extends State<GaugeChart> {
  void onPressed() {
    Navigator.push(
        context,
        MaterialPageRoute(
            builder: (c) => EditChartPage(
                  chart: widget,
                )));
  }

  double checkDouble(dynamic value) {
    if (value is String) {
      return double.parse(value);
    } else {
      return value.toDouble();
    }
  }

  @override
  Widget build(BuildContext context) {
    final value = widget.data.isNotEmpty
        ? checkDouble(widget.data.last["_value"])
        : widget.startValue;

    final calcValue =
        (value - widget.startValue) / (widget.endValue - widget.startValue);

    final label = widget.data.isNotEmpty
        ? value.toStringAsFixed(widget.decimalPlaces!)
        : "no data";

    return Column(
      children: [
        Row(
          children: [
            Expanded(
              child: Text(
                widget.measurement,
                style: const TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
            IconButton(onPressed: onPressed, icon: const Icon(Icons.edit)),
          ],
        ),
        Row(
          children: [
            Expanded(
              child: Center(
                child: SizedBox(
                  width: widget.size,
                  height: widget.size,
                  child: CustomPaint(
                      painter: GaugeChartPainter(
                        calcValue: calcValue,
                        radius: widget.size / 2,
                      ),
                      child: Padding(
                        padding: EdgeInsets.only(top: widget.size / 3 + 10),
                        child: Column(
                          children: [
                            Text(
                              label,
                              style: TextStyle(
                                fontSize: widget.size / 9,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                            Text(
                              widget.unit,
                              style: TextStyle(
                                fontSize: (widget.size / 8) - 5,
                                fontWeight: FontWeight.w800,
                              ),
                            ),
                          ],
                        ),
                      )),
                ),
              ),
            )
          ],
        ),
        Row(
          children: [
            Expanded(
              child: Center(
                child: Text(
                  widget.startValue.toStringAsFixed(0),
                  style: const TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ),
            Expanded(
              child: Center(
                child: Text(
                  widget.endValue.toStringAsFixed(0),
                  style: const TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            )
          ],
        )
      ],
    );
  }
}

class GaugeChartPainter extends CustomPainter {
  const GaugeChartPainter({
    required this.calcValue,
    required this.radius,
  });

  final double calcValue;
  final double radius;

  static const double startAngle = 130;
  static const double endAngle = 280;
  static const double levelCount = 51;

  @override
  void paint(Canvas canvas, Size size) {
    final space = radius / 2;
    const itemAngle = endAngle / levelCount;
    final width = radius / 6 + 5;

    var paint = Paint()
      ..strokeWidth = radius / 100
      ..strokeCap = StrokeCap.round
      ..style = PaintingStyle.stroke;

    for (var index = 0; index < levelCount; index++) {
      final angle = itemAngle * index + startAngle + (itemAngle / 2);
      canvas.save();

      final offset = Offset(
        (radius - space) * cos(pi * angle / 180) + radius,
        (radius - space) * sin(pi * angle / 180) + radius,
      );

      canvas.translate(offset.dx, offset.dy);
      canvas.rotate(radians(angle));

      canvas.drawLine(
        Offset.zero,
        Offset(index % 10 == 0 ? space / 3 : space / 5, 0),
        paint,
      );
      canvas.restore();
    }

    final outerRect = Rect.fromLTWH(
      width / 2,
      width / 2,
      size.height - width,
      size.height - width,
    );

    paint
      ..color = Colors.black26
      ..strokeWidth = width;

    canvas.drawArc(
      outerRect,
      radians(startAngle),
      radians(endAngle),
      false,
      paint,
    );

    canvas.save();

    paint
      ..color = Colors.white
      ..shader = SweepGradient(
        stops: const [0, 0.4],
        colors: const [Colors.blue, Colors.deepPurple],
        startAngle: radians(0),
        endAngle: radians(360),
        transform: GradientRotation(radians(startAngle - width)),
      ).createShader(outerRect);

    canvas.drawArc(
      outerRect,
      radians(startAngle),
      radians(endAngle * calcValue),
      false,
      paint,
    );

    canvas.restore();
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) {
    return this != oldDelegate;
  }
}
