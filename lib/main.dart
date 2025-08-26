import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'providers/group_provider.dart';
import 'screens/home_screen.dart';

void main() {
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
        home: const HomeScreen(),
        debugShowCheckedModeBanner: false,
      ),
    );
  }
}
