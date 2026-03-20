import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:geolocator/geolocator.dart';
import 'dart:async';

class PatientRunTrackerScreen extends StatefulWidget {
  const PatientRunTrackerScreen({super.key});

  @override
  State<PatientRunTrackerScreen> createState() => _PatientRunTrackerScreenState();
}

class _PatientRunTrackerScreenState extends State<PatientRunTrackerScreen> {
  // Controladores de Mapa y Ubicación
  GoogleMapController? _mapController;
  Position? _currentPosition;
  StreamSubscription<Position>? _positionStreamSubscription;

  // Variables de la Carrera
  bool _isTracking = false;
  double _totalDistanceKm = 0.0;
  final List<LatLng> _routeCoordinates = [];
  final Set<Polyline> _polylines = {};

  // Cronómetro
  Timer? _timer;
  int _secondsElapsed = 0;

  @override
  void initState() {
    super.initState();
    _checkPermissionsAndGetLocation();
  }

  // 1. SOLICITAR PERMISOS Y CENTRAR MAPA
  Future<void> _checkPermissionsAndGetLocation() async {
    bool serviceEnabled;
    LocationPermission permission;

    // Verifica si el GPS del teléfono está encendido
    serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Por favor, enciende el GPS.')));
      return;
    }

    permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
      if (permission == LocationPermission.denied) {
        if (mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Permiso de ubicación denegado.')));
        return;
      }
    }

    if (permission == LocationPermission.deniedForever) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Los permisos de ubicación están denegados permanentemente.')));
      return;
    }

    // Obtener la posición inicial para centrar el mapa
    Position initialPosition = await Geolocator.getCurrentPosition(desiredAccuracy: LocationAccuracy.high);
    setState(() {
      _currentPosition = initialPosition;
    });

    _mapController?.animateCamera(CameraUpdate.newLatLngZoom(
      LatLng(initialPosition.latitude, initialPosition.longitude),
      17.0, // Nivel de zoom ideal para calles
    ));
  }

  // 2. INICIAR LA CARRERA
  void _startRun() {
    setState(() {
      _isTracking = true;
      _routeCoordinates.clear();
      _polylines.clear();
      _totalDistanceKm = 0.0;
      _secondsElapsed = 0;
    });

    _startTimer();

    // Configuración de precisión para correr (LocationSettings)
    const locationSettings = LocationSettings(
      accuracy: LocationAccuracy.bestForNavigation,
      distanceFilter: 5, // Se actualiza cada que te mueves 5 metros (Ahorra batería)
    );

    // Empezamos a escuchar el GPS en vivo
    _positionStreamSubscription = Geolocator.getPositionStream(locationSettings: locationSettings).listen((Position position) {
      LatLng newLocation = LatLng(position.latitude, position.longitude);

      if (_routeCoordinates.isNotEmpty) {
        // Calcular distancia entre el último punto y este nuevo punto
        double distanceInMeters = Geolocator.distanceBetween(
          _routeCoordinates.last.latitude, _routeCoordinates.last.longitude,
          position.latitude, position.longitude,
        );
        setState(() {
          _totalDistanceKm += (distanceInMeters / 1000);
        });
      }

      setState(() {
        _currentPosition = position;
        _routeCoordinates.add(newLocation);
        
        // Dibujar la línea azul de la ruta
        _polylines.add(
          Polyline(
            polylineId: const PolylineId('route'),
            color: Colors.tealAccent.shade400,
            width: 6, // Grosor de la línea
            points: _routeCoordinates,
          ),
        );
      });

      // La cámara sigue al corredor automáticamente
      _mapController?.animateCamera(CameraUpdate.newLatLng(newLocation));
    });
  }

  // 3. DETENER LA CARRERA
  void _stopRun() {
    setState(() {
      _isTracking = false;
    });
    _timer?.cancel();
    _positionStreamSubscription?.cancel();
    // Aquí a futuro enviaremos _totalDistanceKm y _secondsElapsed a Firebase
  }

  void _startTimer() {
    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      setState(() {
        _secondsElapsed++;
      });
    });
  }

  String _formatTime(int seconds) {
    int m = seconds ~/ 60;
    int s = seconds % 60;
    return '${m.toString().padLeft(2, '0')}:${s.toString().padLeft(2, '0')}';
  }

  @override
  void dispose() {
    _timer?.cancel();
    _positionStreamSubscription?.cancel();
    _mapController?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    const Color darkSlate = Color(0xFF0F172A);

    return Scaffold(
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        iconTheme: const IconThemeData(color: darkSlate), // Flecha de retroceso visible
      ),
      body: Stack(
        children: [
          // 1. EL MAPA AL FONDO
          _currentPosition == null
              ? const Center(child: CircularProgressIndicator(color: Colors.teal))
              : GoogleMap(
                  initialCameraPosition: CameraPosition(
                    target: LatLng(_currentPosition!.latitude, _currentPosition!.longitude),
                    zoom: 17.0,
                  ),
                  myLocationEnabled: true, // Muestra el puntito azul de Google
                  myLocationButtonEnabled: false, // Ocultamos el botón por defecto
                  zoomControlsEnabled: false,
                  polylines: _polylines,
                  onMapCreated: (GoogleMapController controller) {
                    _mapController = controller;
                  },
                ),

          // 2. PANEL DE MÉTRICAS FLOTANTE (ARRIBA)
          SafeArea(
            child: Align(
              alignment: Alignment.topCenter,
              child: Container(
                margin: const EdgeInsets.only(top: 20, left: 24, right: 24),
                padding: const EdgeInsets.symmetric(vertical: 20, horizontal: 24),
                decoration: BoxDecoration(
                  color: darkSlate.withValues(alpha:0.95),
                  borderRadius: BorderRadius.circular(24),
                  boxShadow: [BoxShadow(color: Colors.black.withValues(alpha:0.3), blurRadius: 15, offset: const Offset(0, 5))],
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceAround,
                  children: [
                    // Distancia
                    Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Text('DISTANCIA', style: TextStyle(color: Colors.grey, fontSize: 10, fontWeight: FontWeight.bold, letterSpacing: 1)),
                        const SizedBox(height: 4),
                        Text('${_totalDistanceKm.toStringAsFixed(2)}', style: const TextStyle(color: Colors.white, fontSize: 28, fontWeight: FontWeight.w900)),
                        const Text('km', style: TextStyle(color: Colors.tealAccent, fontSize: 12, fontWeight: FontWeight.bold)),
                      ],
                    ),
                    Container(width: 1, height: 40, color: Colors.white24), // Separador
                    // Tiempo
                    Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Text('TIEMPO', style: TextStyle(color: Colors.grey, fontSize: 10, fontWeight: FontWeight.bold, letterSpacing: 1)),
                        const SizedBox(height: 4),
                        Text(_formatTime(_secondsElapsed), style: const TextStyle(color: Colors.white, fontSize: 28, fontWeight: FontWeight.w900)),
                        const Text('min', style: TextStyle(color: Colors.tealAccent, fontSize: 12, fontWeight: FontWeight.bold)),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ),

          // 3. BOTÓN DE INICIO / DETENER (ABAJO)
          Align(
            alignment: Alignment.bottomCenter,
            child: Padding(
              padding: const EdgeInsets.only(bottom: 40),
              child: GestureDetector(
                onTap: _isTracking ? _stopRun : _startRun,
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 300),
                  width: _isTracking ? 100 : 200,
                  height: 60,
                  decoration: BoxDecoration(
                    color: _isTracking ? Colors.redAccent : Colors.tealAccent.shade400,
                    borderRadius: BorderRadius.circular(30),
                    boxShadow: [BoxShadow(color: (_isTracking ? Colors.red : Colors.teal).withValues(alpha:0.4), blurRadius: 15, offset: const Offset(0, 5))],
                  ),
                  child: Center(
                    child: Text(
                      _isTracking ? 'DETENER' : 'INICIAR CARRERA',
                      style: TextStyle(color: _isTracking ? Colors.white : darkSlate, fontSize: 16, fontWeight: FontWeight.w900, letterSpacing: 1),
                    ),
                  ),
                ),
              ),
            ),
          ),
          
          // Botón para centrar mi ubicación manual
          Align(
            alignment: Alignment.bottomRight,
            child: Padding(
              padding: const EdgeInsets.only(bottom: 120, right: 24),
              child: FloatingActionButton(
                backgroundColor: Colors.white,
                foregroundColor: darkSlate,
                mini: true,
                onPressed: () {
                  if (_currentPosition != null && _mapController != null) {
                    _mapController!.animateCamera(CameraUpdate.newLatLng(LatLng(_currentPosition!.latitude, _currentPosition!.longitude)));
                  }
                },
                child: const Icon(Icons.my_location),
              ),
            ),
          )
        ],
      ),
    );
  }
}