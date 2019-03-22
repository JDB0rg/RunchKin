//
//  RunDetailsViewController.swift
//  RunchKin
//
//  Created by Madison Waters on 3/19/19.
//  Copyright © 2019 Jonah Bergevin. All rights reserved.
//

import UIKit
import MapKit
import CoreLocation

class RunDetailsViewController: UIViewController, UIImagePickerControllerDelegate, UINavigationControllerDelegate {

    // MARK: - Properties
    var run: Run!
    var location: Location?
    private var originalImage: UIImage?
    
    // MARK: - Outlets
    @IBOutlet weak var runImageView: UIImageView!
    @IBOutlet weak var blockView: UIView!
    @IBOutlet weak var scrollView: UIScrollView!
    @IBOutlet weak var mapView: MKMapView!
    @IBOutlet weak var dateLabel: UILabel!
    @IBOutlet weak var paceLabel: UILabel!
    @IBOutlet weak var distanceLabel: UILabel!
    @IBOutlet weak var timeLabel: UILabel!
    
    @IBOutlet weak var titleLabel: UILabel!
    @IBOutlet weak var paceInfoLabel: UILabel!
    @IBOutlet weak var timeInfoLabel: UILabel!
    
    @IBOutlet weak var titleTextField: UITextField!
    
    @IBOutlet weak var addTitleButton: UIButton!
    @IBOutlet weak var leftButton: UIButton!
    
    // MARK: - Actions
    @IBAction func addImage(_ sender: Any) {
        guard UIImagePickerController.isSourceTypeAvailable(.photoLibrary) else {
            print("The photo library is unavailable")
            return
        }
        
        let picker = UIImagePickerController()
        picker.delegate = self
        picker.sourceType = .photoLibrary
        present(picker, animated: true, completion: nil)
        
    }
    
    @IBAction func addTitle(_ sender: Any) {
        guard let text = titleTextField.text else { return }
        updateRun(titleInput: text)
    }
    
    // MARK: UIImage Picker Controller Delegate
    func imagePickerController(_ picker: UIImagePickerController, didFinishPickingMediaWithInfo info: [UIImagePickerController.InfoKey : Any]) {
        
        picker.dismiss(animated: true, completion: nil)
        originalImage = info[.originalImage] as? UIImage
        runImageView.image = originalImage
        
        let imageData = originalImage?.pngData()
        run.image = imageData
        CoreDataStack.saveContext()
    }
    
    func imagePickerControllerDidCancel(_ picker: UIImagePickerController) {
        picker.dismiss(animated: true, completion: nil)
    }
    
    // MARK: - Methods
    override func viewDidLoad() {
        super.viewDidLoad()

        mapView.mapType = .hybrid
        
        blockView.backgroundColor = navy
        blockView.layer.addBorder(edge: .top, color: lightGray!, thickness: 10)
        blockView.layer.addBorder(edge: .top, color: salmon!, thickness: 5)
        
        titleLabel.textColor = lightGray
        dateLabel.textColor = lightGray
        paceLabel.textColor = lightGray
        distanceLabel.textColor = lightGray
        timeLabel.textColor = lightGray
        paceInfoLabel.textColor = lightGray
        timeInfoLabel.textColor = lightGray
        
        let origLeftImage = UIImage(named: "add-image");
        let tintedLeftImage = origLeftImage?.withRenderingMode(UIImage.RenderingMode.alwaysTemplate)
        leftButton.setImage(tintedLeftImage, for: .normal)
        leftButton.tintColor = green
        
        let origAddImage = UIImage(named: "add-30");
        let tintedAddImage = origAddImage?.withRenderingMode(UIImage.RenderingMode.alwaysTemplate)
        addTitleButton.setImage(tintedAddImage, for: .normal)
        addTitleButton.tintColor = green
        
        configureView()
    }
    
    private func updateRun(titleInput: String) {
        let runTitle = run
        
        titleTextField.text = titleInput
        runTitle?.title = titleInput
        titleLabel.text = titleInput
        CoreDataStack.saveContext()
    }
    
    private func configureView() {
        let distance = Measurement(value: run.distance, unit: UnitLength.meters)
        let seconds = Int(run.duration)
        let formattedDistance = FormatDisplay.distance(distance)
        let formattedDate = FormatDisplay.date(run.timestamp)
        let formattedTime = FormatDisplay.time(seconds)
        let formattedPace = FormatDisplay.pace(distance: distance,
                                               seconds: seconds,
                                               outputUnit: UnitSpeed.minutesPerMile)
        
        dateLabel.text = formattedDate
        paceLabel.text = formattedTime //"\(formattedTime)\n Time"
        distanceLabel.text = formattedDistance
        timeLabel.text = formattedPace //"\(formattedPace)\n Pace"
        
        loadMap()
    }
    
    // MARK: - Map Methods
    private func mapRegion() -> MKCoordinateRegion? {
        
        guard
            let locations = run.locations,
            locations.count > 0 else { return nil }
        
        let latitudes = locations.map {location -> Double in
            let location = location as! Location
            return location.latitude
        }
        
        let longitudes = locations.map {location -> Double in
            let location = location as! Location
            return location.longitude
        }
        
        let maxLat = latitudes.max()!
        let minLat = latitudes.min()!
        let maxLong = longitudes.max()!
        let minLong = longitudes.min()!
        
        
        let center = CLLocationCoordinate2D(latitude: (minLat + maxLat) / 2, longitude: (minLong + maxLong) / 2)
        NSLog("center: \(center)")
        let span = MKCoordinateSpan(latitudeDelta: abs((minLat - maxLat) * 1.3), longitudeDelta: abs((minLong - maxLong) * 1.3))
        return MKCoordinateRegion(center: center, span: span)
    }
    
    private func polyline() -> MKPolyline {
        
        guard let locations = run.locations else { return MKPolyline() }
        
        let coords: [CLLocationCoordinate2D] = locations.map { location in
            let location = location as! Location
            return CLLocationCoordinate2D(latitude: location.latitude, longitude: location.longitude)
        }
        return MKPolyline(coordinates: coords, count: coords.count)
    }
    
    private func colorPolyLine() -> [MultiColorPolyline] {
        
        // 1
        let locations = run.locations?.array as! [Location]
        var coordinates: [(CLLocation, CLLocation)] = []
        var speeds: [Double] = []
        var minSpeed = Double.greatestFiniteMagnitude
        var maxSpeed = 0.0
        
        // 2
        for (first, second) in zip(locations, locations.dropFirst()) {
            let start = CLLocation(latitude: first.latitude, longitude: first.longitude)
            let end = CLLocation(latitude: second.latitude, longitude: second.longitude)
            coordinates.append((start, end))
            
            //3
            let distance = end.distance(from: start)
            let time = second.timestamp!.timeIntervalSince(first.timestamp! as Date)
            let speed = time > 0 ? distance / time : 0
            speeds.append(speed)
            minSpeed = min(minSpeed, speed)
            maxSpeed = max(maxSpeed, speed)
        }
        
        //4
        let midSpeed = speeds.reduce(0, +) / Double(speeds.count)
        
        //5
        var segments: [MultiColorPolyline] = []
        for ((start, end), speed) in zip(coordinates, speeds) {
            let coords = [start.coordinate, end.coordinate]
            let segment = MultiColorPolyline(coordinates: coords, count: 2)
            segment.color = segmentColor(speed: speed,
                                         midSpeed: midSpeed,
                                         slowestSpeed: minSpeed,
                                         fastestSpeed: maxSpeed)
            segments.append(segment)
        }
        return segments
    }
    
    private func loadMap() {
        
        guard let locations = run.locations,
            locations.count > 0,
            let region = mapRegion()
        else {
            let alert = UIAlertController(title: "Error",
                                          message: "Sorry, this run has no location saved",
                                          preferredStyle: .alert)
            alert.addAction(UIAlertAction(title: "OK", style: .cancel))
            present(alert, animated: true)
            return
        }
        
        mapView.setRegion(region, animated: true)
        mapView.addOverlays(colorPolyLine())
    }
    
    private func segmentColor(speed: Double, midSpeed: Double, slowestSpeed: Double, fastestSpeed: Double) -> UIColor {
        
        enum BaseColors {
            static let r_red: CGFloat = 1
            static let r_green: CGFloat = 20 / 255
            static let r_blue: CGFloat = 44 / 255
            
            static let y_red: CGFloat = 1
            static let y_green: CGFloat = 215 / 255
            static let y_blue: CGFloat = 0
            
            static let g_red: CGFloat = 0
            static let g_green: CGFloat = 146 / 255
            static let g_blue: CGFloat = 78 / 255
        }
        let red, green, blue: CGFloat
        
        if speed < midSpeed {
            let ratio = CGFloat((speed - slowestSpeed) / (midSpeed - slowestSpeed))
            red = BaseColors.r_red + ratio * (BaseColors.y_red - BaseColors.r_red)
            green = BaseColors.r_green + ratio * (BaseColors.y_green - BaseColors.r_green)
            blue = BaseColors.r_blue + ratio * (BaseColors.y_blue - BaseColors.r_blue)
        } else {
            let ratio = CGFloat((speed - midSpeed) / (fastestSpeed - midSpeed))
            red = BaseColors.y_red + ratio * (BaseColors.g_red - BaseColors.y_red)
            green = BaseColors.y_green + ratio * (BaseColors.g_green - BaseColors.y_green)
            blue = BaseColors.y_blue + ratio * (BaseColors.g_blue - BaseColors.y_blue)
        }
        return UIColor(red: red, green: green, blue: blue, alpha: 1)
    }
    
    /*
    // MARK: - Navigation

    // In a storyboard-based application, you will often want to do a little preparation before navigation
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        // Get the new view controller using segue.destination.
        // Pass the selected object to the new view controller.
    }
    */

}

extension RunDetailsViewController: MKMapViewDelegate {
    func mapView(_ mapView: MKMapView, rendererFor overlay: MKOverlay) -> MKOverlayRenderer {
    
        guard let polyline = overlay as? MultiColorPolyline else {
            return MKOverlayRenderer(overlay: overlay)
        }
    
        let renderer = MKPolylineRenderer(polyline: polyline)
        renderer.strokeColor = polyline.color
        renderer.lineWidth = 3
        return renderer
    }
}
