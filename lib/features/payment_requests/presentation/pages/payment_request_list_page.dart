import 'package:boklo/core/base/base_state.dart';
import 'package:boklo/core/di/di_initializer.dart';
import 'package:boklo/core/services/navigation_service.dart';
import 'package:boklo/features/payment_requests/domain/entity/payment_request_entity.dart';
import 'package:boklo/features/payment_requests/presentation/bloc/payment_request_cubit.dart';
import 'package:boklo/features/payment_requests/presentation/bloc/payment_request_state.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:boklo/config/theme/app_colors.dart';
import 'package:boklo/config/theme/app_dimens.dart';

class PaymentRequestListPage extends StatelessWidget {
  const PaymentRequestListPage({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (context) {
        final cubit = getIt<PaymentRequestCubit>();
        cubit.init();
        return cubit;
      },
      child: DefaultTabController(
        length: 2,
        child: Scaffold(
          appBar: AppBar(
            title: const Text('Payment Requests'),
            bottom: const TabBar(
              tabs: [
                Tab(text: 'Incoming'),
                Tab(text: 'Outgoing'),
              ],
            ),
            actions: [
              IconButton(
                icon: const Icon(Icons.add),
                onPressed: () {
                  getIt<NavigationService>().push('/payment-requests/create');
                },
              )
            ],
          ),
          body:
              BlocBuilder<PaymentRequestCubit, BaseState<PaymentRequestState>>(
            builder: (context, state) {
              final data = state.data ?? const PaymentRequestState();
              // Error handling? state.when/whenOrNull/etc.
              // For brevity in MVP:

              return TabBarView(
                children: [
                  _buildIncomingList(
                    context,
                    data.incomingRequests,
                    data.actingOnRequestId,
                  ),
                  _buildOutgoingList(context, data.outgoingRequests),
                ],
              );
            },
          ),
        ),
      ),
    );
  }

  Widget _buildIncomingList(
    BuildContext context,
    List<PaymentRequestEntity> requests,
    String? actingOnRequestId,
  ) {
    if (requests.isEmpty) {
      return const Center(child: Text('No incoming requests'));
    }

    return ListView.builder(
      itemCount: requests.length,
      itemBuilder: (context, index) {
        final req = requests[index];
        final isLoading = actingOnRequestId == req.id;

        return Card(
          margin: const EdgeInsets.symmetric(
            horizontal: AppDimens.md,
            vertical: AppDimens.xs,
          ),
          child: ListTile(
            title: Text('${req.amount} ${req.currency}'),
            subtitle: Text('From: ${req.requesterId}\nNote: ${req.note ?? ""}'),
            trailing: req.status == PaymentRequestStatus.pending
                ? isLoading
                    ? const SizedBox(
                        width: 24,
                        height: 24,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          IconButton(
                            icon: const Icon(Icons.check,
                                color: AppColors.success),
                            onPressed: () {
                              context
                                  .read<PaymentRequestCubit>()
                                  .acceptRequest(req.id);
                            },
                          ),
                          IconButton(
                            icon:
                                const Icon(Icons.close, color: AppColors.error),
                            onPressed: () {
                              context
                                  .read<PaymentRequestCubit>()
                                  .declineRequest(req.id);
                            },
                          ),
                        ],
                      )
                : Text(
                    req.status.label,
                    style: const TextStyle(fontWeight: FontWeight.bold),
                  ),
          ),
        );
      },
    );
  }

  Widget _buildOutgoingList(
      BuildContext context, List<PaymentRequestEntity> requests) {
    if (requests.isEmpty)
      return const Center(child: Text('No outgoing requests'));

    return ListView.builder(
      itemCount: requests.length,
      itemBuilder: (context, index) {
        final req = requests[index];
        return Card(
          margin: const EdgeInsets.symmetric(
              horizontal: AppDimens.md, vertical: AppDimens.xs),
          child: ListTile(
            title: Text('${req.amount} ${req.currency}'),
            subtitle: Text('To: ${req.payerId}\nNote: ${req.note ?? ""}'),
            trailing: Text(req.status.label,
                style: TextStyle(
                    color: _getStatusColor(req.status),
                    fontWeight: FontWeight.bold)),
          ),
        );
      },
    );
  }

  Color _getStatusColor(PaymentRequestStatus status) {
    switch (status) {
      case PaymentRequestStatus.pending:
        return AppColors.warning;
      case PaymentRequestStatus.accepted:
        return AppColors.success;
      case PaymentRequestStatus.declined:
        return AppColors.error;
      case PaymentRequestStatus.invalid:
        return AppColors.textSecondaryLight;
    }
  }
}
