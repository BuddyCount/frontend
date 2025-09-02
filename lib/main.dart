import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'providers/group_provider.dart';
import 'screens/groups_overview_screen.dart';
import 'services/local_storage_service.dart';
import 'services/auth_service.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  // Initialize Hive
  await Hive.initFlutter();
  
  // Initialize local storage
  await LocalStorageService.initialize();
  
  // Initialize authentication service
  await AuthService.initialize();
  
  runApp(const BuddyCountApp());
}

class BuddyCountApp extends StatelessWidget {
  const BuddyCountApp({super.key});

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (context) => GroupProvider(),
      child: MaterialApp(
        title: 'BuddyCount',
        theme: ThemeData(
          colorScheme: ColorScheme.fromSeed(seedColor: Colors.blue),
          useMaterial3: true,
        ),
                        home: const GroupsOverviewScreen(),
        debugShowCheckedModeBanner: false,
      ),
    );
  }
}
