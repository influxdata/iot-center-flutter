import 'package:influxdb_client/api.dart';
import 'package:iot_center_flutter_mvc/src/model.dart';
import 'package:iot_center_flutter_mvc/src/view.dart';

import 'package:vector_math/vector_math.dart' show radians;
import 'dart:math' show cos, pi, sin;

class GaugeChart extends StatefulWidget {
  const GaugeChart({
    Key? key,
    required this.chartData, required this.con,
  }) : super(key: key);

  final ChartData chartData;
  final DashboardController con;

  @override
  StateMVC<StatefulWidget> createState() {
    return _GaugeChart();
  }
}

class _GaugeChart extends StateMVC<GaugeChart> {

  @override
  void initState() {
    super.initState();
    _data = widget.con.getDataFromInflux(widget.chartData.measurement, true);

    widget.chartData.reloadData = () {
      _data = widget.con.getDataFromInflux(widget.chartData.measurement, true);
      refresh();
    };
  }

  Future<List<FluxRecord>>? _data;

  @override
  Widget buildWidget(BuildContext context) {
    return Column(
      children: [
        Row(
          children: [
            Expanded(
              child: Center(
                child: SizedBox(
                    width: widget.chartData.size,
                    height: widget.chartData.size,
                    child: FutureBuilder<dynamic>(
                        future: _data,
                        builder: (context, AsyncSnapshot<dynamic> snapshot) {
                          if (snapshot.hasError) {
                            return Text(snapshot.error.toString());
                          }
                          if (snapshot.hasData &&
                              snapshot.connectionState ==
                                  ConnectionState.done) {
                            widget.chartData.data = snapshot.data;
                            final value = widget.chartData.data.isNotEmpty
                                ? widget.con.getDouble(
                                    widget.chartData.data.last["_value"])
                                : widget.chartData.startValue;

                            var calcValue =
                                (value - widget.chartData.startValue) /
                                    (widget.chartData.endValue -
                                        widget.chartData.startValue);

                            calcValue = calcValue > 1 ? 1 : calcValue;
                            calcValue = calcValue < 0 ? 0 : calcValue;

                            final label = widget.chartData.data.isNotEmpty
                                ? value.toStringAsFixed(
                                    widget.chartData.decimalPlaces!)
                                : "no data";
                            return CustomPaint(
                                painter: GaugeChartPainter(
                                  calcValue: calcValue,
                                  radius: widget.chartData.size / 2,
                                ),
                                child: Padding(
                                  padding: EdgeInsets.only(
                                      top: widget.chartData.size / 3 + 10),
                                  child: Column(
                                    children: [
                                      Text(
                                        label,
                                        style: TextStyle(
                                          fontSize: widget.chartData.size / 9,
                                          fontWeight: FontWeight.w700,
                                        ),
                                      ),
                                      Text(
                                        widget.chartData.unit,
                                        style: TextStyle(
                                          fontSize:
                                              (widget.chartData.size / 8) - 5,
                                          fontWeight: FontWeight.w800,
                                        ),
                                      ),
                                    ],
                                  ),
                                ));
                          } else {
                            return CustomPaint(
                                painter: GaugeChartPainter(
                                  calcValue: 0,
                                  radius: widget.chartData.size / 2,
                                ),
                                child: Padding(
                                  padding: EdgeInsets.only(
                                      top: widget.chartData.size / 3 + 10),
                                  child: Column(
                                    children: const [
                                      SizedBox(
                                        width: 20,
                                        height: 20,
                                        child: CircularProgressIndicator(
                                          color: pink,
                                          strokeWidth: 3,
                                        ),
                                      ),
                                    ],
                                  ),
                                ));
                          }
                        })
                    //
                    ),
              ),
            )
          ],
        ),
        SizedBox(
          width: widget.chartData.size,
          child: Row(
            children: [
              Expanded(
                child: Center(
                  child: Text(
                    widget.chartData.startValue.toStringAsFixed(0),
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
                    widget.chartData.endValue.toStringAsFixed(0),
                    style: const TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              )
            ],
          ),
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
        colors: const [
          pink,
          purple,
        ],
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
