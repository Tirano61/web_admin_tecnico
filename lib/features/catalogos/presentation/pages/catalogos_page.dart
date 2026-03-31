import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:web_admin_tecnico/features/catalogos/data/catalogos_repository_impl.dart';
import 'package:web_admin_tecnico/features/catalogos/presentation/bloc/catalogos_bloc.dart';

class CatalogosPage extends StatelessWidget {
  const CatalogosPage({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocProvider<CatalogosBloc>(
      create: (_) => CatalogosBloc(CatalogosRepositoryImpl())..add(CatalogosRequested()),
      child: const _CatalogosView(),
    );
  }
}

class _CatalogosView extends StatelessWidget {
  const _CatalogosView();

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(24),
      child: BlocBuilder<CatalogosBloc, CatalogosState>(
        builder: (context, state) {
          if (state is CatalogosLoading) {
            return const Center(child: CircularProgressIndicator());
          }

          if (state is CatalogosFailure) {
            return Center(child: Text('Error: ${state.message}'));
          }

          if (state is CatalogosLoaded) {
            return Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                Text('Catalogos', style: Theme.of(context).textTheme.headlineSmall),
                const SizedBox(height: 16),
                Expanded(
                  child: ListView.builder(
                    itemCount: state.items.length,
                    itemBuilder: (context, index) {
                      final item = state.items[index];
                      return Card(
                        child: ListTile(
                          title: Text(item.nombre),
                          subtitle: Text('Tipo: ${item.tipo} - ID: ${item.id}'),
                        ),
                      );
                    },
                  ),
                ),
              ],
            );
          }

          return const SizedBox.shrink();
        },
      ),
    );
  }
}
