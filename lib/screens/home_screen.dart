import 'package:flutter/material.dart';

import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

import 'package:roadee_flutter/screens/login_screen.dart';
import 'package:roadee_flutter/screens/user_profile_screen.dart';
import 'package:roadee_flutter/screens/enter_info_screen.dart';

import 'package:geolocator/geolocator.dart';
import 'package:geocoding/geocoding.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final MenuController _menuController = MenuController();
  int selectedIndex = -1;

  void onButtonPressed(int index) {
    setState(() {
      selectedIndex = index;
    });
  }

  Future<Map<String, dynamic>?> getUserProfile() async {
    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid == null) return null;

    final doc =
        await FirebaseFirestore.instance.collection("users").doc(uid).get();
    return doc.exists ? doc.data() : null;
  }

  // Future<Map<String, String>?> getUserAddress(BuildContext context) async {
  Future<String?> getUserAddress(BuildContext context) async {
    bool serviceEnabled;
    LocationPermission permission;

    // Check if location services are enabled
    serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) {
      await showDialog(
            context: context,
            barrierDismissible: false,
            builder:
                (ctx) => AlertDialog(
                  title: Text("Location Services Disabled"),
                  content: Text("Please enable location services in settings."),
                  actions: [
                    TextButton(
                      onPressed: () {
                        Navigator.of(ctx).pop();
                        Geolocator.openLocationSettings();
                      },
                      child: Text("Open Settings"),
                    ),
                    TextButton(
                      onPressed: () => Navigator.of(ctx).pop(),
                      child: Text("Cancel"),
                    ),
                  ],
                ),
          ) ??
          false;
      return null;
    }

    // Handle permission
    permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
      if (permission == LocationPermission.denied) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text("Location permission denied")));
        return null;
      }
    }

    if (permission == LocationPermission.deniedForever) {
      await showDialog(
        context: context,
        builder:
            (ctx) => AlertDialog(
              title: Text("Permission Denied"),
              content: Text("Enable location permissions from app settings."),
              actions: [
                TextButton(
                  onPressed: () {
                    Navigator.of(ctx).pop();
                    Geolocator.openAppSettings();
                  },
                  child: Text("Open App Settings"),
                ),
                TextButton(
                  onPressed: () => Navigator.of(ctx).pop(),
                  child: Text("Cancel"),
                ),
              ],
            ),
      );
      return null;
    }

    // Get position and address
    Position position = await Geolocator.getCurrentPosition(
      // desiredAccuracy: LocationAccuracy.high,
      locationSettings: LocationSettings(accuracy: LocationAccuracy.high),
    );
    List<Placemark> placemarks = await placemarkFromCoordinates(
      position.latitude,
      position.longitude,
    );
    Placemark place = placemarks[0];
    return '${place.name}, ${place.locality}, ${place.administrativeArea}, ${place.country}';
    // return {
    //   "locationPerm": "$permission",
    //   "place":
    //       '${place.name}, ${place.locality}, ${place.administrativeArea}, '
    //       '${place.country}',
    // };
  }

  Widget buildButton(int index, String label, IconData icon) {
    final bool isSelected = selectedIndex == index;
    return GestureDetector(
      onTap: () => onButtonPressed(index),
      child: Container(
        width: 150,
        padding: const EdgeInsets.symmetric(vertical: 10),
        decoration: BoxDecoration(
          color: isSelected ? Colors.teal : Colors.grey[200],
          borderRadius: BorderRadius.circular(12),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, color: isSelected ? Colors.white : Colors.black),
            const SizedBox(width: 8),
            Text(
              label,
              style: TextStyle(
                color: isSelected ? Colors.white : Colors.black,
                fontWeight: FontWeight.w600,
              ),
            ),
            if (isSelected)
              const Padding(
                padding: EdgeInsets.only(left: 4),
                child: Icon(Icons.check, color: Colors.white, size: 18),
              ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    setState(() {});

    Future<void> onSelected(String value) async {
      switch (value) {
        case 'Your Profile':
          Navigator.push(
            context,
            MaterialPageRoute(builder: (context) => UserProfileScreen()),
          );
          break;
        case 'Settings':
          break;
        case 'Log out':
          await FirebaseAuth.instance.signOut();
          Navigator.pushReplacement(
            context,
            MaterialPageRoute(builder: (context) => LoginScreen()),
          );
          break;
      }
    }

    return FutureBuilder<Map<String, dynamic>?>(
      future: getUserProfile(),
      builder: (context, snapshot) {
        if (!snapshot.hasData) {
          return Center(child: CircularProgressIndicator());
        }
        final user = snapshot.data!;
        return PopScope(
          canPop: false,
          onPopInvokedWithResult: (bool didPop, Object? result) async {
            if (didPop) {
              // If the route is popped, exit the app
            } else {
              // Show a confirmation dialog before allowing the pop
              showDialog(
                context: context,
                builder: (BuildContext context) {
                  return AlertDialog(
                    title: Text("Confirm Exit"),
                    content: Text("Are you sure you want to exit the app?"),
                    actions: <Widget>[
                      TextButton(
                        onPressed: () {
                          Navigator.of(context).pop(); // Don't exit
                        },
                        child: Text("Cancel"),
                      ),
                      TextButton(
                        onPressed: () {
                          Navigator.of(context).pop(); // Close dialog
                          Navigator.of(context).pop(); // Pop the route
                        },
                        child: Text("Exit"),
                      ),
                    ],
                  );
                },
              );
            }
          },
          child: Scaffold(
            // backgroundColor: const Color(0xFF128f8b),
            backgroundColor: Colors.white,
            appBar: PreferredSize(
              preferredSize: const Size.fromHeight(60),
              child: AppBar(
                backgroundColor: Colors.white,
                elevation: 0,
                leading: IconButton(
                  icon: const Icon(Icons.menu, color: Colors.black),
                  onPressed: () {},
                ),
                title: Row(
                  children: [
                    const Text(
                      'Roadie',
                      style: TextStyle(
                        fontFamily: 'Cursive',
                        fontWeight: FontWeight.bold,
                        color: Colors.red,
                        fontSize: 24,
                      ),
                    ),
                    const Spacer(),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        const Text(
                          'You Are Logged In',
                          style: TextStyle(fontSize: 12, color: Colors.black54),
                        ),
                        Text(
                          "${user['username']}",
                          style: TextStyle(fontSize: 12, color: Colors.black),
                        ),
                      ],
                    ),
                    const SizedBox(width: 8),
                    MenuAnchor(
                      controller: _menuController,
                      style: MenuStyle(
                        backgroundColor: WidgetStateProperty.all(Colors.white),
                      ),
                      menuChildren: [
                        MenuItemButton(
                          onPressed: () => onSelected('Your Profile'),
                          child: Text('Your Profile'),
                        ),
                        MenuItemButton(
                          onPressed: () => onSelected('Settings'),
                          child: Text('Settings'),
                        ),
                        MenuItemButton(
                          onPressed: () => onSelected('Log out'),
                          child: Text('Log out'),
                        ),
                      ],
                      builder: (
                        BuildContext context,
                        MenuController controller,
                        Widget? child,
                      ) {
                        return GestureDetector(
                          onTap: () {
                            if (controller.isOpen) {
                              controller.close();
                            } else {
                              controller.open();
                            }
                          },

                          child: CircleAvatar(
                            radius: 18,
                            backgroundImage: AssetImage(
                              "images/default_pfp.jpg",
                            ),
                          ),
                        );
                      },
                    ),
                  ],
                ),
              ),
            ),
            body: SafeArea(
              child: Stack(
                children: [
                  Column(
                    children: [
                      // Placeholder for Map
                      Placeholder(),
                      // SizedBox(height: 350, width: double.infinity),
                      Container(
                        padding: const EdgeInsets.all(16),
                        color: Colors.white,
                        child: Column(
                          children: [
                            Row(
                              children: [
                                // Avatar
                                Container(),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: Center(
                                    child: Builder(
                                      builder: (context) {
                                        if (user['orders'][0]["status"]
                                                .toString() ==
                                            "Pending") {
                                          return Text(
                                            "We are working on our end to "
                                            "send someone to your assistance!",
                                            textAlign: TextAlign.center,
                                            style: TextStyle(
                                              fontSize: 16,
                                              fontWeight: FontWeight.w600,
                                            ),
                                          );
                                        } else if (user['orders'][0]["status"]
                                                .toString() ==
                                            "OnRoute") {
                                          return Text(
                                            'Your Roadside '
                                            'Assistance Tech: Aaron G.',
                                            textAlign: TextAlign.center,
                                            style: TextStyle(
                                              fontSize: 16,
                                              fontWeight: FontWeight.w600,
                                            ),
                                          );
                                        } else {
                                          return Text(
                                            'We are here to help!',
                                            style: TextStyle(
                                              fontSize: 16,
                                              fontWeight: FontWeight.w600,
                                            ),
                                          );
                                        }
                                      },
                                    ),
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 20),
                            Wrap(
                              spacing: 12,
                              runSpacing: 12,
                              children: [
                                buildButton(0, 'Towing', Icons.local_shipping),
                                buildButton(1, 'Flat Tire', Icons.tire_repair),
                                buildButton(2, 'Battery', Icons.battery_full),
                                buildButton(3, 'Fuel', Icons.local_gas_station),
                              ],
                            ),
                            const SizedBox(height: 20),
                            ElevatedButton(
                              onPressed: () async {
                                if (selectedIndex == -1) {
                                  showDialog(
                                    context: context,
                                    builder: (BuildContext context) {
                                      return AlertDialog(
                                        title: Text(
                                          "You did not select a "
                                          "service!",
                                        ),
                                        actions: <Widget>[
                                          TextButton(
                                            onPressed: () {
                                              Navigator.of(
                                                context,
                                              ).pop(); // Don't exit
                                            },
                                            child: Text("Okay"),
                                          ),
                                        ],
                                      );
                                    },
                                  );
                                } else {
                                  var address = await getUserAddress(context);

                                  if (address == null) {
                                    // showDialog(
                                    //   context: context,
                                    //   builder: (BuildContext context) {
                                    //     return AlertDialog(
                                    //       title: Text(
                                    //         "You did not select a "
                                    //         "location!",
                                    //       ),
                                    //       actions: <Widget>[
                                    //         TextButton(
                                    //           onPressed: () {
                                    //             Navigator.of(
                                    //               context,
                                    //             ).pop(); // Don't exit
                                    //           },
                                    //           child: Text("Okay"),
                                    //         ),
                                    //       ],
                                    //     );
                                    //   },
                                    // );
                                  } else {
                                    Navigator.push(
                                      context,
                                      MaterialPageRoute(
                                        builder:
                                            (context) => EnterInfoScreen(
                                              serviceSelected: selectedIndex,
                                              addressSelected: address,
                                            ),
                                      ),
                                    );
                                  }
                                }
                              },
                              child: const Text("Place Order"),
                            ),
                            const SizedBox(height: 20),
                            Builder(
                              builder: (context) {
                                if (user['orders'][0]["status"].toString() ==
                                    "Pending") {
                                  return Column(
                                    children: [
                                      Row(
                                        mainAxisAlignment:
                                            MainAxisAlignment.center,
                                        children: [
                                          Icon(
                                            Icons.warning,
                                            color: Colors.yellow,
                                          ),
                                          SizedBox(width: 8),
                                          Text(
                                            'Your current order is in review: ',
                                            style: TextStyle(
                                              fontSize: 16,
                                              fontWeight: FontWeight.w500,
                                            ),
                                          ),
                                        ],
                                      ),
                                      Center(
                                        child: Padding(
                                          padding: EdgeInsets.only(top: 4),
                                          child: Text(
                                            user['orders'][0]["service"]
                                                .toString()
                                                .toCapitalize(),
                                            style: TextStyle(
                                              color: Colors.black54,
                                            ),
                                          ),
                                        ),
                                      ),
                                    ],
                                  );
                                } else if (user['orders'][0]["status"]
                                        .toString() ==
                                    "OnRoute") {
                                  return Column(
                                    children: [
                                      Row(
                                        mainAxisAlignment:
                                            MainAxisAlignment.center,
                                        children: [
                                          Icon(
                                            Icons.check_circle,
                                            color: Colors.green,
                                          ),
                                          SizedBox(width: 8),
                                          Text(
                                            'Assistance is on the way',
                                            style: TextStyle(
                                              fontSize: 16,
                                              fontWeight: FontWeight.w500,
                                            ),
                                          ),
                                        ],
                                      ),
                                      Center(
                                        child: Padding(
                                          padding: EdgeInsets.only(top: 4),
                                          child: Text(
                                            'Arriving in 15 min',
                                            style: TextStyle(
                                              color: Colors.black54,
                                            ),
                                          ),
                                        ),
                                      ),
                                    ],
                                  );
                                } else {
                                  return Text("");
                                }
                              },
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }
}
