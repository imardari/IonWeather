//
//  WeatherViewController.swift
//  IonWeather
//
//  Created by Ion M on 6/5/18.
//  Copyright © 2018 Ion M. All rights reserved.
//

import UIKit
import CoreLocation
import Alamofire
import SwiftyJSON
import RevealingSplashView

class WeatherViewController: UIViewController {
    
    // Properties
    let tempInKelvin = 273.15
    let defaults = UserDefaults.standard
    
    // Client Properties
    let WEATHER_URL = "http://api.openweathermap.org/data/2.5/weather"
    let APP_ID = "1cc0b5a8bdc8c7be73db12ffce202ada"
    
    // Instance variables
    let locationManager = CLLocationManager()
    let weatherDataModel = WeatherDataModel()
    
    // IBOutlets
    @IBOutlet weak var weatherIcon: UIImageView!
    @IBOutlet weak var cityLabel: UILabel!
    @IBOutlet weak var temperatureLabel: UILabel!
    @IBOutlet weak var switchView: UISwitch!
    @IBOutlet weak var activityIndicator: UIActivityIndicatorView!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        // Set up the location manager
        locationManager.delegate = self
        // Set the accuracy of the location
        locationManager.desiredAccuracy = kCLLocationAccuracyBest
        // Request from user the permission to get his gps location
        locationManager.requestWhenInUseAuthorization()
        // Look for user's gps location
        locationManager.startUpdatingLocation()
        
        // If there was a SwitchState key created load the state
        if (defaults.object(forKey: "SwitchState") != nil) {
            switchView.isOn = defaults.bool(forKey: "SwitchState")
        }
        
        // Initialize a revealing Splash
        let revealingSplashView = RevealingSplashView(iconImage: UIImage(named: "sunIcon")!,iconInitialSize: CGSize(width: 80, height: 80), backgroundColor: UIColor(patternImage: UIImage(named: "weatherSplashBackgroud")!))
        
        //Add the revealing splash view as a sub view
        view.addSubview(revealingSplashView)
        
        //Start animation
        revealingSplashView.startAnimation()
    }
    
    @IBAction func changeTemp(_ sender: UISwitch) {
        // Save the current switch state as a bool and update the temp appropriately
        if sender.isOn {
            defaults.set(true, forKey: "SwitchState")
            updateUIWithWeatherData(temperatureIn: "\(weatherDataModel.temperature * Int(9) / 5 + 32)°F")
        } else {
            defaults.set(false, forKey: "SwitchState")
            updateUIWithWeatherData(temperatureIn: "\(weatherDataModel.temperature)°C")
        }
    }
    
    // MARK: Networking
    
    func getWeatherData(url: String, parameters: [String: String]) {
        DispatchQueue.main.async {
            self.switchView.isEnabled = false
            self.activityIndicator.startAnimating()
        }
        // Request data
        Alamofire.request(url, method: .get, parameters: parameters).responseJSON {
            response in
            if response.result.isSuccess {
                // Format the data
                let weatherJSON = JSON(response.result.value!)
                // Pass the weatherJSON constant which contains all of the weather information
                self.updateWeatherData(json: weatherJSON)
                DispatchQueue.main.async {
                    self.activityIndicator.stopAnimating()
                }
                self.switchView.isEnabled = true
            }
            else {
                self.cityLabel.text = "Conection Issues"
                let alert = UIAlertController(title: "Whoops", message: "Looks like you have connectivity issues. Please check your internet connection.", preferredStyle: UIAlertControllerStyle.alert)
                alert.addAction(UIAlertAction(title: "OK", style: UIAlertActionStyle.default, handler: nil))
                self.present(alert, animated: true, completion: nil)
            }
        }
    }
    
    // MARK: JSON Parsing
    
    func updateWeatherData(json: JSON) {
        // Receive the data
        if let tempResult = json["main"]["temp"].double {
            // Access and set the properties of WeatherDataModel() class to hold the proper data
            weatherDataModel.temperature = Int(tempResult - tempInKelvin)
            weatherDataModel.city = json["name"].stringValue
            weatherDataModel.condition = json["weather"][0]["id"].intValue
            weatherDataModel.weatherIconName = weatherDataModel.updateWeatherIcon(condition: weatherDataModel.condition)
            // Update the UI
            changeTemp(switchView)
        }
        else {
            cityLabel.text = "Weather Unavailable"
        }
    }
    
    // MARK: UI Updates
    
    func updateUIWithWeatherData(temperatureIn: String) {
        cityLabel.text = weatherDataModel.city
        temperatureLabel.text = temperatureIn
        weatherIcon.image = UIImage(named: weatherDataModel.weatherIconName)
    }
}

// MARK: Location Manager Delegate Methods

extension WeatherViewController: CLLocationManagerDelegate {
    
    // Find the location
    func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
        // Grab the last value(most accurate) from the array
        let location = locations[locations.count - 1]
        // Check that the value we are getting back is valid
        if location.horizontalAccuracy > 0 {
            // Stop updating the location as soon as we got a valid result. Otherwise it will keep updating which will result in battery drainage
            locationManager.stopUpdatingLocation()
            // Stop the locationManager immediately after it got the location coordinates
            locationManager.delegate = nil
            // Store latitude coordinates
            let latitude = String(location.coordinate.latitude)
            // Store longitude coordinates
            let longitute = String(location.coordinate.longitude)
            // Store parameters in a dictionary
            let params: [String : String] = ["lat" : latitude, "lon" : longitute, "appid" : APP_ID]
            // Make an http request
            getWeatherData(url: WEATHER_URL, parameters: params)
        }
    }
    
    // In case the location could not be found let the user know
    func locationManager(_ manager: CLLocationManager, didFailWithError error: Error) {
        print("There was an error receiving user's location: \(error)")
        cityLabel.text = "Location Unavailable"
    }
}

// MARK: Change City Delegate methods

extension WeatherViewController: ChangeCityDelegate {
    
    func userEnteredANewCityName(city: String) {
        let params = ["q" : city, "appid" : APP_ID]
        getWeatherData(url: WEATHER_URL, parameters: params)
    }
    
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        if segue.identifier == "changeCityName" {
            let destinationVC = segue.destination as! ChangeCityViewController
            destinationVC.delegate = self
        }
    }
}
