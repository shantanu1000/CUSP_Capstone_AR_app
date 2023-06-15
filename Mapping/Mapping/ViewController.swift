//
//  ViewController.swift
//  Mapping
//
//  Created by Shantanu Anikhindi on 6/15/23.
//

//import UIKit
//import MapKit
//import CoreLocation
//
//struct Restroom {
//    let title: String
//    let latitude: Double
//    let longitude: Double
//}
//
//struct GeoJSON: Codable {
//    let features: [Feature]
//}
//
//struct Feature: Codable {
//    let geometry: Geometry
//}
//
//struct Geometry: Codable {
//    let coordinates: [Double]
//}
//
//class ViewController: UIViewController, MKMapViewDelegate {
//    @IBOutlet weak var mapView: MKMapView!
//    
//    let locationManager = CLLocationManager()
//    var currentCoordinate: CLLocationCoordinate2D?
//    var restrooms: [Restroom] = []
//    var currentRoute: MKRoute?
//    
//    override func viewDidLoad() {
//        super.viewDidLoad()
//        
//        mapView.delegate = self
//        configureLocationServices()
//        loadRestroomLocations()
//    }
//    
//    private func loadRestroomLocations() {
//        if let url = Bundle.main.url(forResource: "export", withExtension: "geojson") {
//            do {
//                let data = try Data(contentsOf: url)
//                let geoJSON = try JSONDecoder().decode(GeoJSON.self, from: data)
//                
//                for (index, feature) in geoJSON.features.enumerated() {
//                    let longitude = feature.geometry.coordinates[0]
//                    let latitude = feature.geometry.coordinates[1]
//                    let title = "Restroom \(index + 1)" // generate a title based on index
//                    restrooms.append(Restroom(title: title, latitude: latitude, longitude: longitude))
//                }
//            } catch {
//                print("Error parsing JSON: \(error)")
//            }
//        }
//    }
//    
//    private func configureLocationServices() {
//        locationManager.delegate = self
//        
//        let status = locationManager.authorizationStatus
//        if status == .notDetermined {
//            locationManager.requestWhenInUseAuthorization()
//        } else if status == .authorizedAlways || status == .authorizedWhenInUse {
//            beginLocationUpdates(locationManager: locationManager)
//        }
//    }
//    
//    private func beginLocationUpdates(locationManager: CLLocationManager) {
//        mapView.showsUserLocation = true
//        locationManager.desiredAccuracy = kCLLocationAccuracyBest
//        locationManager.startUpdatingLocation()
//    }
//    
//    private func zoomToLatestLocation(with coordinate: CLLocationCoordinate2D) {
//        let zoomRegion = MKCoordinateRegion.init(center: coordinate, latitudinalMeters: 1000, longitudinalMeters: 1000)
//        mapView.setRegion(zoomRegion, animated: true)
//    }
//    
//    private func addRestroomLocations() {
//        for restroom in restrooms {
//            let annotation = MKPointAnnotation()
//            annotation.title = restroom.title
//            annotation.coordinate = CLLocationCoordinate2D(latitude: restroom.latitude, longitude: restroom.longitude)
//            mapView.addAnnotation(annotation)
//        }
//    }
//    
//    private func displayRoute(_ route: MKRoute) {
//        // Remove existing route, if any
//        if let currentRoute = currentRoute {
//            mapView.removeOverlay(currentRoute.polyline)
//        }
//
//        // Add the new route
//        mapView.addOverlay(route.polyline)
//        currentRoute = route
//    }
//    
//    func mapView(_ mapView: MKMapView, rendererFor overlay: MKOverlay) -> MKOverlayRenderer {
//        if overlay is MKPolyline {
//            let renderer = MKPolylineRenderer(overlay: overlay)
//            renderer.strokeColor = .blue
//            renderer.lineWidth = 3
//            return renderer
//        }
//
//        return MKOverlayRenderer(overlay: overlay)
//    }
//    
//    func mapView(_ mapView: MKMapView, didSelect view: MKAnnotationView) {
//        guard let destinationCoordinate = view.annotation?.coordinate else { return }
//        
//        // Create the request
//        let request = MKDirections.Request()
//        request.source = MKMapItem(placemark: MKPlacemark(coordinate: currentCoordinate!))
//        request.destination = MKMapItem(placemark: MKPlacemark(coordinate: destinationCoordinate))
//        request.requestsAlternateRoutes = false
//        request.transportType = .automobile
//
//        // Use the request to create directions
//        let directions = MKDirections(request: request)
//        directions.calculate { [weak self] (response, error) in
//            if let error = error {
//                print("Error getting directions: \(error)")
//                return
//            }
//
//            if let route = response?.routes.first {
//                self?.displayRoute(route)
//            }
//        }
//    }
//}
//
//extension ViewController: CLLocationManagerDelegate {
//    func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
//        print("Did get latest location")
//        
//        guard let latestLocation = locations.first else { return }
//        
//        if currentCoordinate == nil {
//            zoomToLatestLocation(with: latestLocation.coordinate)
//            addRestroomLocations()
//        }
//        
//        currentCoordinate = latestLocation.coordinate
//    }
//    
//    func locationManager(_ manager: CLLocationManager, didChangeAuthorization status: CLAuthorizationStatus) {
//        print("The status changed")
//        if status == .authorizedAlways || status == .authorizedWhenInUse {
//            beginLocationUpdates(locationManager: manager)
//        }
//    }
//}
//
import UIKit
import MapKit
import CoreLocation
import ARKit

struct Restroom {
    let title: String
    let latitude: Double
    let longitude: Double
}

struct GeoJSON: Codable {
    let features: [Feature]
}

struct Feature: Codable {
    let geometry: Geometry
}

struct Geometry: Codable {
    let coordinates: [Double]
}

class ViewController: UIViewController, MKMapViewDelegate, ARSCNViewDelegate, CLLocationManagerDelegate, ARSessionDelegate {
    
    @IBOutlet weak var arView: ARSCNView!
    @IBOutlet weak var mapView: MKMapView!
    
    let locationManager = CLLocationManager()
        var currentCoordinate: CLLocationCoordinate2D?
        var restrooms: [Restroom] = []
        var currentRoute: MKRoute?
        var anchors: [ARGeoAnchor] = []
            
        override func viewDidLoad() {
            super.viewDidLoad()
                
            mapView.delegate = self
            arView.delegate = self
            configureLocationServices()
            loadRestroomLocations()

            let configuration = ARWorldTrackingConfiguration()
            configuration.worldAlignment = .gravityAndHeading
            arView.session.run(configuration)
        }
            
        func configureLocationServices() {
            locationManager.delegate = self
            let authorizationStatus = CLLocationManager.authorizationStatus()
            if authorizationStatus == .notDetermined {
                locationManager.requestWhenInUseAuthorization()
            } else if authorizationStatus == .authorizedAlways || authorizationStatus == .authorizedWhenInUse {
                beginLocationUpdates(locationManager: locationManager)
            }
        }
            
        func beginLocationUpdates(locationManager: CLLocationManager) {
            mapView.showsUserLocation = true
            locationManager.desiredAccuracy = kCLLocationAccuracyBest
            locationManager.startUpdatingLocation()
        }
            
        func zoomToLatestLocation(with coordinate: CLLocationCoordinate2D) {
            let zoomRegion = MKCoordinateRegion.init(center: coordinate, latitudinalMeters: 1000, longitudinalMeters: 1000)
            mapView.setRegion(zoomRegion, animated: true)
        }
            
        func addRestroomLocations() {
            restrooms.forEach { restroom in
                let annotation = MKPointAnnotation()
                annotation.title = restroom.title
                annotation.coordinate = CLLocationCoordinate2D(latitude: restroom.latitude, longitude: restroom.longitude)
                mapView.addAnnotation(annotation)
            }
        }
            
        func loadRestroomLocations() {
            guard let url = Bundle.main.url(forResource: "export", withExtension: "geojson") else { return }
            do {
                let data = try Data(contentsOf: url)
                let geoJSON = try JSONDecoder().decode(GeoJSON.self, from: data)
                geoJSON.features.forEach { feature in
                    let title = "Restroom"
                    let latitude = feature.geometry.coordinates[1]
                    let longitude = feature.geometry.coordinates[0]
                    let restroom = Restroom(title: title, latitude: latitude, longitude: longitude)
                    restrooms.append(restroom)
                }
                addRestroomLocations()
            } catch {
                print(error)
            }
        }
            
        func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
            guard let latestLocation = locations.first else { return }
                
            if currentCoordinate == nil {
                zoomToLatestLocation(with: latestLocation.coordinate)
            }
                
            currentCoordinate = latestLocation.coordinate
        }
            
        func locationManagerDidChangeAuthorization(_ manager: CLLocationManager) {
            if manager.authorizationStatus == .authorizedAlways || manager.authorizationStatus == .authorizedWhenInUse {
                beginLocationUpdates(locationManager: manager)
            }
        }
            
    func mapView(_ mapView: MKMapView, didSelect view: MKAnnotationView) {
        guard let coordinate = view.annotation?.coordinate else { return }
        // Clear the previous path if any
                if let currentRoute = self.currentRoute {
                    self.mapView.removeOverlay(currentRoute.polyline)
                    self.currentRoute = nil
                }
                
                // Clear the previous anchor if any
                anchors.forEach { anchor in
                    arView.session.remove(anchor: anchor)
                }
                anchors.removeAll()
                
                generateRoute(to: coordinate)
                startARSession(to: coordinate)
            }

            func generateRoute(to destination: CLLocationCoordinate2D) {
                guard let sourceCoordinate = currentCoordinate else { return }

                let sourcePlacemark = MKPlacemark(coordinate: sourceCoordinate)
                let destinationPlacemark = MKPlacemark(coordinate: destination)

                let sourceItem = MKMapItem(placemark: sourcePlacemark)
                let destinationItem = MKMapItem(placemark: destinationPlacemark)

                let directionRequest = MKDirections.Request()
                directionRequest.source = sourceItem
                directionRequest.destination = destinationItem
                directionRequest.transportType = .automobile

                let directions = MKDirections(request: directionRequest)
                directions.calculate { [weak self] (response, error) in
                    guard let response = response else { return } // handle error
                    self?.currentRoute = response.routes[0]
                    self?.mapView.addOverlay((self?.currentRoute!.polyline)!)
                }
            }

            func startARSession(to destination: CLLocationCoordinate2D) {
                let geoAnchor = ARGeoAnchor(coordinate: destination)
                anchors.append(geoAnchor)
                arView.session.add(anchor: geoAnchor)
            }

            func mapView(_ mapView: MKMapView, rendererFor overlay: MKOverlay) -> MKOverlayRenderer {
                if let polyline = overlay as? MKPolyline {
                    let renderer = MKPolylineRenderer(polyline: polyline)
                    renderer.strokeColor = .blue
                    renderer.lineWidth = 3
                    return renderer
                }
                return MKOverlayRenderer()
            }

            func session(_ session: ARSession, didAdd anchors: [ARAnchor]) {
                for anchor in anchors {
                    if let geoAnchor = anchor as? ARGeoAnchor {
                        let sphereNode = SCNNode(geometry: SCNSphere(radius: 0.1))
                        sphereNode.geometry?.firstMaterial?.diffuse.contents = UIColor.yellow
                        let anchorNode = SCNNode()
                        anchorNode.addChildNode(sphereNode)
                        arView.scene.rootNode.addChildNode(anchorNode)
                    }
                }
            }

            func session(_ session: ARSession, didUpdate anchors: [ARAnchor]) {
                for anchor in anchors {
                    if let geoAnchor = anchor as? ARGeoAnchor {
                        print("GeoAnchor updated: \(geoAnchor)")
                    }
                }
            }

            func session(_ session: ARSession, didRemove anchors: [ARAnchor]) {
                for anchor in anchors {
                    if let geoAnchor = anchor as? ARGeoAnchor {
                        print("GeoAnchor removed: \(geoAnchor)")
                        arView.scene.rootNode.enumerateChildNodes { node, _ in
                            node.removeFromParentNode()
                        }
                    }
                }
            }
        }
