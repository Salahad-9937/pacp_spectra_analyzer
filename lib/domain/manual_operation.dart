enum ManualOperation {
  average('Среднее'),
  sum('Сумма'),
  subtractBackground('Вычитание фона');

  const ManualOperation(this.label);

  final String label;
}