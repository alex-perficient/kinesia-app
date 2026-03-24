import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:geolocator/geolocator.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'dart:async';

class PatientRunTrackerScreen extends StatefulWidget {
  const PatientRunTrackerScreen({super.key});

  @override
  State<PatientRunTrackerScreen> createState() =>
      _PatientRunTrackerScreenState();
}

class _PatientRunTrackerScreenState extends State<PatientRunTrackerScreen> {
  // Controladores de Mapa y Ubicación
  GoogleMapController? _mapController;
  Position? _currentPosition;
  StreamSubscription<Position>? _positionStreamSubscription;

  // Variables de la Carrera
  bool _isTracking = false;
  bool _isSaving = false;
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

    serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Por favor, enciende el GPS.')),
        );
      }
      return;
    }

    permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
      if (permission == LocationPermission.denied) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Permiso de ubicación denegado.')),
          );
        }
        return;
      }
    }

    if (permission == LocationPermission.deniedForever) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text(
              'Los permisos de ubicación están denegados permanentemente.',
            ),
          ),
        );
      }
      return;
    }

    Position initialPosition = await Geolocator.getCurrentPosition(
      desiredAccuracy: LocationAccuracy.high,
    );
    // 👇 Agregamos if (mounted)
    if (mounted) {
      setState(() {
        _currentPosition = initialPosition;
      });
    }

    _mapController?.animateCamera(
      CameraUpdate.newLatLngZoom(
        LatLng(initialPosition.latitude, initialPosition.longitude),
        17.0,
      ),
    );
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

    const locationSettings = LocationSettings(
      accuracy: LocationAccuracy.bestForNavigation,
      distanceFilter: 5,
    );

    _positionStreamSubscription =
        Geolocator.getPositionStream(locationSettings: locationSettings).listen(
          (Position position) {
            LatLng newLocation = LatLng(position.latitude, position.longitude);

            if (_routeCoordinates.isNotEmpty) {
              double distanceInMeters = Geolocator.distanceBetween(
                _routeCoordinates.last.latitude,
                _routeCoordinates.last.longitude,
                position.latitude,
                position.longitude,
              );
              setState(() {
                _totalDistanceKm += (distanceInMeters / 1000);
              });
            }

            setState(() {
              _currentPosition = position;
              _routeCoordinates.add(newLocation);

              _polylines.add(
                Polyline(
                  polylineId: const PolylineId('route'),
                  color: Colors.tealAccent.shade400,
                  width: 6,
                  points: _routeCoordinates,
                ),
              );
            });

            _mapController?.animateCamera(CameraUpdate.newLatLng(newLocation));
          },
        );
  }

  // 3. DETENER Y GUARDAR LA CARRERA
  Future<void> _stopRun() async {
    // 1. Pausamos visualmente
    setState(() => _isTracking = false);
    _timer?.cancel();
    _positionStreamSubscription?.pause(); // Pausamos temporalmente

    // 2. Pedimos confirmación
    final confirm = await showDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        title: const Text('¿Finalizar Entrenamiento?'),
        content: const Text(
          'Si terminas ahora, esta carrera se guardará en tu historial clínico.',
        ),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text(
              'Continuar',
              style: TextStyle(color: Colors.grey),
            ),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.tealAccent.shade400,
              foregroundColor: const Color(0xFF0F172A),
            ),
            onPressed: () => Navigator.pop(context, true),
            child: const Text(
              'Finalizar y Guardar',
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
          ),
        ],
      ),
    );

    // Si el usuario decide continuar corriendo
    if (confirm != true) {
      setState(() => _isTracking = true);
      _startTimer();
      _positionStreamSubscription?.resume();
      return;
    }

    // 3. Si confirma, detenemos todo definitivamente
    _positionStreamSubscription?.cancel();

    // Filtro anti-trampas: mínimo 50 metros para guardar
    if (_totalDistanceKm < 0.05) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text(
              'Distancia muy corta. No se registró en el historial.',
            ),
          ),
        );
      }
      _resetRunData();
      return;
    }

    setState(() => _isSaving = true);

    try {
      // 4. Matemáticas: Calcular el Pace (Ritmo en min/km)
      double minutes = _secondsElapsed / 60.0;
      double paceDecimal = _totalDistanceKm > 0
          ? (minutes / _totalDistanceKm)
          : 0;
      int paceMin = paceDecimal.floor();
      int paceSec = ((paceDecimal - paceMin) * 60).round();
      String formattedPace =
          '${paceMin.toString().padLeft(2, '0')}:${paceSec.toString().padLeft(2, '0')} min/km';

      final patientId = FirebaseAuth.instance.currentUser!.uid;

      // 5. Guardar en Firestore
      await FirebaseFirestore.instance.collection('workout_logs').add({
        'patientId': patientId,
        'exerciseName': 'Carrera al aire libre 🏃‍♂️',
        'distanceKm': _totalDistanceKm,
        'durationSeconds': _secondsElapsed,
        'pace': formattedPace,
        'type': 'cardio', // Etiqueta clave
        'date': FieldValue.serverTimestamp(),
      });

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text(
              '¡Excelente ritmo! Carrera guardada con éxito 🏆',
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
            backgroundColor: Colors.teal,
          ),
        );
        _resetRunData();
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Error al guardar: $e')));
      }
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }

  void _resetRunData() {
    setState(() {
      _totalDistanceKm = 0.0;
      _secondsElapsed = 0;
      _routeCoordinates.clear();
      _polylines.clear();
    });
  }

  void _startTimer() {
    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (mounted) {
        setState(() {
          _secondsElapsed++;
        });
      }
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
        iconTheme: const IconThemeData(color: darkSlate),
      ),
      body: Stack(
        children: [
          // 1. EL MAPA AL FONDO
          _currentPosition == null
              ? const Center(
                  child: CircularProgressIndicator(color: Colors.teal),
                )
              : GoogleMap(
                  initialCameraPosition: CameraPosition(
                    target: LatLng(
                      _currentPosition!.latitude,
                      _currentPosition!.longitude,
                    ),
                    zoom: 17.0,
                  ),
                  myLocationEnabled: true,
                  myLocationButtonEnabled: false,
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
                padding: const EdgeInsets.symmetric(
                  vertical: 20,
                  horizontal: 24,
                ),
                decoration: BoxDecoration(
                  color: darkSlate.withValues(alpha: 0.95),
                  borderRadius: BorderRadius.circular(24),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.3),
                      blurRadius: 15,
                      offset: const Offset(0, 5),
                    ),
                  ],
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceAround,
                  children: [
                    // Distancia
                    Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Text(
                          'DISTANCIA',
                          style: TextStyle(
                            color: Colors.grey,
                            fontSize: 10,
                            fontWeight: FontWeight.bold,
                            letterSpacing: 1,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          _totalDistanceKm.toStringAsFixed(2),
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 28,
                            fontWeight: FontWeight.w900,
                          ),
                        ),
                        const Text(
                          'km',
                          style: TextStyle(
                            color: Colors.tealAccent,
                            fontSize: 12,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                    Container(
                      width: 1,
                      height: 40,
                      color: Colors.white24,
                    ), // Separador
                    // Tiempo
                    Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Text(
                          'TIEMPO',
                          style: TextStyle(
                            color: Colors.grey,
                            fontSize: 10,
                            fontWeight: FontWeight.bold,
                            letterSpacing: 1,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          _formatTime(_secondsElapsed),
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 28,
                            fontWeight: FontWeight.w900,
                          ),
                        ),
                        const Text(
                          'min',
                          style: TextStyle(
                            color: Colors.tealAccent,
                            fontSize: 12,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
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
                onTap: _isSaving ? null : (_isTracking ? _stopRun : _startRun),
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 300),
                  width: _isTracking
                      ? 120
                      : 200, // Se hace más pequeño al correr
                  height: 60,
                  decoration: BoxDecoration(
                    color: _isTracking
                        ? Colors.redAccent
                        : Colors.tealAccent.shade400,
                    borderRadius: BorderRadius.circular(30),
                    boxShadow: [
                      BoxShadow(
                        color: (_isTracking ? Colors.red : Colors.teal)
                            .withValues(alpha: 0.4),
                        blurRadius: 15,
                        offset: const Offset(0, 5),
                      ),
                    ],
                  ),
                  child: Center(
                    child: _isSaving
                        ? const CircularProgressIndicator(color: Colors.white)
                        : Text(
                            _isTracking ? 'DETENER' : 'INICIAR CARRERA',
                            style: TextStyle(
                              color: _isTracking ? Colors.white : darkSlate,
                              fontSize: 16,
                              fontWeight: FontWeight.w900,
                              letterSpacing: 1,
                            ),
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
                    _mapController!.animateCamera(
                      CameraUpdate.newLatLng(
                        LatLng(
                          _currentPosition!.latitude,
                          _currentPosition!.longitude,
                        ),
                      ),
                    );
                  }
                },
                child: const Icon(Icons.my_location),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
