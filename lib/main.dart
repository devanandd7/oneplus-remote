import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'ui/remote_screen.dart';
import 'utils/constants.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();

  // Set immersive dark navigation bar and status bar
  SystemChrome.setSystemUIOverlayStyle(
    const SystemUiOverlayStyle(
      statusBarColor: Colors.transparent,
      statusBarIconBrightness: Brightness.light,
      systemNavigationBarColor: AppColors.background,
      systemNavigationBarIconBrightness: Brightness.light,
    ),
  );

  runApp(const OnePlusRemoteApp());
}

class OnePlusRemoteApp extends StatelessWidget {
  const OnePlusRemoteApp({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: AppConstants.appName,
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        brightness: Brightness.dark,
        scaffoldBackgroundColor: AppColors.background,
        colorScheme: const ColorScheme.dark(
          primary: AppColors.onePlusRed,
          surface: AppColors.remoteBody,
        ),
        fontFamily: 'Roboto',
      ),
      home: const RemoteScreen(),
    );
  }
}
