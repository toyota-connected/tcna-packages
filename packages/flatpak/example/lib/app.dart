import 'package:flatpak_flutter_example/business_logic/app_status/app_status_cubit.dart';
import 'package:flatpak_flutter_example/business_logic/system_info/system_info_cubit.dart';
import 'package:flatpak_flutter_example/presentation/widgets/app_status.dart';
import 'package:flatpak_flutter_example/presentation/widgets/permission_handler_wrapper.dart';
import 'package:flatpak_flutter_example/presentation/widgets/snackbar_listener.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'app_router.dart';
import 'business_logic/app_launch/app_launch_cubit.dart';
import 'business_logic/discovery/discovery_cubit.dart';
import 'business_logic/installation/installation_cubit.dart';
import 'business_logic/permission_listener/permission_listener_bloc.dart';
import 'business_logic/permission_listener/permission_listener_event.dart';
import 'injection_container.dart';

class FlatpakApp extends StatelessWidget {
  const FlatpakApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiBlocProvider(
      providers: [
        BlocProvider<PermissionListenerBloc>(
          create: (context) => sl<PermissionListenerBloc>()
            ..add(StartPermissionListening()),
          lazy: false,
        ),

        // App status
        BlocProvider<AppStatusCubit>(
          create: (context) => sl<AppStatusCubit>()..loadAppStatus(),
          lazy: false,
        ),

        // Installation cubit
        BlocProvider<InstallationCubit>(
          create: (context) => sl<InstallationCubit>(),
        ),

        BlocProvider<DiscoveryCubit>(
          create: (context) => sl<DiscoveryCubit>(),
          lazy: false,
        ),

        BlocProvider<AppLaunchCubit>(
          create: (context) => sl<AppLaunchCubit>(),
        ),

        BlocProvider<SystemInfoCubit>(
          create: (context) => sl<SystemInfoCubit>(),
        ),
      ],
      child: PermissionHandlerWrapper(
        child: MaterialApp.router(
          routerConfig: AppRouter.router,
          title: 'AGL Store',
          theme: ThemeData(
            colorScheme: ColorScheme.fromSeed(
              seedColor: Colors.blue,
              brightness: Brightness.light,
            ),
            useMaterial3: true,
          ),
          darkTheme: ThemeData(
            colorScheme: ColorScheme.fromSeed(
              seedColor: Colors.blue,
              brightness: Brightness.dark,
            ),
            useMaterial3: true,
          ),
          builder: (context, child) {
            WidgetsBinding.instance.addPostFrameCallback((_) {
              if (permissionNavigatorKey.currentContext == null && context.mounted) {
                debugPrint('[App] Navigator context available');
              }
            });

            return AppStatusCoordinator(
              child: SnackbarListener(
                child: child ?? const SizedBox(),
              ),
            );
          },
          debugShowCheckedModeBanner: false,
        ),
      ),
    );
  }
}