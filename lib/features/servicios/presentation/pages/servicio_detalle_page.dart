import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:web_admin_tecnico/core/utils/open_external_url.dart';
import 'package:web_admin_tecnico/core/widgets/module_page_layout.dart';
import 'package:web_admin_tecnico/features/servicios/data/servicios_repository_impl.dart';
import 'package:web_admin_tecnico/features/servicios/domain/servicios_repository.dart';

class ServicioDetallePage extends StatefulWidget {
  const ServicioDetallePage({
    super.key,
    required this.servicioId,
  });

  final String servicioId;

  @override
  State<ServicioDetallePage> createState() => _ServicioDetallePageState();
}

class _ServicioDetallePageState extends State<ServicioDetallePage> {
  final ServiciosRepository _repository = ServiciosRepositoryImpl();

  ServicioDetalle? _detalle;
  ServicioDocumentoInfo? _documento;
  String? _error;
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() {
      _loading = true;
      _error = null;
    });

    try {
      final detalle = await _repository.fetchServicioDetalle(widget.servicioId);
      final documento = await _repository.fetchDocumento(widget.servicioId);

      if (!mounted) {
        return;
      }

      setState(() {
        _detalle = detalle;
        _documento = documento;
        _loading = false;
      });
    } catch (error) {
      if (!mounted) {
        return;
      }
      setState(() {
        _error = error.toString();
        _loading = false;
      });
    }
  }

  Future<void> _openPdfUrl() async {
    final url = _documento?.pdfUrl;
    if (url == null || url.trim().isEmpty) {
      return;
    }

    try {
      await openExternalUrl(url);
    } catch (error) {
      if (!mounted) {
        return;
      }
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('No se pudo abrir la URL del PDF: $error')),
      );
    }
  }

  Future<void> _copyPdfUrl() async {
    final url = _documento?.pdfUrl;
    if (url == null || url.trim().isEmpty) {
      return;
    }
    await Clipboard.setData(ClipboardData(text: url));
    if (!mounted) {
      return;
    }
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('URL de PDF copiada al portapapeles.')),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }

    if (_error != null) {
      return Scaffold(
        appBar: AppBar(title: const Text('Detalle de servicio')),
        body: Center(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: <Widget>[
                Text(
                  'Error cargando detalle: $_error',
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 12),
                FilledButton.icon(
                  onPressed: _load,
                  icon: const Icon(Icons.refresh),
                  label: const Text('Reintentar'),
                ),
              ],
            ),
          ),
        ),
      );
    }

    final detalle = _detalle;
    final documento = _documento;

    return Scaffold(
      appBar: AppBar(
        title: Text('Servicio ${detalle?.id ?? widget.servicioId}'),
        actions: <Widget>[
          IconButton(
            tooltip: 'Refrescar',
            onPressed: _load,
            icon: const Icon(Icons.refresh),
          ),
          const SizedBox(width: 8),
        ],
      ),
      body: ModulePageLayout(
        title: 'Detalle de servicio',
        subtitle: 'Informacion operativa y estado del documento.',
        trailing: ModuleStatusChip(label: (detalle?.estadoOrden ?? 'sin_estado').toUpperCase()),
        child: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              Wrap(
                spacing: 10,
                runSpacing: 10,
                children: <Widget>[
                  _InfoTile(label: 'ID', value: detalle?.id ?? '-'),
                  _InfoTile(label: 'Canal', value: (detalle?.canal ?? '-').toUpperCase()),
                  _InfoTile(label: 'Cliente', value: detalle?.clienteNombre ?? '-'),
                  _InfoTile(label: 'Fecha', value: detalle?.fechaHoraServicio ?? '-'),
                ],
              ),
              const SizedBox(height: 14),
              _InfoTile(label: 'Lugar', value: detalle?.lugar ?? '-'),
              const SizedBox(height: 10),
              _InfoTile(label: 'Equipo serie', value: detalle?.equipoSerie ?? '-'),
              const SizedBox(height: 10),
              _InfoTile(label: 'Sintoma', value: detalle?.sintoma ?? '-'),
              const SizedBox(height: 10),
              _InfoTile(label: 'Diagnostico', value: detalle?.diagnosticoDetalle ?? '-'),
              const SizedBox(height: 10),
              _InfoTile(label: 'Observaciones', value: detalle?.observaciones ?? '-'),
              const SizedBox(height: 18),
              const Divider(color: Color(0x334EA6FF)),
              const SizedBox(height: 14),
              Text(
                'Documento',
                style: Theme.of(context).textTheme.titleLarge?.copyWith(
                      color: const Color(0xFFEAF3FF),
                      fontWeight: FontWeight.w600,
                    ),
              ),
              const SizedBox(height: 10),
              _InfoTile(label: 'Hash SHA256', value: documento?.pdfHashSha256 ?? '-'),
              const SizedBox(height: 10),
              _InfoTile(label: 'Firma cliente', value: documento?.firmaClienteNombre ?? '-'),
              const SizedBox(height: 10),
              _InfoTile(label: 'Documento firma', value: documento?.firmaClienteDocumento ?? '-'),
              const SizedBox(height: 10),
              _InfoTile(label: 'Fecha firma', value: documento?.firmaFechaHora ?? '-'),
              const SizedBox(height: 10),
              _InfoTile(label: 'URL PDF', value: documento?.pdfUrl ?? '-'),
              const SizedBox(height: 14),
              Row(
                children: <Widget>[
                  FilledButton.icon(
                    onPressed: (documento?.pdfUrl ?? '').isEmpty ? null : _openPdfUrl,
                    icon: const Icon(Icons.open_in_new),
                    label: const Text('Abrir PDF'),
                  ),
                  const SizedBox(width: 10),
                  OutlinedButton.icon(
                    onPressed: (documento?.pdfUrl ?? '').isEmpty ? null : _copyPdfUrl,
                    icon: const Icon(Icons.copy_all_outlined),
                    label: const Text('Copiar URL'),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _InfoTile extends StatelessWidget {
  const _InfoTile({
    required this.label,
    required this.value,
  });

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: const Color(0x1F122B4A),
        border: Border.all(color: const Color(0x334EA6FF)),
        borderRadius: BorderRadius.circular(10),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Text(
            label,
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: const Color(0xFF9AB1CC),
                  fontWeight: FontWeight.w600,
                ),
          ),
          const SizedBox(height: 4),
          Text(
            value,
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: const Color(0xFFEAF3FF),
                ),
          ),
        ],
      ),
    );
  }
}
