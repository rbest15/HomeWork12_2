import UIKit
import MapKit
import Vision
import CoreML

class ViewController: UIViewController, MKMapViewDelegate, UIGestureRecognizerDelegate {

    @IBOutlet weak var map: MKMapView!
    
    let initialLocation = CLLocation(latitude: 45.057191, longitude: 38.982560)
    
    @IBOutlet weak var sSlider: UISlider!
    @IBOutlet weak var rSlider: UISlider!
    @IBOutlet weak var fSlider: UISlider!
    @IBOutlet weak var sLabel: UILabel!
    @IBOutlet weak var rLabel: UILabel!
    @IBOutlet weak var fLabel: UILabel!
    @IBOutlet weak var priceLabel: UILabel!
    
    private var currentPointCoordinates : CLLocationCoordinate2D? = nil
    
    @IBOutlet var longPressRecognition: UILongPressGestureRecognizer!
    
    @IBAction func sSliderChanged(_ sender: Any) {
        sLabel.text = "Площадь: \(Int(sSlider.value))"
        checkPrice()
    }
    @IBAction func rSliderChanged(_ sender: Any) {
        rLabel.text = "Количество комнат: \(Int(rSlider.value))"
        checkPrice()
    }
    @IBAction func fSliderChanged(_ sender: Any) {
        fLabel.text = "Этаж: \(Int(fSlider.value))"
        checkPrice()
    }
    
    @IBAction func longPress(_ sender: Any) {
        map.annotations.forEach { (ann) in
            self.map.removeAnnotation(ann)
        }
        addAnnotation(gesture: longPressRecognition)
        checkPrice()
    }
    override func viewDidLoad() {
        super.viewDidLoad()
        map.delegate = self
        map.showsUserLocation = true
        map.centerToLocation(initialLocation)
       
        longPressRecognition.delegate = self
        
        setupSliders()
    }
    
    func setupSliders(){
        sSlider.value = 85
        rSlider.value = 4
        fSlider.value = 11
        sLabel.text = "Площадь: \(sSlider.value)"
        rLabel.text = "Количество комнат: \(rSlider.value)"
        fLabel.text = "Этаж: \(fSlider.value)"
    }
    
    func addAnnotation(gesture: UIGestureRecognizer) {
        if gesture.state == .ended {
            if let map = gesture.view as? MKMapView {
                let point = gesture.location(in: map)
                let coord = map.convert(point, toCoordinateFrom: map)
                let ann = MKPointAnnotation()
                ann.coordinate = coord
                self.currentPointCoordinates = coord
                map.addAnnotation(ann)
            }
        }
    }
    
    func checkPrice(){
        let floor = Double(fSlider.value)
        let area = Double(sSlider.value)
        let rooms = Double(rSlider.value)
        let lat = Double(currentPointCoordinates?.latitude ?? 0)
        let long = Double(currentPointCoordinates?.longitude ?? 0)
        
        let config = MLModelConfiguration()
        guard let model = try? MyTabularRegressor_3(configuration: config) else {
            fatalError()
        }
        let input = MyTabularRegressor_3Input(Area: area, Floor: floor, Rooms: rooms, Latitude: lat, Longitude: long)
        guard let output = try? model.prediction(input: input) else {
            fatalError()
        }
        
        let currencyFormatter = NumberFormatter()
        currencyFormatter.usesGroupingSeparator = true
        currencyFormatter.numberStyle = .currency
        currencyFormatter.locale = Locale.current
        
        let price = currencyFormatter.string(from: NSNumber(value: output.Price))
        priceLabel.text = "Цена: \(price ?? "0")"
        print(output.Price)
    }
    
}

private extension MKMapView {
  func centerToLocation(_ location: CLLocation, regionRadius: CLLocationDistance = 22500) {
    let coordinateRegion = MKCoordinateRegion(center: location.coordinate, latitudinalMeters: regionRadius, longitudinalMeters: regionRadius)
    setRegion(coordinateRegion, animated: true)
  }
}


