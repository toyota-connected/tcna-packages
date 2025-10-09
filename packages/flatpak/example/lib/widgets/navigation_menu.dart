import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:flatpak_flutter_example/screens/categories_screen.dart';
import 'package:flatpak_flutter_example/screens/home_screen.dart';
import 'package:flatpak_flutter_example/screens/remotes_screen.dart';
import 'package:flatpak_flutter_example/screens/profile_screen.dart';

class NavigationMenu extends StatelessWidget {
  const NavigationMenu({super.key});

  @override
  Widget build(BuildContext context) {
    final controller = Get.put(NavigationController());
    
    return Scaffold(
      bottomNavigationBar: Obx(
       () => NavigationBar(
        height: 80,
        elevation: 0,
        selectedIndex: controller.selectedIndex.value,
        onDestinationSelected: (index) => controller.selectedIndex.value = index,
        indicatorColor: Colors.transparent,
         destinations: [
           NavigationDestination(
               icon: Icon(
                 CupertinoIcons.house_fill,
                 color: controller.selectedIndex.value == 0
                     ? const Color(0XFF0D99FF)
                     : Colors.white,
               ),
               label: 'Home'
           ),
           NavigationDestination(
               icon: Icon(
                 CupertinoIcons.square_grid_2x2_fill,
                 color: controller.selectedIndex.value == 1
                     ? const Color(0XFF0D99FF)
                     : Colors.white,
               ),
               label: 'Apps'
           ),
           NavigationDestination(
               icon: Icon(
                 CupertinoIcons.cloud_fill,
                 color: controller.selectedIndex.value == 2
                     ? const Color(0XFF0D99FF)
                     : Colors.white,
               ),
               label: 'Remotes'
           ),
           NavigationDestination(
               icon: Icon(
                 CupertinoIcons.person_crop_circle_fill,
                 color: controller.selectedIndex.value == 3
                     ? const Color(0XFF0D99FF)
                     : Colors.white,
               ),
               label: 'Profile'
           ),
         ],
      )),
      body: Obx(() => controller.screens[controller.selectedIndex.value]),
    );
  }
}

class NavigationController extends GetxController {
  final Rx<int> selectedIndex = 0.obs;

  final screens = [
    const HomeScreen(),
    const CategroiesScreen(),
    const RemotesScreen(),
    const ProfileScreen(),
  ];
}