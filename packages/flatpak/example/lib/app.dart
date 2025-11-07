import 'package:flatpak_flutter_example/business_logic/system_info/system_info_cubit.dart';
import 'package:flatpak_flutter_example/presentation/widgets/installation_status_listener.dart';
import 'package:flatpak_flutter_example/presentation/widgets/snackbar_listener.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'app_router.dart';
import 'business_logic/app_launch/app_launch_cubit.dart';
import 'business_logic/discovery/dicovery_cubit.dart';
import 'business_logic/event_listener/event_listener_bloc.dart';
import 'business_logic/event_listener/event_listener_event.dart';
import 'business_logic/installation/installation_cubit.dart';
import 'business_logic/installed_apps/installed_apps_cubit.dart';
import 'injection_container.dart';

class FlatpakApp extends StatelessWidget {
  const FlatpakApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiBlocProvider(
      providers: [
        BlocProvider<EventListenerBloc>(
          create: (context) => sl<EventListenerBloc>()..add(StartListening()),
          lazy: false,
        ),

        BlocProvider<InstallationCubit>(
          create: (context) => sl<InstallationCubit>(),
          lazy: false,
        ),

        BlocProvider<InstalledAppsCubit>(
          create: (context) => sl<InstalledAppsCubit>(),
          lazy: false,
        ),

        BlocProvider<DiscoveryCubit>(
          create: (context) => sl<DiscoveryCubit>(),
          lazy: false,
        ),

        BlocProvider<AppLaunchCubit>(create: (context) => sl<AppLaunchCubit>()),
        BlocProvider<SystemInfoCubit>(
          create: (context) => sl<SystemInfoCubit>(),
        ),
      ],
      child: InstallationStatusListener(
        child: MaterialApp.router(
          title: 'AGL Store',
          theme: ThemeData(
            colorScheme: ColorScheme.fromSeed(seedColor: Colors.blue),
            useMaterial3: true,
          ),
          darkTheme: ThemeData.dark(useMaterial3: true),
          builder: (context, child) {
            return SnackbarListener(child: child ?? const SizedBox());
          },
          routerConfig: AppRouter.router,
        ),
      ),
    );
  }
}
