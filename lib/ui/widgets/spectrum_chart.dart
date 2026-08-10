import 'dart:math' as math;

import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';

import '../../domain/models.dart';
import '../theme.dart';

class PlotCurve {
  const PlotCurve(this.meta, this.data);

  final SpectrumMeta meta;
  final SpectrumData data;
}

Color chartColor(int index) {
  const colors = [
    Color(0xFF1F77B4),
    Color(0xFFD62728),
    Color(0xFF2CA02C),
    Color(0xFFFF7F0E),
    Color(0xFF9467BD),
    Color(0xFF17BECF),
    Color(0xFF8C564B),
    Color(0xFFE377C2),
    Color(0xFF7F7F7F),
    Color(0xFFBCBD22),
  ];

  return colors[index % colors.length];
}

class SpectrumChart extends StatelessWidget {
  const SpectrumChart({
    super.key,
    required this.curves,
    required this.viewMin,
    required this.viewMax,
  });

  final List<PlotCurve> curves;
  final int viewMin;
  final int viewMax;

  static const Color _tickColor = Color(0xFF8A97A5);

  static const TextStyle _axisTitleStyle = TextStyle(
    fontSize: 12,
    fontWeight: FontWeight.w600,
    color: AppTheme.textSecondary,
  );

  static const TextStyle _axisLabelStyle = TextStyle(
    fontSize: 10.5,
    color: AppTheme.textSecondary,
  );

  @override
  Widget build(BuildContext context) {
    final lineBars = <LineChartBarData>[];

    var rawMinY = double.infinity;
    var rawMaxY = -double.infinity;

    for (var i = 0; i < curves.length; i++) {
      final spots = _buildSpots(curves[i].data);

      if (spots.isEmpty) {
        continue;
      }

      for (final spot in spots) {
        if (spot.y < rawMinY) {
          rawMinY = spot.y;
        }

        if (spot.y > rawMaxY) {
          rawMaxY = spot.y;
        }
      }

      lineBars.add(
        LineChartBarData(
          spots: spots,
          isCurved: false,
          barWidth: 1.2,
          color: chartColor(i),
          dotData: const FlDotData(show: false),
          belowBarData: BarAreaData(show: false),
        ),
      );
    }

    if (lineBars.isEmpty) {
      return const Center(
        child: Text('Нет данных в выбранном диапазоне каналов.'),
      );
    }

    // Ось X: границы выравниваются до кратных интервалу,
    // чтобы подписи и риски были на "ровных" каналах (кратных 2).
    final span = math.max(1, viewMax - viewMin);
    final xInterval = _pickXInterval(span);

    final minX = ((viewMin ~/ xInterval) * xInterval).toDouble();
    var maxX = (((viewMax + xInterval - 1) ~/ xInterval) * xInterval)
        .toDouble();

    if (maxX <= minX) {
      maxX = minX + xInterval;
    }

    // Ось Y: автоматический подбор "красивого" интервала
    // по видимому диапазону каналов.
    final yInterval = _niceInterval(rawMaxY - rawMinY);

    var minY = (rawMinY / yInterval).floor() * yInterval;
    var maxY = (rawMaxY / yInterval).ceil() * yInterval;

    if (maxY - minY < yInterval) {
      maxY = minY + yInterval;
    }

    return LineChart(
      LineChartData(
        minX: minX,
        maxX: maxX,
        minY: minY,
        maxY: maxY,
        lineBarsData: lineBars,
        gridData: FlGridData(
          show: true,
          drawVerticalLine: true,
          horizontalInterval: yInterval,
          verticalInterval: xInterval.toDouble(),
          getDrawingHorizontalLine: (value) =>
              const FlLine(color: Color(0xFFE4E9EF), strokeWidth: 1),
          getDrawingVerticalLine: (value) =>
              const FlLine(color: Color(0xFFEDF1F6), strokeWidth: 1),
        ),
        titlesData: FlTitlesData(
          show: true,
          leftTitles: AxisTitles(
            axisNameWidget: const Text('Импульсы', style: _axisTitleStyle),
            axisNameSize: 16,
            sideTitles: SideTitles(
              showTitles: true,
              reservedSize: 48,
              interval: yInterval,
              getTitlesWidget: (value, meta) =>
                  _leftTitle(value, yInterval),
            ),
          ),
          rightTitles: const AxisTitles(
            sideTitles: SideTitles(showTitles: false),
          ),
          topTitles: const AxisTitles(
            sideTitles: SideTitles(showTitles: false),
          ),
          bottomTitles: AxisTitles(
            axisNameWidget: const Text('Канал', style: _axisTitleStyle),
            axisNameSize: 22,
            sideTitles: SideTitles(
              showTitles: true,
              reservedSize: 30,
              interval: xInterval.toDouble(),
              getTitlesWidget: (value, meta) => _bottomTitle(value),
            ),
          ),
        ),
        borderData: FlBorderData(
          show: true,
          border: Border.all(color: const Color(0xFFC9D3DE)),
        ),
        lineTouchData: const LineTouchData(enabled: true),
      ),
    );
  }

  Widget _bottomTitle(double value) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(width: 1, height: 5, color: _tickColor),
        const SizedBox(height: 2),
        Text(
          '${value.round()}',
          style: _axisLabelStyle,
        ),
      ],
    );
  }

  Widget _leftTitle(double value, double interval) {
    final label = interval >= 1
        ? '${value.round()}'
        : value.toStringAsFixed(1);

    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(label, style: _axisLabelStyle),
        const SizedBox(width: 2),
        Container(width: 5, height: 1, color: _tickColor),
      ],
    );
  }

  /// Интервалы оси X — только степени/кратные 2,
  /// чтобы каналы на оси были "ровными".
  int _pickXInterval(int span) {
    const ladder = [1, 2, 4, 8, 16, 32, 64, 128, 256, 512, 1024, 2048, 4096];

    for (final step in ladder) {
      if (span / step <= 8) {
        return step;
      }
    }

    return 8192;
  }

  double _niceInterval(double range) {
    if (!range.isFinite || range <= 0) {
      return 1;
    }

    final raw = range / 6;
    final exponent = (math.log(raw) / math.ln10).floor();
    final base = math.pow(10, exponent).toDouble();

    for (final m in [1.0, 2.0, 5.0, 10.0]) {
      if (raw <= m * base * 1.0000001) {
        return m * base;
      }
    }

    return 10 * base;
  }

  List<FlSpot> _buildSpots(SpectrumData data) {
    const maxPoints = 3000;

    final lo = viewMin.toDouble();
    final hi = viewMax.toDouble();

    final visibleIndexes = <int>[];

    for (var i = 0; i < data.channelCount; i++) {
      final x = data.channels[i];

      if (x >= lo && x <= hi) {
        visibleIndexes.add(i);
      }
    }

    if (visibleIndexes.isEmpty) {
      return const [];
    }

    final step = visibleIndexes.length <= maxPoints
        ? 1
        : (visibleIndexes.length / maxPoints).ceil();

    final spots = <FlSpot>[];

    for (var k = 0; k < visibleIndexes.length; k += step) {
      final i = visibleIndexes[k];
      spots.add(FlSpot(data.channels[i], data.counts[i]));
    }

    if (step > 1) {
      final lastIndex = visibleIndexes.last;
      final lastX = data.channels[lastIndex];

      if (spots.isEmpty || spots.last.x != lastX) {
        spots.add(FlSpot(lastX, data.counts[lastIndex]));
      }
    }

    return spots;
  }
}