//
//  ChangeCityViewController.swift
//  IonWeather
//
//  Created by Ion M on 6/5/18.
//  Copyright © 2018 Ion M. All rights reserved.
//

import UIKit

protocol ChangeCityDelegate {
    func userEnteredANewCityName(city: String)
}

class ChangeCityViewController: UIViewController {
    var delegate: ChangeCityDelegate?
    
    @IBOutlet weak var changeCityTextField: UITextField!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        changeCityTextField.delegate = self
    }
    
    @IBAction func getWeatherPressed(_ sender: AnyObject) {
        // Pass the name of the city that user entered
        delegate?.userEnteredANewCityName(city: changeCityTextField.text!)
        dismiss(animated: true, completion: nil)
    }
    
    @IBAction func backButtonPressed(_ sender: AnyObject) {
        dismiss(animated: true, completion: nil)
    }
    
    override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent?) {
        view.endEditing(true)
    }
}

extension ChangeCityViewController: UITextFieldDelegate {
    func textFieldShouldReturn(_ textField: UITextField) -> Bool {
        textField.resignFirstResponder()
        return true
    }
}
