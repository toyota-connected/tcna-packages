import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../business_logic/permission_listener/permission_listener_bloc.dart';
import '../../business_logic/permission_listener/permission_listener_event.dart';
import '../../business_logic/permission_listener/permission_listener_state.dart';
import '../../core/permissions/permission_types.dart';
import '../../data/models/flatpak_permission_model.dart';
import 'flatpak_permission_dialog.dart';

final GlobalKey<NavigatorState> permissionNavigatorKey = GlobalKey<NavigatorState>();

/// Uses a global navigator key to show dialogs from anywhere
class PermissionHandlerWrapper extends StatelessWidget {
  final Widget child;

  const PermissionHandlerWrapper({
    super.key,
    required this.child,
  });

  @override
  Widget build(BuildContext context) {
    return BlocListener<PermissionListenerBloc, PermissionListenerState>(
      listener: (context, state) {
        if (state is PermissionRequestReceived) {
          _handlePermissionRequest(context, state.event);
        } else if (state is PermissionError) {
          _showErrorSnackbar(state.message);
        } else if (state is PermissionOperationSuccess) {
          _showSuccessSnackbar(state.message);
        }
      },
      child: child,
    );
  }

  void _handlePermissionRequest(BuildContext blocContext, PermissionEvent event) {
    if (event.permission == null) {
      debugPrint('[PermissionHandler] Warning: Permission is null');
      return;
    }

    // get context
    final navContext = permissionNavigatorKey.currentContext;

    if (navContext == null) {
      debugPrint('[PermissionHandler] Navigator context not available');
      Future.delayed(const Duration(milliseconds: 500), () {
        _handlePermissionRequest(blocContext, event);
      });
      return;
    }

    debugPrint('[PermissionHandler] Showing dialog for ${event.permission?.displayName}');

    // Show the dialog and handle response
    FlatpakPermissionDialog.show(
      context: navContext,
      event: event,
    ).then((granted) {
      if (granted != null) {
        blocContext.read<PermissionListenerBloc>().add(
          RespondToPermissionRequest(
            requestId: event.requestId,
            permission: event.permission!,
            granted: granted,
          ),
        );
      }
    });
  }

  void _showErrorSnackbar(String message) {
    final navContext = permissionNavigatorKey.currentContext;
    if (navContext == null) return;

    WidgetsBinding.instance.addPostFrameCallback((_) {
      final scaffoldMessenger = ScaffoldMessenger.maybeOf(navContext);
      if (scaffoldMessenger == null) return;

      scaffoldMessenger.showSnackBar(
        SnackBar(
          content: Row(
            children: [
              const Icon(Icons.error_outline, color: Colors.white),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  message,
                  style: const TextStyle(fontSize: 14),
                ),
              ),
            ],
          ),
          backgroundColor: Colors.red.shade700,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(10),
          ),
          margin: const EdgeInsets.all(16),
          duration: const Duration(seconds: 4),
        ),
      );
    });
  }

  void _showSuccessSnackbar(String message) {
    final navContext = permissionNavigatorKey.currentContext;
    if (navContext == null) return;

    WidgetsBinding.instance.addPostFrameCallback((_) {
      final scaffoldMessenger = ScaffoldMessenger.maybeOf(navContext);
      if (scaffoldMessenger == null) return;

      scaffoldMessenger.showSnackBar(
        SnackBar(
          content: Row(
            children: [
              const Icon(Icons.check_circle_outline, color: Colors.white),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  message,
                  style: const TextStyle(fontSize: 14),
                ),
              ),
            ],
          ),
          backgroundColor: Colors.green.shade700,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(10),
          ),
          margin: const EdgeInsets.all(16),
          duration: const Duration(seconds: 2),
        ),
      );
    });
  }
}