import 'dart:async';

import 'dart:math';
import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import 'package:wakelock/wakelock.dart';

void main() => runApp(MyApp());

class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Compteur distance',
      theme: ThemeData.dark(),
      home: Main(),
    );
  }
}

class Main extends StatefulWidget {
  @override
  _MainState createState() => _MainState();
}

class _MainState extends State<Main> with WidgetsBindingObserver {
  DateTime _computationStartTimeStamp;
  bool _streamsSubscribed = false;
  Position _lastPosition;
  double _currentSpeed = 0;
  double _highestSpeed = 0;
  StreamSubscription<Position> _positionStream;
  final Geolocator geolocator = Geolocator();

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    Wakelock.enable();
    if (!_streamsSubscribed) {
      _lastPosition = null;
      _computationStartTimeStamp = DateTime.now().add(Duration(seconds: 5));
      _subscribeToPositionUpdates();
      _streamsSubscribed = true;
    }
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    if (_streamsSubscribed) {
      _positionStream?.cancel();
      _streamsSubscribed = false;
    }
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    switch (state) {
      case AppLifecycleState.resumed:
        Wakelock.enable();
        break;
      case AppLifecycleState.paused:
        Wakelock.disable();
        break;
      default:
    }
  }

  void _subscribeToPositionUpdates() {
    _positionStream = geolocator
        .getPositionStream(LocationOptions(
            accuracy: LocationAccuracy.bestForNavigation, distanceFilter: 0))
        .listen((Position position) {
      if (position.timestamp.isBefore(_computationStartTimeStamp)) {
        _lastPosition = null;
      } else if (_lastPosition == null) {
        _lastPosition = position;
      } else {
        double speed = position.speed / 1000 * 3600;
        print("Speed: $speed");
        _lastPosition = position;
        setState(() {
          _currentSpeed = speed;
        });
        if (speed > _highestSpeed) {
          setState(() {
            _highestSpeed = speed;
          });
        }
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child:
            Column(mainAxisAlignment: MainAxisAlignment.spaceEvenly, children: [
          Text(
            'Vitesse\n${(_currentSpeed).toStringAsFixed(0)} km/h',
            style: TextStyle(fontWeight: FontWeight.w900, fontSize: 80),
          ),
          GestureDetector(
            onLongPress: () {
              setState(() {
                _highestSpeed = 0;
              });
            },
            child: Text(
              'Max\n${(_highestSpeed).toStringAsFixed(0)} km/h',
              style: TextStyle(fontWeight: FontWeight.w900, fontSize: 80),
            ),
          ),
        ]),
      ),
    );
  }
}
