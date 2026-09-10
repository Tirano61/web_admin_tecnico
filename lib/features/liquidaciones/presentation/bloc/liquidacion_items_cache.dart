import 'package:web_admin_tecnico/features/liquidaciones/domain/liquidaciones_repository.dart';

/// Estado de carga del desglose de items de una liquidacion.
///
/// `unavailable` es distinto de `loaded` con lista vacia: significa que el
/// endpoint no respondio el detalle (flag apagado o 404), asi que reintentar
/// tiene sentido. Confundir ambos casos dejaba la UI colgada sin reintento.
enum LiquidacionItemsLoadStatus { idle, loading, loaded, unavailable, error }

class LiquidacionItemsEntry {
  const LiquidacionItemsEntry({
    required this.status,
    this.response,
    this.error,
  });

  const LiquidacionItemsEntry.loading()
      : this(status: LiquidacionItemsLoadStatus.loading);

  const LiquidacionItemsEntry.unavailable()
      : this(status: LiquidacionItemsLoadStatus.unavailable);

  const LiquidacionItemsEntry.loaded(LiquidacionItemsResponse response)
      : this(status: LiquidacionItemsLoadStatus.loaded, response: response);

  const LiquidacionItemsEntry.failed(String message)
      : this(status: LiquidacionItemsLoadStatus.error, error: message);

  final LiquidacionItemsLoadStatus status;
  final LiquidacionItemsResponse? response;
  final String? error;

  bool get isLoading => status == LiquidacionItemsLoadStatus.loading;

  bool get isLoaded => status == LiquidacionItemsLoadStatus.loaded;

  bool get canRetry =>
      status == LiquidacionItemsLoadStatus.idle ||
      status == LiquidacionItemsLoadStatus.unavailable ||
      status == LiquidacionItemsLoadStatus.error;
}
