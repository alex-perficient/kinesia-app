import Flutter
import UIKit
import GoogleMaps // <-- 1. NUEVO: Importamos la librería de Google Maps

@main
@objc class AppDelegate: FlutterAppDelegate, FlutterImplicitEngineDelegate {
  override func application(
    _ application: UIApplication,
    didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?
  ) -> Bool {
      
    // 2. NUEVO: Inyectamos la llave API antes de arrancar la app
    GMSServices.provideAPIKey("AIzaSyAoy6TbeaNUgo19g9k8LTkwgXUj53sfIrs")
      
    return super.application(application, didFinishLaunchingWithOptions: launchOptions)
  }

  func didInitializeImplicitFlutterEngine(_ engineBridge: FlutterImplicitEngineBridge) {
    GeneratedPluginRegistrant.register(with: engineBridge.pluginRegistry)
  }
}