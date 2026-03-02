import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'providers/diy_provider.dart';
import 'providers/merit_provider.dart';
import 'providers/navigation_provider.dart';
import 'providers/sleep_provider.dart';
import 'routes/app_route_information_parser.dart';
import 'routes/app_router_delegate.dart';
import 'services/api_service.dart';
import 'services/audio_cache_service.dart';
import 'services/audio_service.dart';
import 'services/storage_service.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  final storage = await StorageService.getInstance();
  final apiService = ApiService();
  final audioService = AudioService();
  final audioCacheService = AudioCacheService();
  final navigationProvider = NavigationProvider();
  final meritProvider = MeritProvider(storage: storage);
  final sleepProvider = SleepProvider(
    apiService: apiService,
    audioService: audioService,
    audioCacheService: audioCacheService,
  );
  final diyProvider = DiyProvider(
    apiService: apiService,
    audioService: audioService,
    audioCacheService: audioCacheService,
  );
  final routerDelegate = AppRouterDelegate(navigationProvider: navigationProvider);
  final routeInformationParser = AppRouteInformationParser();

  runApp(WhiteNoiseApp(
    routerDelegate: routerDelegate,
    routeInformationParser: routeInformationParser,
    navigationProvider: navigationProvider,
    meritProvider: meritProvider,
    sleepProvider: sleepProvider,
    diyProvider: diyProvider,
    apiService: apiService,
    audioService: audioService,
  ));
}

class WhiteNoiseApp extends StatelessWidget {
  const WhiteNoiseApp({
    super.key,
    required this.routerDelegate,
    required this.routeInformationParser,
    required this.navigationProvider,
    required this.meritProvider,
    required this.sleepProvider,
    required this.diyProvider,
    required this.apiService,
    required this.audioService,
  });

  final RouterDelegate<Object> routerDelegate;
  final RouteInformationParser<Object> routeInformationParser;
  final NavigationProvider navigationProvider;
  final MeritProvider meritProvider;
  final SleepProvider sleepProvider;
  final DiyProvider diyProvider;
  final ApiService apiService;
  final AudioService audioService;

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider<NavigationProvider>.value(value: navigationProvider),
        ChangeNotifierProvider<MeritProvider>.value(value: meritProvider),
        ChangeNotifierProvider<SleepProvider>.value(value: sleepProvider),
        ChangeNotifierProvider<DiyProvider>.value(value: diyProvider),
        Provider<ApiService>.value(value: apiService),
        Provider<AudioService>.value(value: audioService),
      ],
      child: MaterialApp.router(
        title: 'White Noise',
        theme: ThemeData(
          colorScheme: ColorScheme.fromSeed(seedColor: Colors.deepPurple),
          useMaterial3: true,
        ),
        routerDelegate: routerDelegate,
        routeInformationParser: routeInformationParser,
      ),
    );
  }
}
