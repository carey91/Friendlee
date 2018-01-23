//
//  ViewController.swift
//  Friendlee
//
//  Created by Mathan on 1/22/18.
//  Copyright © 2018 Ruah. All rights reserved.
//

import UIKit
import FBSDKCoreKit
import FBSDKLoginKit
import CountryPickerView
import SkyFloatingLabelTextField
import Navajo_Swift

public extension UIView {
    
    func shake(count : Float = 2,for duration : TimeInterval = 0.5,withTranslation translation : Float = -5) {
        
        let animation : CABasicAnimation = CABasicAnimation(keyPath: "transform.translation.x")
        animation.timingFunction = CAMediaTimingFunction(name: kCAMediaTimingFunctionLinear)
        animation.repeatCount = count
        animation.duration = duration/TimeInterval(animation.repeatCount)
        animation.autoreverses = true
        animation.byValue = translation
        layer.add(animation, forKey: "shake")
    }
    
}

public extension String {
    func isValidEmail() -> Bool {
        let emailRegEx = "[A-Z0-9a-z._%+-]+@[A-Za-z0-9.-]+\\.[A-Za-z]{2,64}"
        
        let emailTest = NSPredicate(format:"SELF MATCHES %@", emailRegEx)
        return emailTest.evaluate(with: self)
    }
}


enum ValidationError : Error {
    case NonMandatoryTextField
}

class ViewController: UIViewController, FBSDKLoginButtonDelegate, CountryPickerViewDelegate, UITextFieldDelegate {
 
    
    @IBOutlet weak var nameTextField: SkyFloatingLabelTextField!
    
    @IBOutlet weak var emailTextField: SkyFloatingLabelTextField!
    
    @IBOutlet weak var passwordTextField: SkyFloatingLabelTextField!
    
    @IBOutlet weak var confirmPasswordTextField: SkyFloatingLabelTextField!
    
    @IBOutlet weak var phoneTextField: UITextField!
    
    @IBOutlet weak var fbLoginButton: FBSDKLoginButton!
    
    @IBOutlet weak var validationLabel: UILabel!
    
    var activeTextField : UITextField!
    
    var mandatoryFields  = [UITextField]()
    var emptyErrorMessages = [String]()
    
    var emailFields = [UITextField]()
    var emailErrorMessages = [String]()
    
    private var validator = PasswordValidator.standard
    
    let lightGreyColor: UIColor = UIColor(red: 197 / 255, green: 205 / 255, blue: 205 / 255, alpha: 1.0)
    let darkGreyColor: UIColor = UIColor(red: 52 / 255, green: 42 / 255, blue: 61 / 255, alpha: 1.0)
    let overcastBlueColor: UIColor = UIColor(red: 0, green: 187 / 255, blue: 204 / 255, alpha: 1.0)
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        if(FBSDKAccessToken.current() == nil)
        {
            print("not logged in")
        }
        else{
            print("logged in already")
            
        }
        
        fbLoginButton.delegate = self
        
        let countryPicker = CountryPickerView(frame: CGRect(x: 0, y: 0, width: 120, height: 30))
        phoneTextField.leftView = countryPicker
        phoneTextField.leftViewMode = .always
        countryPicker.delegate = self
        
//        applySkyscannerTheme(textField: nameTextField)
        
        self.addMandatoryField(textField: nameTextField, message: "Please enter your name")
        self.addMandatoryField(textField: emailTextField, message: "Please enter your email id")
        self.addEmailField(textField: emailTextField, message: "Please enter a valid email address")
        self.addMandatoryField(textField: nameTextField, message: "Name canot be empty")
        self.addMandatoryField(textField: phoneTextField, message: "Please enter your phone number")
    
        
        
        // Do any additional setup after loading the view, typically from a nib.
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
//        passwordTextField.becomeFirstResponder()
        registerForNotifications()
    }
    
    @IBAction func passwordFieldUpdated(_ sender: SkyFloatingLabelTextField) {
        validationLabel.isHidden = false
        validatePassword()
    }
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        NotificationCenter.default.removeObserver(self)
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    private func validatePassword() {
        let password = passwordTextField.text ?? ""
        
        if let failingRules = validator.validate(password) {
            
            displayValidationMesage(message: failingRules.map { return $0.localizedErrorDescription }.joined(separator: "\n"))
            
        }
    }
    
    private func registerForNotifications() {
        NotificationCenter.default.addObserver(self, selector: #selector(self.keyboardWillShow(notification:)), name:NSNotification.Name.UIKeyboardWillShow, object: nil);
        NotificationCenter.default.addObserver(self, selector: #selector(self.keyboardWillHide(notification:)), name:NSNotification.Name.UIKeyboardWillHide, object: nil);
    }
    
    @objc func keyboardWillShow(notification:NSNotification?) {
        let keyboardSize = (notification?.userInfo![UIKeyboardFrameEndUserInfoKey] as! NSValue).cgRectValue.size
        self.view.frame.origin.y = 0
        let keyboardYPosition = self.view.frame.size.height - keyboardSize.height
        if keyboardYPosition < self.activeTextField!.frame.origin.y {
            UIView.animate(withDuration: 200) { () -> Void in
                self.view.frame.origin.y = self.view.frame.origin.y - keyboardSize.height + 30
            }
        }
    }
    
    @objc func keyboardWillHide(notification:NSNotification?) {
        UIView.animate(withDuration: 200) { () -> Void in
            self.view.frame.origin.y = 0
        }
    }
    
    func validateEmailForFields(emailTextFields:[UITextField]) -> [Bool] {
        var validatedBits = [Bool]()
        for emailTextField in emailTextFields {
            if let text = emailTextField.text, !text.isValidEmail() {
                emailTextField.shake(count: 2, for: 0.5, withTranslation: 10)
                validatedBits.append(false)
            } else {
                validatedBits.append(true)
            }
        }
        return validatedBits
    }
    

    
    func validateEmptyFields(textFields : [UITextField]) -> [Bool] {
        var validatedBits = [Bool]()
        for textField in textFields {
            if let text = textField.text, text.isEmpty {
                textField.shake(count: 2, for: 0.5, withTranslation: 10)
                validatedBits.append(false)
            } else {
                validatedBits.append(true)
            }
        }
        return validatedBits
    }
    
    func addMandatoryField(textField : UITextField, message : String) {
        self.mandatoryFields.append(textField)
        self.emptyErrorMessages.append(message)
    }
    
    func addEmailField(textField : UITextField , message : String) {
        textField.keyboardType = .emailAddress
        self.emailFields.append(textField)
        self.emailErrorMessages.append(message)
    }
    
    func errorMessageForEmptyTextField(textField : UITextField) throws -> String  {
        if self.mandatoryFields.contains(textField) {
            return self.emptyErrorMessages[self.mandatoryFields.index(of: textField)!]
        } else {
            throw ValidationError.NonMandatoryTextField
        }
    }
    
    func errorMessageForMultipleEmptyErrors() -> String {
        return "Fields cannot be empty"
    }
    
    func errorMessageForMutipleEmailError() -> String {
        return "Invalid email addresses"
    }
    
    func showVisualFeedbackWithErrorMessage(errorMessage : String) {
        displayValidationMesage(message: errorMessage)
        //fatalError("Implement this method")
    }
    
    func didCompleteValidationSuccessfully() {
        
    }
    
    func errorMessageAfterPerformingValidation() -> String? {
        if let errorMessage = self.errorMessageAfterPerformingEmptyValidations() {
            return errorMessage
        }
        if let errorMessage = self.errorMessageAfterPerformingEmailValidations() {
            return errorMessage
        }
        
        return nil
    }
    
    private func errorMessageAfterPerformingEmptyValidations() -> String? {
        let emptyValidationBits = self.performEmptyValidations()
        var index = 0
        var errorCount = 0
        var errorMessage : String?
        for validation in emptyValidationBits {
            if !validation {
                errorMessage = self.emptyErrorMessages[index]
                errorCount += 1
            }
            if errorCount > 1 {
                return self.errorMessageForMultipleEmptyErrors()
            }
            index = index + 1
        }
        return errorMessage
    }
    
    private func errorMessageAfterPerformingEmailValidations() -> String? {
        let emptyValidationBits = self.performEmailValidations()
        var index = 0
        var errorCount = 0
        var errorMessage : String?
        for validation in emptyValidationBits {
            if !validation {
                errorMessage = self.emailErrorMessages[index]
                errorCount += 1
            }
            if errorCount > 1 {
                return self.errorMessageForMutipleEmailError()
            }
            index = index + 1
        }
        return errorMessage
    }
    
    func performEqualValidationsForTextField(textField : UITextField, anotherTextField : UITextField) -> Bool {
        return textField.text! == anotherTextField.text!
    }
    
    
    private func performEmptyValidations() -> [Bool] {
        return validateEmptyFields(textFields: self.mandatoryFields)
    }
    private func performEmailValidations() -> [Bool] {
        return validateEmailForFields(emailTextFields: self.emailFields)
    }

    
    func countryPickerView(_ countryPickerView: CountryPickerView, didSelectCountry country: Country) {
        let message = "Name: \(country.name) \nCode: \(country.code) \nPhone: \(country.phoneCode)"
        print(message)
    }
    
    func loginButton(_ loginButton: FBSDKLoginButton!, didCompleteWith result: FBSDKLoginManagerLoginResult!, error: Error!) {
        updateUserInfo()
    }
    
    func loginButtonDidLogOut(_ loginButton: FBSDKLoginButton!) {
        
    }
    
    func updateUserInfo()
    {
        let graphRequest:FBSDKGraphRequest = FBSDKGraphRequest(graphPath: "me", parameters: ["fields":"first_name,email, picture.type(large)"])
        
        graphRequest.start(completionHandler: { (connection, result, error) -> Void in
            
            if ((error) != nil)
            {
                print("Error: \(String(describing: error))")
            }
            else
            {
                let data:[String:AnyObject] = result as! [String : AnyObject]
                print(data)
                
            }
        })
    }
    
    
    @IBAction func onSignupPressed(_ sender: UIButton) {
        
        validationLabel.isHidden = false
        
        if ( performEqualValidationsForTextField(textField: passwordTextField, anotherTextField: confirmPasswordTextField) )
        {
            print("Same")
        } else
        {
            print("not same")
        }
        
        if let errorMessage = self.errorMessageAfterPerformingValidation() {
            self.showVisualFeedbackWithErrorMessage(errorMessage: errorMessage)
            return
        }
        self.didCompleteValidationSuccessfully()
        
       
        
    }
    
    func textFieldDidBeginEditing(_ textField: UITextField) {
        self.activeTextField = textField
    }
    func textFieldDidEndEditing(_ textField: UITextField) {
        self.activeTextField = nil
    }
    
    func applySkyscannerTheme(textField: SkyFloatingLabelTextField) {
        
        textField.tintColor = overcastBlueColor
        
        textField.textColor = darkGreyColor
        textField.lineColor = lightGreyColor
        
        textField.selectedTitleColor = overcastBlueColor
        textField.selectedLineColor = overcastBlueColor
        
        // Set custom fonts for the title, placeholder and textfield labels
        textField.titleLabel.font = UIFont(name: "AppleSDGothicNeo-Regular", size: 12)
        textField.placeholderFont = UIFont(name: "AppleSDGothicNeo-Light", size: 18)
        textField.font = UIFont(name: "AppleSDGothicNeo-Regular", size: 18)
    }
    
    func displayValidationMesage(message: String)
    {
        validationLabel.text = message
        Timer.scheduledTimer(timeInterval: 5, target: self, selector: #selector(self.hideLabel), userInfo: nil, repeats: false)
    }
    
    @objc func hideLabel()
    {
        validationLabel.isHidden = true
    }

}
