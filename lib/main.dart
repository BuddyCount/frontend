import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'providers/group_provider.dart';
import 'screens/groups_overview_screen.dart';
import 'services/local_storage_service.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  // Initialize local storage
  await LocalStorageService.initialize();
  
  // Note: Removed clearAllData() to preserve data across hot restarts
  // Use LocalStorageService.clearAllData() manually when needed for testing
  
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
