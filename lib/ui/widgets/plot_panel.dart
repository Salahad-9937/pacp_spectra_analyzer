import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../theme.dart';
import 'panel_card.dart';
import 'spectrum_chart.dart';

class PlotPanel extends StatefulWidget {
  const PlotPanel({super.key, required this.curves});

  final List<PlotCurve> curves;

  @override
  State<PlotPanel> createState() => _PlotPanelState();
}

class _PlotPanelState extends State<PlotPanel> {
  /// Фиксированный шаг кнопок диапазона. Кратен 2.
  static const int _step = 64;
  static const int _defaultMax = 2048;

  int _viewMin = 0;
  int _viewMax = _defaultMax;

  /// Пока пользователь не трогал диапазон — держим "весь диапазон".
  bool _auto = true;

  late final TextEditingController _minController =
      TextEditingController(text: '$_viewMin');

  late final TextEditingController _maxController =
      TextEditingController(text: '$_viewMax');

  @override
  void dispose() {
    _minController.dispose();
    _maxController.dispose();
    super.dispose();
  }

  int get _dataMax {
    var max = 0;

    for (final curve in widget.curves) {
      if (curve.data.channels.isEmpty) {
        continue;
      }

      final last = curve.data.channels.last.round();

      if (last > max) {
        max = last;
      }
    }

    return max <= 0 ? _defaultMax : max;
  }

  @override
  void didUpdateWidget(covariant PlotPanel oldWidget) {
    super.didUpdateWidget(oldWidget);

    if (_auto) {
      _setRange(0, _dataMax);
    } else {
      final dataMax = _dataMax;

      if (_viewMax > dataMax) {
        _setRange(_viewMin, dataMax);
      }
    }
  }

  void _setRange(int lo, int hi) {
    final dataMax = _dataMax;

    var newLo = lo.clamp(0, dataMax).toInt();
    var newHi = hi.clamp(0, dataMax).toInt();

    if (newHi - newLo < _step) {
      if (newHi == dataMax) {
        newLo = newHi - _step;
      } else {
        newHi = newLo + _step;

        if (newHi > dataMax) {
          newHi = dataMax;
          newLo = newHi - _step;
        }
      }
    }

    setState(() {
      _viewMin = newLo;
      _viewMax = newHi;
      _minController.text = '$newLo';
      _maxController.text = '$newHi';
    });
  }

  /// Привязка к фиксированной сетке значений, кратных шагу,
  /// независимо от того, что введено в поле.
  int _snapUp(int value) => (value ~/ _step + 1) * _step;

  int _snapDown(int value) =>
      value % _step == 0 ? value - _step : (value ~/ _step) * _step;

  void _moveMinLeft() {
    _auto = false;
    _setRange(_snapDown(_viewMin), _viewMax);
  }

  void _moveMinRight() {
    _auto = false;
    _setRange(_snapUp(_viewMin), _viewMax);
  }

  void _moveMaxLeft() {
    _auto = false;
    _setRange(_viewMin, _snapDown(_viewMax));
  }

  void _moveMaxRight() {
    _auto = false;
    _setRange(_viewMin, _snapUp(_viewMax));
  }

  void _submitMin(String text) {
    _auto = false;

    final value = int.tryParse(text.trim());

    if (value == null) {
      _minController.text = '$_viewMin';
      return;
    }

    _setRange(value, _viewMax);
  }

  void _submitMax(String text) {
    _auto = false;

    final value = int.tryParse(text.trim());

    if (value == null) {
      _maxController.text = '$_viewMax';
      return;
    }

    _setRange(_viewMin, value);
  }

  void _resetRange() {
    _auto = true;
    _setRange(0, _dataMax);
  }

  @override
  Widget build(BuildContext context) {
    return PanelCard(
      title: 'График',
      child: widget.curves.isEmpty
          ? const Center(
              child: Padding(
                padding: EdgeInsets.all(24),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      Icons.show_chart,
                      size: 42,
                      color: AppTheme.textSecondary,
                    ),
                    SizedBox(height: 8),
                    Text(
                      'Выберите директорию и отметьте файлы чекбоксами, '
                      'чтобы отобразить спектры.',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontSize: 13,
                        color: AppTheme.textSecondary,
                      ),
                    ),
                  ],
                ),
              ),
            )
          : Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Padding(
                  padding: const EdgeInsets.fromLTRB(12, 10, 12, 4),
                  child: Wrap(
                    spacing: 6,
                    runSpacing: 6,
                    children: [
                      for (var i = 0; i < widget.curves.length; i++)
                        _legendChip(i),
                    ],
                  ),
                ),
                Expanded(
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(4, 0, 12, 8),
                    child: SpectrumChart(
                      curves: widget.curves,
                      viewMin: _viewMin,
                      viewMax: _viewMax,
                    ),
                  ),
                ),
                Container(height: 1, color: AppTheme.border),
                _buildRangeBar(),
              ],
            ),
    );
  }

  Widget _buildRangeBar() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      child: Row(
        children: [
          const Text(
            'Диапазон каналов:',
            style: TextStyle(fontSize: 12, color: AppTheme.textSecondary),
          ),
          const SizedBox(width: 10),
          _arrowButton(Icons.chevron_left, _moveMinLeft),
          const SizedBox(width: 4),
          _field(_minController, _submitMin),
          const SizedBox(width: 4),
          _arrowButton(Icons.chevron_right, _moveMinRight),
          const Padding(
            padding: EdgeInsets.symmetric(horizontal: 8),
            child: Text(
              '—',
              style: TextStyle(color: AppTheme.textSecondary),
            ),
          ),
          _arrowButton(Icons.chevron_left, _moveMaxLeft),
          const SizedBox(width: 4),
          _field(_maxController, _submitMax),
          const SizedBox(width: 4),
          _arrowButton(Icons.chevron_right, _moveMaxRight),
          const SizedBox(width: 12),
          const Text(
            'шаг: $_step',
            style: TextStyle(fontSize: 11, color: AppTheme.textSecondary),
          ),
          const Spacer(),
          IconButton(
            tooltip: 'Показать весь диапазон',
            onPressed: _resetRange,
            icon: const Icon(Icons.fit_screen, size: 16),
            visualDensity: VisualDensity.compact,
            constraints: const BoxConstraints(
              minWidth: 32,
              minHeight: 32,
            ),
          ),
        ],
      ),
    );
  }

  Widget _arrowButton(IconData icon, VoidCallback onPressed) {
    return IconButton(
      onPressed: onPressed,
      icon: Icon(icon, size: 18),
      padding: EdgeInsets.zero,
      constraints: const BoxConstraints(minWidth: 28, minHeight: 28),
      visualDensity: VisualDensity.compact,
      style: IconButton.styleFrom(
        backgroundColor: const Color(0xFFF4F7FA),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(6),
        ),
        side: const BorderSide(color: AppTheme.border),
      ),
    );
  }

  Widget _field(
    TextEditingController controller,
    ValueChanged<String> onSubmitted,
  ) {
    return SizedBox(
      width: 64,
      child: TextField(
        controller: controller,
        onSubmitted: onSubmitted,
        textAlign: TextAlign.center,
        style: const TextStyle(fontSize: 12.5),
        keyboardType: TextInputType.number,
        inputFormatters: [FilteringTextInputFormatter.digitsOnly],
        decoration: InputDecoration(
          isDense: true,
          filled: true,
          fillColor: Colors.white,
          contentPadding: const EdgeInsets.symmetric(
            vertical: 6,
            horizontal: 4,
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(6),
            borderSide: const BorderSide(color: AppTheme.border),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(6),
            borderSide: const BorderSide(color: AppTheme.primary),
          ),
        ),
      ),
    );
  }

  Widget _legendChip(int index) {
    final curve = widget.curves[index];

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 5),
      decoration: BoxDecoration(
        color: const Color(0xFFF4F7FA),
        borderRadius: BorderRadius.circular(6),
        border: Border.all(color: AppTheme.border),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(width: 10, height: 10, color: chartColor(index)),
          const SizedBox(width: 6),
          ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 300),
            child: Text(
              curve.meta.shortLabel,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(
                fontSize: 12,
                color: AppTheme.textPrimary,
              ),
            ),
          ),
        ],
      ),
    );
  }
}