import UIKit
import CoreLocation

class ViewController: UIViewController, CLLocationManagerDelegate {

    // Used to start getting the users location
    let locationManager = CLLocationManager()
    var currentLocation: CLLocation = .init()
    
    @IBOutlet weak var fajr: UILabel!
    @IBOutlet weak var johr: UILabel!
    @IBOutlet weak var asr: UILabel!
    @IBOutlet weak var maghrib: UILabel!
    @IBOutlet weak var isha: UILabel!
    @IBOutlet weak var loadingView: UIView!
    @IBOutlet weak var loading: UIActivityIndicatorView!
    
    func fetchData(location: CLLocation) {
        print("Fetching.......")
        var components = URLComponents()
        components.scheme = "http"
        components.host = "api.aladhan.com"
        components.path = "/v1/timings/30-11-2024"

        components.queryItems = [
            URLQueryItem(name: "latitude", value: "\(location.coordinate.latitude)"),
            URLQueryItem(name: "longitude", value: "\(location.coordinate.latitude)")
        ]
        print(components.string)
        let url = URL(string: components.string!)!
        let req = URLRequest(url: url)
        let session = URLSession.shared
        let task = session.dataTask(with: req) { (data, response, error) in

            if let error = error {
                // Handle HTTP request error
            } else if let data = data {
                print("[AAAAAA]  = \(data)")
                do {
                    let book = try JSONDecoder().decode(Welcome.self, from: data)
                    print("Title: \(book.data.timings.asr)")
                    print(book.data.meta.timezone)
                    DispatchQueue.main.async {
                        self.fajr.text = "Fajr : " + book.data.timings.fajr
                        self.johr.text = "Johr : " + book.data.timings.dhuhr
                        self.asr.text = "Asr : " + book.data.timings.asr
                        self.maghrib.text = "Maghrib : " + book.data.timings.maghrib
                        self.isha.text = "Isha : " + book.data.timings.isha
                        DispatchQueue.main.asyncAfter(deadline: .now() + 1) {
                            self.loading.stopAnimating()
                            self.loadingView.isHidden = true
                        }
                    }
                    
                } catch {
                    print("Error decoding JSON: \(error)")
                }
            } else {
                // Handle unexpected error
            }
        }.resume()
    }
    
    @IBAction func updateAction(_ sender: Any) {
        loading.hidesWhenStopped = true
        loading.startAnimating()
        loadingView.isHidden = false
        fetchData(location: currentLocation)
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        locationManager.requestAlwaysAuthorization()
        if CLLocationManager.locationServicesEnabled() {
            locationManager.delegate = self
            locationManager.desiredAccuracy = kCLLocationAccuracyBest
            locationManager.startUpdatingLocation()
        }
    }
    
    // Print out the location to the console
    func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
        if let location = locations.first {
            print(location.coordinate)
            currentLocation = location
            fetchData(location: currentLocation)
            // http://api.aladhan.com/v1/timings/29-11-2024?latitude=37.785834&longitude=-122.406417
            
        }
    }
    
    // If we have been deined access give the user the option to change it
    func locationManager(_ manager: CLLocationManager, didChangeAuthorization status: CLAuthorizationStatus) {
        if(status == CLAuthorizationStatus.denied) {
            showLocationDisabledPopUp()
        }
    }
    
    // Show the popup to the user if we have been deined access
    func showLocationDisabledPopUp() {
        let alertController = UIAlertController(title: "Background Location Access Disabled",
                                                message: "In order to deliver pizza we need your location",
                                                preferredStyle: .alert)
        
        let cancelAction = UIAlertAction(title: "Cancel", style: .cancel, handler: nil)
        alertController.addAction(cancelAction)
        
        let openAction = UIAlertAction(title: "Open Settings", style: .default) { (action) in
            if let url = URL(string: UIApplication.openSettingsURLString) {
                UIApplication.shared.open(url, options: [:], completionHandler: nil)
            }
        }
        alertController.addAction(openAction)
        
        self.present(alertController, animated: true, completion: nil)
    }
    
}


// MARK: - Welcome
struct Welcome: Codable {
    let code: Int
    let status: String
    let data: DataClass
}

// MARK: - DataClass
struct DataClass: Codable {
    let timings: Timings
    let date: DateClass
    let meta: Meta
}

// MARK: - DateClass
struct DateClass: Codable {
    let readable, timestamp: String
    let hijri: Hijri
    let gregorian: Gregorian
}

// MARK: - Gregorian
struct Gregorian: Codable {
    let date, format, day: String
    let weekday: GregorianWeekday
    let month: GregorianMonth
    let year: String
    let designation: Designation
}

// MARK: - Designation
struct Designation: Codable {
    let abbreviated, expanded: String
}

// MARK: - GregorianMonth
struct GregorianMonth: Codable {
    let number: Int
    let en: String
}

// MARK: - GregorianWeekday
struct GregorianWeekday: Codable {
    let en: String
}

// MARK: - Hijri
struct Hijri: Codable {
    let date, format, day: String
    let weekday: HijriWeekday
    let month: HijriMonth
    let year: String
    let designation: Designation
}

// MARK: - HijriMonth
struct HijriMonth: Codable {
    let number: Int
    let en, ar: String
}

// MARK: - HijriWeekday
struct HijriWeekday: Codable {
    let en, ar: String
}

// MARK: - Meta
struct Meta: Codable {
    let latitude, longitude: Double
    let timezone: String
    let method: Method
    let latitudeAdjustmentMethod, midnightMode, school: String
    let offset: [String: Int]
}

// MARK: - Method
struct Method: Codable {
    let id: Int
    let name: String
    let params: Params
    let location: Location
}

// MARK: - Location
struct Location: Codable {
    let latitude, longitude: Double
}

// MARK: - Params
struct Params: Codable {
    let fajr, isha: Int

    enum CodingKeys: String, CodingKey {
        case fajr = "Fajr"
        case isha = "Isha"
    }
}

// MARK: - Timings
struct Timings: Codable {
    let fajr, sunrise, dhuhr, asr: String
    let sunset, maghrib, isha, imsak: String
    let midnight, firstthird, lastthird: String

    enum CodingKeys: String, CodingKey {
        case fajr = "Fajr"
        case sunrise = "Sunrise"
        case dhuhr = "Dhuhr"
        case asr = "Asr"
        case sunset = "Sunset"
        case maghrib = "Maghrib"
        case isha = "Isha"
        case imsak = "Imsak"
        case midnight = "Midnight"
        case firstthird = "Firstthird"
        case lastthird = "Lastthird"
    }
}
