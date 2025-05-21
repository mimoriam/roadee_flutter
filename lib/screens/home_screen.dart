import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter/services.dart';

import 'package:roadee_flutter/screens/admin_panel_screen.dart';
import 'package:roadee_flutter/screens/chat_screen.dart';
import 'package:roadee_flutter/screens/login_screen.dart';
import 'package:roadee_flutter/screens/order_history_screen.dart';
import 'package:roadee_flutter/screens/user_profile_screen.dart';
import 'package:roadee_flutter/screens/enter_info_screen.dart';
import 'package:roadee_flutter/screens/payment_checkout_screen.dart';

import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

import 'package:geolocator/geolocator.dart';
import 'package:geocoding/geocoding.dart';
import 'package:mapbox_maps_flutter/mapbox_maps_flutter.dart' as mp;
import 'package:dio/dio.dart';

import 'package:geolocator_android/geolocator_android.dart';
import 'package:geolocator_apple/geolocator_apple.dart';

import '../constants.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final MenuController _menuController = MenuController();

  final dio = Dio();
  int selectedIndex = -1;

  mp.MapWidget? mapWidget;

  mp.PointAnnotationManager? _pointAnnotationManager;

  mp.PolylineAnnotationManager? _polylineAnnotationManager;

  mp.MapboxMap? mapboxMapController;
  Position? _currentPosition;

  StreamSubscription? userPositionStream;

  late Placemark _place;

  var locationChecked;

  bool _isRequestingLocation = false;

  @override
  void initState() {
    super.initState();

    WidgetsBinding.instance.addPostFrameCallback((_) {
      getCurrentLocationOnLaunch();
    });
    setupPositionTracking();
  }

  @override
  void dispose() {
    userPositionStream?.cancel();
    super.dispose();
  }

  void onButtonPressed(int index) {
    setState(() {
      selectedIndex = index;
    });
  }

  Future<Map<String, dynamic>?> getUserProfile() async {
    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid == null) return null;

    final doc = await FirebaseFirestore.instance.collection("users").doc(uid).get();
    return doc.exists ? doc.data() : null;
  }

  Future<void> updateUserAddressOnPlaceOrder(String addr) async {
    final user = FirebaseAuth.instance.currentUser!;

    // Update Firestore address
    await FirebaseFirestore.instance.collection('users').doc(user.uid).update({'address': addr});
  }

  Future<Location?> getCoordinatesFromPlacemark({
    String? thoroughfare,
    required String subThoroughfare,
    String? city,
    String? country,
  }) async {
    final address = [
      subThoroughfare,
      thoroughfare,
      city,
      country,
    ].where((e) => e != null && e.trim().isNotEmpty).join(', ');

    try {
      final locations = await locationFromAddress(address);

      if (locations.isNotEmpty) {
        return locations.first;
      } else {
        print('No location found');
      }
    } catch (e) {}
    return null;
  }

  Future<Map<String, dynamic>?> getUserData() async {
    final uid = FirebaseAuth.instance.currentUser?.uid;

    final doc = await FirebaseFirestore.instance.collection("users").doc(uid).get();

    return doc.data();
  }

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
                        // setState(() {});
                      },
                      child: Text("Open Settings"),
                    ),
                    TextButton(
                      onPressed: () {
                        Navigator.of(ctx).pop();
                      },
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
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("Location permission denied")));
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
                    // Geolocator.openAppSettings();
                    Geolocator.openLocationSettings();
                    // setState(() {});
                  },
                  child: Text("Open App Settings"),
                ),
                TextButton(
                  onPressed: () {
                    Navigator.of(ctx).pop();
                    // Navigator.of(ctx).pop();
                  },
                  child: Text("Cancel"),
                ),
              ],
            ),
      );
      return null;
    }

    late LocationSettings locationSettings;

    if (defaultTargetPlatform == TargetPlatform.android) {
      locationSettings = AndroidSettings(
        accuracy: LocationAccuracy.high,
        forceLocationManager: true,

      );
    } else if (defaultTargetPlatform == TargetPlatform.iOS) {
      locationSettings = AppleSettings(
        accuracy: LocationAccuracy.high,
        activityType: ActivityType.fitness,
        distanceFilter: 100,
        pauseLocationUpdatesAutomatically: true,
        // Only set to true if our app will be started up in the background.
        showBackgroundLocationIndicator: false,
      );
    } else {
      locationSettings = LocationSettings(
        accuracy: LocationAccuracy.high,
        distanceFilter: 100,
      );
    }

    // Get position and address
    // Position position = await Geolocator.getCurrentPosition(
    //   timeLimit: Duration(seconds: 10),
    //   // desiredAccuracy: LocationAccuracy.high,
    //   locationSettings: LocationSettings(accuracy: LocationAccuracy.low),
    // );

    Position position = await Geolocator.getCurrentPosition(
      locationSettings: locationSettings
    );

    debugPrint(position.toString());
    List<Placemark> placemarks = await placemarkFromCoordinates(position.latitude, position.longitude);
    Placemark place = placemarks[0];

    // Why is this here? Sheesh. Took me a long while to find this out
    // Load bearing code, I guess
    await updateUserAddressOnPlaceOrder(
      '${place.name}, ${place.locality}, ${place.administrativeArea}, ${place.country} ${_place.thoroughfare}',
    );

    return '${place.name}, ${place.locality}, ${place.administrativeArea}, ${place.country} ${_place.thoroughfare}';
  }

  Future<void> calculatePlacemarks({required var long, required var lat}) async {
    List<Placemark> placemarks = await placemarkFromCoordinates(lat, long);

    setState(() {
      _place = placemarks[0];
    });
  }

  getCurrentLocationOnLaunch() async {
    if (_isRequestingLocation) return;
    _isRequestingLocation = true;

    bool serviceEnabled;
    LocationPermission permission;

    serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) {
      _isRequestingLocation = false;
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
                        Navigator.pushReplacement(
                          ctx,
                          MaterialPageRoute(builder: (BuildContext context) => super.widget),
                        );
                      },
                      child: Text("Open Settings"),
                    ),
                    TextButton(
                      onPressed: () {
                        Navigator.of(ctx).pop();
                        Navigator.pushReplacement(
                          ctx,
                          MaterialPageRoute(builder: (BuildContext context) => super.widget),
                        );
                      },
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
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("Location permission denied!")));
        _isRequestingLocation = false;
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
                    // Geolocator.openLocationSettings();
                    // Navigator.pushReplacement(
                    //   ctx,
                    //   MaterialPageRoute(builder: (BuildContext context) => super.widget),
                    // );
                  },
                  child: Text("Open App Settings"),
                ),
                TextButton(
                  onPressed: () {
                    Navigator.of(ctx).pop();
                    Navigator.pushReplacement(
                      ctx,
                      MaterialPageRoute(builder: (BuildContext context) => super.widget),
                    );
                  },
                  child: Text("Cancel"),
                ),
              ],
            ),
      );
      _isRequestingLocation = false;
      return null;
    }

    late LocationSettings locationSettings;

    if (defaultTargetPlatform == TargetPlatform.android) {
      locationSettings = AndroidSettings(
        accuracy: LocationAccuracy.high,
        forceLocationManager: true,

      );
    } else if (defaultTargetPlatform == TargetPlatform.iOS) {
      locationSettings = AppleSettings(
        accuracy: LocationAccuracy.high,
        activityType: ActivityType.fitness,
        distanceFilter: 100,
        pauseLocationUpdatesAutomatically: true,
        // Only set to true if our app will be started up in the background.
        showBackgroundLocationIndicator: false,
      );
    } else {
      locationSettings = LocationSettings(
        accuracy: LocationAccuracy.high,
        distanceFilter: 100,
      );
    }

    // Get position and address
    // Position position = await Geolocator.getCurrentPosition(
    //   timeLimit: Duration(seconds: 10),
    //   locationSettings: LocationSettings(accuracy: LocationAccuracy.low),
    // );

    Position position = await Geolocator.getCurrentPosition(
        locationSettings: locationSettings
    );

    List<Placemark> placemarks = await placemarkFromCoordinates(position.latitude, position.longitude);

    if (context.mounted) {
      setState(() {
        _place = placemarks[0];
        _currentPosition = position;
        _isRequestingLocation = false;
      });
    }
  }

  Future<void> updateAddressFromMarker(String addr) async {
    try {
      final user = FirebaseAuth.instance.currentUser!;

      // Update Firestore email
      await FirebaseFirestore.instance.collection('users').doc(user.uid).update({'address': addr});
    } on FirebaseAuthException {}
  }

  Future<void> setupPositionTracking() async {
    userPositionStream?.cancel();

    // LocationSettings locationSettings = LocationSettings(
    //   accuracy: LocationAccuracy.low,
    //   distanceFilter: 100,
    //   timeLimit: const Duration(seconds: 15),
    // );

    late LocationSettings locationSettings;

    if (defaultTargetPlatform == TargetPlatform.android) {
      locationSettings = AndroidSettings(
        accuracy: LocationAccuracy.high,
        forceLocationManager: true,

      );
    } else if (defaultTargetPlatform == TargetPlatform.iOS) {
      locationSettings = AppleSettings(
        accuracy: LocationAccuracy.high,
        activityType: ActivityType.fitness,
        distanceFilter: 100,
        pauseLocationUpdatesAutomatically: true,
        // Only set to true if our app will be started up in the background.
        showBackgroundLocationIndicator: false,
      );
    } else {
      locationSettings = LocationSettings(
        accuracy: LocationAccuracy.high,
        distanceFilter: 100,
      );
    }

    userPositionStream = Geolocator.getPositionStream(locationSettings: locationSettings).listen((
      Position position,
    ) {
      if (mapboxMapController != null) {
        if (context.mounted) {
          mapboxMapController?.setCamera(
            mp.CameraOptions(
              zoom: 14,
              center: mp.Point(coordinates: mp.Position(position.longitude, position.latitude)),
            ),
          );
        }
      }
    });
  }

  void _onMapCreated(mp.MapboxMap mapboxMap) async {
    mapboxMap.logo.updateSettings(mp.LogoSettings(enabled: true));
    mapboxMap.attribution.updateSettings(mp.AttributionSettings(enabled: true));

    mapboxMapController = mapboxMap;

    _polylineAnnotationManager = await mapboxMap.annotations.createPolylineAnnotationManager();
    _pointAnnotationManager = await mapboxMapController?.annotations.createPointAnnotationManager();

    mapboxMapController?.location.updateSettings(
      mp.LocationComponentSettings(enabled: true, pulsingEnabled: true),
    );

    Map<String, dynamic>? user = await getUserData();

    if (user == null) {
      if (context.mounted) {
        setState(() {});
      }
    }

    // if (user?['orders'][user["order_index"]]["assistant_assigned"].isEmpty) {
    // CHANGED HERE
    // if (user?['orders_assigned'][0]['orderAssignedFrom'].isNotEmpty) {
    // Draw polylines if user is assigned to admin:
    // final query =
    // await FirebaseFirestore.instance
    //     .collection("users")
    //     .where('username', isEqualTo: user?['orders_assigned'][0]['orderAssignedFrom'])
    //     .limit(1)
    //     .get();
    //
    // final docRef = query.docs.first.reference;
    // final doc = await docRef.get();
    //
    // final orders = List<Map<String, dynamic>>.from(doc.data()?['orders'] ?? []);
    //
    // var splitRiderAddress = user?["address"].split(" ~ ");
    // var splitUserAddress = orders[orders.length - 1]["user_marked_address"].split(" ~ ");

    // var userLatLng = await getCoordinatesFromPlacemark(
    //   thoroughfare: splitUserAddress[0],
    //   subThoroughfare: splitUserAddress[1],
    //   city: orders[orders.length - 1]["assistant_city"],
    //   country: orders[orders.length - 1]["assistant_country"],
    // );

    // TODO Draw polylines for Admin:
    // var riderLatLng = await getCoordinatesFromPlacemark(
    //   thoroughfare: splitRiderAddress[3],
    //   subThoroughfare: splitRiderAddress[0],
    //   city: splitUserAddress[1],
    //   country: splitUserAddress[2],
    // );

    // Draw marker for Assistant/Rider:
    // await createMarkerOnMap(
    //   currentLong: riderLatLng?.longitude as num,
    //   currentLat: riderLatLng?.latitude as num,
    //   text: "Rider",
    // );
    //
    // // Draw marker for User:
    // await createMarkerOnMap(
    //   currentLong: userLatLng?.longitude as num,
    //   currentLat: userLatLng?.latitude as num,
    //   text: "User",
    // );
    //
    // drawPolyline(
    //   userLatLng?.longitude,
    //   userLatLng?.latitude,
    //   riderLatLng?.longitude,
    //   riderLatLng?.latitude,
    // );

    // } else
    if (user?['orders'][user["orders"].length - 1]["status"] == OrderStatus.Empty.name ||
        user?['orders'][user["orders"].length - 1]["status"] == OrderStatus.Pending.name ||
        user?['orders'][user["orders"].length - 1]["status"] == OrderStatus.Completed.name) {
      // If user isn't assigned to admin, enable drawing free markers
      await createMarkerOnMap(
        currentLong: _currentPosition!.longitude,
        currentLat: _currentPosition!.latitude,
      );
    } else {
      // Otherwise draw polylines for user-facing side:
      var splitRiderAddress = user?['orders'][user["orders"].length - 1]["assistant_address"].split(" ~ ");
      var splitUserAddress = user?['address'].split(",");

      var riderLatLng = await getCoordinatesFromPlacemark(
        thoroughfare: splitRiderAddress[0],
        subThoroughfare: splitRiderAddress[1],
        city: user?['orders'][user["orders"].length - 1]["assistant_city"],
        country: user?['orders'][user["orders"].length - 1]["assistant_country"],
      );

      // print(splitUserAddress);

      var userLatLng = await getCoordinatesFromPlacemark(
        thoroughfare: splitUserAddress[3],
        subThoroughfare: splitUserAddress[0],
        city: splitUserAddress[1],
        country: splitUserAddress[2],
      );

      // print(riderLatLng);
      // print(userLatLng);

      // Draw marker for Assistant/Rider:
      await createMarkerOnMap(
        currentLong: riderLatLng?.longitude as num,
        currentLat: riderLatLng?.latitude as num,
        text: "Rider",
      );

      // Draw marker for User:
      await createMarkerOnMap(
        currentLong: userLatLng?.longitude as num,
        currentLat: userLatLng?.latitude as num,
        text: "User",
      );

      drawPolyline(
        userLatLng?.longitude,
        userLatLng?.latitude,
        riderLatLng?.longitude,
        riderLatLng?.latitude,
      );
    }
  }

  void drawPolyline(startLng, startLat, endLng, endLat) async {
    var coords;
    final url =
        'https://api.mapbox.com/directions/v5/mapbox/driving/$startLng,$startLat;$endLng,$endLat?overview=full&geometries=geojson&access_token=$mapBoxToken';

    // final response = await http.get(Uri.parse(url));
    try {
      final response = await dio.get(url);
      if (response.statusCode == 200) {
        final data = response.data;
        coords =
            coords =
                (data['routes'][0]['geometry']['coordinates'] as List).map<mp.Position>((coord) {
                  final lon = coord[0].toDouble();
                  final lat = coord[1].toDouble();
                  return mp.Position(lon, lat);
                }).toList();

        await _polylineAnnotationManager!.create(
          mp.PolylineAnnotationOptions(
            // geometry: mp.LineString(coordinates: [mp.Position(startLng, startLat), mp.Position(endLng, endLat)]),
            geometry: mp.LineString(coordinates: coords),
            // lineColor: 120000,
            lineWidth: 4.0,
          ),
        );
      }
    } catch (e) {
      showDialog(
        context: context,
        builder: (BuildContext context) {
          return AlertDialog(
            title: Text("MapBox API Error"),
            actions: <Widget>[
              TextButton(
                onPressed: () {
                  Navigator.of(context).pop(); // Don't exit
                },
                child: Text("Ok"),
              ),
            ],
          );
        },
      );
    }
  }

  Future<void> createMarkerOnMap({required num currentLong, required num currentLat, String? text}) async {
    // // Load the image from assets
    final ByteData bytes = await rootBundle.load("images/red_marker.png");
    final Uint8List imageData = bytes.buffer.asUint8List();

    // Create a PointAnnotationOptions
    final mp.PointAnnotationOptions pointAnnotationOptions = mp.PointAnnotationOptions(
      geometry: mp.Point(coordinates: mp.Position(currentLong, currentLat)),
      // Example
      // coordinates
      image: imageData,
      // textField: "${_place.thoroughfare} ${_place.subThoroughfare}",
      textField:
          (text != null && text.trim().isNotEmpty)
              ? text
              : (_place.thoroughfare == ""
                  ? "${_place.name} ${_place.street}"
                  : "${_place.thoroughfare} "
                      "${_place.subThoroughfare}"),
      textOffset: [0.0, -3],
      // textAnchor: mp.TextAnchor.TOP_LEFT,
      iconSize: 1.0,
      iconOffset: [0.0, -18.0],
    );

    // Add the annotation to the map
    _pointAnnotationManager?.create(pointAnnotationOptions);
  }

  _onCameraChangeListener(mp.CameraChangedEventData data) {
    // createMarkerOnMap(
    //   currentLong: data.cameraState.center.coordinates.lng,
    //   currentLat: data.cameraState.center.coordinates.lat,
    // );
    // _pointAnnotationManager?.deleteAll();
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
              style: TextStyle(color: isSelected ? Colors.white : Colors.black, fontWeight: FontWeight.w600),
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
    if (context.mounted) {
      setState(() {});
    }

    SystemChrome.setPreferredOrientations([DeviceOrientation.portraitUp, DeviceOrientation.portraitDown]);

    Future<void> onSelected(String value) async {
      switch (value) {
        case 'Your Profile':
          Navigator.push(context, MaterialPageRoute(builder: (context) => UserProfileScreen()));
          break;
        case 'Admin':
          // Go to Admin area:
          Navigator.push(
            context,
            MaterialPageRoute(builder: (context) => AdminScreen(placemark: _place)),
          ).then((value) {
            if (context.mounted) {
              setState(() {});
            }
          });
          break;

        case 'Your Orders':
          // Go to orders:
          var user = await getUserProfile();
          Navigator.push(
            context,
            MaterialPageRoute(builder: (context) => OrderHistoryScreen(userData: user!)),
          );
          break;
        case 'Log out':
          await FirebaseAuth.instance.signOut();
          Navigator.pushReplacement(context, MaterialPageRoute(builder: (context) => LoginScreen()));
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
                          // Navigator.of(context).pop(); // Close dialog
                          // Navigator.of(context).pop(); // Pop the route
                          SystemNavigator.pop();
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
                leading: IconButton(icon: const Icon(Icons.menu, color: Colors.black), onPressed: () {}),
                title: Row(
                  children: [
                    // const Text(
                    //   'Roadie',
                    //   style: TextStyle(
                    //     fontFamily: 'Cursive',
                    //     fontWeight: FontWeight.bold,
                    //     color: Colors.red,
                    //     fontSize: 24,
                    //   ),
                    // ),
                    Image(image: AssetImage("images/Logo_White.jpg"), height: 24),
                    const Spacer(),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        const Text('Logged In as', style: TextStyle(fontSize: 12, color: Colors.black54)),
                        Text("${user['username']}", style: TextStyle(fontSize: 12, color: Colors.black)),
                      ],
                    ),
                    const SizedBox(width: 8),
                    MenuAnchor(
                      controller: _menuController,
                      style: MenuStyle(backgroundColor: WidgetStateProperty.all(Colors.white)),
                      menuChildren: [
                        MenuItemButton(
                          onPressed: () => onSelected('Your Profile'),
                          child: Text('Your Profile'),
                        ),
                        user["is_admin"]
                            ? MenuItemButton(onPressed: () => onSelected('Admin'), child: Text('Admin Panel'))
                            : MenuItemButton(
                              onPressed: () => onSelected('Your Orders'),
                              child: Text("Your Orders"),
                            ),
                        MenuItemButton(onPressed: () => onSelected('Log out'), child: Text('Log out')),
                      ],
                      builder: (BuildContext context, MenuController controller, Widget? child) {
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
                            backgroundImage: AssetImage("images/default_pfp.jpg"),
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
                  SingleChildScrollView(
                    child: Column(
                      children: [
                        // Placeholder for Map
                        _currentPosition == null
                            ? Center(child: CircularProgressIndicator())
                            : SizedBox(
                              height: 420,
                              width: double.infinity,
                              child: mp.MapWidget(
                                key: ValueKey('mapWidget'),
                                gestureRecognizers: {
                                  Factory<EagerGestureRecognizer>(() => EagerGestureRecognizer()),
                                },
                                cameraOptions: mp.CameraOptions(
                                  center: mp.Point(
                                    coordinates: mp.Position(
                                      _currentPosition!.longitude,
                                      _currentPosition!.latitude,
                                    ),
                                  ),
                                  zoom: 14,
                                ),
                                onMapCreated: _onMapCreated,
                                onCameraChangeListener: _onCameraChangeListener,
                                onTapListener: (mp.MapContentGestureContext context) async {
                                  // print("OnTap coordinate: {${context.point.coordinates.lng}, ${context.point.coordinates.lat}}" +
                                  //     " point: {x: ${context.touchPosition.x}, y: ${context.touchPosition.y}}" +
                                  //     " state: ${context.gestureState}");

                                  if (context.gestureState == mp.GestureState.ended) {
                                    // Disable Marker creation if user has assistant assigned:
                                    // if (user['orders'][user["order_index"]]["assistant_assigned"].isEmpty) {
                                    if (user['orders'][user["orders"].length - 1]["status"] ==
                                            OrderStatus.Empty.name ||
                                        user['orders'][user["orders"].length - 1]["status"] ==
                                            OrderStatus.Pending.name ||
                                        user['orders'][user["orders"].length - 1]["status"] ==
                                            OrderStatus.Completed.name) {
                                      await _pointAnnotationManager?.deleteAll();
                                      await _polylineAnnotationManager?.deleteAll();

                                      await calculatePlacemarks(
                                        long: context.point.coordinates.lng,
                                        lat: context.point.coordinates.lat,
                                      );

                                      await createMarkerOnMap(
                                        currentLong: context.point.coordinates.lng,
                                        currentLat: context.point.coordinates.lat,
                                      );
                                    } else {}

                                    // drawPolyline(
                                    //   _currentPosition!.longitude,
                                    //   _currentPosition!.latitude,
                                    //   context.point.coordinates.lng,
                                    //   context.point.coordinates.lat,
                                    // );
                                  }
                                },
                                // onScrollListener: (mp.MapContentGestureContext context) {
                                //   if (context.gestureState == mp.GestureState.changed) {
                                //     _pointAnnotationManager?.deleteAll();
                                //   } else {
                                //     createMarkerOnMap(
                                //       currentLong: context.point.coordinates.lng,
                                //       currentLat: context.point.coordinates.lat,
                                //     );
                                //   }
                                // },
                              ),
                            ),
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
                                          if (user['orders'][user["orders"].length - 1]["status"]
                                                  .toString() ==
                                              "Pending") {
                                            return Text(
                                              "We are working on our end to "
                                              "send someone to your assistance!",
                                              textAlign: TextAlign.center,
                                              style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
                                            );
                                          } else if (user['orders'][user["orders"].length - 1]["status"]
                                                  .toString() ==
                                              "OnRoute") {
                                            return Text(
                                              'Your Roadside '
                                              'Assistance Tech: '
                                              '${user['orders'][user["orders"].length - 1]["assistant_assigned"].toString().toCapitalize()}',
                                              textAlign: TextAlign.center,
                                              style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
                                            );
                                          } else {
                                            return Text(
                                              'We are here to help!',
                                              style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
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
                              Builder(
                                builder: (context) {
                                  if (user['orders'][user["orders"].length - 1]["status"].toString() ==
                                      "Pending") {
                                    return Card(
                                      elevation: 4,
                                      shape: RoundedRectangleBorder(
                                        borderRadius: BorderRadius.circular(16), // Rounded corners
                                      ),
                                      margin: EdgeInsets.all(16.0),
                                      child: Column(
                                        children: [
                                          ListTile(
                                            leading: Icon(Icons.schedule),
                                            title: const Text('We are currently reviewing your order...'),
                                            // subtitle: Text(
                                            //   'Secondary Text',
                                            //   style: TextStyle(color: Colors.black.withOpacity(0.6)),
                                            // ),
                                          ),
                                        ],
                                      ),
                                    );
                                  } else if (user['orders'][user["orders"].length - 1]["status"].toString() ==
                                      "OnRoute") {
                                    return ElevatedButton(
                                      style: ElevatedButton.styleFrom(backgroundColor: Color(0xFF098232)),
                                      onPressed: () {
                                        // Navigator.push(
                                        //   context,
                                        //   MaterialPageRoute(builder: (context) => ChatHomeScreen(user: user)),
                                        // );
                                        Navigator.push(
                                          context,
                                          MaterialPageRoute(
                                            builder:
                                                (context) => ChatScreen(
                                                  receiverId:
                                                      "${user['orders'][user["orders"].length - 1]["assistant_id"]}",
                                                  receiverEmail:
                                                      "${user['orders'][user["orders"].length - 1]["assistant_email"]}",
                                                  user: user,
                                                ),
                                          ),
                                        );
                                      },
                                      child: Text(
                                        // "Chat with your assistant: ${user['orders'][user["order_index"]]["assistant_assigned"].toString().toCapitalize()}",
                                        "Chat with your assistant",
                                        style: TextStyle(color: Colors.white, fontSize: 16),
                                      ),
                                    );
                                  } else {
                                    if (user["is_admin"] == true &&
                                        "${user['orders_assigned'][0]["orderAssignedFrom"]}".isNotEmpty) {
                                      return ElevatedButton(
                                        style: ElevatedButton.styleFrom(backgroundColor: Color(0xFF098232)),
                                        onPressed: () async {
                                          final query =
                                              await FirebaseFirestore.instance
                                                  .collection("users")
                                                  .where(
                                                    'username',
                                                    isEqualTo:
                                                        user["orders_assigned"][0]["orderAssignedFrom"],
                                                  )
                                                  .limit(1)
                                                  .get();

                                          var doc = await query.docs.first.reference.get();
                                          var clientData = doc.data();

                                          Navigator.push(
                                            context,
                                            MaterialPageRoute(
                                              builder:
                                                  (context) => ChatScreen(
                                                    receiverId: clientData?["id"],
                                                    receiverEmail: clientData?["email"],
                                                    user: user,
                                                  ),
                                            ),
                                          );
                                        },
                                        child: Text(
                                          // "Chat with your assistant: ${user['orders'][user["order_index"]]["assistant_assigned"].toString().toCapitalize()}",
                                          "Chat with the Client",
                                          style: TextStyle(color: Colors.white, fontSize: 16),
                                        ),
                                      );
                                    }
                                    return ElevatedButton(
                                      // style: ButtonStyle(
                                      //   shape: MaterialStateProperty.all<RoundedRectangleBorder>(
                                      //       RoundedRectangleBorder(
                                      //           borderRadius: BorderRadius.circular(10.0),
                                      //       )
                                      //   ),
                                      //   textStyle: MaterialStateProperty.all<Color>(
                                      //     Colors.white,
                                      //   ),
                                      //   backgroundColor: MaterialStateProperty.all<Color>(Color(0xFF098232)),
                                      // ),
                                      style: ElevatedButton.styleFrom(backgroundColor: Color(0xFF098232)),
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
                                                      Navigator.of(context).pop(); // Don't exit
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
                                            showDialog(
                                              context: context,
                                              builder: (BuildContext context) {
                                                // TODO Fix a potential bug here on multiple user orders
                                                // Add a field in DB for Red/Blue location and use that to
                                                // draw markers
                                                return AlertDialog(
                                                  title: Text(
                                                    "Would you like to use current location or marked location?",
                                                  ),
                                                  actions: <Widget>[
                                                    TextButton(
                                                      onPressed: () {
                                                        setState(() {
                                                          locationChecked = "Blue";
                                                        });
                                                        Navigator.of(context).pop();
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
                                                      },
                                                      child: Text("Current (Blue)"),
                                                    ),
                                                    TextButton(
                                                      onPressed: () {
                                                        setState(() {
                                                          locationChecked = "Red";
                                                        });
                                                        Navigator.of(context).pop();
                                                        Navigator.push(
                                                          context,
                                                          MaterialPageRoute(
                                                            builder:
                                                                (context) => EnterInfoScreen(
                                                                  serviceSelected: selectedIndex,
                                                                  addressSelected:
                                                                      '${_place.name}, ${_place.locality}, '
                                                                      '${_place.administrativeArea}, ${_place.country}, ${_place.thoroughfare}',
                                                                ),
                                                          ),
                                                        );
                                                      },
                                                      child: Text("Marked (Red)"),
                                                    ),
                                                  ],
                                                );
                                              },
                                            );
                                          }
                                        }
                                      },
                                      child: const Text(
                                        "Place an Order",
                                        style: TextStyle(color: Colors.white, fontSize: 16),
                                      ),
                                    );
                                  }
                                },
                              ),
                              const SizedBox(height: 20),
                              Builder(
                                builder: (context) {
                                  if (user['orders'][0]["status"].toString() == "Pending") {
                                    return Column(
                                      children: [
                                        Row(
                                          mainAxisAlignment: MainAxisAlignment.center,
                                          children: [
                                            Icon(Icons.warning, color: Colors.yellow),
                                            SizedBox(width: 8),
                                            Text(
                                              'Your current order is in review: ',
                                              style: TextStyle(fontSize: 16, fontWeight: FontWeight.w500),
                                            ),
                                          ],
                                        ),
                                        Center(
                                          child: Padding(
                                            padding: EdgeInsets.only(top: 4),
                                            child: Text(
                                              user['orders'][0]["service"].toString().toCapitalize(),
                                              style: TextStyle(color: Colors.black54),
                                            ),
                                          ),
                                        ),
                                      ],
                                    );
                                  } else if (user['orders'][0]["status"].toString() == "OnRoute") {
                                    return Column(
                                      children: [
                                        Row(
                                          mainAxisAlignment: MainAxisAlignment.center,
                                          children: [
                                            Icon(Icons.check_circle, color: Colors.green),
                                            SizedBox(width: 8),
                                            Text(
                                              'Assistance is on the way',
                                              style: TextStyle(fontSize: 16, fontWeight: FontWeight.w500),
                                            ),
                                          ],
                                        ),
                                        Center(
                                          child: Padding(
                                            padding: EdgeInsets.only(top: 4),
                                            child: Text(
                                              'Arriving in 15 min',
                                              style: TextStyle(color: Colors.black54),
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
                  ),
                  MediaQuery.of(context).viewInsets.bottom == 0.0
                      ? Align(
                        alignment: Alignment.bottomCenter,
                        child: Padding(
                          padding: const EdgeInsets.only(bottom: 16.0),
                          child: Container(
                            // margin: const EdgeInsets.only(bottom: 8.0),
                            width: 135,
                            height: 5,
                            decoration: BoxDecoration(
                              // color: Colors.white.withValues(alpha: 0.5),
                              color: Colors.grey,
                              borderRadius: BorderRadius.circular(2.5),
                            ),
                          ),
                        ),
                      )
                      : Container(),
                ],
              ),
            ),
          ),
        );
      },
    );
  }
}
