import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:web_admin_tecnico/features/servicios/data/servicios_repository_impl.dart';
import 'package:web_admin_tecnico/features/servicios/presentation/bloc/servicios_bloc.dart';

class ServiciosPage extends StatelessWidget {
  const ServiciosPage({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocProvider<ServiciosBloc>(
      create: (_) => ServiciosBloc(ServiciosRepositoryImpl())..add(ServiciosRequested()),
      child: const _ServiciosView(),
    );
  }
}

class _ServiciosView extends StatelessWidget {
  const _ServiciosView();

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(24),
      child: BlocBuilder<ServiciosBloc, ServiciosState>(
        builder: (context, state) {
          if (state is ServiciosLoading) {
            return const Center(child: CircularProgressIndicator());
          }

          if (state is ServiciosFailure) {
            return Center(child: Text('Error: ${state.message}'));
          }

          if (state is ServiciosLoaded) {
            return Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                Text('Servicios', style: Theme.of(context).textTheme.headlineSmall),
                const SizedBox(height: 16),
                Expanded(
                  child: ListView.builder(
                    itemCount: state.items.length,
                    itemBuilder: (context, index) {
                      final item = state.items[index];
                      return Card(
                        child: ListTile(
                          title: Text(item.descripcion),
                          subtitle: Text('ID: ${item.id} - Estado: ${item.estadoOrden}'),
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
