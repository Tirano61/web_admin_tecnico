import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:web_admin_tecnico/core/api/paged_result.dart';
import 'package:web_admin_tecnico/core/error/app_failure.dart';
import 'package:web_admin_tecnico/features/liquidaciones/domain/liquidaciones_repository.dart';

class LiquidacionesPagosState {
  const LiquidacionesPagosState({
    this.loadingPreview = false,
    this.loadingHistory = false,
    this.loadingDetail = false,
    this.confirming = false,
    this.tecnicoId,
    this.desde,
    this.hasta,
    this.preview,
    this.selectedLiquidacionIds = const <String>{},
    this.history,
    this.historyPage = 1,
    this.historyLimit = 20,
    this.historyDetail,
    this.ultimoResumen,
    this.message,
    this.error,
  });

  final bool loadingPreview;
  final bool loadingHistory;
  final bool loadingDetail;
  final bool confirming;
  final String? tecnicoId;
  final String? desde;
  final String? hasta;
  final ResumenPagoPreviewResponse? preview;
  final Set<String> selectedLiquidacionIds;
  final PagedResult<ResumenPagoHistorialItem>? history;
  final int historyPage;
  final int historyLimit;
  final ResumenPagoDetalleResponse? historyDetail;
  final UltimoResumenPagoItem? ultimoResumen;
  final String? message;
  final String? error;

  double get totalSeleccionadoUsd {
    final rows = preview?.items ?? const <ResumenPagoPreviewItem>[];
    return rows
        .where((row) => selectedLiquidacionIds.contains(row.id))
        .fold<double>(0, (sum, row) => sum + row.totalLiquidacionUsd);
  }

  List<TecnicoPagoOption> get tecnicoOptions {
    final items = history?.items ?? const <ResumenPagoHistorialItem>[];
    final byId = <String, TecnicoPagoOption>{};

    for (final item in items) {
      final id = item.tecnicoId.trim();
      if (id.isEmpty) {
        continue;
      }
      byId[id] = TecnicoPagoOption(
        id: id,
        nombre: item.tecnicoNombre.trim().isEmpty ? null : item.tecnicoNombre,
      );
    }

    final output = byId.values.toList();
    output.sort((a, b) => a.label.toLowerCase().compareTo(b.label.toLowerCase()));
    return output;
  }

  LiquidacionesPagosState copyWith({
    bool? loadingPreview,
    bool? loadingHistory,
    bool? loadingDetail,
    bool? confirming,
    String? tecnicoId,
    String? desde,
    String? hasta,
    Object? preview = _noChange,
    Set<String>? selectedLiquidacionIds,
    Object? history = _noChange,
    int? historyPage,
    int? historyLimit,
    Object? historyDetail = _noChange,
    Object? ultimoResumen = _noChange,
    Object? message = _noChange,
    Object? error = _noChange,
  }) {
    return LiquidacionesPagosState(
      loadingPreview: loadingPreview ?? this.loadingPreview,
      loadingHistory: loadingHistory ?? this.loadingHistory,
      loadingDetail: loadingDetail ?? this.loadingDetail,
      confirming: confirming ?? this.confirming,
      tecnicoId: tecnicoId ?? this.tecnicoId,
      desde: desde ?? this.desde,
      hasta: hasta ?? this.hasta,
      preview: identical(preview, _noChange)
          ? this.preview
          : preview as ResumenPagoPreviewResponse?,
      selectedLiquidacionIds:
          selectedLiquidacionIds ?? this.selectedLiquidacionIds,
      history: identical(history, _noChange)
          ? this.history
          : history as PagedResult<ResumenPagoHistorialItem>?,
      historyPage: historyPage ?? this.historyPage,
      historyLimit: historyLimit ?? this.historyLimit,
      historyDetail: identical(historyDetail, _noChange)
          ? this.historyDetail
          : historyDetail as ResumenPagoDetalleResponse?,
      ultimoResumen: identical(ultimoResumen, _noChange)
          ? this.ultimoResumen
          : ultimoResumen as UltimoResumenPagoItem?,
      message: identical(message, _noChange) ? this.message : message as String?,
      error: identical(error, _noChange) ? this.error : error as String?,
    );
  }
}

class TecnicoPagoOption {
  const TecnicoPagoOption({
    required this.id,
    this.nombre,
  });

  final String id;
  final String? nombre;

  String get label {
    final cleanName = (nombre ?? '').trim();
    if (cleanName.isEmpty) {
      return 'ID $id';
    }
    return '$cleanName <$id>';
  }
}

const Object _noChange = Object();

class LiquidacionesPagosCubit extends Cubit<LiquidacionesPagosState> {
  LiquidacionesPagosCubit(this._repository)
      : super(const LiquidacionesPagosState());

  final LiquidacionesRepository _repository;

  void updateFilters({
    required String tecnicoId,
    required String desde,
    required String hasta,
  }) {
    emit(
      state.copyWith(
        tecnicoId: tecnicoId.trim(),
        desde: desde.trim(),
        hasta: hasta.trim(),
        message: null,
        error: null,
      ),
    );
  }

  Future<void> loadUltimoResumen(String tecnicoId) async {
    final value = tecnicoId.trim();
    if (value.isEmpty) {
      emit(state.copyWith(ultimoResumen: null));
      return;
    }

    try {
      final ultimo = await _repository.fetchUltimoResumenPago(value);
      emit(state.copyWith(ultimoResumen: ultimo));
    } catch (_) {
      emit(state.copyWith(ultimoResumen: null));
    }
  }

  Future<void> previewResumen() async {
    final tecnicoId = (state.tecnicoId ?? '').trim();
    final desde = (state.desde ?? '').trim();
    final hasta = (state.hasta ?? '').trim();
    if (tecnicoId.isEmpty || desde.isEmpty || hasta.isEmpty) {
      emit(
        state.copyWith(
          error: 'Selecciona tecnico, desde y hasta para previsualizar.',
        ),
      );
      return;
    }

    emit(state.copyWith(loadingPreview: true, error: null, message: null));

    try {
      final preview = await _repository.fetchResumenPagoPreview(
        query: ResumenPagoPreviewQuery(
          tecnicoId: tecnicoId,
          desde: desde,
          hasta: hasta,
        ),
      );
      emit(
        state.copyWith(
          loadingPreview: false,
          preview: preview,
          selectedLiquidacionIds: const <String>{},
        ),
      );
    } catch (error) {
      emit(
        state.copyWith(
          loadingPreview: false,
          error: _errorMessage(error),
        ),
      );
    }
  }

  void toggleSelected(String liquidacionId, bool selected) {
    final next = <String>{...state.selectedLiquidacionIds};
    if (selected) {
      next.add(liquidacionId);
    } else {
      next.remove(liquidacionId);
    }
    emit(state.copyWith(selectedLiquidacionIds: next, message: null, error: null));
  }

  Future<String?> confirmarResumen() async {
    final tecnicoId = (state.tecnicoId ?? '').trim();
    final desde = (state.desde ?? '').trim();
    final hasta = (state.hasta ?? '').trim();
    final selectedIds = state.selectedLiquidacionIds.toList(growable: false);

    if (tecnicoId.isEmpty || desde.isEmpty || hasta.isEmpty) {
      emit(
        state.copyWith(
          error: 'Completa tecnico y periodo antes de confirmar.',
        ),
      );
      return null;
    }

    if (selectedIds.isEmpty) {
      emit(
        state.copyWith(
          error: 'Selecciona al menos una liquidacion para confirmar.',
        ),
      );
      return null;
    }

    emit(state.copyWith(confirming: true, message: null, error: null));

    try {
      final result = await _repository.confirmarResumenPago(
        input: ConfirmarResumenPagoInput(
          tecnicoId: tecnicoId,
          desde: desde,
          hasta: hasta,
          liquidacionIds: selectedIds,
        ),
      );

      final confirmation = result.confirmacion;
      final updated = confirmation?.updated ?? 0;
      final fecha = confirmation?.fechaLiquidadaPago;

      emit(
        state.copyWith(
          confirming: false,
          selectedLiquidacionIds: const <String>{},
          preview: result,
          message: fecha == null
              ? 'Resumen confirmado. Liquidaciones marcadas: $updated.'
              : 'Resumen confirmado. Updated: $updated. Fecha: $fecha',
        ),
      );

      await previewResumen();
      await loadHistory(page: state.historyPage, limit: state.historyLimit);

      return confirmation?.resumenPagoId;
    } catch (error) {
      final text = _errorMessage(error);
      if (_isEligibilityError(text)) {
        await previewResumen();
        emit(
          state.copyWith(
            confirming: false,
            error: 'Algunas liquidaciones ya no son elegibles; actualizamos la lista.',
          ),
        );
        return null;
      }

      emit(
        state.copyWith(
          confirming: false,
          error: text,
        ),
      );
      return null;
    }
  }

  Future<void> loadHistory({int page = 1, int limit = 20}) async {
    emit(
      state.copyWith(
        loadingHistory: true,
        historyPage: page,
        historyLimit: limit,
        error: null,
      ),
    );

    try {
      final result = await _repository.fetchResumenesPago(
        query: ResumenesPagoQuery(
          tecnicoId: state.tecnicoId,
          desde: state.desde,
          hasta: state.hasta,
          page: page,
          limit: limit,
        ),
      );
      emit(
        state.copyWith(
          loadingHistory: false,
          history: result,
        ),
      );
    } catch (error) {
      emit(
        state.copyWith(
          loadingHistory: false,
          error: _errorMessage(error),
        ),
      );
    }
  }

  Future<void> loadHistoryDetail(String resumenId) async {
    emit(state.copyWith(loadingDetail: true, error: null));

    try {
      final detail = await _repository.fetchResumenPagoDetalle(resumenId);
      emit(
        state.copyWith(
          loadingDetail: false,
          historyDetail: detail,
        ),
      );
    } catch (error) {
      emit(
        state.copyWith(
          loadingDetail: false,
          error: _errorMessage(error),
        ),
      );
    }
  }

  bool _isEligibilityError(String message) {
    final normalized = message.toLowerCase();
    return normalized.contains('elegible') ||
        normalized.contains('eligib') ||
        normalized.contains('revalida');
  }

  String _errorMessage(Object error) {
    if (error is AppFailure) {
      return error.message;
    }

    final text = error.toString().trim();
    if (text.startsWith('Exception: ')) {
      return text.replaceFirst('Exception: ', '').trim();
    }
    return text;
  }
}
