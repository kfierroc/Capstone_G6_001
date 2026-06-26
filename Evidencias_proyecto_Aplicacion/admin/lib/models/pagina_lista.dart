/// Resultado de una página de listado admin.
class PaginaLista<T> {
  const PaginaLista({
    required this.items,
    required this.hayMas,
  });

  final List<T> items;
  final bool hayMas;
}

const kTamanoPaginaLista = 20;
