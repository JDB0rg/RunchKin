//
//  NewRunViewController.swift
//  RunchKin
//
//  Created by Madison Waters on 3/19/19.
//  Copyright © 2019 Jonah Bergevin. All rights reserved.
//

import UIKit
import MapKit
import CoreLocation

class NewRunViewController: UIViewController, PlayerDelegate, RecorderDelegate {
    
    // MARK: - Properties
    private var run: Run?
    private let locationManager = LocationManager.shared
    private var seconds = 0
    private var timer: Timer?
    var distance = Measurement(value: 0, unit: UnitLength.meters)
    var locationList: [CLLocation] = []
    private let player = Player()
    private let recorder = Recorder()
    
    // MARK: - Outlets
    @IBOutlet weak var colorRuleView: UIView!
    @IBOutlet weak var mapView: MKMapView!
    @IBOutlet weak var dataStackView: UIStackView!
    
    @IBOutlet weak var distanceLabel: UILabel!
    @IBOutlet weak var timeLabel: UILabel!
    @IBOutlet weak var paceLabel: UILabel!
    
    @IBOutlet weak var startButton: UIButton!
    @IBOutlet weak var stopButton: UIButton!
    @IBOutlet weak var leftButton: UIButton!
    @IBOutlet weak var rightButton: UIButton!
    
    @IBOutlet weak var viewBlock: UIView!
    
    // MARK: - Actions
    @IBAction func startButtonTapped() {
        startRun()
    }
    
    @IBAction func stopButtonTapped() {
        let alertController = UIAlertController(title: "End run?",
                                                message: "Do you want to end your run?",
                                                preferredStyle: .actionSheet)
        alertController.addAction(UIAlertAction(title: "Cancel", style: .cancel))
        alertController.addAction(UIAlertAction(title: "Save", style: .default, handler: { _ in
            self.stopRun()
            self.saveRun()
            self.performSegue(withIdentifier: .details, sender: nil)
        }))
        alertController.addAction(UIAlertAction(title: "Don't Save", style: .destructive, handler: { _ in
            self.stopRun()
            _ = self.navigationController?.popViewController(animated: true)
        }))
        
        present(alertController, animated: true)
    }
    
    @IBAction func playButtonTapped(_ sender: Any) {
        player.playPause(song: recorder.currentFile)
    }
    
    // MARK: - Audio Player Method
    func playerDidChangeState(_ player: Player) {
    }
    
    func recorderDidChangeState(_ recorder: Recorder) {
    }
    
    // MARK: - View Controller Methods
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        // User Location
        if (CLLocationManager.locationServicesEnabled())
        {
            locationManager.delegate = self
            locationManager.desiredAccuracy = kCLLocationAccuracyBest
            locationManager.requestAlwaysAuthorization()
            locationManager.startUpdatingLocation()
            
            mapView.isScrollEnabled = true
            mapView.isZoomEnabled = true
            mapView.showsUserLocation = true
        }
    }
    override func viewDidLoad() {
        super.viewDidLoad()
        
        setupTheme()
        // Delegates
        player.delegate = self
        recorder.delegate = self
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        timer?.invalidate()
        locationManager.stopUpdatingLocation()
    }
    
    func eachSecond() {
        seconds += 1
        updateDataDisplay()
    }
    
    // MARK: - Run Methods
    private func startRun() {
        
        startButton.isHidden = true
        stopButton.isHidden = false
        
        seconds = 0
        distance = Measurement(value: 0, unit: UnitLength.meters)
        locationList.removeAll()
        updateDataDisplay()
        timer = Timer.scheduledTimer(withTimeInterval: 1.0, repeats: true, block: { _ in
            self.eachSecond()
        })
        startLocationUpdates()
    }

    private func stopRun() {
        
        startButton.isHidden = false
        stopButton.isHidden = true
        
        locationManager.stopUpdatingLocation()
    }
    
    private func saveRun() {
        let newRun = Run(context: CoreDataStack.context)
        newRun.distance = distance.value
        newRun.duration = Int16(seconds)
        newRun.timestamp = Date()
        
        for location in locationList {
            let locationObject = Location(context: CoreDataStack.context)
            locationObject.timestamp = location.timestamp
            locationObject.latitude = location.coordinate.latitude
            locationObject.longitude = location.coordinate.longitude
            newRun.addToLocations(locationObject)
        }
        
        CoreDataStack.saveContext()
        run = newRun
    }
    
    // If I get the chance this is how to calculate calores / minute
    // Energy expenditure (calories/minute) = .0175 x MET (from table) x weight (in kilograms)
    func caloriesBurned(metrics: Double, weight: Double) -> Double {
        let weightInKilos = weight / 2.205
        let calories = 0.75 * metrics * weightInKilos
        
        enum metrics: Double {
            typealias RawValue = Double
            
            //case twelve  minute mile = metrics # of 8
            case twelve = 8
            case elevenPointFive = 9
            case ten = 10
            case nine = 11
            case eightPointFive = 11.5
            case eight = 12.5
            case sevenPointFive = 13.5
            case seven = 14
            case sixPointFive = 15
            case six = 16
            case fivePointFive = 18
        }
        return calories
    }
    
    // MARK: - Location Methods
    private func startLocationUpdates() {
        locationManager.delegate = self
        locationManager.activityType = .fitness
        locationManager.distanceFilter = 10
        locationManager.startUpdatingLocation()
        locationManager.allowsBackgroundLocationUpdates = true
    }
    
    // MARK: - Update Methods
    private func updateDataDisplay() {
        let formattedDistance = FormatDisplay.distance(distance)
        let formattedTime = FormatDisplay.time(seconds)
        let formattedPace = FormatDisplay.pace(distance: distance, seconds: seconds, outputUnit: .minutesPerMile)
        
        distanceLabel.text = formattedDistance
        timeLabel.text = formattedTime
        paceLabel.text = formattedPace
    }
    // MARK: - Theme Setup Method
    private func setupTheme() {
        mapView.mapType = .hybrid //.hybridFlyover

        paceLabel.textColor = lightGray
        distanceLabel.textColor = lightGray
        timeLabel.textColor = lightGray

        viewBlock.backgroundColor = navy
        //viewBlock.layer.addBorder(edge: .top, color: green!, thickness: 15)
        viewBlock.layer.addBorder(edge: .top, color: lightGray!, thickness: 10)
        viewBlock.layer.addBorder(edge: .top, color: salmon!, thickness: 5)

        startButton.backgroundColor = green
        startButton.setTitleColor(navy, for: .normal)
        startButton.layer.cornerRadius = startButton.frame.size.width / 2

        stopButton.setTitleColor(navy, for: .normal)
        stopButton.backgroundColor = green
        stopButton.layer.cornerRadius = stopButton.frame.size.width / 2

        let origLeftImage = UIImage(named: "add-image");
        let tintedLeftImage = origLeftImage?.withRenderingMode(UIImage.RenderingMode.alwaysTemplate)
        leftButton.setImage(tintedLeftImage, for: .normal)
        leftButton.tintColor = lightGray

        let origRightImage = UIImage(named: "musical-notes-30");
        let tintedRightImage = origRightImage?.withRenderingMode(UIImage.RenderingMode.alwaysTemplate)
        rightButton.setImage(tintedRightImage, for: .normal)
        rightButton.tintColor = lightGray

        stopButton.isHidden = true
    }
}
// MARK: - Extensions

// MARK: - Navigation
extension NewRunViewController: SegueHandlerType {
    enum SegueIdentifier: String {
        case details = "ShowRunDetailsVC"
    }
    
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        switch segueIdentifier(for: segue) {
        case .details:
            let destination = segue.destination as! RunDetailsViewController
            destination.run = run
        }
    }
}

// MARK: - MapView
extension NewRunViewController: MKMapViewDelegate {
    func mapView(_ mapView: MKMapView, rendererFor overlay: MKOverlay) -> MKOverlayRenderer {
        
        guard let polyline = overlay as? MKPolyline else {
            return MKOverlayRenderer(overlay: overlay)
        }
        let renderer = MKPolylineRenderer(polyline: polyline)
        renderer.strokeColor = green
        renderer.lineWidth = 3
        return renderer
    }
}

// MARK: - Location Manager
extension NewRunViewController: CLLocationManagerDelegate {
    
    func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
        for newLocation in locations {
            let howRecent = newLocation.timestamp.timeIntervalSinceNow
            guard newLocation.horizontalAccuracy < 20 && abs(howRecent) < 10 else { continue }
            
            if let lastLocation = locationList.last {
                let delta = newLocation.distance(from: lastLocation)
                distance = distance + Measurement(value: delta, unit: UnitLength.meters)

                let coordinates = [lastLocation.coordinate, newLocation.coordinate]
                mapView.addOverlay(MKPolyline(coordinates: coordinates, count: 2))
           
                // I had to construct this center. It might need to be on Last Location or another property //
                //let lastCenter = CLLocationCoordinate2D(latitude: lastLocation.coordinate.latitude, longitude: lastLocation.coordinate.longitude)
                //let span = MKCoordinateSpan(latitudeDelta: 0.05, longitudeDelta: 0.05)
                let newCenter = CLLocationCoordinate2D(latitude: newLocation.coordinate.latitude, longitude: newLocation.coordinate.longitude)
                let region = MKCoordinateRegion(center: newCenter, latitudinalMeters: 500, longitudinalMeters: 500)
                //let thirdRegion = MKCoordinateRegion(center: newCenter, span: span)
                
                //let fourthRegion = MKCoordinateRegion(<#T##rect: MKMapRect##MKMapRect#>)
                
                mapView.setRegion(region, animated: true)
            }
            
            locationList.append(newLocation)
        }
    }
}



    
    

