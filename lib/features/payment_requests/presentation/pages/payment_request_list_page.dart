import 'package:boklo/core/base/base_state.dart';
import 'package:boklo/core/di/di_initializer.dart';
import 'package:boklo/core/services/navigation_service.dart';
import 'package:boklo/core/services/snackbar_service.dart';
import 'package:boklo/features/payment_requests/domain/entity/payment_request_entity.dart';
import 'package:boklo/features/payment_requests/presentation/bloc/payment_request_cubit.dart';
import 'package:boklo/features/payment_requests/presentation/bloc/payment_request_state.dart';
import 'package:boklo/features/payment_requests/presentation/widgets/payment_request_item.dart';
import 'package:boklo/shared/extensions/l10n.dart';
import 'package:boklo/shared/widgets/atoms/app_loading_indicator.dart';
import 'package:boklo/shared/widgets/molecules/app_empty_state.dart';
import 'package:boklo/shared/widgets/molecules/app_page_scaffold.dart';
import 'package:boklo/shared/widgets/molecules/wallet_error_view.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

class PaymentRequestListPage extends StatelessWidget {
  const PaymentRequestListPage({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) => getIt<PaymentRequestCubit>()..init(),
      child: DefaultTabController(
        length: 2,
        child: AppPageScaffold(
          title: context.l10n.paymentRequests,
          actions: [
            IconButton(
              tooltip: context.l10n.createPaymentRequest,
              icon: const Icon(Icons.add_rounded),
              onPressed: () =>
                  getIt<NavigationService>().push('/payment-requests/create'),
            ),
          ],
          bottom: TabBar(
            tabs: [
              Tab(text: context.l10n.incoming),
              Tab(text: context.l10n.outgoing),
            ],
          ),
          child:
              BlocConsumer<PaymentRequestCubit, BaseState<PaymentRequestState>>(
                listener: (context, state) {
                  state.whenOrNull(
                    error: (failure) =>
                        getIt<SnackbarService>().showError(failure.message),
                  );
                },
                builder: (context, state) {
                  if (state.isLoading) {
                    return const AppLoadingIndicator();
                  }
                  if (state.isError &&
                      state.data?.incomingRequests.isEmpty == true &&
                      state.data?.outgoingRequests.isEmpty == true) {
                    return WalletErrorView(
                      title: state.error?.message ?? 'Something went wrong',
                      onRetry: () => getIt<PaymentRequestCubit>().init(),
                    );
                  }
                  final data = state.data ?? const PaymentRequestState();
                  return TabBarView(
                    children: [
                      _RequestList(
                        requests: data.incomingRequests,
                        actingOnId: data.actingOnRequestId,
                      ),
                      _RequestList(
                        requests: data.outgoingRequests,
                        isOutgoing: true,
                      ),
                    ],
                  );
                },
              ),
        ),
      ),
    );
  }
}

class _RequestList extends StatelessWidget {
  const _RequestList({
    required this.requests,
    this.actingOnId,
    this.isOutgoing = false,
  });

  final List<PaymentRequestEntity> requests;
  final String? actingOnId;
  final bool isOutgoing;

  @override
  Widget build(BuildContext context) {
    if (requests.isEmpty) {
      return AppEmptyState(
        icon: isOutgoing ? Icons.outbox_outlined : Icons.move_to_inbox_outlined,
        title: isOutgoing
            ? context.l10n.noOutgoingRequests
            : context.l10n.noIncomingRequests,
        subtitle: isOutgoing
            ? 'Requests you send will appear here.'
            : 'Requests sent to you will appear here.',
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.only(top: 16, bottom: 32),
      itemCount: requests.length,
      itemBuilder: (context, index) {
        final request = requests[index];
        return PaymentRequestItem(
          request: request,
          isOutgoing: isOutgoing,
          isLoading: actingOnId == request.id,
        );
      },
    );
  }
}
